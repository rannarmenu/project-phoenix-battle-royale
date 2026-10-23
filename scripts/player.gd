extends CharacterBody3D

signal camera_mode_changed(first_person: bool)

const MOVE_SPEED := 6.5
const SPRINT_SPEED := 8.5
const JUMP_SPEED := 7.0
const GRAVITY := 22.0
const MOUSE_SENSITIVITY := 0.0022
const TOUCH_LOOK_SENSITIVITY := 0.003
const JOYSTICK_RADIUS := 88.0

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
var health := 100
var spawn_position := Vector3.ZERO
var hud_label: Label

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

	var body := MeshInstance3D.new()
	body.name = "PhoenixPlayerBody"
	var body_mesh := CapsuleMesh.new()
	body_mesh.radius = 0.39
	body_mesh.height = 1.8
	body.mesh = body_mesh
	body.position.y = 0.93
	var body_material := StandardMaterial3D.new()
	body_material.albedo_color = Color(0.09, 0.36, 0.29)
	body_material.roughness = 0.8
	body.material_override = body_material
	add_child(body)

	var head := MeshInstance3D.new()
	head.name = "PhoenixPlayerHead"
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.22
	head_mesh.height = 0.44
	head.mesh = head_mesh
	head.position.y = 1.92
	var head_material := StandardMaterial3D.new()
	head_material.albedo_color = Color(0.72, 0.52, 0.38)
	head.material_override = head_material
	add_child(head)

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

func _configure_input() -> void:
	_add_key_action("move_forward", KEY_W)
	_add_key_action("move_back", KEY_S)
	_add_key_action("move_left", KEY_A)
	_add_key_action("move_right", KEY_D)
	_add_key_action("jump", KEY_SPACE)

func _add_key_action(action_name: String, key_code: Key) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	var key_event := InputEventKey.new()
	key_event.physical_keycode = key_code
	InputMap.action_add_event(action_name, key_event)

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	layer.name = "PlayerHUD"
	add_child(layer)

	hud_label = Label.new()
	hud_label.position = Vector2(22.0, 82.0)
	hud_label.add_theme_font_size_override("font_size", 17)
	hud_label.add_theme_color_override("font_color", Color(0.9, 0.97, 0.9))
	layer.add_child(hud_label)
	_update_hud()

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

	if is_mobile:
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
		_apply_look(event.relative, MOUSE_SENSITIVITY)
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
		else:
			var touching_action_buttons := event.position.x >= view_size.x - 175.0 and event.position.y <= 260.0
			if not touching_action_buttons and event.position.x > view_size.x * 0.46 and event.position.y < view_size.y * 0.82 and touch_look_index == -1:
				touch_look_index = event.index
	else:
		if event.index == touch_move_index:
			touch_move_index = -1
			touch_move_vector = Vector2.ZERO
		if event.index == touch_look_index:
			touch_look_index = -1

func _handle_screen_drag(event: InputEventScreenDrag) -> void:
	if event.index == touch_move_index:
		var drag_vector: Vector2 = (event.position - touch_move_origin) / JOYSTICK_RADIUS
		touch_move_vector = Vector2(drag_vector.x, -drag_vector.y).limit_length(1.0)
	elif event.index == touch_look_index:
		_apply_look(event.relative, TOUCH_LOOK_SENSITIVITY)

func _apply_look(relative_motion: Vector2, sensitivity: float) -> void:
	rotate_y(-relative_motion.x * sensitivity)
	camera_pivot.rotate_x(-relative_motion.y * sensitivity)
	camera_pivot.rotation.x = clampf(camera_pivot.rotation.x, deg_to_rad(-55.0), deg_to_rad(65.0))

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	if jump_requested and is_on_floor():
		velocity.y = JUMP_SPEED
	jump_requested = false

	var move_input := touch_move_vector if touch_move_index >= 0 else Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	if move_input.length() > 1.0:
		move_input = move_input.normalized()
	var direction := (global_transform.basis * Vector3(move_input.x, 0.0, move_input.y)).normalized()
	var speed := SPRINT_SPEED if Input.is_key_pressed(KEY_SHIFT) and not is_mobile else MOVE_SPEED
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	if Input.is_action_just_pressed("jump"):
		_request_jump()
	move_and_slide()

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
	for node in get_children():
		if node is MeshInstance3D and node.name in ["PhoenixPlayerBody", "PhoenixPlayerHead"]:
			node.visible = not first_person

func _shoot() -> void:
	if not can_fire or not is_instance_valid(camera) or ammo <= 0:
		if ammo <= 0:
			_reload()
		return
	can_fire = false
	ammo -= 1
	_update_hud()
	get_tree().create_timer(0.14).timeout.connect(func() -> void: can_fire = true)
	var ray_start: Vector3 = camera.global_position
	var ray_end: Vector3 = ray_start - camera.global_transform.basis.z * 140.0
	var query := PhysicsRayQueryParameters3D.create(ray_start, ray_end)
	query.exclude = [get_rid()]
	var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		var collider: Object = hit.get("collider")
		if is_instance_valid(collider) and collider.has_method("take_damage"):
			collider.call("take_damage", 34.0)

func take_damage(amount: int) -> void:
	health = maxi(0, health - amount)
	if health <= 0:
		health = 100
		global_position = spawn_position
		velocity = Vector3.ZERO
	_update_hud()

func _reload() -> void:
	if ammo >= 30 or reserve_ammo <= 0:
		return
	var amount: int = mini(30 - ammo, reserve_ammo)
	ammo += amount
	reserve_ammo -= amount
	_update_hud()

func _request_jump() -> void:
	if is_on_floor():
		jump_requested = true

func _update_hud() -> void:
	if is_instance_valid(hud_label):
		hud_label.text = "HP %d     AMMO %d / %d" % [health, ammo, reserve_ammo]
		var text_color := Color(0.9, 0.97, 0.9)
		if health <= 35:
			text_color = Color(1.0, 0.32, 0.25)
		hud_label.add_theme_color_override("font_color", text_color)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT and not is_mobile:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
