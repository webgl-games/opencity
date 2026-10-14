extends Camera3D
## Chase camera that trails the player and leans into turns slightly.
## Finds its target by group, so nothing breaks if the car is renamed or reparented.

@export var distance := 8.5
@export var height := 3.8
@export var follow_speed := 6.0
@export var look_height := 1.2

var _target: Node3D


func _ready() -> void:
	_acquire_target()


func _physics_process(delta: float) -> void:
	if not is_instance_valid(_target):
		_acquire_target()
		return

	# basis.z points backwards out of the car, so this sits behind it.
	var behind := _target.global_transform.basis.z.normalized()
	var desired := _target.global_position + behind * distance + Vector3.UP * height

	var weight := clampf(follow_speed * delta, 0.0, 1.0)
	global_position = global_position.lerp(desired, weight)

	var focus := _target.global_position + Vector3.UP * look_height
	if global_position.distance_to(focus) > 0.05:
		look_at(focus, Vector3.UP)


func _acquire_target() -> void:
	_target = get_tree().get_first_node_in_group("player") as Node3D
