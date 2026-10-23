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

	var start_menu_layer: CanvasLayer = main_scene.find_child("StartMenuLayer", true, false) as CanvasLayer
	var deploy_button: Button = main_scene.find_child("DeployButton", true, false) as Button
	var menu_title: Label = main_scene.find_child("StartMenuTitle", true, false) as Label
	if start_menu_layer == null or deploy_button == null or menu_title == null or not start_menu_layer.visible:
		push_error("SMOKE TEST: Professional start/deployment menu was not created")
		quit(1)
		return
	if not main_scene.get_tree().paused:
		push_error("SMOKE TEST: Gameplay should be paused behind the deployment menu")
		quit(1)
		return
	deploy_button.pressed.emit()
	if main_scene.get_tree().paused or start_menu_layer.visible:
		push_error("SMOKE TEST: Deploy action did not close the menu and start gameplay")
		quit(1)
		return
	await process_frame
	await physics_frame

	var bot: Node3D = main_scene.find_child("Target_01", true, false) as Node3D
	if bot == null:
		push_error("SMOKE TEST: First enemy bot was not created")
		quit(1)
		return
	var old_strafe_phase := float(bot.get("strafe_phase"))
	bot.set("strafe_phase", 0.0)
	var clear_direction: Vector3 = bot.call("_calculate_obstacle_steer", Vector3(0.0, 0.0, -1.0), false, true, true)
	if clear_direction.distance_to(Vector3(0.0, 0.0, -1.0)) > 0.001:
		push_error("SMOKE TEST: Bot steering changed a clear path")
		quit(1)
		return
	var detour_direction: Vector3 = bot.call("_calculate_obstacle_steer", Vector3(0.0, 0.0, -1.0), true, true, false)
	if detour_direction.x >= -0.1 or detour_direction.z >= -0.1:
		push_error("SMOKE TEST: Bot did not steer around a blocked preferred side")
		quit(1)
		return
	var escape_direction: Vector3 = bot.call("_calculate_obstacle_steer", Vector3(0.0, 0.0, -1.0), true, true, true)
	if escape_direction.z <= 0.1:
		push_error("SMOKE TEST: Bot did not back away when both side paths were blocked")
		quit(1)
		return
	bot.set("strafe_phase", old_strafe_phase)

	var health_bar: ProgressBar = player.find_child("PlayerHealthBar", true, false) as ProgressBar
	var damage_overlay: ColorRect = player.find_child("DamageFlashOverlay", true, false) as ColorRect
	if health_bar == null or damage_overlay == null or int(health_bar.value) != 100:
		push_error("SMOKE TEST: Health bar or damage-feedback overlay was not initialized")
		quit(1)
		return
	player.call("_flash_damage_screen")
	if float(damage_overlay.color.a) < 0.25:
		push_error("SMOKE TEST: Incoming damage screen flash did not activate")
		quit(1)
		return
	player.call("_spawn_bullet_tracer", Vector3.ZERO, Vector3(0.0, 0.0, -8.0))
	var tracer_test: MeshInstance3D = main_scene.find_child("BulletTracer", true, false) as MeshInstance3D
	if tracer_test == null or tracer_test.mesh == null:
		push_error("SMOKE TEST: Bullet tracer mesh did not spawn")
		quit(1)
		return
	tracer_test.queue_free()

	var minimap: Control = main_scene.find_child("TacticalMinimap", true, false) as Control
	var combat_stats: Label = main_scene.find_child("CombatStats", true, false) as Label
	var player_visual: Node3D = main_scene.find_child("PhoenixPlayerVisual", true, false) as Node3D
	var third_person_weapon: Node3D = main_scene.find_child("ThirdPersonWeapon", true, false) as Node3D
	var bot_armor: Node3D = main_scene.find_child("BotArmor", true, false) as Node3D
	var left_leg_visual: Node3D = player.get("left_leg_visual") as Node3D
	var right_leg_visual: Node3D = player.get("right_leg_visual") as Node3D
	if minimap == null or minimap.get_script() == null or combat_stats == null:
		push_error("SMOKE TEST: Tactical minimap or alive/elimination HUD was not created")
		quit(1)
		return
	if player_visual == null or third_person_weapon == null:
		push_error("SMOKE TEST: Player tactical model or third-person weapon model was not created")
		quit(1)
		return
	if bot_armor == null or main_scene.find_child("BotHelmet", true, false) == null:
		push_error("SMOKE TEST: Enemy tactical armor/helmet model was not created")
		quit(1)
		return
	if left_leg_visual == null or right_leg_visual == null or not player.has_method("_update_character_animation"):
		push_error("SMOKE TEST: Character procedural gait references were not initialized")
		quit(1)
		return
	player.set("velocity", Vector3(5.5, 0.0, 0.0))
	player.call("_update_character_animation", 0.016)
	if not is_instance_valid(left_leg_visual) or not is_instance_valid(right_leg_visual):
		push_error("SMOKE TEST: Procedural gait update did not retain the leg visuals")
		quit(1)
		return
	player.set("velocity", Vector3.ZERO)
	player.call("_update_character_animation", 0.016)
	if not combat_stats.text.contains("ALIVE") or not combat_stats.text.contains("ELIMS"):
		push_error("SMOKE TEST: Tactical combat stats did not show alive and eliminations")
		quit(1)
		return

	var match_hud: Node = main_scene.get_node_or_null("GameHUD")
	if match_hud == null:
		push_error("SMOKE TEST: Match HUD layer was not created")
		quit(1)
		return
	var match_status: Label = match_hud.get_node_or_null("MatchStatus") as Label
	if match_status == null:
		push_error("SMOKE TEST: Match status label was not created")
		quit(1)
		return
	if not match_status.text.contains("TIME: 05:00") or not match_status.text.contains("LIVES: 3"):
		push_error("SMOKE TEST: Match countdown/lives HUD was incorrect: %s" % match_status.text)
		quit(1)
		return
	if main_scene.get("match_state") != &"IN_PROGRESS":
		push_error("SMOKE TEST: Match did not start in IN_PROGRESS state")
		quit(1)
		return

	var quality_button: Button = main_scene.get_node_or_null("GameHUD/GraphicsQualityButton") as Button
	if quality_button == null or quality_button.text != "QUALITY: BALANCED":
		push_error("SMOKE TEST: Balanced graphics preset was not selected initially")
		quit(1)
		return
	main_scene.call("_cycle_graphics_quality")
	if quality_button.text != "QUALITY: HIGH":
		push_error("SMOKE TEST: High graphics preset did not activate")
		quit(1)
		return
	main_scene.call("_cycle_graphics_quality")
	if quality_button.text != "QUALITY: LOW" or bool(main_scene.get("sun_light").get("shadow_enabled")):
		push_error("SMOKE TEST: Low graphics preset did not disable shadows")
		quit(1)
		return
	main_scene.call("_cycle_graphics_quality")
	if quality_button.text != "QUALITY: BALANCED" or not bool(main_scene.get("sun_light").get("shadow_enabled")):
		push_error("SMOKE TEST: Balanced graphics preset did not restore shadows")
		quit(1)
		return

	var pause_button: Button = main_scene.find_child("PauseButton", true, false) as Button
	var pause_panel: PanelContainer = main_scene.find_child("PausePanel", true, false) as PanelContainer
	var sensitivity_slider: HSlider = main_scene.find_child("AimSensitivitySlider", true, false) as HSlider
	if pause_button == null or pause_panel == null or sensitivity_slider == null:
		push_error("SMOKE TEST: Pause/settings controls were not created")
		quit(1)
		return
	pause_button.pressed.emit()
	if not main_scene.get_tree().paused or not pause_panel.visible:
		push_error("SMOKE TEST: Pause button did not pause gameplay and show the settings panel")
		quit(1)
		return
	sensitivity_slider.value = 0.0044
	if not is_equal_approx(float(player.get("mouse_sensitivity")), 0.0044):
		push_error("SMOKE TEST: Aim sensitivity slider did not update player mouse sensitivity")
		quit(1)
		return
	if not is_equal_approx(float(player.get("touch_look_sensitivity")), 0.006):
		push_error("SMOKE TEST: Aim sensitivity slider did not update touch sensitivity")
		quit(1)
		return
	pause_button.pressed.emit()
	if main_scene.get_tree().paused or pause_panel.visible:
		push_error("SMOKE TEST: Resume button did not resume gameplay")
		quit(1)
		return
	sensitivity_slider.value = 0.0022

	var online_toggle: Button = main_scene.find_child("OnlineToggleButton", true, false) as Button
	var network_panel: PanelContainer = main_scene.find_child("NetworkPanel", true, false) as PanelContainer
	var address_input: LineEdit = main_scene.find_child("ServerAddressInput", true, false) as LineEdit
	var port_input: LineEdit = main_scene.find_child("ServerPortInput", true, false) as LineEdit
	if online_toggle == null or network_panel == null or address_input == null or port_input == null:
		push_error("SMOKE TEST: Online host/join UI controls were not created")
		quit(1)
		return
	main_scene.call("_toggle_network_panel")
	if not network_panel.visible:
		push_error("SMOKE TEST: Online panel did not open")
		quit(1)
		return
	main_scene.call("_toggle_network_panel")
	if network_panel.visible:
		push_error("SMOKE TEST: Online panel did not close")
		quit(1)
		return
	if int(main_scene.call("_read_network_port")) != 24567:
		push_error("SMOKE TEST: Default network port was not parsed correctly")
		quit(1)
		return
	port_input.text = "not-a-port"
	if int(main_scene.call("_read_network_port")) != -1:
		push_error("SMOKE TEST: Invalid network port was not rejected")
		quit(1)
		return
	port_input.text = "24567"

	var network_test_roster: Array[Dictionary] = [
		{"peer_id": 1, "position": Vector3(0.0, 0.05, 16.0), "yaw": 0.0},
		{"peer_id": 42, "position": Vector3(3.0, 0.05, 4.0), "yaw": 1.2}
	]
	main_scene.call("_apply_network_roster", network_test_roster)
	var remote_avatar: Node3D = main_scene.get_node_or_null("RemotePlayer_42") as Node3D
	var replicas_after_add: Dictionary = main_scene.get("network_player_avatars")
	if remote_avatar == null or not replicas_after_add.has(42):
		push_error("SMOKE TEST: A remote roster member did not create a visible avatar")
		quit(1)
		return
	var roster_without_remote: Array[Dictionary] = [
		{"peer_id": 1, "position": Vector3(0.0, 0.05, 16.0), "yaw": 0.0}
	]
	main_scene.call("_apply_network_roster", roster_without_remote)
	var replicas_after_remove: Dictionary = main_scene.get("network_player_avatars")
	if replicas_after_remove.has(42):
		push_error("SMOKE TEST: Removed roster member avatar was not cleaned up")
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

	var poi_signs := main_scene.find_children("POI_*", "Label3D", true, false)
	if poi_signs.size() != 3:
		push_error("SMOKE TEST: Expected three named points of interest, got %d" % poi_signs.size())
		quit(1)
		return
	var warehouse_roofs := main_scene.find_children("WarehouseRoof_*", "StaticBody3D", true, false)
	var warehouse_windows := main_scene.find_children("WarehouseWindow_*", "MeshInstance3D", true, false)
	if warehouse_roofs.size() != 3 or warehouse_windows.size() != 6:
		push_error("SMOKE TEST: POI buildings must have three roofs and six facade windows")
		quit(1)
		return
	var loot_crates := main_scene.find_children("LootCrate_*", "Node3D", true, false)
	if loot_crates.size() != 3:
		push_error("SMOKE TEST: Expected three interactive supply crates, got %d" % loot_crates.size())
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

	var muzzle_flash: Node = player.get_node_or_null("CameraPivot/ThirdPersonSpringArm/PlayerCamera/MuzzleFlash")
	if muzzle_flash == null:
		push_error("SMOKE TEST: Muzzle flash visual was not created")
		quit(1)
		return
	var hit_marker: Node = player.get_node_or_null("PlayerHUD/HitMarker")
	if hit_marker == null:
		push_error("SMOKE TEST: Hit marker UI was not created")
		quit(1)
		return
	player.call("_trigger_weapon_feedback", 0.02)
	if float(player.get("recoil_offset")) >= 0.0 or not bool(muzzle_flash.get("visible")):
		push_error("SMOKE TEST: Weapon recoil or muzzle flash did not activate")
		quit(1)
		return
	player.call("_show_hit_marker")
	if not bool(hit_marker.get("visible")):
		push_error("SMOKE TEST: Hit marker did not activate")
		quit(1)
		return

	var loot_nodes: Array[Node] = main_scene.find_children("Loot_*", "Area3D", true, false)
	if loot_nodes.size() != 12:
		push_error("SMOKE TEST: Expected 12 loot pickups, got %d" % loot_nodes.size())
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

	if player.call("get_current_weapon_name") != "RIFLE":
		push_error("SMOKE TEST: Rifle should be equipped by default")
		quit(1)
		return
	player.call("switch_weapon", 1)
	if player.call("get_current_weapon_name") != "SMG" or int(player.get("ammo")) != 36 or int(player.get("reserve_ammo")) != 180:
		push_error("SMOKE TEST: SMG profile or starting ammo is incorrect")
		quit(1)
		return
	player.set("ammo", 7)
	player.set("reserve_ammo", 55)
	player.call("switch_weapon", 2)
	if player.call("get_current_weapon_name") != "SHOTGUN" or int(player.get("ammo")) != 8 or int(player.get("reserve_ammo")) != 40:
		push_error("SMOKE TEST: Shotgun profile or starting ammo is incorrect")
		quit(1)
		return
	player.call("switch_weapon", 3)
	if player.call("get_current_weapon_name") != "SNIPER" or int(player.get("ammo")) != 5 or int(player.get("reserve_ammo")) != 30:
		push_error("SMOKE TEST: Sniper profile or starting ammo is incorrect")
		quit(1)
		return
	player.call("switch_weapon", 4)
	if player.call("get_current_weapon_name") != "PISTOL" or int(player.get("ammo")) != 12 or int(player.get("reserve_ammo")) != 60:
		push_error("SMOKE TEST: Pistol profile or starting ammo is incorrect")
		quit(1)
		return
	player.call("switch_weapon", 0)
	if player.call("get_current_weapon_name") != "RIFLE" or int(player.get("ammo")) != 30 or int(player.get("reserve_ammo")) != 20:
		push_error("SMOKE TEST: Rifle ammunition was not preserved after switching")
		quit(1)
		return
	player.call("switch_weapon", 1)
	if int(player.get("ammo")) != 7 or int(player.get("reserve_ammo")) != 55:
		push_error("SMOKE TEST: SMG ammunition was not preserved after switching")
		quit(1)
		return
	player.call("switch_weapon", 0)

	var smg_ammo_pickup: Node = main_scene.get_node("Loot_09")
	smg_ammo_pickup.call("collect", player)
	if player.call("get_current_weapon_name") != "SMG" or int(player.get("ammo")) != 7 or int(player.get("reserve_ammo")) != 115:
		push_error("SMOKE TEST: SMG ammo pickup did not top up and select the SMG loadout")
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
	if int(health_bar.value) != 82:
		push_error("SMOKE TEST: Health bar did not update after combat damage")
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

	var network_script: Script = load("res://scripts/network_session.gd")
	if network_script == null:
		push_error("SMOKE TEST: Multiplayer session script could not be loaded")
		quit(1)
		return
	var network_session: Node = network_script.new()
	root.add_child(network_session)
	await process_frame
	var session_status: Dictionary = network_session.call("get_status_snapshot")
	if session_status.get("role") != &"OFFLINE" or bool(session_status.get("is_online")):
		push_error("SMOKE TEST: Multiplayer session did not initialize offline")
		quit(1)
		return
	if not bool(network_session.call("validate_server_address", "127.0.0.1")):
		push_error("SMOKE TEST: Valid IPv4 server address was rejected")
		quit(1)
		return
	if not bool(network_session.call("validate_server_address", "localhost")):
		push_error("SMOKE TEST: Valid hostname was rejected")
		quit(1)
		return
	if bool(network_session.call("validate_server_address", "bad address")) or bool(network_session.call("validate_server_address", "..bad-host")):
		push_error("SMOKE TEST: Invalid server address was accepted")
		quit(1)
		return
	if int(network_session.call("host_game", 0, 16)) != ERR_INVALID_PARAMETER:
		push_error("SMOKE TEST: Invalid server port was not rejected")
		quit(1)
		return
	if int(network_session.call("join_game", "bad address", 24567)) != ERR_INVALID_PARAMETER:
		push_error("SMOKE TEST: Invalid join address was not rejected")
		quit(1)
		return
	if int(network_session.call("host_game", 24681, 4)) != OK:
		push_error("SMOKE TEST: ENet host could not start on a valid local port")
		quit(1)
		return
	session_status = network_session.call("get_status_snapshot")
	if session_status.get("role") != &"SERVER" or not bool(session_status.get("is_server")) or not bool(session_status.get("is_online")):
		push_error("SMOKE TEST: ENet host did not enter server state")
		quit(1)
		return
	network_session.call("leave_game")
	session_status = network_session.call("get_status_snapshot")
	if session_status.get("role") != &"OFFLINE" or bool(session_status.get("is_online")):
		push_error("SMOKE TEST: ENet session did not return cleanly to offline state")
		quit(1)
		return
	network_session.queue_free()
	network_session.queue_free()

	var crate_for_test: Node3D = main_scene.get_node_or_null("LootCrate_01") as Node3D
	if crate_for_test == null:
		push_error("SMOKE TEST: Loot crate was missing before interaction")
		quit(1)
		return
	player.global_position = crate_for_test.global_position
	if not bool(player.call("_try_open_loot_crate")) or not bool(crate_for_test.get("opened")):
		push_error("SMOKE TEST: Nearby supply crate did not open and grant loot")
		quit(1)
		return
	if bool(crate_for_test.call("open_for", player)):
		push_error("SMOKE TEST: An already opened supply crate granted loot twice")
		quit(1)
		return

	for elimination_index in range(6):
		main_scene.call("_on_target_eliminated")
	if main_scene.get("match_state") != &"VICTORY":
		push_error("SMOKE TEST: Eliminating all targets did not complete the match")
		quit(1)
		return
	if main_scene.get_node_or_null("MatchResultLayer/MatchResultPanel") == null:
		push_error("SMOKE TEST: Victory result screen was not created")
		quit(1)
		return

	print("PHOENIX_SMOKE_TEST_OK: deployment menu, tactical minimap/HUD, health bar, damage flash, bullet tracer, player/enemy models, arena POIs, camera toggle, bots, loot crates, weapon ammo, inventory, armor, respawn, safe zone, virtual joystick, pause/sensitivity settings, network prototype and victory flow validated")
	quit(0)
