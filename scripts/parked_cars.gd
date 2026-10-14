extends Node3D
## Enterable vehicles placed around the map - cars and a truck at the kerb,
## and a helicopter on a pad at the north edge, straight up the spawn road.
##
## Kerbside maths: roads are 14 wide centred on grid lines (..., -23, 23, 69, ...),
## so a car hugging the kerb sits 5.6 from the centreline, leaving the traffic
## lane (offset 3.5) just clear.

const CAR := preload("res://scenes/car.tscn")
const TRUCK := preload("res://scenes/truck.tscn")
const Heli := preload("res://scripts/heli.gd")

## [scene kind, position, y-rotation, colour]
const SPOTS := [
	["car", Vector3(28.6, 0.4, -30.0), 0.0, Color(0.85, 0.72, 0.12)],   # taxi
	["car", Vector3(28.6, 0.4, -76.0), 0.0, Color(0.13, 0.13, 0.15)],
	["car", Vector3(-28.6, 0.4, 60.0), PI, Color(0.20, 0.35, 0.68)],
	["car", Vector3(60.0, 0.4, 28.6), -PI * 0.5, Color(0.86, 0.86, 0.88)],
	["car", Vector3(-60.0, 0.4, -28.6), PI * 0.5, Color(0.24, 0.48, 0.30)],
	["car", Vector3(74.6, 0.4, 40.0), 0.0, Color(0.52, 0.16, 0.42)],
	["truck", Vector3(28.4, 0.6, 45.0), 0.0, Color(0.75, 0.3, 0.1)],
]

const HELI_POS := Vector3(23.0, 0.25, -156.5)


func _ready() -> void:
	for spot: Array in SPOTS:
		var scene: PackedScene = TRUCK if spot[0] == "truck" else CAR
		var vehicle := scene.instantiate()
		vehicle.body_color = spot[3]
		add_child(vehicle)
		vehicle.global_position = spot[1]
		vehicle.rotation.y = spot[2]

	_build_helipad()
	var heli: RigidBody3D = Heli.new()
	add_child(heli)
	heli.global_position = HELI_POS
	heli.rotation.y = PI  # nose pointing back down the spawn road


func _build_helipad() -> void:
	var pad := StaticBody3D.new()
	pad.position = Vector3(HELI_POS.x, 0.0, HELI_POS.z)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.35, 0.36, 0.38)
	mat.roughness = 0.85

	var ring_mat := StandardMaterial3D.new()
	ring_mat.albedo_color = Color(0.95, 0.8, 0.2)
	ring_mat.emission_enabled = true
	ring_mat.emission = Color(0.95, 0.8, 0.2)
	ring_mat.emission_energy_multiplier = 0.7

	var slab := MeshInstance3D.new()
	var slab_mesh := CylinderMesh.new()
	slab_mesh.top_radius = 4.2
	slab_mesh.bottom_radius = 4.2
	slab_mesh.height = 0.12
	slab_mesh.radial_segments = 24
	slab.mesh = slab_mesh
	slab.material_override = mat
	slab.position = Vector3(0.0, 0.06, 0.0)
	pad.add_child(slab)

	var ring := MeshInstance3D.new()
	var ring_mesh := TorusMesh.new()
	ring_mesh.inner_radius = 3.4
	ring_mesh.outer_radius = 3.8
	ring_mesh.rings = 24
	ring_mesh.ring_segments = 8
	ring.mesh = ring_mesh
	ring.material_override = ring_mat
	ring.position = Vector3(0.0, 0.13, 0.0)
	pad.add_child(ring)

	var col := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = 4.2
	shape.height = 0.12
	col.shape = shape
	col.position = Vector3(0.0, 0.06, 0.0)
	pad.add_child(col)

	add_child(pad)
