extends RigidBody3D
## One ambient traffic car. A rigid body so ramming it shoves it like a real
## car, but while unbothered it drives itself by writing linear_velocity
## directly - kinematic driving with physical collisions.
##
## States: driving -> stunned (just hit, physics owns it) -> back to driving,
## or wrecked (flipped over) where it stays physical forever.

var manager: Node3D
var grid_i := 0
var grid_j := 0
var dir := Vector2i(1, 0)
var cruise := 10.0
var colour := Color.GRAY
var is_truck := false

var _speed := 0.0
var _waypoint := Vector3.ZERO
var _stunned := 0.0
var _wrecked := false
var _ray: RayCast3D


func _ready() -> void:
	mass = 2400.0 if is_truck else 900.0
	contact_monitor = true
	max_contacts_reported = 4
	body_entered.connect(_on_body_entered)
	_build_visual()
	refresh_waypoint()
	# Ramps sit on roads on purpose; braking for them would jam the lane.
	for ramp in get_tree().get_nodes_in_group("ramp"):
		_ray.add_exception(ramp)


func _physics_process(delta: float) -> void:
	if _wrecked:
		return

	if _stunned > 0.0:
		_stunned -= delta
		if _stunned <= 0.0:
			_recover()
		return

	# Brake for whatever the front ray sees; accelerate gently otherwise.
	var target_speed := 0.0 if _ray.is_colliding() else cruise
	var rate := 20.0 if target_speed < _speed else 5.0
	_speed = move_toward(_speed, target_speed, rate * delta)

	var to := _waypoint - global_position
	to.y = 0.0
	if to.length() < 1.4:
		_advance()
		to = _waypoint - global_position
		to.y = 0.0

	var d := to.normalized()
	linear_velocity = Vector3(d.x * _speed, linear_velocity.y, d.z * _speed)
	angular_velocity = Vector3.ZERO
	rotation.y = lerp_angle(rotation.y, atan2(d.x, d.z), 6.0 * delta)


func refresh_waypoint() -> void:
	_waypoint = manager.lane_waypoint(grid_i + dir.x, grid_j + dir.y, dir)


func _advance() -> void:
	grid_i += dir.x
	grid_j += dir.y
	dir = manager.pick_turn(grid_i, grid_j, dir)
	refresh_waypoint()


func _on_body_entered(body: Node) -> void:
	# Only the player's vehicle stuns - nudges from other traffic don't.
	if body is VehicleBody3D:
		_stunned = 2.5
		_speed = 0.0


func _recover() -> void:
	if global_transform.basis.y.y < 0.5:
		_wrecked = true  # flipped: leave it as scenery
		return
	manager.reattach(self)


func _build_visual() -> void:
	var body_mat := StandardMaterial3D.new()
	body_mat.albedo_color = colour
	body_mat.metallic = 0.3
	body_mat.roughness = 0.42

	var glass_mat := StandardMaterial3D.new()
	glass_mat.albedo_color = Color(0.08, 0.10, 0.13)
	glass_mat.metallic = 0.6
	glass_mat.roughness = 0.15

	var tire_mat := StandardMaterial3D.new()
	tire_mat.albedo_color = Color(0.06, 0.06, 0.07)
	tire_mat.roughness = 0.95

	var body := MeshInstance3D.new()
	var body_mesh := BoxMesh.new()
	body_mesh.size = Vector3(2.1, 0.6, 5.6) if is_truck else Vector3(1.8, 0.5, 4.0)
	body.mesh = body_mesh
	body.material_override = body_mat
	body.position = Vector3(0.0, 0.66, 0.0) if is_truck else Vector3(0.0, 0.62, 0.0)
	add_child(body)

	if is_truck:
		var cargo := MeshInstance3D.new()
		var cargo_mesh := BoxMesh.new()
		cargo_mesh.size = Vector3(2.05, 1.7, 3.4)
		cargo.mesh = cargo_mesh
		cargo.material_override = body_mat
		cargo.position = Vector3(0.0, 1.7, 0.9)
		add_child(cargo)

	var cabin := MeshInstance3D.new()
	var cabin_mesh := BoxMesh.new()
	cabin_mesh.size = Vector3(1.9, 1.0, 1.5) if is_truck else Vector3(1.5, 0.45, 1.7)
	cabin.mesh = cabin_mesh
	cabin.material_override = glass_mat
	cabin.position = Vector3(0.0, 1.4, -1.9) if is_truck else Vector3(0.0, 1.08, -0.2)
	add_child(cabin)

	var wheel_mesh := CylinderMesh.new()
	wheel_mesh.top_radius = 0.32
	wheel_mesh.bottom_radius = 0.32
	wheel_mesh.height = 0.24
	wheel_mesh.radial_segments = 14
	for wx in [-0.82, 0.82]:
		for wz in [-1.35, 1.35]:
			var wheel := MeshInstance3D.new()
			wheel.mesh = wheel_mesh
			wheel.material_override = tire_mat
			# Cylinder axis is Y; lie it on its side so it rolls, not stands.
			wheel.transform = Transform3D(
				Basis(Vector3(0, 1, 0), Vector3(-1, 0, 0), Vector3(0, 0, 1)),
				Vector3(wx, 0.32, wz))
			add_child(wheel)

	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(2.1, 2.4, 5.6) if is_truck else Vector3(1.8, 1.0, 4.0)
	col.shape = shape
	col.position = Vector3(0.0, 1.2, 0.0) if is_truck else Vector3(0.0, 0.5, 0.0)
	add_child(col)

	_ray = RayCast3D.new()
	_ray.position = Vector3(0.0, 0.55, 3.1 if is_truck else 2.3)
	_ray.target_position = Vector3(0.0, 0.0, 6.0 if is_truck else 5.0)
	add_child(_ray)
