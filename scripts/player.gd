extends CharacterBody3D

const MOVE_SPEED: float = 7.0
const JUMP_SPEED: float = 7.2
const GRAVITY: float = 22.0
const MOUSE_SENSITIVITY: float = 0.0022
const TOUCH_LOOK_SENSITIVITY: float = 0.003
const JOYSTICK_RADIUS: float = 92.0

var camera: Camera3D
var touch_move_index: int = -1
var touch_look_index: int = -1
var touch_move_origin: Vector2 = Vector2.ZERO
var touch_move_vector: Vector2 = Vector2.ZERO
var can_fire: bool = true
var jump_requested: bool = false
var is_mobile: bool = false

func _ready() -> void:
	is_mobile = OS.has_feature("android") or OS.has_feature("ios")
	_make_player_body()
	_make_camera_and_weapon()
	_configure_input()
	_build_touch_controls()
	if not is_mobile:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _make_player_body() -> void:
	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.42
	capsule.height = 1.85
	collision.shape = capsule
	collision.position.y = 0.93
	add_child(collision)

func _make_camera_and_weapon() -> void:
	camera = Camera3D.new()
	camera.name = "PlayerCamera"
	camera.position = Vector3(0.0, 1.58, 0.0)
	camera.current = true
	camera.fov = 78.0
	add_child(camera)

	var weapon := MeshInstance3D.new()
	weapon.name = "PrototypeRifle"
	var weapon_mesh := BoxMesh.new()
	weapon_mesh.size = Vector3(0.16, 0.13, 0.52)
	weapon.mesh = weapon_mesh
	weapon.position = Vector3(0.27, -0.22, -0.48)
	var weapon_material := StandardMaterial3D.new()
	weapon_material.albedo_color = Color(0.095, 0.12, 0.12)
	weapon_material.metallic = 0.58
	weapon_material.roughness = 0.45
	weapon.material_override = weapon_material
	camera.add_child(weapon)

func _configure_input() -> void:
	_add_key_action("move_forward", KEY_W)
	_add_key_action("move_back", KEY_S)
	_add_key_action("move_left", KEY_A)
	_add_key_action("move_right", KEY_D)
	_add_key_action("jump", KEY_SPACE)
	if not InputMap.has_action("fire"):
		InputMap.add_action("fire")

func _add_key_action(action_name: String, key_code: Key) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	var key_event := InputEventKey.new()
	key_event.physical_keycode = key_code
	InputMap.action_add_event(action_name, key_event)

func _build_touch_controls() -> void:
	if not is_mobile:
		return
	var layer := CanvasLayer.new()
	layer.name = "TouchControls"
	add_child(layer)

	var fire_button := Button.new()
	fire_button.text = "FIRE"
	fire_button.anchor_left = 1.0
	fire_button.anchor_right = 1.0
	fire_button.anchor_top = 1.0
	fire_button.anchor_bottom = 1.0
	fire_button.offset_left = -154.0
	fire_button.offset_right = -24.0
	fire_button.offset_top = -184.0
	fire_button.offset_bottom = -74.0
	fire_button.add_theme_font_size_override("font_size", 22)
	fire_button.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	fire_button.add_theme_color_override("font_pressed_color", Color(1.0, 0.82, 0.58))
	layer.add_child(fire_button)
	fire_button.pressed.connect(_shoot)

	var jump_button := Button.new()
	jump_button.text = "JUMP"
	jump_button.anchor_left = 1.0
	jump_button.anchor_right = 1.0
	jump_button.anchor_top = 1.0
	jump_button.anchor_bottom = 1.0
	jump_button.offset_left = -286.0
	jump_button.offset_right = -166.0
	jump_button.offset_top = -154.0
	jump_button.offset_bottom = -74.0
	jump_button.add_theme_font_size_override("font_size", 18)
	layer.add_child(jump_button)
	jump_button.pressed.connect(_request_jump)

	var hint := Label.new()
	hint.text = "LEFT SIDE: MOVE   •   DRAG RIGHT SIDE: AIM"
	hint.anchor_left = 0.5
	hint.anchor_right = 0.5
	hint.offset_left = -250.0
	hint.offset_right = 250.0
	hint.offset_top = 58.0
	hint.offset_bottom = 88.0
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 13)
	hint.add_theme_color_override("font_color", Color(0.82, 0.88, 0.83, 0.85))
	layer.add_child(hint)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and not is_mobile:
		_apply_look(event.relative, MOUSE_SENSITIVITY)
	elif event is InputEventMouseButton and not is_mobile:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_shoot()
	elif event is InputEventKey:
		if event.keycode == KEY_ESCAPE and event.pressed and not is_mobile:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	elif event is InputEventScreenTouch and is_mobile:
		_handle_screen_touch(event)
	elif event is InputEventScreenDrag and is_mobile:
		_handle_screen_drag(event)

func _handle_screen_touch(event: InputEventScreenTouch) -> void:
	var view_size: Vector2 = get_viewport().get_visible_rect().size
	if event.pressed:
		if event.position.x < view_size.x * 0.43 and event.position.y > view_size.y * 0.2:
			touch_move_index = event.index
			touch_move_origin = event.position
			touch_move_vector = Vector2.ZERO
		elif event.position.x > view_size.x * 0.46 and event.position.y < view_size.y * 0.72:
			touch_look_index = event.index
	else:
		if event.index == touch_move_index:
			touch_move_index = -1
			touch_move_vector = Vector2.ZERO
		if event.index == touch_look_index:
			touch_look_index = -1

func _handle_screen_drag(event: InputEventScreenDrag) -> void:
	if event.index == touch_move_index:
		touch_move_vector = ((event.position - touch_move_origin) / JOYSTICK_RADIUS).limit_length(1.0)
	elif event.index == touch_look_index:
		_apply_look(event.relative, TOUCH_LOOK_SENSITIVITY)

func _apply_look(relative_motion: Vector2, sensitivity: float) -> void:
	rotate_y(-relative_motion.x * sensitivity)
	camera.rotate_x(-relative_motion.y * sensitivity)
	camera.rotation.x = clampf(camera.rotation.x, deg_to_rad(-82.0), deg_to_rad(82.0))

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	elif jump_requested:
		velocity.y = JUMP_SPEED
	jump_requested = false

	var move_input := touch_move_vector if touch_move_index >= 0 else Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	if move_input.length() > 1.0:
		move_input = move_input.normalized()
	var direction := (global_transform.basis * Vector3(move_input.x, 0.0, move_input.y)).normalized()
	velocity.x = direction.x * MOVE_SPEED
	velocity.z = direction.z * MOVE_SPEED

	if Input.is_action_just_pressed("jump"):
		_request_jump()
	if Input.is_action_just_pressed("fire"):
		_shoot()
	move_and_slide()

func _request_jump() -> void:
	jump_requested = true

func _shoot() -> void:
	if not can_fire or not is_instance_valid(camera):
		return
	can_fire = false
	var timer := get_tree().create_timer(0.16)
	timer.timeout.connect(func() -> void: can_fire = true)

	var ray_start: Vector3 = camera.global_position
	var ray_end: Vector3 = ray_start - camera.global_transform.basis.z * 140.0
	var query := PhysicsRayQueryParameters3D.create(ray_start, ray_end)
	query.exclude = [get_rid()]
	var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		var collider: Object = hit.get("collider")
		if is_instance_valid(collider) and collider.has_method("take_damage"):
			collider.call("take_damage", 34.0)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT and not is_mobile:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
