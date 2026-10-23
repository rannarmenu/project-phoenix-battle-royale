extends SceneTree

func _initialize() -> void:
	call_deferred("_run_smoke_test")

func _run_smoke_test() -> void:
	var packed_scene: PackedScene = load("res://scenes/main.tscn")
	if packed_scene == null:
		push_error("SMOKE TEST: Could not load res://scenes/main.tscn")
		quit(1)
		return

	var main_scene: Node = packed_scene.instantiate()
	root.add_child(main_scene)
	await process_frame
	await physics_frame

	var player: Node = main_scene.get_node_or_null("Player")
	if player == null:
		push_error("SMOKE TEST: Player node was not spawned")
		quit(1)
		return

	if not player.has_method("toggle_camera_mode"):
		push_error("SMOKE TEST: Player camera toggle method is missing")
		quit(1)
		return

	var targets: Array[Node] = main_scene.find_children("Target_*", "CharacterBody3D", true, false)
	if targets.size() != 6:
		push_error("SMOKE TEST: Expected 6 targets, got %d" % targets.size())
		quit(1)
		return

	var cameras := main_scene.find_children("*", "Camera3D", true, false)
	if cameras.is_empty():
		push_error("SMOKE TEST: No Camera3D was created")
		quit(1)
		return

	var missing_meshes: Array[String] = []
	var mesh_nodes := main_scene.find_children("*", "MeshInstance3D", true, false)
	for node in mesh_nodes:
		if node is MeshInstance3D and node.mesh == null:
			missing_meshes.append(str(node.get_path()))
	if not missing_meshes.is_empty():
		push_error("SMOKE TEST: MeshInstance3D nodes without meshes: %s" % ", ".join(missing_meshes))
		quit(1)
		return

	if bool(player.get("first_person")):
		push_error("SMOKE TEST: Expected third-person camera as the initial mode")
		quit(1)
		return
	player.call("toggle_camera_mode")
	await process_frame
	if not bool(player.get("first_person")):
		push_error("SMOKE TEST: First-person toggle did not activate")
		quit(1)
		return
	player.call("toggle_camera_mode")
	await process_frame
	if bool(player.get("first_person")):
		push_error("SMOKE TEST: Third-person toggle did not restore")
		quit(1)
		return

	var test_target: Node = targets[0]
	if not test_target.has_method("take_damage"):
		push_error("SMOKE TEST: Bot damage method is missing")
		quit(1)
		return
	test_target.call("take_damage", 34.0)
	if int(test_target.get("health")) != 66:
		push_error("SMOKE TEST: Bot health did not decrease after a hit")
		quit(1)
		return
	test_target.call("take_damage", 66.0)
	if int(main_scene.get("eliminated_count")) != 1:
		push_error("SMOKE TEST: Target elimination counter did not increment")
		quit(1)
		return

	player.call("take_damage", 999)
	if int(player.get("health")) != 100:
		push_error("SMOKE TEST: Player did not respawn at full health")
		quit(1)
		return

	print("PHOENIX_SMOKE_TEST_OK: arena, player, camera toggle, targets and mesh references, combat damage and respawn validated")
	quit(0)
