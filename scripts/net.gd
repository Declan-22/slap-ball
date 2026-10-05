extends Node3D
## Slap Ball — Step 1: zoned net (hybrid sim, actually tuned).
## Net: 135cm diameter (radius 0.675), height ~0.30m. No rim faults.
## Zones: Center (clean high), Mid (flatter faster skip), Rim pocket (low sticky).
## Implementation: shaped trigger — kills velocity, relaunches on fixed arc
## toward pass-through direction + zone modifier. Deterministic, no wind.

signal bounced(zone: String, in_angle_deg: float, out_vel: Vector3, radial_norm: float)
signal net_dead(zone: String, radial_norm: float)

@export var net_radius: float = 0.675 ## 135cm diameter
@export var net_height: float = 0.30 ## rim tube center height (visual)
@export var fabric_edge_y: float = 0.28 ## visual fabric height at the rim
@export var fabric_sag: float = 0.06 ## visual center dip — bounce surface matches this
@export var ball_radius: float = 0.11
@export var center_frac: float = 0.35
@export var mid_frac: float = 0.80
## Passive-net model: the net returns energy, never adds much.
## Outgoing = reflection of incoming about the fabric normal, scaled by
## zone restitution, plus a small base pop so soft drops still leave the net.
@export var center_restitution: float = 0.82 ## clean, livelier middle
@export var mid_restitution: float = 0.72 ## deader, skips through flatter
@export var pocket_restitution: float = 0.45 ## sticky rim, kills pace
@export var settle_speed: float = 1.0 ## below this the ball is dead: rests on fabric
@export var dead_out_speed: float = 1.2 ## a bounce weaker than this dies immediately
@export var max_out_speed: float = 11.0
@export var bounce_cooldown_msec: int = 40 ## short: gravity must not rebuild pace between bounces

var _last_bounce_msec: int = -10000
var _held: bool = false
var _hold_msec: int = 100
var _hold_until_msec: int = 0
var _held_out_vel: Vector3 = Vector3.ZERO
var _hold_top: Vector3 = Vector3.ZERO
var _hold_bottom: Vector3 = Vector3.ZERO
var _dent: float = 0.0
var _dent_pos := Vector2(99.0, 99.0)
var _ball: Node3D
var last_zone: String = "-"
var last_in_angle: float = 0.0
var last_out_vel: Vector3 = Vector3.ZERO

func _ready() -> void:
	# Ball is sibling named "Ball" under same parent (NetLab root).
	_ball = get_parent().get_node_or_null("Ball") if get_parent() else null
	if _ball == null:
		# Fall back: search later each frame (lab scene may reorder).
		pass

func _physics_process(delta: float) -> void:
	_tick_dent(delta)
	if _held:
		_tick_hold()
		return
	if _ball == null:
		if get_parent():
			_ball = get_parent().get_node_or_null("Ball")
		if _ball == null:
			return
	if not ("velocity" in _ball and "flying" in _ball):
		return
	if not _ball.flying:
		return
	# Only bounce when ball is falling onto the net plane.
	if _ball.velocity.y >= 0.0:
		return
	var bp: Vector3 = _ball.global_position
	var lp: Vector3 = to_local(bp)
	var radial: float = Vector2(lp.x, lp.z).length()
	if radial > net_radius + ball_radius:
		return # clean miss — fault, no bounce (Step 1: just falls through)
	# Sag-aware surface: matches the visual fabric dip (edge 0.28, center ~0.22).
	var rn_pre: float = clampf(radial / net_radius, 0.0, 1.0)
	var surf_y: float = global_position.y + fabric_edge_y - fabric_sag * (1.0 - rn_pre * rn_pre)
	var bottom: float = bp.y - ball_radius
	if bottom > surf_y + 0.03 or bottom < surf_y - 0.30:
		return
	var now: int = Time.get_ticks_msec()
	if now - _last_bounce_msec < bounce_cooldown_msec:
		return
	_last_bounce_msec = now
	_do_bounce(radial)

func _tick_hold() -> void:
	if _ball.flying:
		_held = false # externally relaunched (test shot / reset) — drop the hold
		return
	var now: int = Time.get_ticks_msec()
	var t: float = 1.0 - float(_hold_until_msec - now) / float(maxi(_hold_msec, 1))
	_ball.global_position = _hold_top.lerp(_hold_bottom, clampf(t * 2.0, 0.0, 1.0))
	_ball.velocity = Vector3.ZERO
	if now >= _hold_until_msec:
		_held = false
		_ball.launch(_held_out_vel)

func _set_dent(local_xz: Vector2, dent: float) -> void:
	_dent_pos = local_xz
	_dent = dent
	_apply_dent()

func _tick_dent(delta: float) -> void:
	if _dent > 0.003:
		_dent *= exp(-6.0 * delta)
		_apply_dent()
	elif _dent != 0.0:
		_dent = 0.0
		_apply_dent()

func _apply_dent() -> void:
	var mesh := get_node_or_null("NetMesh") as MeshInstance3D
	if mesh and mesh.material_override:
		var mat := mesh.material_override as ShaderMaterial
		if mat:
			mat.set_shader_parameter("impact_pos", _dent_pos)
			mat.set_shader_parameter("impact_dent", _dent)

func get_zone(radial: float) -> String:
	var rn: float = radial / net_radius
	if rn < center_frac:
		return "CENTER"
	if rn < mid_frac:
		return "MID"
	return "POCKET"

func _do_bounce(radial: float) -> void:
	var v_in: Vector3 = _ball.velocity
	var in_speed: float = v_in.length()
	var in_angle: float = _ball.incoming_angle_deg()
	var zone: String = get_zone(radial)
	var rn: float = clampf(radial / net_radius, 0.0, 1.0)
	# Fabric normal of the sag bowl: straight up in the middle,
	# tilted slightly outward near the rim.
	var slope: float = 2.0 * fabric_sag * rn / net_radius
	var radial_dir := Vector3.ZERO
	var lp: Vector3 = to_local(_ball.global_position)
	var flat := Vector2(lp.x, lp.z)
	if flat.length() > 0.01:
		var n2 := flat.normalized()
		radial_dir = Vector3(n2.x, 0.0, n2.y)
	var surf_normal := Vector3(-slope * radial_dir.x, 1.0, -slope * radial_dir.z).normalized()
	# Passive reflection: steep in = high out, flat in = low skip. Never
	# returns more energy than came in, so dribbles can't explode.
	var restitution: float
	match zone:
		"CENTER":
			restitution = center_restitution
		"MID":
			restitution = mid_restitution
		_:
			restitution = pocket_restitution
	var rn_now: float = clampf(radial / net_radius, 0.0, 1.0)
	var surf_now: float = global_position.y + fabric_edge_y - fabric_sag * (1.0 - rn_now * rn_now)
	if in_speed < settle_speed:
		# Dead ball: not enough energy to leave the net. Rest it on the
		# fabric with nothing added — this is the honest end of a soft touch.
		_ball.global_position.y = surf_now + ball_radius
		_ball.stop()
		_held = false
		_set_dent(Vector2(lp.x, lp.z), 0.02)
		last_zone = zone
		net_dead.emit(zone, rn)
		return
	# Strictly passive: reflection scaled down, nothing added. Bounces can
	# only decay now — a rocket in is a rocket out, a dribble dies.
	var out_vel: Vector3 = (v_in - 2.0 * v_in.dot(surf_normal) * surf_normal) * restitution
	var spd: float = out_vel.length()
	if spd > max_out_speed:
		out_vel = out_vel / spd * max_out_speed
	elif spd < dead_out_speed:
		# Too weak to visibly leave the net: end it here instead of
		# rattling forever on gravity-rebuilt micro-falls.
		_ball.global_position.y = surf_now + ball_radius
		_ball.stop()
		_held = false
		_set_dent(Vector2(lp.x, lp.z), 0.02)
		last_zone = zone
		net_dead.emit(zone, rn)
		return
	# Catch-and-throw: pin the ball into the fabric, let the net dip hold
	# it for a beat (pocket holds longest — sticky), then release.
	var sink: float = clampf(in_speed * 0.012, 0.02, 0.09)
	_hold_top = Vector3(_ball.global_position.x, surf_now + ball_radius, _ball.global_position.z)
	_hold_bottom = Vector3(_ball.global_position.x, surf_now + ball_radius - sink, _ball.global_position.z)
	_hold_msec = 150
	match zone:
		"CENTER":
			_hold_msec = 90
		"MID":
			_hold_msec = 110
	_ball.global_position = _hold_top
	_ball.stop()
	_held = true
	_held_out_vel = out_vel
	_hold_until_msec = Time.get_ticks_msec() + _hold_msec
	_set_dent(Vector2(lp.x, lp.z), sink)

	last_zone = zone
	last_in_angle = in_angle
	last_out_vel = out_vel
	bounced.emit(zone, in_angle, out_vel, rn)
