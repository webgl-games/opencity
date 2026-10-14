extends CharacterBody3D
## On-foot player. Moves relative to wherever the camera is looking, which is
## what every third-person game does and what makes stick/WASD movement feel right.

@export var walk_speed := 4.2
@export var run_speed := 8.5
@export var jump_velocity := 5.5
## How quickly the player reaches target speed. Higher is snappier, less floaty.
@export var acceleration := 14.0
@export var air_control := 3.0
@export var turn_speed := 12.0

var running := false

var _punch_cooldown := 0.0

@onready var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 14.0)
@onready var _anim: AnimationPlayer = $Model/AnimationPlayer

## Locomotion clips loop; everything else is one-shot.
const LOOPED_ANIMS := ["Idle", "Walk", "Jog_Fwd", "Sprint"]


func _ready() -> void:
	add_to_group("player")
	for name in LOOPED_ANIMS:
		var anim := _anim.get_animation(name)
		if anim:
			anim.loop_mode = Animation.LOOP_LINEAR
	_anim.playback_default_blend_time = 0.2
	_anim.play("Idle")
	_dress()


## The Quaternius mannequin ships banana-yellow with purple joint bands.
## Recolour it into something that reads as clothes until we have real skins.
func _dress() -> void:
	var mesh: MeshInstance3D = $Model.find_child("Mannequin", true, false)
	if mesh == null:
		return
	var main: StandardMaterial3D = mesh.mesh.surface_get_material(0).duplicate()
	main.albedo_color = Color(0.30, 0.36, 0.44)  # slate-blue jacket
	main.metallic = 0.0
	main.roughness = 0.85  # fabric, not chrome
	mesh.set_surface_override_material(0, main)
	var joints: StandardMaterial3D = mesh.mesh.surface_get_material(1).duplicate()
	joints.albedo_color = Color(0.15, 0.16, 0.18)  # near-black seams
	joints.metallic = 0.0
	joints.roughness = 0.9
	mesh.set_surface_override_material(1, joints)


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= _gravity * delta
	elif Input.is_key_pressed(KEY_SPACE):
		velocity.y = jump_velocity

	var input := Vector2.ZERO
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		input.y += 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		input.y -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		input.x += 1.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		input.x -= 1.0
	input = input.limit_length(1.0)

	running = Input.is_key_pressed(KEY_SHIFT)
	var speed := run_speed if running else walk_speed

	var direction := _camera_relative(input)
	var target := direction * speed
	var rate := acceleration if is_on_floor() else air_control
	velocity.x = move_toward(velocity.x, target.x, rate * delta * speed)
	velocity.z = move_toward(velocity.z, target.z, rate * delta * speed)

	# Face the way we're going.
	if direction.length_squared() > 0.01:
		var wanted := atan2(direction.x, direction.z)
		rotation.y = lerp_angle(rotation.y, wanted, turn_speed * delta)

	_punch_cooldown = maxf(_punch_cooldown - delta, 0.0)
	if Input.is_key_pressed(KEY_F) and _punch_cooldown == 0.0:
		_punch_cooldown = 0.6
		_punch()
		_anim.play("Punch_Jab", 0.1)

	move_and_slide()
	_update_animation()


## Pick the clip that matches what the body is actually doing. Punches are
## one-shots: while one is playing, locomotion keeps its hands off the player.
func _update_animation() -> void:
	if _anim.current_animation.begins_with("Punch") and _anim.is_playing():
		return

	var target: String
	if not is_on_floor():
		target = "Jump"
	else:
		var speed := get_speed_kmh() / 3.6
		if speed < 0.3:
			target = "Idle"
		elif speed < walk_speed + 0.4:
			target = "Walk"
		elif running:
			target = "Sprint"
		else:
			target = "Jog_Fwd"

	if _anim.current_animation != target:
		_anim.play(target, 0.2)


## Knock down any ped close in front. The player model faces +Z.
func _punch() -> void:
	var forward := global_transform.basis.z
	for ped in get_tree().get_nodes_in_group("ped"):
		var to: Vector3 = ped.global_position - global_position
		if to.length() < 2.0 and to.normalized().dot(forward) > 0.2:
			ped.knock(randf_range(1.5, 3.0))


## Turn WASD into a world-space direction based on the active camera's yaw.
func _camera_relative(input: Vector2) -> Vector3:
	if is_zero_approx(input.length()):
		return Vector3.ZERO

	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return Vector3(input.x, 0.0, -input.y)

	# Use the camera's *target* yaw, not its current basis. The camera lags behind
	# the player, so steering off its live orientation feeds back on itself and
	# curves a straight input into an arc.
	var basis := Basis(Vector3.UP, cam.yaw) if "yaw" in cam else cam.global_transform.basis
	var forward := -basis.z
	forward.y = 0.0
	forward = forward.normalized()
	var right := basis.x
	right.y = 0.0
	right = right.normalized()

	return (forward * input.y + right * input.x).normalized()


func get_speed_kmh() -> float:
	return Vector3(velocity.x, 0.0, velocity.z).length() * 3.6
