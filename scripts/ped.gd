extends CharacterBody3D
## One pedestrian. Walks the sidewalk loop it was given, pauses now and then,
## and dives to the ground when the player drives at it.

var corners := PackedVector3Array()
var corner_idx := 0
var walk_speed := 1.6
var shirt := Color(0.4, 0.4, 0.5)
var skin := Color(0.75, 0.6, 0.5)

var _pause := 0.0
var _down := 0.0
var _visual: Node3D
var _game: Node

@onready var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 14.0)


func _ready() -> void:
	add_to_group("ped")
	_build_visual()


## Knock this ped flat for a while. Cars, punches, whatever - one entry point.
func knock(duration: float) -> void:
	_down = duration
	_visual.rotation.x = -PI * 0.5


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= _gravity * delta

	if _down > 0.0:
		_down -= delta
		velocity.x = 0.0
		velocity.z = 0.0
		move_and_slide()
		if _down <= 0.0:
			_visual.rotation.x = 0.0  # get back up
		return

	_check_knockdown()

	if _pause > 0.0:
		_pause -= delta
		velocity.x = 0.0
		velocity.z = 0.0
		move_and_slide()
		return

	var target := corners[corner_idx]
	var to := target - global_position
	to.y = 0.0
	if to.length() < 0.5:
		corner_idx = (corner_idx + 1) % corners.size()
		if randf() < 0.3:
			_pause = randf_range(0.5, 2.5)
		return

	var dir := to.normalized()
	velocity.x = dir.x * walk_speed
	velocity.z = dir.z * walk_speed
	rotation.y = lerp_angle(rotation.y, atan2(dir.x, dir.z), 8.0 * delta)
	move_and_slide()


func _check_knockdown() -> void:
	if _game == null:
		_game = get_tree().get_first_node_in_group("game")
		if _game == null:
			return
	var car: RigidBody3D = _game.driving
	if car == null or car.get_speed_kmh() < 20.0:
		return
	if global_position.distance_to(car.global_position) < 2.6:
		knock(randf_range(2.5, 4.0))


func _build_visual() -> void:
	_visual = Node3D.new()
	add_child(_visual)

	var body_mat := StandardMaterial3D.new()
	body_mat.albedo_color = shirt
	body_mat.roughness = 0.85

	var skin_mat := StandardMaterial3D.new()
	skin_mat.albedo_color = skin
	skin_mat.roughness = 0.75

	var body := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.26
	capsule.height = 1.3
	body.mesh = capsule
	body.material_override = body_mat
	body.position = Vector3(0.0, 0.72, 0.0)
	_visual.add_child(body)

	var head := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.16
	sphere.height = 0.32
	sphere.radial_segments = 12
	sphere.rings = 6
	head.mesh = sphere
	head.material_override = skin_mat
	head.position = Vector3(0.0, 1.56, 0.0)
	_visual.add_child(head)

	var col := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.28
	shape.height = 1.4
	col.shape = shape
	col.position = Vector3(0.0, 0.7, 0.0)
	add_child(col)
