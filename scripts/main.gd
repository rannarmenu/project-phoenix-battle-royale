extends Node3D

const PlayerScript = preload("res://scripts/player.gd")
const TargetScript = preload("res://scripts/target.gd")
const LootScript = preload("res://scripts/loot_pickup.gd")
const SafeZoneScript = preload("res://scripts/safe_zone.gd")

var status_label: Label
var kill_feed_label: Label
var eliminated_count: int = 0
var total_targets: int = 0
var safe_zone: Node3D
var hud_refresh_timer: float = 0.0
var match_elapsed: float = 0.0
var match_duration: float = 300.0
var match_state: StringName = &"IN_PROGRESS"
var match_overlay: PanelContainer
var sun_light: DirectionalLight3D
var world_environment: WorldEnvironment
var quality_button: Button
var graphics_quality_index: int = 1
var online_toggle_button: Button
var network_panel: PanelContainer
var network_address_input: LineEdit
var network_port_input: LineEdit
var network_status_label: Label
var network_sync_elapsed: float = 0.0
var network_player_states: Dictionary = {}
var network_player_avatars: Dictionary = {}
const NETWORK_SYNC_INTERVAL: float = 0.05
const GRAPHICS_QUALITY_NAMES: Array[String] = ["LOW", "BALANCED", "HIGH"]

func _ready() -> void:
	NetworkSession.session_changed.connect(_on_network_session_changed)
	NetworkSession.peer_joined.connect(_on_network_peer_joined)
	NetworkSession.peer_left.connect(_on_network_peer_left)
	_build_environment()
	_build_arena()
	_spawn_safe_zone()
	_spawn_player()
	_spawn_targets()
	_spawn_loot()
	_build_hud()
	_set_graphics_quality(graphics_quality_index)
	_update_hud()

func _process(delta: float) -> void:
	_process_network_replication(delta)
	if match_state != &"IN_PROGRESS":
		return
	match_elapsed += delta
	if match_elapsed >= match_duration:
		_finish_match(&"TIME UP")
		return
	hud_refresh_timer += delta
	if hud_refresh_timer >= 0.25:
		hud_refresh_timer = 0.0
		_update_hud()

func _cycle_graphics_quality() -> void:
	_set_graphics_quality((graphics_quality_index + 1) % GRAPHICS_QUALITY_NAMES.size())

func _set_graphics_quality(quality_index: int) -> void:
	graphics_quality_index = clampi(quality_index, 0, GRAPHICS_QUALITY_NAMES.size() - 1)
	var quality_name: String = GRAPHICS_QUALITY_NAMES[graphics_quality_index]
	if is_instance_valid(quality_button):
		quality_button.text = "QUALITY: " + quality_name
	if is_instance_valid(sun_light):
		sun_light.shadow_enabled = quality_name != "LOW"
		sun_light.light_energy = 1.1 if quality_name == "LOW" else (1.4 if quality_name == "HIGH" else 1.25)
	if is_instance_valid(world_environment) and is_instance_valid(world_environment.environment):
		world_environment.environment.ambient_light_energy = 0.55 if quality_name == "LOW" else (0.78 if quality_name == "HIGH" else 0.65)

func _build_environment() -> void:
	world_environment = WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color(0.10, 0.23, 0.32)
	sky_material.sky_horizon_color = Color(0.53, 0.66, 0.66)
	sky_material.ground_bottom_color = Color(0.075, 0.095, 0.085)
	sky_material.ground_horizon_color = Color(0.30, 0.38, 0.31)
	sky.sky_material = sky_material
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.65
	world_environment.environment = env
	add_child(world_environment)

	sun_light = DirectionalLight3D.new()
	sun_light.name = "Sun"
	sun_light.rotation_degrees = Vector3(-48.0, -28.0, 0.0)
	sun_light.light_energy = 1.35
	sun_light.shadow_enabled = true
	add_child(sun_light)

func _build_arena() -> void:
	var floor_body := StaticBody3D.new()
	floor_body.name = "ArenaFloor"
	floor_body.position = Vector3(0.0, -0.5, 0.0)
	add_child(floor_body)

	var floor_mesh := MeshInstance3D.new()
	var floor_box := BoxMesh.new()
	floor_box.size = Vector3(90.0, 1.0, 90.0)
	floor_mesh.mesh = floor_box
	var floor_material := StandardMaterial3D.new()
	floor_material.albedo_color = Color(0.12, 0.19, 0.17)
	floor_material.roughness = 0.94
	floor_mesh.material_override = floor_material
	floor_body.add_child(floor_mesh)

	var floor_collision := CollisionShape3D.new()
	var floor_shape := BoxShape3D.new()
	floor_shape.size = Vector3(90.0, 1.0, 90.0)
	floor_collision.shape = floor_shape
	floor_body.add_child(floor_collision)

	_add_cover(Vector3(-8.0, 0.0, 2.0), Vector3(2.0, 2.2, 5.0), Color(0.26, 0.31, 0.29))
	_add_cover(Vector3(8.0, 0.0, -4.0), Vector3(2.0, 2.8, 4.0), Color(0.28, 0.30, 0.28))
	_add_cover(Vector3(0.0, 0.0, -10.0), Vector3(8.0, 1.4, 1.4), Color(0.31, 0.29, 0.23))
	_add_cover(Vector3(-15.0, 0.0, -12.0), Vector3(3.0, 2.0, 3.0), Color(0.22, 0.29, 0.30))
	_add_cover(Vector3(15.0, 0.0, 13.0), Vector3(3.5, 1.8, 3.0), Color(0.28, 0.25, 0.20))
	_add_cover(Vector3(2.0, 0.0, 9.0), Vector3(5.5, 1.2, 1.2), Color(0.25, 0.30, 0.27))
	_add_cover(Vector3(-21.0, 0.0, 3.0), Vector3(1.5, 3.0, 7.0), Color(0.27, 0.28, 0.29))
	_add_cover(Vector3(21.0, 0.0, -6.0), Vector3(1.5, 2.5, 7.0), Color(0.24, 0.29, 0.28))
	_build_perimeter_foliage()

func _build_perimeter_foliage() -> void:
	var tree_positions: Array[Vector3] = [
		Vector3(-34.0, 0.0, -32.0), Vector3(-23.0, 0.0, -35.0),
		Vector3(-11.0, 0.0, -37.0), Vector3(2.0, 0.0, -37.0),
		Vector3(17.0, 0.0, -35.0), Vector3(30.0, 0.0, -32.0),
		Vector3(-36.0, 0.0, -17.0), Vector3(-37.0, 0.0, -2.0),
		Vector3(-36.0, 0.0, 14.0), Vector3(-31.0, 0.0, 30.0),
		Vector3(35.0, 0.0, -21.0), Vector3(37.0, 0.0, -4.0),
		Vector3(36.0, 0.0, 13.0), Vector3(31.0, 0.0, 30.0),
		Vector3(-18.0, 0.0, 35.0), Vector3(0.0, 0.0, 37.0),
		Vector3(18.0, 0.0, 35.0)
	]
	for index in range(tree_positions.size()):
		var tree_scale := 0.88 + float(index % 4) * 0.12
		_add_pine_tree(tree_positions[index], tree_scale)

func _add_pine_tree(pos: Vector3, tree_scale: float) -> void:
	var tree := StaticBody3D.new()
	tree.name = "PineTree"
	tree.position = pos
	add_child(tree)

	var trunk := MeshInstance3D.new()
	var trunk_mesh := CylinderMesh.new()
	trunk_mesh.top_radius = 0.16 * tree_scale
	trunk_mesh.bottom_radius = 0.27 * tree_scale
	trunk_mesh.height = 1.8 * tree_scale
	trunk.mesh = trunk_mesh
	trunk.position.y = 0.9 * tree_scale
	var trunk_material := StandardMaterial3D.new()
	trunk_material.albedo_color = Color(0.30, 0.20, 0.12)
	trunk_material.roughness = 1.0
	trunk.material_override = trunk_material
	tree.add_child(trunk)

	var trunk_collision := CollisionShape3D.new()
	var trunk_shape := CylinderShape3D.new()
	trunk_shape.radius = 0.25 * tree_scale
	trunk_shape.height = 1.8 * tree_scale
	trunk_collision.shape = trunk_shape
	trunk_collision.position.y = 0.9 * tree_scale
	tree.add_child(trunk_collision)

	var foliage_colors: Array[Color] = [
		Color(0.10, 0.27, 0.18),
		Color(0.13, 0.32, 0.20),
		Color(0.16, 0.36, 0.22)
	]
	for tier in range(3):
		var foliage := MeshInstance3D.new()
		var cone := CylinderMesh.new()
		cone.top_radius = 0.035 * tree_scale
		cone.bottom_radius = (1.05 - float(tier) * 0.17) * tree_scale
		cone.height = (1.65 - float(tier) * 0.12) * tree_scale
		cone.radial_segments = 8
		foliage.mesh = cone
		foliage.position.y = (1.55 + float(tier) * 0.63) * tree_scale
		var foliage_material := StandardMaterial3D.new()
		foliage_material.albedo_color = foliage_colors[tier]
		foliage_material.roughness = 0.94
		foliage.material_override = foliage_material
		tree.add_child(foliage)

func _add_cover(pos: Vector3, dimensions: Vector3, tint: Color) -> void:
	var body := StaticBody3D.new()
	body.position = pos
	add_child(body)

	var mesh_instance := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = dimensions
	mesh_instance.mesh = box
	mesh_instance.position.y = dimensions.y * 0.5
	var mat := StandardMaterial3D.new()
	mat.albedo_color = tint
	mat.roughness = 0.82
	mesh_instance.material_override = mat
	body.add_child(mesh_instance)

	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = dimensions
	collision.shape = shape
	collision.position.y = dimensions.y * 0.5
	body.add_child(collision)

func _spawn_safe_zone() -> void:
	safe_zone = SafeZoneScript.new()
	safe_zone.name = "SafeZone"
	safe_zone.position = Vector3.ZERO
	add_child(safe_zone)

func _spawn_loot() -> void:
	var positions: Array[Vector3] = [
		Vector3(-10.0, 0.0, -1.0),
		Vector3(10.0, 0.0, -15.0),
		Vector3(12.0, 0.0, 7.0),
		Vector3(-18.0, 0.0, 9.0),
		Vector3(1.0, 0.0, -24.0),
		Vector3(24.0, 0.0, -10.0),
		Vector3(-24.0, 0.0, -21.0),
		Vector3(5.0, 0.0, 24.0)
	]
	var item_types: Array[StringName] = [
		&"ammo", &"medkit", &"armor", &"ammo",
		&"armor", &"medkit", &"ammo", &"medkit"
	]
	var amounts: Array[int] = [45, 1, 35, 30, 40, 1, 60, 1]
	for index in range(positions.size()):
		var pickup: Node3D = LootScript.new()
		pickup.name = "Loot_%02d" % (index + 1)
		pickup.set("item_type", item_types[index])
		pickup.set("amount", amounts[index])
		pickup.position = positions[index]
		add_child(pickup)

func _spawn_player() -> void:
	var player: CharacterBody3D = PlayerScript.new()
	player.name = "Player"
	player.position = Vector3(0.0, 0.05, 16.0)
	player.player_eliminated.connect(_on_player_eliminated)
	add_child(player)

func _spawn_targets() -> void:
	var target_positions: Array[Vector3] = [
		Vector3(-12.0, 0.0, -6.0),
		Vector3(-4.0, 0.0, -16.0),
		Vector3(5.0, 0.0, -20.0),
		Vector3(13.0, 0.0, -13.0),
		Vector3(16.0, 0.0, 3.0),
		Vector3(-17.0, 0.0, 12.0)
	]
	total_targets = target_positions.size()
	for index in range(target_positions.size()):
		var target = TargetScript.new()
		target.name = "Target_%02d" % (index + 1)
		target.position = target_positions[index]
		add_child(target)
		target.connect("eliminated", _on_target_eliminated)

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	layer.name = "GameHUD"
	add_child(layer)

	status_label = Label.new()
	status_label.name = "MatchStatus"
	status_label.position = Vector2(24.0, 16.0)
	status_label.add_theme_font_size_override("font_size", 18)
	status_label.add_theme_color_override("font_color", Color(0.9, 0.95, 0.9))
	layer.add_child(status_label)

	kill_feed_label = Label.new()
	kill_feed_label.name = "KillFeed"
	kill_feed_label.position = Vector2(24.0, 110.0)
	kill_feed_label.add_theme_font_size_override("font_size", 14)
	kill_feed_label.add_theme_color_override("font_color", Color(1.0, 0.82, 0.52))
	layer.add_child(kill_feed_label)

	var title := Label.new()
	title.text = "PHOENIX  /  BATTLE SIM"
	title.anchor_left = 0.5
	title.anchor_right = 0.5
	title.offset_left = -210.0
	title.offset_right = 210.0
	title.offset_top = 18.0
	title.offset_bottom = 52.0
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(0.87, 0.78, 0.48))
	layer.add_child(title)

	quality_button = Button.new()
	quality_button.name = "GraphicsQualityButton"
	quality_button.text = "QUALITY: BALANCED"
	quality_button.anchor_left = 0.5
	quality_button.anchor_right = 0.5
	quality_button.offset_left = -92.0
	quality_button.offset_right = 92.0
	quality_button.offset_top = 58.0
	quality_button.offset_bottom = 94.0
	quality_button.pressed.connect(_cycle_graphics_quality)
	layer.add_child(quality_button)

	_build_network_panel(layer)

	var crosshair := Label.new()
	crosshair.text = "+"
	crosshair.anchor_left = 0.5
	crosshair.anchor_top = 0.5
	crosshair.anchor_right = 0.5
	crosshair.anchor_bottom = 0.5
	crosshair.offset_left = -10.0
	crosshair.offset_right = 10.0
	crosshair.offset_top = -20.0
	crosshair.offset_bottom = 20.0
	crosshair.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	crosshair.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	crosshair.add_theme_font_size_override("font_size", 30)
	crosshair.add_theme_color_override("font_color", Color(0.95, 0.98, 0.89, 0.9))
	layer.add_child(crosshair)

func _on_target_eliminated() -> void:
	if match_state != &"IN_PROGRESS":
		return
	eliminated_count = mini(total_targets, eliminated_count + 1)
	if is_instance_valid(kill_feed_label):
		kill_feed_label.text = "ELIMINATION  +%d" % eliminated_count
	_update_hud()
	if eliminated_count >= total_targets:
		_finish_match(&"VICTORY")

func _on_player_eliminated() -> void:
	_finish_match(&"DEFEAT")

func _finish_match(result: StringName) -> void:
	if match_state != &"IN_PROGRESS":
		return
	match_state = result
	var player := get_node_or_null("Player")
	if is_instance_valid(player):
		player.process_mode = Node.PROCESS_MODE_DISABLED
		player.set_process_input(false)
		player.set_process_unhandled_input(false)
	for bot in get_tree().get_nodes_in_group("enemy_bots"):
		if is_instance_valid(bot):
			bot.process_mode = Node.PROCESS_MODE_DISABLED
	if is_instance_valid(safe_zone):
		safe_zone.process_mode = Node.PROCESS_MODE_DISABLED

	var layer := CanvasLayer.new()
	layer.name = "MatchResultLayer"
	add_child(layer)
	match_overlay = PanelContainer.new()
	match_overlay.name = "MatchResultPanel"
	match_overlay.anchor_left = 0.5
	match_overlay.anchor_right = 0.5
	match_overlay.anchor_top = 0.5
	match_overlay.anchor_bottom = 0.5
	match_overlay.offset_left = -190.0
	match_overlay.offset_right = 190.0
	match_overlay.offset_top = -125.0
	match_overlay.offset_bottom = 125.0
	layer.add_child(match_overlay)

	var layout := VBoxContainer.new()
	layout.alignment = BoxContainer.ALIGNMENT_CENTER
	layout.add_theme_constant_override("separation", 14)
	match_overlay.add_child(layout)
	var headline := Label.new()
	headline.text = "MISSION COMPLETE" if result == &"VICTORY" else "MISSION FAILED"
	headline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	headline.add_theme_font_size_override("font_size", 26)
	headline.add_theme_color_override("font_color", Color(0.87, 0.78, 0.48) if result == &"VICTORY" else Color(1.0, 0.36, 0.28))
	layout.add_child(headline)
	var details := Label.new()
	details.text = "All enemies eliminated." if result == &"VICTORY" else ("All lives lost." if result == &"DEFEAT" else "The match timer has expired.")
	details.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	details.add_theme_font_size_override("font_size", 16)
	layout.add_child(details)
	var retry := Button.new()
	retry.text = "PLAY AGAIN"
	retry.custom_minimum_size = Vector2(150.0, 44.0)
	retry.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	retry.pressed.connect(func() -> void: get_tree().reload_current_scene())
	layout.add_child(retry)
	_update_hud()



func _build_network_panel(layer: CanvasLayer) -> void:
	online_toggle_button = Button.new()
	online_toggle_button.name = "OnlineToggleButton"
	online_toggle_button.text = "ONLINE  +"
	online_toggle_button.anchor_left = 0.5
	online_toggle_button.anchor_right = 0.5
	online_toggle_button.anchor_top = 1.0
	online_toggle_button.anchor_bottom = 1.0
	online_toggle_button.offset_left = -76.0
	online_toggle_button.offset_right = 76.0
	online_toggle_button.offset_top = -52.0
	online_toggle_button.offset_bottom = -12.0
	online_toggle_button.pressed.connect(_toggle_network_panel)
	layer.add_child(online_toggle_button)

	network_panel = PanelContainer.new()
	network_panel.name = "NetworkPanel"
	network_panel.anchor_left = 0.5
	network_panel.anchor_right = 0.5
	network_panel.anchor_top = 1.0
	network_panel.anchor_bottom = 1.0
	network_panel.offset_left = -150.0
	network_panel.offset_right = 150.0
	network_panel.offset_top = -276.0
	network_panel.offset_bottom = -62.0
	network_panel.visible = false
	layer.add_child(network_panel)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 7)
	network_panel.add_child(layout)

	var heading := Label.new()
	heading.text = "PHOENIX ONLINE  /  EXPERIMENTAL"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 13)
	layout.add_child(heading)

	network_address_input = LineEdit.new()
	network_address_input.name = "ServerAddressInput"
	network_address_input.placeholder_text = "Server IP or hostname"
	network_address_input.text = "127.0.0.1"
	network_address_input.clear_button_enabled = true
	layout.add_child(network_address_input)

	network_port_input = LineEdit.new()
	network_port_input.name = "ServerPortInput"
	network_port_input.placeholder_text = "UDP port (1024-65535)"
	network_port_input.text = str(NetworkSession.DEFAULT_PORT)
	network_port_input.max_length = 5
	network_port_input.input_filter = "0123456789"
	layout.add_child(network_port_input)

	var button_row := HBoxContainer.new()
	button_row.add_theme_constant_override("separation", 6)
	layout.add_child(button_row)

	var host_button := Button.new()
	host_button.name = "HostSessionButton"
	host_button.text = "HOST"
	host_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	host_button.pressed.connect(_on_host_session_pressed)
	button_row.add_child(host_button)

	var join_button := Button.new()
	join_button.name = "JoinSessionButton"
	join_button.text = "JOIN"
	join_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	join_button.pressed.connect(_on_join_session_pressed)
	button_row.add_child(join_button)

	var leave_button := Button.new()
	leave_button.name = "LeaveSessionButton"
	leave_button.text = "LEAVE"
	leave_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	leave_button.pressed.connect(_on_leave_session_pressed)
	button_row.add_child(leave_button)

	network_status_label = Label.new()
	network_status_label.name = "NetworkStatus"
	network_status_label.text = "Offline — host and join over a reachable network."
	network_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	network_status_label.add_theme_font_size_override("font_size", 12)
	layout.add_child(network_status_label)

func _toggle_network_panel() -> void:
	if not is_instance_valid(network_panel):
		return
	network_panel.visible = not network_panel.visible
	online_toggle_button.text = "ONLINE  -" if network_panel.visible else "ONLINE  +"

func _read_network_port() -> int:
	if not is_instance_valid(network_port_input):
		return NetworkSession.DEFAULT_PORT
	var value := network_port_input.text.strip_edges()
	if not value.is_valid_int():
		return -1
	var port := int(value)
	return port if port >= 1 and port <= 65535 else -1

func _on_host_session_pressed() -> void:
	var port := _read_network_port()
	if port < 1:
		_set_network_status("Invalid port. Enter a value from 1 to 65535.")
		return
	var result: int = NetworkSession.host_game(port, 16)
	if result != OK:
		_set_network_status(NetworkSession.status_message)
	else:
		_set_network_status("Hosting on UDP %d. Allow this port through your firewall/router." % port)

func _on_join_session_pressed() -> void:
	var port := _read_network_port()
	if port < 1:
		_set_network_status("Invalid port. Enter a value from 1 to 65535.")
		return
	var address := network_address_input.text.strip_edges()
	var result: int = NetworkSession.join_game(address, port)
	if result != OK:
		_set_network_status(NetworkSession.status_message)
	else:
		_set_network_status("Connecting to %s:%d…" % [address, port])

func _on_leave_session_pressed() -> void:
	NetworkSession.leave_game()

func _set_network_status(message: String) -> void:
	if is_instance_valid(network_status_label):
		network_status_label.text = message

func _on_network_session_changed(role: StringName, message: String) -> void:
	_set_network_status("%s — %s" % [str(role), message])
	if role == &"SERVER":
		network_player_states.clear()
		var local_player := get_node_or_null("Player") as Node3D
		if is_instance_valid(local_player):
			network_player_states[1] = {
				"position": local_player.global_position,
				"yaw": local_player.rotation.y,
				"received_at": Time.get_ticks_msec() * 0.001
			}
		_broadcast_network_roster()
	elif role == &"CLIENT":
		var local_player := get_node_or_null("Player") as Node3D
		if is_instance_valid(local_player):
			var local_id := multiplayer.get_unique_id()
			local_player.global_position = _spawn_position_for_peer(local_id)
			local_player.set("spawn_position", local_player.global_position)
			network_player_states[local_id] = {
				"position": local_player.global_position,
				"yaw": local_player.rotation.y,
				"received_at": Time.get_ticks_msec() * 0.001
			}
	elif role == &"OFFLINE":
		_clear_network_avatars()
		network_player_states.clear()

func _on_network_peer_joined(peer_id: int) -> void:
	if NetworkSession.session_role != &"SERVER" or peer_id <= 1:
		return
	var spawn_position := _spawn_position_for_peer(peer_id)
	network_player_states[peer_id] = {
		"position": spawn_position,
		"yaw": 0.0,
		"received_at": Time.get_ticks_msec() * 0.001
	}
	_broadcast_network_roster()

func _on_network_peer_left(peer_id: int) -> void:
	network_player_states.erase(peer_id)
	if network_player_avatars.has(peer_id):
		var avatar: Node = network_player_avatars[peer_id]
		if is_instance_valid(avatar):
			avatar.queue_free()
		network_player_avatars.erase(peer_id)
	if NetworkSession.session_role == &"SERVER":
		_broadcast_network_roster()

func _spawn_position_for_peer(peer_id: int) -> Vector3:
	var spawn_positions: Array[Vector3] = [
		Vector3(0.0, 0.05, 16.0),
		Vector3(8.0, 0.05, 16.0),
		Vector3(-8.0, 0.05, 16.0),
		Vector3(0.0, 0.05, 8.0),
		Vector3(12.0, 0.05, 8.0),
		Vector3(-12.0, 0.05, 8.0),
		Vector3(5.0, 0.05, 24.0),
		Vector3(-5.0, 0.05, 24.0)
	]
	return spawn_positions[wrapi(peer_id - 1, 0, spawn_positions.size())]

func _broadcast_network_roster() -> void:
	if NetworkSession.session_role != &"SERVER":
		return
	var roster: Array[Dictionary] = []
	var peer_ids: Array[int] = [1]
	for peer_id_variant in multiplayer.get_peers():
		peer_ids.append(int(peer_id_variant))
	for peer_id in peer_ids:
		var state: Dictionary = network_player_states.get(peer_id, {
			"position": _spawn_position_for_peer(peer_id),
			"yaw": 0.0,
			"received_at": Time.get_ticks_msec() * 0.001
		})
		roster.append({
			"peer_id": peer_id,
			"position": state.get("position", _spawn_position_for_peer(peer_id)),
			"yaw": float(state.get("yaw", 0.0))
		})
	_apply_network_roster(roster)
	if not multiplayer.get_peers().is_empty():
		rpc("_receive_network_roster", roster)

@rpc("authority", "call_remote", "reliable")
func _receive_network_roster(roster: Array) -> void:
	_apply_network_roster(roster)

func _apply_network_roster(roster: Array) -> void:
	var local_id := multiplayer.get_unique_id()
	var seen: Dictionary = {}
	for entry_variant in roster:
		if not entry_variant is Dictionary:
			continue
		var entry: Dictionary = entry_variant
		var peer_id := int(entry.get("peer_id", 0))
		if peer_id <= 0:
			continue
		seen[peer_id] = true
		var player_position: Vector3 = entry.get("position", _spawn_position_for_peer(peer_id))
		var player_yaw := float(entry.get("yaw", 0.0))
		network_player_states[peer_id] = {
			"position": player_position,
			"yaw": player_yaw,
			"received_at": Time.get_ticks_msec() * 0.001
		}
		if peer_id != local_id:
			_ensure_network_avatar(peer_id, player_position)
	for peer_id_variant in network_player_avatars.keys():
		var peer_id := int(peer_id_variant)
		if not seen.has(peer_id) or peer_id == local_id:
			var avatar: Node = network_player_avatars.get(peer_id)
			if is_instance_valid(avatar):
				avatar.queue_free()
			network_player_avatars.erase(peer_id)

func _ensure_network_avatar(peer_id: int, initial_position: Vector3) -> Node3D:
	var existing: Node3D = network_player_avatars.get(peer_id) as Node3D
	if is_instance_valid(existing):
		return existing
	var avatar := Node3D.new()
	avatar.name = "RemotePlayer_%d" % peer_id

	var body := MeshInstance3D.new()
	var body_mesh := CapsuleMesh.new()
	body_mesh.radius = 0.39
	body_mesh.height = 1.8
	body.mesh = body_mesh
	body.position.y = 0.93
	var body_material := StandardMaterial3D.new()
	body_material.albedo_color = Color.from_hsv(fposmod(float(peer_id) * 0.19, 1.0), 0.56, 0.78)
	body_material.roughness = 0.78
	body.material_override = body_material
	avatar.add_child(body)

	var head := MeshInstance3D.new()
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.22
	head_mesh.height = 0.44
	head.mesh = head_mesh
	head.position.y = 1.92
	var head_material := StandardMaterial3D.new()
	head_material.albedo_color = Color(0.72, 0.52, 0.38)
	head.material_override = head_material
	avatar.add_child(head)

	var name_label := Label3D.new()
	name_label.text = "PLAYER %02d" % peer_id
	name_label.position = Vector3(0.0, 2.35, 0.0)
	name_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	name_label.font_size = 28
	name_label.pixel_size = 0.006
	name_label.modulate = Color(0.92, 0.97, 0.91)
	avatar.add_child(name_label)

	add_child(avatar)
	avatar.global_position = initial_position
	network_player_avatars[peer_id] = avatar
	return avatar

func _clear_network_avatars() -> void:
	for avatar_variant in network_player_avatars.values():
		var avatar: Node = avatar_variant
		if is_instance_valid(avatar):
			avatar.queue_free()
	network_player_avatars.clear()

func _process_network_replication(delta: float) -> void:
	var smoothing := clampf(delta * 14.0, 0.0, 1.0)
	for peer_id_variant in network_player_avatars.keys():
		var peer_id := int(peer_id_variant)
		var avatar: Node3D = network_player_avatars.get(peer_id) as Node3D
		var state: Dictionary = network_player_states.get(peer_id, {})
		if is_instance_valid(avatar) and not state.is_empty():
			var target_position: Vector3 = state.get("position", avatar.global_position)
			var target_yaw := float(state.get("yaw", avatar.rotation.y))
			avatar.global_position = avatar.global_position.lerp(target_position, smoothing)
			avatar.rotation.y = lerp_angle(avatar.rotation.y, target_yaw, smoothing)

	if NetworkSession.session_role not in [&"SERVER", &"CLIENT"]:
		return
	network_sync_elapsed += delta
	if network_sync_elapsed < NETWORK_SYNC_INTERVAL:
		return
	network_sync_elapsed = 0.0
	var local_player := get_node_or_null("Player") as Node3D
	if not is_instance_valid(local_player):
		return
	var position_now := local_player.global_position
	var yaw_now := local_player.rotation.y
	if NetworkSession.session_role == &"CLIENT":
		rpc_id(1, "_server_submit_player_state", position_now, yaw_now)
	elif NetworkSession.session_role == &"SERVER":
		network_player_states[1] = {
			"position": position_now,
			"yaw": yaw_now,
			"received_at": Time.get_ticks_msec() * 0.001
		}
		if not multiplayer.get_peers().is_empty():
			rpc("_receive_player_state", 1, position_now, yaw_now)

@rpc("any_peer", "call_remote", "unreliable_ordered")
func _server_submit_player_state(player_position: Vector3, player_yaw: float) -> void:
	if NetworkSession.session_role != &"SERVER" or not multiplayer.is_server():
		return
	var sender_id := multiplayer.get_remote_sender_id()
	if sender_id <= 1 or not network_player_states.has(sender_id):
		return
	if not (
		absf(player_position.x) <= 45.0
		and absf(player_position.z) <= 45.0
		and player_position.y >= -5.0
		and player_position.y <= 20.0
	):
		return

	var now := Time.get_ticks_msec() * 0.001
	var previous: Dictionary = network_player_states.get(sender_id, {})
	var previous_position: Vector3 = previous.get("position", _spawn_position_for_peer(sender_id))
	var previous_time := float(previous.get("received_at", now))
	if previous_time > 0.0:
		var elapsed := clampf(now - previous_time, 0.05, 0.75)
		var max_distance := 14.0 * elapsed + 2.0
		if previous_position.distance_to(player_position) > max_distance:
			return

	var safe_yaw := wrapf(player_yaw, -PI, PI)
	network_player_states[sender_id] = {
		"position": player_position,
		"yaw": safe_yaw,
		"received_at": now
	}
	if not multiplayer.get_peers().is_empty():
		rpc("_receive_player_state", sender_id, player_position, safe_yaw)

@rpc("authority", "call_remote", "unreliable_ordered")
func _receive_player_state(peer_id: int, player_position: Vector3, player_yaw: float) -> void:
	if peer_id <= 0:
		return
	var local_id := multiplayer.get_unique_id()
	network_player_states[peer_id] = {
		"position": player_position,
		"yaw": player_yaw,
		"received_at": Time.get_ticks_msec() * 0.001
	}
	if peer_id != local_id:
		_ensure_network_avatar(peer_id, player_position)


func _update_hud() -> void:
	if not is_instance_valid(status_label):
		return
	var zone_text := "SAFE ZONE: --"
	var player := get_node_or_null("Player") as Node3D
	if is_instance_valid(safe_zone) and is_instance_valid(player):
		zone_text = safe_zone.call("get_status_text_for_position", player.global_position)
	var player_lives: int = int(player.get("lives_remaining")) if is_instance_valid(player) else 0
	var time_left: int = maxi(0, int(ceil(match_duration - match_elapsed)))
	var clock_text := "%02d:%02d" % [int(time_left / 60), time_left % 60]
	status_label.text = "PHOENIX  |  %s\nTARGETS: %d / %d   LIVES: %d   TIME: %s\n%s" % [
		str(match_state), eliminated_count, total_targets, player_lives, clock_text, zone_text
	]
