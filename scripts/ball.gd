extends Node3D
## Slap Ball — Step 1: test ball with MANUAL projectile (no Jolt chaos).
## Heavy volleyball-like feel: fixed flight times 0.6-0.9s between touches.
## Net relaunch is handled by net.gd calling launch().

signal ground_bounced(speed: float)
signal launched(velocity: Vector3)

@export var gravity: float = 18.0 ## heavy ball, snappy arcs
@export var radius: float = 0.11 ## slightly bigger ball for readability
@export var ground_bounce_damp: float = 0.45
@export var ground_friction: float = 0.8
@export var rest_threshold: float = 0.6
@export var max_trail_points: int = 24

var velocity: Vector3 = Vector3.ZERO
var flying: bool = true
var last_launch_time_msec: int = 0
var flight_time_sec: float = 0.0

var _trail: Array[Vector3] = []
var _mesh: MeshInstance3D

func _ready() -> void:
	_mesh = get_node_or_null("Mesh") as MeshInstance3D
	last_launch_time_msec = Time.get_ticks_msec()

func launch(vel: Vector3) -> void:
	velocity = vel
	flying = true
	flight_time_sec = 0.0
	last_launch_time_msec = Time.get_ticks_msec()
	launched.emit(velocity)

func stop() -> void:
	velocity = Vector3.ZERO
	flying = false

func reset_to(pos: Vector3) -> void:
	global_position = pos
	velocity = Vector3.ZERO
	flying = false
	_trail.clear()
	flight_time_sec = 0.0
	queue_redraw_trail()

func _physics_process(delta: float) -> void:
	if not flying:
		return
	flight_time_sec += delta
	velocity.y -= gravity * delta
	global_position += velocity * delta
	# Ground plane at y = 0.
	if global_position.y < radius:
		global_position.y = radius
		if absf(velocity.y) > rest_threshold:
			velocity.y = -velocity.y * ground_bounce_damp
			velocity.x *= ground_friction
			velocity.z *= ground_friction
			ground_bounced.emit(velocity.length())
		else:
			# Rest on ground.
			velocity = Vector3.ZERO
			flying = false
	# Safety: kill runaway balls in lab.
	if global_position.length() > 40.0:
		stop()
	_push_trail(global_position)

func _push_trail(p: Vector3) -> void:
	_trail.push_back(p)
	if _trail.size() > max_trail_points:
		_trail.pop_front()
	queue_redraw_trail()

func queue_redraw_trail() -> void:
	# Trail drawn by TestLauncher debug line or future Trail3D; keep hook.
	pass

func speed() -> float:
	return velocity.length()

func incoming_angle_deg() -> float:
	# Angle of travel below horizontal: steep in = high value.
	var h := Vector2(velocity.x, velocity.z).length()
	if h < 0.001:
		return 90.0 if velocity.y < 0.0 else 0.0
	return rad_to_deg(atan2(-velocity.y, h))
