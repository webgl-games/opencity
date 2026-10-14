extends VehicleBody3D
## Player car. Deliberately simple arcade handling - tune the exported values
## until the feel is right, then worry about making it look like a real car.

## Measured, not assumed: a positive engine_force pushes this chassis toward its
## local +Z, while the model (and Godot's usual convention) treats -Z as forward.
## So throttle is negated to drive the car nose-first.
const FORWARD := -1.0

@export_group("Power")
@export var max_engine_force := 2600.0
@export var top_speed_kmh := 175.0
## Held SHIFT: more force and a much higher ceiling.
@export var boost_force_multiplier := 1.9
@export var boost_top_speed_kmh := 265.0
## Reverse is deliberately weaker than forward.
@export var reverse_force_factor := 0.4

@export_group("Braking")
@export var max_brake_force := 45.0
## Light drag applied when coasting, so it rolls to a stop instead of forever.
@export var coast_brake := 2.0

@export_group("Steering")
@export var max_steer_angle := 0.5
## How fast the wheels turn toward the target angle. Lower feels heavier.
@export var steer_speed := 3.2
## Steering lock shrinks at speed so the car doesn't spin out at 200 km/h.
@export var high_speed_steer_factor := 0.35

@export_group("Recovery")
## Seconds on its roof before the car rights itself where it lies.
@export var self_right_delay := 2.0

var boosting := false
## Set by game.gd when the player gets in. Parked cars ignore input.
var active := false

var _spawn_transform: Transform3D
var _upside_down_for := 0.0


## Paint job, applied on spawn. Lets parked_cars.gd vary instances of one scene.
@export var body_color := Color(0.72, 0.19, 0.16)


func _ready() -> void:
	add_to_group("vehicle")
	_spawn_transform = global_transform
	var body := get_node_or_null("Body") as MeshInstance3D
	if body and body.material_override is StandardMaterial3D:
		var mat: StandardMaterial3D = body.material_override.duplicate()
		mat.albedo_color = body_color
		body.material_override = mat


func _physics_process(delta: float) -> void:
	if not active:
		engine_force = 0.0
		brake = coast_brake
		steering = move_toward(steering, 0.0, steer_speed * delta)
		boosting = false
		_handle_recovery(delta)
		return

	var throttle := 0.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		throttle += 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		throttle -= 1.0

	var steer_input := 0.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		steer_input += 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		steer_input -= 1.0

	var speed := get_speed_kmh()
	boosting = Input.is_key_pressed(KEY_SHIFT) and throttle > 0.0

	# Taper power toward the speed ceiling so it doesn't accelerate forever.
	var ceiling := boost_top_speed_kmh if boosting else top_speed_kmh
	var power := 1.0 - clampf(speed / ceiling, 0.0, 1.0)
	var force := max_engine_force * power
	if boosting:
		force *= boost_force_multiplier
	if throttle < 0.0:
		force = max_engine_force * reverse_force_factor
	engine_force = FORWARD * throttle * force

	if Input.is_key_pressed(KEY_SPACE):
		brake = max_brake_force
	elif is_zero_approx(throttle):
		brake = coast_brake
	else:
		brake = 0.0

	var speed_ratio := clampf(speed / 160.0, 0.0, 1.0)
	var lock := lerpf(max_steer_angle, max_steer_angle * high_speed_steer_factor, speed_ratio)
	steering = move_toward(steering, steer_input * lock, steer_speed * delta)

	_handle_recovery(delta)

	if Input.is_key_pressed(KEY_R):
		respawn()


func get_speed_kmh() -> float:
	return linear_velocity.length() * 3.6


func respawn() -> void:
	global_transform = _spawn_transform
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	_upside_down_for = 0.0


## Flip the car back over in place rather than sending it to spawn - being
## stranded on your roof halfway across the map isn't interesting.
func _handle_recovery(delta: float) -> void:
	# Fell out of the world entirely - nothing to right, just go back to spawn.
	if global_position.y < -15.0:
		respawn()
		return

	if global_transform.basis.y.y > 0.2:
		_upside_down_for = 0.0
		return

	_upside_down_for += delta
	if _upside_down_for < self_right_delay:
		return

	_upside_down_for = 0.0
	var yaw := global_rotation.y
	global_transform = Transform3D(Basis(Vector3.UP, yaw), global_position + Vector3.UP * 1.5)
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
