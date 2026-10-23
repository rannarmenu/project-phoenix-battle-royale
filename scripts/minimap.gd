extends Control

const MAP_LIMIT: float = 45.0
const POI_MARKERS: Array[Dictionary] = [
	{"label": "NW", "position": Vector2(-25.0, -10.0)},
	{"label": "EO", "position": Vector2(24.0, -24.0)},
	{"label": "SD", "position": Vector2(23.0, 22.0)}
]

var redraw_elapsed: float = 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(168.0, 168.0)
	queue_redraw()

func _process(delta: float) -> void:
	redraw_elapsed += delta
	if redraw_elapsed >= 0.12:
		redraw_elapsed = 0.0
		queue_redraw()

func _draw() -> void:
	var panel_rect := Rect2(Vector2.ZERO, size)
	draw_rect(panel_rect, Color(0.018, 0.035, 0.041, 0.94), true)
	draw_rect(panel_rect, Color(0.66, 0.78, 0.68, 0.72), false, 1.4)

	var map_rect := Rect2(Vector2(5.0, 21.0), Vector2(maxf(1.0, size.x - 10.0), maxf(1.0, size.y - 26.0)))
	draw_rect(map_rect, Color(0.075, 0.13, 0.105, 0.98), true)

	for grid_index in range(1, 4):
		var x := map_rect.position.x + map_rect.size.x * float(grid_index) / 4.0
		var y := map_rect.position.y + map_rect.size.y * float(grid_index) / 4.0
		draw_line(Vector2(x, map_rect.position.y), Vector2(x, map_rect.end.y), Color(0.6, 0.75, 0.64, 0.15), 1.0)
		draw_line(Vector2(map_rect.position.x, y), Vector2(map_rect.end.x, y), Color(0.6, 0.75, 0.64, 0.15), 1.0)

	var main_road := PackedVector2Array([
		_world_to_map(Vector2(-MAP_LIMIT, 1.0), map_rect),
		_world_to_map(Vector2(0.0, 0.0), map_rect),
		_world_to_map(Vector2(MAP_LIMIT, -2.0), map_rect)
	])
	draw_polyline(main_road, Color(0.48, 0.52, 0.43, 0.55), 5.0, true)
	var cross_road := PackedVector2Array([
		_world_to_map(Vector2(-8.0, -MAP_LIMIT), map_rect),
		_world_to_map(Vector2(0.0, -4.0), map_rect),
		_world_to_map(Vector2(6.0, MAP_LIMIT), map_rect)
	])
	draw_polyline(cross_road, Color(0.48, 0.52, 0.43, 0.42), 3.0, true)

	for poi in POI_MARKERS:
		var point: Vector2 = _world_to_map(poi["position"], map_rect)
		draw_rect(Rect2(point - Vector2(3.0, 3.0), Vector2(6.0, 6.0)), Color(0.82, 0.72, 0.42), true)
		draw_string(get_theme_default_font(), point + Vector2(5.0, -4.0), str(poi["label"]), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 9, Color(0.91, 0.88, 0.7, 0.95))

	var safe_zone := get_tree().root.find_child("SafeZone", true, false) as Node3D
	if is_instance_valid(safe_zone) and safe_zone.has_method("get_current_radius"):
		var pixels_per_unit: float = minf(map_rect.size.x, map_rect.size.y) / (MAP_LIMIT * 2.0)
		var radius: float = clampf(float(safe_zone.call("get_current_radius")) * pixels_per_unit, 1.0, map_rect.size.x * 0.75)
		draw_arc(map_rect.get_center(), radius, 0.0, TAU, 64, Color(0.24, 0.72, 1.0, 0.9), 1.5, true)

	for pickup_variant in get_tree().get_nodes_in_group("loot_pickups"):
		var pickup := pickup_variant as Node3D
		if is_instance_valid(pickup):
			var pickup_position := _world_to_map(Vector2(pickup.global_position.x, pickup.global_position.z), map_rect)
			draw_circle(pickup_position, 2.0, Color(1.0, 0.73, 0.28, 0.95))

	for crate_variant in get_tree().get_nodes_in_group("loot_crates"):
		var crate := crate_variant as Node3D
		if is_instance_valid(crate) and not bool(crate.get("opened")):
			var crate_position := _world_to_map(Vector2(crate.global_position.x, crate.global_position.z), map_rect)
			var diamond := PackedVector2Array([
				crate_position + Vector2(0.0, -4.0),
				crate_position + Vector2(4.0, 0.0),
				crate_position + Vector2(0.0, 4.0),
				crate_position + Vector2(-4.0, 0.0)
			])
			draw_colored_polygon(diamond, Color(1.0, 0.82, 0.32))

	for bot_variant in get_tree().get_nodes_in_group("enemy_bots"):
		var bot := bot_variant as Node3D
		if is_instance_valid(bot):
			draw_circle(_world_to_map(Vector2(bot.global_position.x, bot.global_position.z), map_rect), 3.0, Color(1.0, 0.28, 0.23))

	var remote_players := get_tree().root.find_children("RemotePlayer_*", "Node3D", true, false)
	for remote_variant in remote_players:
		var remote := remote_variant as Node3D
		if is_instance_valid(remote):
			draw_circle(_world_to_map(Vector2(remote.global_position.x, remote.global_position.z), map_rect), 3.0, Color(0.3, 0.75, 1.0))

	var player := get_tree().get_first_node_in_group("player") as Node3D
	if is_instance_valid(player):
		var player_point := _world_to_map(Vector2(player.global_position.x, player.global_position.z), map_rect)
		var forward: Vector3 = -player.global_transform.basis.z
		var direction := Vector2(forward.x, forward.z).normalized()
		var tip := player_point + direction * 7.0
		var rear := player_point - direction * 4.5
		var side := Vector2(-direction.y, direction.x) * 4.2
		draw_colored_polygon(PackedVector2Array([tip, rear + side, rear - side]), Color(0.78, 1.0, 0.88))
		draw_circle(player_point, 2.0, Color(0.03, 0.12, 0.09))

	draw_string(get_theme_default_font(), Vector2(8.0, 14.0), "TACTICAL  /  PHOENIX", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 10, Color(0.88, 0.83, 0.65))

func _world_to_map(world_position: Vector2, map_rect: Rect2) -> Vector2:
	var normalized := (world_position + Vector2(MAP_LIMIT, MAP_LIMIT)) / (MAP_LIMIT * 2.0)
	return Vector2(
		map_rect.position.x + clampf(normalized.x, 0.0, 1.0) * map_rect.size.x,
		map_rect.position.y + clampf(normalized.y, 0.0, 1.0) * map_rect.size.y
	)
