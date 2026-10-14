extends Node3D
## Street furniture. Just lamp posts for now - one at each sidewalk corner,
## with an emissive head so they read at dusk once day/night exists.
##
## Grid constants mirror city.gd - if the city layout changes, change these too.

const BLOCK_SIZE := 46.0
const ROAD_WIDTH := 14.0
const GRID := 7
const SIDEWALK_HEIGHT := 0.16

var _pole_mat: StandardMaterial3D
var _head_mat: StandardMaterial3D


func _ready() -> void:
	_pole_mat = StandardMaterial3D.new()
	_pole_mat.albedo_color = Color(0.16, 0.17, 0.19)
	_pole_mat.metallic = 0.4
	_pole_mat.roughness = 0.6

	_head_mat = StandardMaterial3D.new()
	_head_mat.albedo_color = Color(1.0, 0.9, 0.7)
	_head_mat.emission_enabled = true
	_head_mat.emission = Color(1.0, 0.85, 0.55)
	_head_mat.emission_energy_multiplier = 1.6

	var extent := GRID * BLOCK_SIZE
	var inner := BLOCK_SIZE - ROAD_WIDTH
	var offset := inner * 0.5 - 0.35

	for gx in GRID:
		for gz in GRID:
			var centre := Vector3(
				-extent * 0.5 + gx * BLOCK_SIZE + BLOCK_SIZE * 0.5,
				0.0,
				-extent * 0.5 + gz * BLOCK_SIZE + BLOCK_SIZE * 0.5)
			for corner: Vector3 in [
					Vector3(-offset, 0, -offset), Vector3(offset, 0, -offset),
					Vector3(offset, 0, offset), Vector3(-offset, 0, offset)]:
				_lamp(centre + corner)

	_build_ramps()


## Stunt ramps. Two on the quiet east-edge strip (no traffic - it's a natural
## drag strip), one on the spawn road for chaos. Yaw picks the approach side:
## the ramp rises toward its local -Z.
func _build_ramps() -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.85, 0.45, 0.10)
	mat.roughness = 0.6

	for spec: Array in [
			[Vector3(157.5, 0.0, 30.0), 0.0],       # east strip, jump heading north
			[Vector3(157.5, 0.0, -30.0), PI],       # east strip, jump heading south
			[Vector3(23.0, 0.0, -100.0), 0.0]]:     # spawn road, jump heading north
		var body := StaticBody3D.new()
		body.add_to_group("ramp")  # traffic's brake ray ignores these
		body.position = spec[0] + Vector3(0.0, 0.85, 0.0)
		body.rotation = Vector3(0.2, spec[1], 0.0)

		var mesh := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(7.0, 0.4, 11.0)
		mesh.mesh = box
		mesh.material_override = mat
		body.add_child(mesh)

		var col := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = Vector3(7.0, 0.4, 11.0)
		col.shape = shape
		body.add_child(col)

		add_child(body)


func _lamp(base: Vector3) -> void:
	var body := StaticBody3D.new()
	body.position = base + Vector3(0.0, SIDEWALK_HEIGHT, 0.0)

	var pole := MeshInstance3D.new()
	var pole_mesh := BoxMesh.new()
	pole_mesh.size = Vector3(0.14, 4.4, 0.14)
	pole.mesh = pole_mesh
	pole.material_override = _pole_mat
	pole.position = Vector3(0.0, 2.2, 0.0)
	body.add_child(pole)

	var head := MeshInstance3D.new()
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.22
	head_mesh.height = 0.44
	head_mesh.radial_segments = 10
	head_mesh.rings = 5
	head.mesh = head_mesh
	head.material_override = _head_mat
	head.position = Vector3(0.0, 4.5, 0.0)
	body.add_child(head)

	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.2, 4.4, 0.2)
	col.shape = shape
	col.position = Vector3(0.0, 2.2, 0.0)
	body.add_child(col)

	add_child(body)
