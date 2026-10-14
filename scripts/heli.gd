extends RigidBody3D
## Arcade helicopter. Enter with E like any vehicle.
## SPACE climbs, SHIFT descends, W/S fly forward/back, A/D turn.
##
## Flight is velocity-steered rather than force-based - blunt, but stable and
## fun, which beats realistic-and-unflyable. Gravity is dialled down while
## flying so hover doesn't need a PID controller.

@export var fly_speed := 24.0
@export var climb_speed := 9.0
@export var descend_speed := 7.0
@export var yaw_rate := 1.7
## How hard velocity chases the stick. Lower = heavier, more momentum.
@export var response := 2.2

var active := false:
	set(value):
		active = value
		gravity_scale = 0.3 if value else 1.0
var boosting := false  # HUD expects it; the heli has no boost

var _rotor: Node3D
var _tail_rotor: MeshInstance3D


func _ready() -> void:
	add_to_group("vehicle")
	mass = 2200.0
	_build_visual()


func _physics_process(delta: float) -> void:
	# Rotor always turns a little; spins up when flown.
	_rotor.rotate_y((22.0 if active else 1.5) * delta)
	_tail_rotor.rotate_x(30.0 * delta)

	if not active:
		return

	var up_input := 0.0
	if Input.is_key_pressed(KEY_SPACE):
		up_input += 1.0
	if Input.is_key_pressed(KEY_SHIFT):
		up_input -= 1.0

	var fwd_input := 0.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		fwd_input += 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		fwd_input -= 1.0

	var yaw_input := 0.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		yaw_input += 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		yaw_input -= 1.0

	rotation.y += yaw_input * yaw_rate * delta
	# Cosmetic lean into the stick; the collision box stays functionally level.
	rotation.x = lerp_angle(rotation.x, fwd_input * -0.16, 2.5 * delta)
	rotation.z = lerp_angle(rotation.z, yaw_input * 0.10, 2.5 * delta)

	var forward := -global_transform.basis.z
	forward.y = 0.0
	forward = forward.normalized()

	var target := forward * fwd_input * fly_speed
	target.y = up_input * (climb_speed if up_input > 0.0 else descend_speed)

	linear_velocity = linear_velocity.lerp(target, clampf(response * delta, 0.0, 1.0))
	angular_velocity = Vector3.ZERO


func get_speed_kmh() -> float:
	return linear_velocity.length() * 3.6


func _build_visual() -> void:
	var hull_mat := StandardMaterial3D.new()
	hull_mat.albedo_color = Color(0.16, 0.18, 0.22)
	hull_mat.metallic = 0.4
	hull_mat.roughness = 0.45

	var accent_mat := StandardMaterial3D.new()
	accent_mat.albedo_color = Color(0.85, 0.45, 0.10)
	accent_mat.roughness = 0.5

	var glass_mat := StandardMaterial3D.new()
	glass_mat.albedo_color = Color(0.10, 0.14, 0.18)
	glass_mat.metallic = 0.6
	glass_mat.roughness = 0.12

	var blade_mat := StandardMaterial3D.new()
	blade_mat.albedo_color = Color(0.08, 0.08, 0.09)
	blade_mat.roughness = 0.7

	var cabin := MeshInstance3D.new()
	var cabin_mesh := BoxMesh.new()
	cabin_mesh.size = Vector3(1.7, 1.4, 3.2)
	cabin.mesh = cabin_mesh
	cabin.material_override = hull_mat
	cabin.position = Vector3(0.0, 1.05, -0.5)
	add_child(cabin)

	var canopy := MeshInstance3D.new()
	var canopy_mesh := BoxMesh.new()
	canopy_mesh.size = Vector3(1.5, 0.8, 1.0)
	canopy.mesh = canopy_mesh
	canopy.material_override = glass_mat
	canopy.position = Vector3(0.0, 1.15, -1.75)
	add_child(canopy)

	var boom := MeshInstance3D.new()
	var boom_mesh := BoxMesh.new()
	boom_mesh.size = Vector3(0.3, 0.35, 3.4)
	boom.mesh = boom_mesh
	boom.material_override = accent_mat
	boom.position = Vector3(0.0, 1.25, 2.6)
	add_child(boom)

	var fin := MeshInstance3D.new()
	var fin_mesh := BoxMesh.new()
	fin_mesh.size = Vector3(0.12, 1.0, 0.7)
	fin.mesh = fin_mesh
	fin.material_override = hull_mat
	fin.position = Vector3(0.0, 1.7, 4.1)
	add_child(fin)

	_tail_rotor = MeshInstance3D.new()
	var tail_mesh := BoxMesh.new()
	tail_mesh.size = Vector3(0.06, 1.4, 0.18)
	_tail_rotor.mesh = tail_mesh
	_tail_rotor.material_override = blade_mat
	_tail_rotor.position = Vector3(0.18, 1.7, 4.25)
	add_child(_tail_rotor)

	for sx in [-0.75, 0.75]:
		var skid := MeshInstance3D.new()
		var skid_mesh := BoxMesh.new()
		skid_mesh.size = Vector3(0.12, 0.12, 2.8)
		skid.mesh = skid_mesh
		skid.material_override = accent_mat
		skid.position = Vector3(sx, 0.1, -0.4)
		add_child(skid)

	_rotor = Node3D.new()
	_rotor.position = Vector3(0.0, 1.95, -0.5)
	add_child(_rotor)
	for angle in [0.0, PI * 0.5]:
		var blade := MeshInstance3D.new()
		var blade_mesh := BoxMesh.new()
		blade_mesh.size = Vector3(0.32, 0.05, 8.0)
		blade.mesh = blade_mesh
		blade.material_override = blade_mat
		blade.rotation.y = angle
		_rotor.add_child(blade)

	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.8, 2.0, 4.6)
	col.shape = shape
	col.position = Vector3(0.0, 1.0, 0.6)
	add_child(col)
