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

	var loot_nodes: Array[Node] = main_scene.find_children("Loot_*", "Area3D", true, false)
	if loot_nodes.size() != 8:
		push_error("SMOKE TEST: Expected 8 loot pickups, got %d" % loot_nodes.size())
		quit(1)
		return

	var zone: Node = main_scene.get_node_or_null("SafeZone")
	if zone == null or not zone.has_method("get_zone_status_for_position"):
		push_error("SMOKE TEST: Safe zone was not created")
		quit(1)
		return
	if zone.call("get_zone_status_for_position", Vector3.ZERO) != "SAFE":
		push_error("SMOKE TEST: Safe-zone center should be safe")
		quit(1)
		return
	if zone.call("get_zone_status_for_position", Vector3(50.0, 0.0, 50.0)) != "OUTSIDE ZONE":
		push_error("SMOKE TEST: Outside-zone boundary check failed")
		quit(1)
		return
	if not is_equal_approx(float(zone.call("get_current_radius")), 38.0):
		push_error("SMOKE TEST: Safe-zone start radius is incorrect")
		quit(1)
		return

	var ammo_before: int = int(player.get("reserve_ammo"))
	var ammo_pickup: Node = main_scene.get_node("Loot_01")
	if not ammo_pickup.has_method("collect"):
		push_error("SMOKE TEST: Loot pickup collection method is missing")
		quit(1)
		return
	ammo_pickup.call("collect", player)
	if int(player.get("reserve_ammo")) != ammo_before + 45:
		push_error("SMOKE TEST: Ammo pickup did not update inventory")
		quit(1)
		return
	if not bool(player.call("add_loot", &"ammo", 500)):
		push_error("SMOKE TEST: Ammo inventory rejected valid capacity")
		quit(1)
		return
	if int(player.get("reserve_ammo")) != 240:
		push_error("SMOKE TEST: Ammo inventory did not enforce its 240 cap")
		quit(1)
		return
	if bool(player.call("add_loot", &"ammo", 1)):
		push_error("SMOKE TEST: Ammo inventory accepted ammo above cap")
		quit(1)
		return
	player.set("ammo", 10)
	player.set("reserve_ammo", 40)
	player.call("_reload")
	if int(player.get("ammo")) != 30 or int(player.get("reserve_ammo")) != 20:
		push_error("SMOKE TEST: Reload did not transfer ammo correctly")
		quit(1)
		return

	player.set("health", 45)
	player.set("medkits", 0)
	var medkit_pickup: Node = main_scene.get_node("Loot_02")
	medkit_pickup.call("collect", player)
	if int(player.get("medkits")) != 1:
		push_error("SMOKE TEST: Medkit pickup did not update inventory")
		quit(1)
		return
	player.call("use_medkit")
	if int(player.get("health")) != 90 or int(player.get("medkits")) != 0:
		push_error("SMOKE TEST: Medkit did not restore health or consume inventory")
		quit(1)
		return

	var armor_pickup: Node = main_scene.get_node("Loot_03")
	armor_pickup.call("collect", player)
	if int(player.get("armor")) != 35:
		push_error("SMOKE TEST: Armor pickup did not update inventory")
		quit(1)
		return
	player.call("take_damage", 20)
	if int(player.get("health")) != 82 or int(player.get("armor")) != 23:
		push_error("SMOKE TEST: Armor damage reduction was incorrect")
		quit(1)
		return

	player.call("take_damage", 999)
	if int(player.get("health")) != 100 or int(player.get("armor")) != 0:
		push_error("SMOKE TEST: Player did not respawn correctly")
		quit(1)
		return

	var attacker: Node = targets[1]
	attacker.set("global_position", player.global_position + Vector3(0.0, 0.0, -6.0))
	attacker.set("attack_cooldown", 0.05)
	await create_timer(0.35).timeout
	if int(player.get("health")) >= 100:
		push_error("SMOKE TEST: Nearby enemy bot did not damage the player")
		quit(1)
		return

	zone.set("elapsed_time", 999.0)
	zone.call("_update_zone_radius")
	if not is_equal_approx(float(zone.call("get_current_radius")), float(zone.get("final_radius"))):
		push_error("SMOKE TEST: Safe zone did not shrink to final radius")
		quit(1)
		return

	player.set("global_position", Vector3(20.0, 0.05, 0.0))
	player.set("health", 100)
	player.set("armor", 0)
	zone.call("apply_zone_damage_to", player)
	if int(player.get("health")) != 95:
		push_error("SMOKE TEST: Outside-zone damage was not applied")
		quit(1)
		return

	var joystick_script: Script = load("res://scripts/virtual_joystick.gd")
	if joystick_script == null:
		push_error("SMOKE TEST: Virtual joystick script could not be loaded")
		quit(1)
		return
	var joystick: Control = joystick_script.new()
	root.add_child(joystick)
	await process_frame
	joystick.call("begin_drag", Vector2(100.0, 120.0))
	if not bool(joystick.get("is_active")):
		push_error("SMOKE TEST: Virtual joystick did not activate")
		quit(1)
		return
	joystick.call("update_drag", Vector2(300.0, 120.0))
	var joystick_offset: Vector2 = joystick.get("knob_offset")
	if not is_equal_approx(joystick_offset.length(), 76.0):
		push_error("SMOKE TEST: Virtual joystick did not clamp its knob to the radius")
		quit(1)
		return
	var joystick_vector: Vector2 = joystick.call("get_move_vector")
	if not is_equal_approx(joystick_vector.x, 1.0) or not is_equal_approx(joystick_vector.y, 0.0):
		push_error("SMOKE TEST: Virtual joystick direction was incorrect")
		quit(1)
		return
	joystick.call("end_drag")
	if bool(joystick.get("is_active")) or joystick.call("get_move_vector") != Vector2.ZERO:
		push_error("SMOKE TEST: Virtual joystick did not reset on release")
		quit(1)
		return
	joystick.queue_free()

	player.call("_toggle_mobile_sprint")
	if not bool(player.get("mobile_sprint_active")):
		push_error("SMOKE TEST: Sprint toggle did not activate")
		quit(1)
		return
	player.call("_toggle_mobile_sprint")
	if bool(player.get("mobile_sprint_active")):
		push_error("SMOKE TEST: Sprint toggle did not deactivate")
		quit(1)
		return

	print("PHOENIX_SMOKE_TEST_OK: arena, camera toggle, bots, loot, inventory caps/reload, medkit, armor, respawn, enemy attack, zone shrink/damage, virtual joystick and sprint toggle validated")
	quit(0)
