extends Node3D
## Slap Ball — Step 1 lab controls.
## Keys: 1 = steep, 2 = flat, 3 = pocket, R = reset, Space = repeat last.
## Also wires UI buttons + readout labels.

@export var ball_path: NodePath = ^"Ball"
@export var net_path: NodePath = ^"Net"
@export var readout_path: NodePath = ^"UI/Readout"
@export var help_path: NodePath = ^"UI/Help"

var _ball: Node3D
var _net: Node3D
var _readout: Label
var _last_shot: String = "steep"
var _bounce_count: int = 0

func _ready() -> void:
	_ball = get_node(ball_path) as Node3D
	_net = get_node(net_path) as Node3D
	_readout = get_node_or_null(readout_path) as Label
	if _net and _net.has_signal("bounced"):
		_net.bounced.connect(_on_net_bounced)
	if _net and _net.has_signal("net_dead"):
		_net.net_dead.connect(_on_net_dead)
	if _ball and _ball.has_signal("ground_bounced"):
		_ball.ground_bounced.connect(_on_ground_bounced)
	_update_readout("Ready [PHYS v3 passive+deadball]. Press 1/2/3 to shoot.")
	# Auto fire one steep ball so first run shows motion without input.
	await get_tree().create_timer(0.5).timeout
	shoot("steep")

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1:
				shoot("steep")
			KEY_2:
				shoot("flat")
			KEY_3:
				shoot("pocket")
			KEY_R:
				reset_ball()
			KEY_SPACE:
				shoot(_last_shot)

func shoot_at(from: Vector3, target: Vector3, flight_time: float, label: String) -> void:
	# Solve the throw so the ball center arrives exactly at target after
	# flight_time seconds under the ball's gravity. Guarantees contact.
	var g: float = float(_ball.get("gravity"))
	var vel := (target - from) / flight_time + Vector3(0.0, 0.5 * g * flight_time, 0.0)
	_ball.global_position = from
	_ball.launch(vel)
	_update_readout(label)

func shoot(kind: String) -> void:
	if _ball == null:
		return
	_last_shot = kind
	_bounce_count = 0
	match kind:
		"steep":
			# High_arc drop onto CENTER. Expect clean high bounce.
			shoot_at(Vector3(0.6, 2.6, 1.4), Vector3(0.0, 0.33, 0.0), 0.55,
				"Shot: STEEP into center — expect clean high bounce.")
		"flat":
			# Low fastball across MID. Expect flatter faster skip.
			shoot_at(Vector3(2.0, 1.1, 0.2), Vector3(0.45, 0.36, 0.0), 0.45,
				"Shot: FLAT into mid — expect fast low skip.")
		"pocket":
			# Short drop onto the rim edge. Expect low sticky dribble.
			shoot_at(Vector3(1.0, 1.2, 1.0), Vector3(0.424, 0.38, 0.424), 0.40,
				"Shot: POCKET at rim — expect low dribble.")
		_:
			shoot("steep")

func reset_ball() -> void:
	if _ball and _ball.has_method("reset_to"):
		_ball.reset_to(Vector3(0.0, 2.0, 2.0))
	_update_readout("Reset. Press 1/2/3 to shoot.")

func _on_net_bounced(zone: String, in_angle: float, out_vel: Vector3, rn: float) -> void:
	_bounce_count += 1
	_update_readout("BOUNCE #%d  zone=%s  r=%.2f  in_angle=%.0f deg  out=(%.1f, %.1f, %.1f) |V|=%.1f  [1 steep / 2 flat / 3 pocket / R reset]" % [
		_bounce_count, zone, rn, in_angle,
		out_vel.x, out_vel.y, out_vel.z, out_vel.length()
	])

func _on_net_dead(zone: String, rn: float) -> void:
	_update_readout("DEAD BALL on %s  r=%.2f — soft touch dies on the net. R / 1 / 2 / 3" % [zone, rn])

func _on_ground_bounced(_speed: float) -> void:
	pass

func _update_readout(text: String) -> void:
	if _readout:
		_readout.text = text
	print("[NetLab] ", text)
