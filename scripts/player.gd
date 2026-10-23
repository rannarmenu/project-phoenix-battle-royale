extends CharacterBody3D

signal camera_mode_changed(first_person: bool)
signal player_eliminated

const VirtualJoystickScript = preload("res://scripts/virtual_joystick.gd")
const WEAPON_PROFILES: Array[Dictionary] = [
	{"name": "RIFLE", "damage": 34.0, "fire_delay": 0.14, "magazine_size": 30, "reserve_capacity": 240, "default_reserve": 120, "range": 140.0, "pellets": 1, "spread": 0.008, "recoil": 0.012, "mesh_size": Vector3(0.16, 0.13, 0.58), "color": Color(0.095, 0.12, 0.12)},
	{"name": "SMG", "damage": 21.0, "fire_delay": 0.075, "magazine_size": 36, "reserve_capacity": 300, "default_reserve": 180, "range": 95.0, "pellets": 1, "spread": 0.02, "recoil": 0.008, "mesh_size": Vector3(0.14, 0.12, 0.46), "color": Color(0.16, 0.23, 0.21)},
	{"name": "SHOTGUN", "damage": 12.0, "fire_delay": 0.72, "magazine_size": 8, "reserve_capacity": 80, "default_reserve": 40, "range": 38.0, "pellets": 7, "spread": 0.055, "recoil": 0.035, "mesh_size": Vector3(0.19, 0.16, 0.72), "color": Color(0.29, 0.21, 0.14)},
	{"name": "SNIPER", "damage": 88.0, "fire_delay": 1.05, "magazine_size": 5, "reserve_capacity": 60, "default_reserve": 30, "range": 220.0, "pellets": 1, "spread": 0.002, "recoil": 0.05, "mesh_size": Vector3(0.12, 0.12, 0.88), "color": Color(0.18, 0.20, 0.23)},
	{"name": "PISTOL", "damage": 26.0, "fire_delay": 0.24, "magazine_size": 12, "reserve_capacity": 120, "default_reserve": 60, "range": 90.0, "pellets": 1, "spread": 0.014, "recoil": 0.016, "mesh_size": Vector3(0.13, 0.12, 0.34), "color": Color(0.22, 0.24, 0.22)}
]

const MOVE_SPEED := 6.5
const SPRINT_SPEED := 8.5
const JUMP_SPEED := 7.0
const GRAVITY := 22.0
var mouse_sensitivity: float = 0.0022
var touch_look_sensitivity: float = 0.003
const JOYSTICK_RADIUS := 88.0

var player_visual_root: Node3D
var third_person_weapon: Node3D
var left_upper_arm_visual: MeshInstance3D
var right_upper_arm_visual: MeshInstance3D
var left_leg_visual: MeshInstance3D
var right_leg_visual: MeshInstance3D
var camera: Camera3D
var camera_pivot: Node3D
var spring_arm: SpringArm3D
var weapon: MeshInstance3D
var touch_move_index := -1
var touch_look_index := -1
var touch_move_origin := Vector2.ZERO
var touch_move_vector := Vector2.ZERO
var can_fire := true
var jump_requested := false
var first_person := false
var is_mobile := false
var ammo := 30
var reserve_ammo := 120
var current_weapon_index: int = 0
var weapon_loadouts: Dictionary = {
	"RIFLE": {"ammo": 30, "reserve": 120},
	"SMG": {"ammo": 36, "reserve": 180},
	"SHOTGUN": {"ammo": 8, "reserve": 40},
	"SNIPER": {"ammo": 5, "reserve": 30},
	"PISTOL": {"ammo": 12, "reserve": 60}
}
var medkits := 1
var armor := 0
var health := 100
var lives_remaining: int = 3
var spawn_position := Vector3.ZERO
var hud_label: Label
var health_bar: ProgressBar
var health_fill_style: StyleBoxFlat
var damage_overlay: ColorRect
var damage_flash_tween: Tween
var joystick_overlay: Control
var mobile_sprint_button: Button
var mobile_sprint_active: bool = false
var mobile_weapon_button: Button
var hit_marker_label: Label
var muzzle_flash: MeshInstance3D
var camera_pitch: float = 0.0
var recoil_offset: float = 0.0

func _ready() -> void:
	is_mobile = OS.has_feature("android") or OS.has_feature("ios")
	spawn_position = global_position
	add_to_group("player")
	_make_player_body()
	_make_camera_and_weapon()
	_configure_input()
	_build_hud()
	if not is_mobile:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	_update_camera_mode()

func _make_player_body() -> void:
	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.42
	capsule.height = 1.85
	collision.shape = capsule
	collision.position.y = 0.93
	add_child(collision)

	player_visual_root = Node3D.new()
	player_visual_root.name = "PhoenixPlayerVisual"
	add_child(player_visual_root)

	var body := MeshInstance3D.new()
	body.name = "PhoenixPlayerBody"
	var body_mesh := CapsuleMesh.new()
	body_mesh.radius = 0.39
	body_mesh.height = 1.8
	body.mesh = body_mesh
	body.position.y = 0.93
	var body_material := StandardMaterial3D.new()
	body_material.albedo_color = Color(0.10, 0.25, 0.22)
	body_material.roughness = 0.86
	body.material_override = body_material
	player_visual_root.add_child(body)

	var head := MeshInstance3D.new()
	head.name = "PhoenixPlayerHead"
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.22
	head_mesh.height = 0.44
	head.mesh = head_mesh
	head.position.y = 1.92
	var head_material := StandardMaterial3D.new()
	head_material.albedo_color = Color(0.72, 0.52, 0.38)
	head_material.roughness = 0.9
	head.material_override = head_material
	player_visual_root.add_child(head)

	var helmet := MeshInstance3D.new()
	helmet.name = "CombatHelmet"
	var helmet_mesh := SphereMesh.new()
	helmet_mesh.radius = 0.255
	helmet_mesh.height = 0.36
	helmet.mesh = helmet_mesh
	helmet.scale = Vector3(1.0, 0.72, 1.06)
	helmet.position = Vector3(0.0, 2.075, 0.015)
	var helmet_material := StandardMaterial3D.new()
	helmet_material.albedo_color = Color(0.13, 0.23, 0.2)
	helmet_material.metallic = 0.12
	helmet_material.roughness = 0.58
	helmet.material_override = helmet_material
	player_visual_root.add_child(helmet)

	_add_model_box(player_visual_root, "HelmetVisor", Vector3(0.30, 0.065, 0.075), Vector3(0.0, 1.995, -0.19), Color(0.035, 0.065, 0.064), 0.35)
	_add_model_box(player_visual_root, "ChestArmor", Vector3(0.56, 0.61, 0.235), Vector3(0.0, 1.27, -0.14), Color(0.16, 0.28, 0.23), 0.18)
	_add_model_box(player_visual_root, "ChestArmorPlate", Vector3(0.34, 0.23, 0.045), Vector3(0.0, 1.37, -0.27), Color(0.27, 0.38, 0.31), 0.28)
	_add_model_box(player_visual_root, "CombatBelt", Vector3(0.53, 0.105, 0.28), Vector3(0.0, 0.94, -0.015), Color(0.19, 0.17, 0.12), 0.1)
	_add_model_box(player_visual_root, "LeftUtilityPouch", Vector3(0.14, 0.17, 0.105), Vector3(-0.18, 1.12, -0.285), Color(0.35, 0.31, 0.21), 0.04)
	_add_model_box(player_visual_root, "RightUtilityPouch", Vector3(0.14, 0.17, 0.105), Vector3(0.18, 1.12, -0.285), Color(0.35, 0.31, 0.21), 0.04)
	_add_model_box(player_visual_root, "TacticalBackpack", Vector3(0.42, 0.58, 0.23), Vector3(0.0, 1.36, 0.255), Color(0.12, 0.22, 0.19), 0.08)
	_add_model_box(player_visual_root, "BackpackTopFlap", Vector3(0.34, 0.13, 0.25), Vector3(0.0, 1.64, 0.25), Color(0.21, 0.31, 0.24), 0.05)

	left_upper_arm_visual = _add_model_capsule(player_visual_root, "LeftUpperArm", 0.145, 0.66, Vector3(-0.47, 1.28, -0.015), Color(0.12, 0.29, 0.24), Vector3(0.0, 0.0, -12.0))
	right_upper_arm_visual = _add_model_capsule(player_visual_root, "RightUpperArm", 0.145, 0.66, Vector3(0.47, 1.28, -0.015), Color(0.12, 0.29, 0.24), Vector3(0.0, 0.0, 12.0))
	_add_model_capsule(player_visual_root, "LeftForearm", 0.12, 0.43, Vector3(-0.53, 0.91, -0.09), Color(0.23, 0.29, 0.22), Vector3(0.0, 0.0, -9.0))
	_add_model_capsule(player_visual_root, "RightForearm", 0.12, 0.43, Vector3(0.53, 0.91, -0.09), Color(0.23, 0.29, 0.22), Vector3(0.0, 0.0, 9.0))
	_add_model_capsule(player_visual_root, "LeftGlove", 0.105, 0.20, Vector3(-0.55, 0.63, -0.1), Color(0.07, 0.09, 0.08))
	_add_model_capsule(player_visual_root, "RightGlove", 0.105, 0.20, Vector3(0.55, 0.63, -0.1), Color(0.07, 0.09, 0.08))

	_add_model_sphere(player_visual_root, "LeftShoulderPad", Vector3(0.24, 0.19, 0.25), Vector3(-0.44, 1.55, -0.025), Color(0.22, 0.34, 0.27))
	_add_model_sphere(player_visual_root, "RightShoulderPad", Vector3(0.24, 0.19, 0.25), Vector3(0.44, 1.55, -0.025), Color(0.22, 0.34, 0.27))

	left_leg_visual = _add_model_capsule(player_visual_root, "LeftLeg", 0.16, 0.77, Vector3(-0.19, 0.47, 0.025), Color(0.19, 0.23, 0.19))
	right_leg_visual = _add_model_capsule(player_visual_root, "RightLeg", 0.16, 0.77, Vector3(0.19, 0.47, 0.025), Color(0.19, 0.23, 0.19))
	_add_model_box(player_visual_root, "LeftCombatBoot", Vector3(0.25, 0.16, 0.40), Vector3(-0.2, 0.105, -0.055), Color(0.07, 0.085, 0.075), 0.12)
	_add_model_box(player_visual_root, "RightCombatBoot", Vector3(0.25, 0.16, 0.40), Vector3(0.2, 0.105, -0.055), Color(0.07, 0.085, 0.075), 0.12)

	third_person_weapon = Node3D.new()
	third_person_weapon.name = "ThirdPersonWeapon"
	third_person_weapon.position = Vector3(0.44, 1.24, -0.2)
	third_person_weapon.rotation_degrees = Vector3(-3.0, 0.0, 10.0)
	player_visual_root.add_child(third_person_weapon)
	_add_model_box(third_person_weapon, "RifleReceiver", Vector3(0.13, 0.13, 0.46), Vector3(0.0, 0.0, -0.23), Color(0.06, 0.085, 0.08), 0.52)
	_add_model_box(third_person_weapon, "RifleHandguard", Vector3(0.12, 0.11, 0.24), Vector3(0.0, 0.0, -0.49), Color(0.12, 0.15, 0.13), 0.3)
	_add_model_box(third_person_weapon, "RifleStock", Vector3(0.11, 0.105, 0.22), Vector3(0.0, 0.0, 0.09), Color(0.16, 0.19, 0.16), 0.12)
	_add_model_box(third_person_weapon, "RifleMagazine", Vector3(0.095, 0.22, 0.12), Vector3(0.0, -0.14, -0.19), Color(0.1, 0.13, 0.12), 0.44)
	_add_model_box(third_person_weapon, "RifleBarrel", Vector3(0.055, 0.055, 0.28), Vector3(0.0, 0.0, -0.72), Color(0.035, 0.05, 0.048), 0.78)

func _add_model_box(parent: Node3D, part_name: String, dimensions: Vector3, local_position: Vector3, tint: Color, metallic: float = 0.0) -> MeshInstance3D:
	var part := MeshInstance3D.new()
	part.name = part_name
	var part_mesh := BoxMesh.new()
	part_mesh.size = dimensions
	part.mesh = part_mesh
	part.position = local_position
	var part_material := StandardMaterial3D.new()
	part_material.albedo_color = tint
	part_material.metallic = metallic
	part_material.roughness = 0.72
	part.material_override = part_material
	parent.add_child(part)
	return part

func _add_model_capsule(parent: Node3D, part_name: String, radius: float, height: float, local_position: Vector3, tint: Color, part_rotation: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var part := MeshInstance3D.new()
	part.name = part_name
	var part_mesh := CapsuleMesh.new()
	part_mesh.radius = radius
	part_mesh.height = height
	part_mesh.radial_segments = 10
	part_mesh.rings = 4
	part.mesh = part_mesh
	part.position = local_position
	part.rotation_degrees = part_rotation
	var part_material := StandardMaterial3D.new()
	part_material.albedo_color = tint
	part_material.roughness = 0.86
	part.material_override = part_material
	parent.add_child(part)
	return part

func _add_model_sphere(parent: Node3D, part_name: String, dimensions: Vector3, local_position: Vector3, tint: Color) -> MeshInstance3D:
	var part := MeshInstance3D.new()
	part.name = part_name
	var part_mesh := SphereMesh.new()
	part_mesh.radius = 0.5
	part_mesh.height = 1.0
	part_mesh.radial_segments = 12
	part_mesh.rings = 6
	part.mesh = part_mesh
	part.scale = dimensions
	part.position = local_position
	var part_material := StandardMaterial3D.new()
	part_material.albedo_color = tint
	part_material.metallic = 0.08
	part_material.roughness = 0.72
	part.material_override = part_material
	parent.add_child(part)
	return part

func _make_camera_and_weapon() -> void:
	camera_pivot = Node3D.new()
	camera_pivot.name = "CameraPivot"
	camera_pivot.position = Vector3(0.0, 1.55, 0.0)
	add_child(camera_pivot)

	spring_arm = SpringArm3D.new()
	spring_arm.name = "ThirdPersonSpringArm"
	spring_arm.spring_length = 4.2
	spring_arm.margin = 0.18
	spring_arm.collision_mask = 1
	spring_arm.add_excluded_object(get_rid())
	camera_pivot.add_child(spring_arm)

	camera = Camera3D.new()
	camera.name = "PlayerCamera"
	camera.current = true
	camera.fov = 76.0
	spring_arm.add_child(camera)

	weapon = MeshInstance3D.new()
	weapon.name = "PrototypeRifle"
	var weapon_mesh := BoxMesh.new()
	weapon_mesh.size = Vector3(0.16, 0.13, 0.58)
	weapon.mesh = weapon_mesh
	weapon.position = Vector3(0.28, -0.22, -0.55)
	var weapon_material := StandardMaterial3D.new()
	weapon_material.albedo_color = Color(0.095, 0.12, 0.12)
	weapon_material.metallic = 0.45
	weapon_material.roughness = 0.5
	weapon.material_override = weapon_material
	camera.add_child(weapon)
	_apply_weapon_appearance()

	muzzle_flash = MeshInstance3D.new()
	muzzle_flash.name = "MuzzleFlash"
	var flash_mesh := SphereMesh.new()
	flash_mesh.radius = 0.065
	flash_mesh.height = 0.13
	muzzle_flash.mesh = flash_mesh
	muzzle_flash.position = Vector3(0.28, -0.20, -0.90)
	var flash_material := StandardMaterial3D.new()
	flash_material.albedo_color = Color(1.0, 0.72, 0.24)
	flash_material.emission_enabled = true
	flash_material.emission = Color(1.0, 0.48, 0.12)
	flash_material.emission_energy_multiplier = 3.0
	flash_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	muzzle_flash.material_override = flash_material
	muzzle_flash.visible = false
	camera.add_child(muzzle_flash)

func _configure_input() -> void:
	_add_key_action("move_forward", KEY_W)
	_add_key_action("move_back", KEY_S)
	_add_key_action("move_left", KEY_A)
	_add_key_action("move_right", KEY_D)
	_add_key_action("jump", KEY_SPACE)

func _add_key_action(action_name: String, key_code: Key) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	for existing_event in InputMap.action_get_events(action_name):
		if existing_event is InputEventKey and existing_event.physical_keycode == key_code:
			return
	var key_event := InputEventKey.new()
	key_event.physical_keycode = key_code
	InputMap.action_add_event(action_name, key_event)

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	layer.name = "PlayerHUD"
	add_child(layer)

	damage_overlay = ColorRect.new()
	damage_overlay.name = "DamageFlashOverlay"
	damage_overlay.anchor_right = 1.0
	damage_overlay.anchor_bottom = 1.0
	damage_overlay.color = Color(0.65, 0.02, 0.015, 0.0)
	damage_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(damage_overlay)

	health_bar = ProgressBar.new()
	health_bar.name = "PlayerHealthBar"
	health_bar.position = Vector2(22.0, 61.0)
	health_bar.size = Vector2(248.0, 11.0)
	health_bar.min_value = 0.0
	health_bar.max_value = 100.0
	health_bar.value = health
	health_bar.show_percentage = false
	health_bar.tooltip_text = "PLAYER HEALTH"
	var health_background := StyleBoxFlat.new()
	health_background.bg_color = Color(0.025, 0.045, 0.04, 0.92)
	health_background.set_corner_radius_all(4)
	health_bar.add_theme_stylebox_override("background", health_background)
	health_fill_style = StyleBoxFlat.new()
	health_fill_style.bg_color = Color(0.26, 0.78, 0.43)
	health_fill_style.set_corner_radius_all(4)
	health_bar.add_theme_stylebox_override("fill", health_fill_style)
	layer.add_child(health_bar)

	hud_label = Label.new()
	hud_label.position = Vector2(22.0, 82.0)
	hud_label.add_theme_font_size_override("font_size", 17)
	hud_label.add_theme_color_override("font_color", Color(0.9, 0.97, 0.9))
	layer.add_child(hud_label)
	_update_hud()

	hit_marker_label = Label.new()
	hit_marker_label.name = "HitMarker"
	hit_marker_label.text = "×"
	hit_marker_label.anchor_left = 0.5
	hit_marker_label.anchor_right = 0.5
	hit_marker_label.anchor_top = 0.5
	hit_marker_label.anchor_bottom = 0.5
	hit_marker_label.offset_left = -18.0
	hit_marker_label.offset_right = 18.0
	hit_marker_label.offset_top = -24.0
	hit_marker_label.offset_bottom = 24.0
	hit_marker_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hit_marker_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hit_marker_label.add_theme_font_size_override("font_size", 32)
	hit_marker_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.55))
	hit_marker_label.visible = false
	layer.add_child(hit_marker_label)

	if is_mobile:
		joystick_overlay = VirtualJoystickScript.new() as Control
		joystick_overlay.name = "VirtualJoystickOverlay"
		layer.add_child(joystick_overlay)

		var camera_button := _make_button("CAMERA", Vector2(-154, 22), Vector2(130, 44))
		camera_button.pressed.connect(toggle_camera_mode)
		layer.add_child(camera_button)

		var fire_button := _make_button("FIRE", Vector2(-154, 76), Vector2(130, 60))
		fire_button.add_theme_font_size_override("font_size", 22)
		fire_button.pressed.connect(_shoot)
		layer.add_child(fire_button)

		var jump_button := _make_button("JUMP", Vector2(-154, 146), Vector2(130, 46))
		jump_button.pressed.connect(_request_jump)
		layer.add_child(jump_button)

		var reload_button := _make_button("RELOAD", Vector2(-154, 202), Vector2(130, 44))
		reload_button.pressed.connect(_reload)
		layer.add_child(reload_button)

		var heal_button := _make_button("HEAL", Vector2(-154, 258), Vector2(130, 44))
		heal_button.pressed.connect(use_medkit)
		layer.add_child(heal_button)

		mobile_sprint_button = _make_button("SPRINT: OFF", Vector2(-154, 314), Vector2(130, 44))
		mobile_sprint_button.pressed.connect(_toggle_mobile_sprint)
		layer.add_child(mobile_sprint_button)

		mobile_weapon_button = _make_button("RIFLE", Vector2(-154, 370), Vector2(130, 44))
		mobile_weapon_button.pressed.connect(func() -> void: switch_weapon())
		layer.add_child(mobile_weapon_button)

		var loot_button := _make_button("LOOT", Vector2(-154, 426), Vector2(130, 44))
		loot_button.pressed.connect(func() -> void: _try_open_loot_crate())
		layer.add_child(loot_button)

		var hint := Label.new()
		hint.text = "LEFT: MOVE   •   RIGHT: AIM"
		hint.anchor_left = 0.5
		hint.anchor_right = 0.5
		hint.offset_left = -180
		hint.offset_right = 180
		hint.offset_top = 54
		hint.offset_bottom = 82
		hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hint.add_theme_font_size_override("font_size", 13)
		hint.add_theme_color_override("font_color", Color(0.82, 0.88, 0.83, 0.9))
		layer.add_child(hint)

func _make_button(text_value: String, offset: Vector2, button_size: Vector2) -> Button:
	var button := Button.new()
	button.text = text_value
	button.anchor_left = 1.0
	button.anchor_right = 1.0
	button.anchor_top = 0.0
	button.anchor_bottom = 0.0
	button.offset_left = offset.x
	button.offset_right = offset.x + button_size.x
	button.offset_top = offset.y
	button.offset_bottom = offset.y + button_size.y
	button.add_theme_font_size_override("font_size", 16)
	return button

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and not is_mobile and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_apply_look(event.relative, mouse_sensitivity)
	elif event is InputEventMouseButton and not is_mobile and event.pressed:
		if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		elif event.button_index == MOUSE_BUTTON_LEFT:
			_shoot()
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE and not is_mobile:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		elif event.keycode == KEY_V:
			toggle_camera_mode()
		elif event.keycode == KEY_R:
			_reload()
		elif event.keycode == KEY_E:
			_try_open_loot_crate()
		elif event.keycode == KEY_Q or event.keycode == KEY_TAB:
			switch_weapon()
		elif event.keycode >= KEY_1 and event.keycode <= KEY_5:
			switch_weapon(int(event.keycode - KEY_1))
		elif event.keycode == KEY_H:
			use_medkit()
	elif event is InputEventScreenTouch and is_mobile:
		_handle_screen_touch(event)
	elif event is InputEventScreenDrag and is_mobile:
		_handle_screen_drag(event)

func _handle_screen_touch(event: InputEventScreenTouch) -> void:
	var view_size: Vector2 = get_viewport().get_visible_rect().size
	if event.pressed:
		if event.position.x < view_size.x * 0.43 and event.position.y > view_size.y * 0.2 and touch_move_index == -1:
			touch_move_index = event.index
			touch_move_origin = event.position
			touch_move_vector = Vector2.ZERO
			if is_instance_valid(joystick_overlay):
				joystick_overlay.call("begin_drag", event.position)
		else:
			var touching_action_buttons := event.position.x >= view_size.x - 175.0 and event.position.y <= 480.0
			if not touching_action_buttons and event.position.x > view_size.x * 0.46 and event.position.y < view_size.y * 0.82 and touch_look_index == -1:
				touch_look_index = event.index
	else:
		if event.index == touch_move_index:
			touch_move_index = -1
			touch_move_vector = Vector2.ZERO
			if is_instance_valid(joystick_overlay):
				joystick_overlay.call("end_drag")
		if event.index == touch_look_index:
			touch_look_index = -1

func _handle_screen_drag(event: InputEventScreenDrag) -> void:
	if event.index == touch_move_index:
		var drag_vector: Vector2 = (event.position - touch_move_origin) / JOYSTICK_RADIUS
		touch_move_vector = Vector2(drag_vector.x, -drag_vector.y).limit_length(1.0)
		if is_instance_valid(joystick_overlay):
			joystick_overlay.call("update_drag", event.position)
	elif event.index == touch_look_index:
		_apply_look(event.relative, touch_look_sensitivity)

func _apply_look(relative_motion: Vector2, sensitivity: float) -> void:
	rotate_y(-relative_motion.x * sensitivity)
	camera_pitch = clampf(camera_pitch - relative_motion.y * sensitivity, deg_to_rad(-55.0), deg_to_rad(65.0))
	camera_pivot.rotation.x = clampf(camera_pitch + recoil_offset, deg_to_rad(-55.0), deg_to_rad(65.0))

func _physics_process(delta: float) -> void:
	recoil_offset = move_toward(recoil_offset, 0.0, delta * 1.8)
	camera_pivot.rotation.x = clampf(camera_pitch + recoil_offset, deg_to_rad(-55.0), deg_to_rad(65.0))
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	if jump_requested and is_on_floor():
		velocity.y = JUMP_SPEED
	jump_requested = false

	var move_input := touch_move_vector if touch_move_index >= 0 else Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	if move_input.length() > 1.0:
		move_input = move_input.normalized()
	var direction := (global_transform.basis * Vector3(move_input.x, 0.0, move_input.y)).normalized()
	var sprinting := (Input.is_key_pressed(KEY_SHIFT) and not is_mobile) or (is_mobile and mobile_sprint_active)
	var speed := SPRINT_SPEED if sprinting else MOVE_SPEED
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	if Input.is_action_just_pressed("jump"):
		_request_jump()
	move_and_slide()
	_update_character_animation(delta)

func _update_character_animation(_delta: float) -> void:
	if not is_instance_valid(player_visual_root):
		return
	var planar_speed := Vector2(velocity.x, velocity.z).length()
	var gait_weight := clampf(planar_speed / SPRINT_SPEED, 0.0, 1.0)
	var phase := float(Time.get_ticks_msec()) * 0.001 * (5.8 + gait_weight * 3.8)
	var stride := sin(phase) * gait_weight
	player_visual_root.position.y = sin(phase * 2.0) * 0.003 + absf(sin(phase)) * 0.026 * gait_weight
	if is_instance_valid(left_leg_visual):
		left_leg_visual.rotation.x = stride * 0.42
	if is_instance_valid(right_leg_visual):
		right_leg_visual.rotation.x = -stride * 0.42
	if is_instance_valid(left_upper_arm_visual):
		left_upper_arm_visual.rotation.x = -stride * 0.13
	if is_instance_valid(right_upper_arm_visual):
		right_upper_arm_visual.rotation.x = stride * 0.13
	if is_instance_valid(third_person_weapon):
		third_person_weapon.position.y = 1.24 + sin(phase * 2.0) * 0.012 * gait_weight
		third_person_weapon.rotation_degrees.x = -3.0 + stride * 1.2

func toggle_camera_mode() -> void:
	first_person = not first_person
	_update_camera_mode()
	camera_mode_changed.emit(first_person)

func _update_camera_mode() -> void:
	if not is_instance_valid(camera):
		return
	spring_arm.spring_length = 0.0 if first_person else 4.2
	camera.position = Vector3(0.0, 0.0, 0.08) if first_person else Vector3(0.48, 0.0, 0.0)
	camera.fov = 82.0 if first_person else 74.0
	weapon.visible = first_person
	if is_instance_valid(player_visual_root):
		player_visual_root.visible = not first_person

func _toggle_mobile_sprint() -> void:
	mobile_sprint_active = not mobile_sprint_active
	if is_instance_valid(mobile_sprint_button):
		mobile_sprint_button.text = "SPRINT: ON" if mobile_sprint_active else "SPRINT: OFF"

func _weapon_profile() -> Dictionary:
	return WEAPON_PROFILES[current_weapon_index]

func get_current_weapon_name() -> String:
	return str(_weapon_profile().get("name", "RIFLE"))

func switch_weapon(next_index: int = -1) -> void:
	var resolved_index := (current_weapon_index + 1) % WEAPON_PROFILES.size()
	if next_index >= 0:
		resolved_index = clampi(next_index, 0, WEAPON_PROFILES.size() - 1)
	if resolved_index == current_weapon_index:
		return

	weapon_loadouts[get_current_weapon_name()] = {"ammo": ammo, "reserve": reserve_ammo}
	current_weapon_index = resolved_index
	var profile := _weapon_profile()
	var weapon_name := get_current_weapon_name()
	var loadout: Dictionary = weapon_loadouts.get(weapon_name, {})
	ammo = int(loadout.get("ammo", int(profile.get("magazine_size", 30))))
	reserve_ammo = int(loadout.get("reserve", int(profile.get("default_reserve", 120))))
	_apply_weapon_appearance()
	if is_instance_valid(mobile_weapon_button):
		mobile_weapon_button.text = weapon_name
	_update_hud()

func _apply_weapon_appearance() -> void:
	if not is_instance_valid(weapon):
		return
	var profile := _weapon_profile()
	var rifle_mesh := BoxMesh.new()
	rifle_mesh.size = profile.get("mesh_size", Vector3(0.16, 0.13, 0.58))
	weapon.mesh = rifle_mesh
	var weapon_material := StandardMaterial3D.new()
	weapon_material.albedo_color = profile.get("color", Color(0.095, 0.12, 0.12))
	weapon_material.metallic = 0.35
	weapon_material.roughness = 0.52
	weapon.material_override = weapon_material
	weapon.name = str(profile.get("name", "RIFLE")) + "ViewModel"
	weapon.visible = first_person

func _trigger_weapon_feedback(recoil: float) -> void:
	recoil_offset = clampf(recoil_offset - recoil, deg_to_rad(-8.0), 0.0)
	camera_pivot.rotation.x = clampf(camera_pitch + recoil_offset, deg_to_rad(-55.0), deg_to_rad(65.0))
	if is_instance_valid(muzzle_flash):
		muzzle_flash.visible = true
		get_tree().create_timer(0.055).timeout.connect(func() -> void:
			if is_instance_valid(muzzle_flash):
				muzzle_flash.visible = false
		)

func _show_hit_marker() -> void:
	if not is_instance_valid(hit_marker_label):
		return
	hit_marker_label.visible = true
	get_tree().create_timer(0.14).timeout.connect(func() -> void:
		if is_instance_valid(hit_marker_label):
			hit_marker_label.visible = false
		)

func _shoot() -> void:
	if not can_fire or not is_instance_valid(camera):
		return
	if ammo <= 0:
		_reload()
		return

	var profile := _weapon_profile()
	can_fire = false
	ammo -= 1
	weapon_loadouts[get_current_weapon_name()] = {"ammo": ammo, "reserve": reserve_ammo}
	_update_hud()
	_trigger_weapon_feedback(float(profile.get("recoil", 0.012)))
	var fire_delay := float(profile.get("fire_delay", 0.14))
	get_tree().create_timer(fire_delay).timeout.connect(func() -> void: can_fire = true)

	var ray_start: Vector3 = camera.global_position
	var forward: Vector3 = -camera.global_transform.basis.z
	var right: Vector3 = camera.global_transform.basis.x
	var up: Vector3 = camera.global_transform.basis.y
	var pellet_count: int = int(profile.get("pellets", 1))
	var spread: float = float(profile.get("spread", 0.008))
	var shot_range: float = float(profile.get("range", 140.0))
	var damage: float = float(profile.get("damage", 34.0))
	for pellet_index in range(pellet_count):
		var horizontal_spread := randf_range(-spread, spread)
		var vertical_spread := randf_range(-spread, spread)
		var shot_direction := (forward + right * horizontal_spread + up * vertical_spread).normalized()
		var ray_end: Vector3 = ray_start + shot_direction * shot_range
		var query := PhysicsRayQueryParameters3D.create(ray_start, ray_end)
		query.exclude = [get_rid()]
		var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
		var trace_end: Vector3 = ray_end
		if not hit.is_empty():
			var hit_position: Variant = hit.get("position", ray_end)
			if hit_position is Vector3:
				trace_end = hit_position
			var collider: Object = hit.get("collider")
			if is_instance_valid(collider) and collider.has_method("take_damage"):
				collider.call("take_damage", damage)
				_show_hit_marker()
		elif pellet_index == 0:
			trace_end = ray_start + shot_direction * minf(shot_range, 18.0)
		if pellet_index == 0:
			_spawn_bullet_tracer(ray_start, trace_end)

func _spawn_bullet_tracer(from_position: Vector3, to_position: Vector3) -> void:
	var world_parent := get_parent() as Node3D
	if not is_instance_valid(world_parent) or from_position.distance_to(to_position) < 0.2:
		return
	var tracer_material := StandardMaterial3D.new()
	tracer_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	tracer_material.albedo_color = Color(1.0, 0.72, 0.28, 0.92)
	tracer_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	tracer_material.emission_enabled = true
	tracer_material.emission = Color(1.0, 0.48, 0.12)
	tracer_material.emission_energy_multiplier = 2.2

	var tracer_mesh := ImmediateMesh.new()
	tracer_mesh.surface_begin(Mesh.PRIMITIVE_LINES, tracer_material)
	tracer_mesh.surface_add_vertex(world_parent.to_local(from_position))
	tracer_mesh.surface_add_vertex(world_parent.to_local(to_position))
	tracer_mesh.surface_end()

	var tracer := MeshInstance3D.new()
	tracer.name = "BulletTracer"
	tracer.mesh = tracer_mesh
	tracer.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	world_parent.add_child(tracer)
	get_tree().create_timer(0.055).timeout.connect(func() -> void:
		if is_instance_valid(tracer):
			tracer.queue_free()
	)

func _try_open_loot_crate() -> bool:
	var nearest_crate: Node3D
	var nearest_distance: float = 4.0
	for crate_variant in get_tree().get_nodes_in_group("loot_crates"):
		var crate := crate_variant as Node3D
		if not is_instance_valid(crate) or not crate.has_method("open_for"):
			continue
		var distance := global_position.distance_to(crate.global_position)
		if distance <= nearest_distance:
			nearest_distance = distance
			nearest_crate = crate
	if is_instance_valid(nearest_crate):
		return bool(nearest_crate.call("open_for", self))
	return false

func add_loot(item_type: StringName, amount: int) -> bool:
	var pickup_amount: int = maxi(1, amount)
	match item_type:
		&"ammo":
			var reserve_cap: int = int(_weapon_profile().get("reserve_capacity", 240))
			var added_ammo: int = mini(pickup_amount, reserve_cap - reserve_ammo)
			if added_ammo <= 0:
				return false
			reserve_ammo += added_ammo
		&"medkit":
			var added_medkits: int = mini(pickup_amount, 3 - medkits)
			if added_medkits <= 0:
				return false
			medkits += added_medkits
		&"armor":
			var added_armor: int = mini(pickup_amount, 100 - armor)
			if added_armor <= 0:
				return false
			armor += added_armor
		&"weapon_smg":
			return _collect_weapon_ammo(1, pickup_amount)
		&"weapon_shotgun":
			return _collect_weapon_ammo(2, pickup_amount)
		&"weapon_sniper":
			return _collect_weapon_ammo(3, pickup_amount)
		&"weapon_pistol":
			return _collect_weapon_ammo(4, pickup_amount)
		_:
			return false
	_update_hud()
	return true

func _collect_weapon_ammo(weapon_index: int, pickup_amount: int) -> bool:
	if weapon_index < 0 or weapon_index >= WEAPON_PROFILES.size():
		return false
	var profile: Dictionary = WEAPON_PROFILES[weapon_index]
	var weapon_name := str(profile.get("name", "RIFLE"))
	var loadout: Dictionary = weapon_loadouts.get(weapon_name, {})
	var reserve_cap := int(profile.get("reserve_capacity", 120))
	var reserve_before := int(loadout.get("reserve", int(profile.get("default_reserve", 30))))
	var added_ammo := mini(pickup_amount, reserve_cap - reserve_before)
	if added_ammo <= 0:
		return false
	loadout["reserve"] = reserve_before + added_ammo
	if not loadout.has("ammo"):
		loadout["ammo"] = int(profile.get("magazine_size", 12))
	weapon_loadouts[weapon_name] = loadout
	if weapon_index != current_weapon_index:
		switch_weapon(weapon_index)
	else:
		ammo = int(loadout.get("ammo", ammo))
		reserve_ammo = int(loadout["reserve"])
		weapon_loadouts[weapon_name] = {"ammo": ammo, "reserve": reserve_ammo}
		_update_hud()
	return true

func use_medkit() -> void:
	if medkits <= 0 or health >= 100:
		return
	medkits -= 1
	health = mini(100, health + 45)
	_update_hud()

func take_damage(amount: int) -> void:
	if amount <= 0 or lives_remaining <= 0:
		return
	_flash_damage_screen()
	var incoming_damage: int = amount
	var armor_absorbed: int = mini(armor, int(ceil(float(incoming_damage) * 0.6)))
	armor -= armor_absorbed
	incoming_damage -= armor_absorbed
	health = maxi(0, health - incoming_damage)
	if health <= 0:
		lives_remaining -= 1
		armor = 0
		if lives_remaining <= 0:
			health = 0
			player_eliminated.emit()
		else:
			health = 100
			global_position = spawn_position
			velocity = Vector3.ZERO
	_update_hud()

func _reload() -> void:
	var profile := _weapon_profile()
	var magazine_size: int = int(profile.get("magazine_size", 30))
	if ammo >= magazine_size or reserve_ammo <= 0:
		return
	var amount: int = mini(magazine_size - ammo, reserve_ammo)
	ammo += amount
	reserve_ammo -= amount
	weapon_loadouts[get_current_weapon_name()] = {"ammo": ammo, "reserve": reserve_ammo}
	_update_hud()

func _request_jump() -> void:
	if is_on_floor():
		jump_requested = true

func _flash_damage_screen() -> void:
	if not is_instance_valid(damage_overlay):
		return
	if is_instance_valid(damage_flash_tween) and damage_flash_tween.is_running():
		damage_flash_tween.kill()
	damage_overlay.color = Color(0.68, 0.025, 0.015, 0.3)
	damage_flash_tween = create_tween()
	damage_flash_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	damage_flash_tween.tween_property(
		damage_overlay,
		"color",
		Color(0.68, 0.025, 0.015, 0.0),
		0.32
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _update_hud() -> void:
	if is_instance_valid(health_bar):
		health_bar.value = health
		if health <= 35:
			health_fill_style.bg_color = Color(0.94, 0.19, 0.15)
		elif health <= 65:
			health_fill_style.bg_color = Color(0.96, 0.63, 0.2)
		else:
			health_fill_style.bg_color = Color(0.26, 0.78, 0.43)
	if is_instance_valid(hud_label):
		hud_label.text = "HP %d   ARM %d   MED %d\n%s  %d / %d" % [health, armor, medkits, get_current_weapon_name(), ammo, reserve_ammo]
		var text_color := Color(0.9, 0.97, 0.9)
		if health <= 35:
			text_color = Color(1.0, 0.32, 0.25)
		hud_label.add_theme_color_override("font_color", text_color)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT and not is_mobile:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
