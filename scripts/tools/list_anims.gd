extends SceneTree
## Dev tool: prints the animation names and skeleton info inside the character GLB.
## Run: godot --headless --path . --script scripts/tools/list_anims.gd


func _init() -> void:
	var scene: PackedScene = load("res://assets/characters/UAL1_Standard.glb")
	if scene == null:
		push_error("could not load GLB")
		quit(1)
		return

	var root := scene.instantiate()
	var players := root.find_children("*", "AnimationPlayer", true, false)
	for ap: AnimationPlayer in players:
		print("AnimationPlayer: ", ap.name)
		var names := ap.get_animation_list()
		print("animations (", names.size(), "):")
		for n in names:
			print("  ", n)

	var skeletons := root.find_children("*", "Skeleton3D", true, false)
	for sk: Skeleton3D in skeletons:
		print("Skeleton3D: ", sk.name, "  bones: ", sk.get_bone_count())

	var meshes := root.find_children("*", "MeshInstance3D", true, false)
	print("meshes: ", meshes.size())
	root.free()
	quit(0)
