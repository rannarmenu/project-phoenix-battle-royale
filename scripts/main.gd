extends Node3D

const PlayerScript = preload("res://scripts/player.gd")
const TargetScript = preload("res://scripts/target.gd")

var status_label: Label
var eliminated_count: int = 0
var total_targets: int = 0

func _ready() -> void:
	_build_environment()
	_build_arena()
	_spawn_player()
	_spawn_targets()
	_build_hud()
	_update_hud()

func _build_environment() -> void:
	var world_env := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.035, 0.065, 0.085)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.72, 0.79, 0.83)
	env.ambient_light_energy = 0.75
	world_env.environment = env
	add_child(world_env)

	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.rotation_degrees = Vector3(-48.0, -28.0, 0.0)
	sun.light_energy = 1.35
	sun.shadow_enabled = true
	add_child(sun)

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

func _spawn_player() -> void:
	var player: CharacterBody3D = PlayerScript.new()
	player.name = "Player"
	player.position = Vector3(0.0, 0.05, 16.0)
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
	status_label.position = Vector2(24.0, 20.0)
	status_label.add_theme_font_size_override("font_size", 22)
	status_label.add_theme_color_override("font_color", Color(0.9, 0.95, 0.9))
	layer.add_child(status_label)

	var title := Label.new()
	title.text = "PHOENIX  /  TRAINING RANGE"
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
	eliminated_count += 1
	_update_hud()

func _update_hud() -> void:
	if is_instance_valid(status_label):
		status_label.text = "TRAINING RANGE\nTARGETS: %d / %d" % [eliminated_count, total_targets]
