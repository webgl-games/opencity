extends SceneTree
## Dev tool: prints surfaces and materials of the character mesh.


func _init() -> void:
	var scene: PackedScene = load("res://assets/characters/UAL1_Standard.glb")
	var root := scene.instantiate()
	for mi: MeshInstance3D in root.find_children("*", "MeshInstance3D", true, false):
		print("mesh: ", mi.name, "  surfaces: ", mi.mesh.get_surface_count())
		for s in mi.mesh.get_surface_count():
			var mat := mi.mesh.surface_get_material(s)
			var desc := "<none>"
			if mat != null:
				desc = "%s (%s)" % [mat.resource_name, mat.get_class()]
				if mat is BaseMaterial3D and mat.albedo_texture != null:
					desc += " tex=%s" % mat.albedo_texture.resource_name
			print("  surface %d: %s" % [s, desc])
	root.free()
	quit(0)
