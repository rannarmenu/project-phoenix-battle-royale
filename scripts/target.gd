extends CharacterBody3D

signal eliminated

@export var max_health: float = 100.0
@export var move_speed: float = 2.1
@export var attack_damage: int = 7
@export var attack_interval: float = 1.35

const GRAVITY: float = 22.0
const ATTACK_RANGE: float = 10.0
const STOP_RANGE: float = 4.2
const BACK_OFF_RANGE: float = 2.6

var health: float = 100.0
var body_material: StandardMaterial3D
var health_label: Label3D
var attack_cooldown: float = 0.8
var strafe_phase: float = 0.0

func _ready() -> void:
	health = max_health
	strafe_phase = randf_range(0.0, TAU)
	collision_layer = 1
	collision_mask = 1
	add_to_group("enemy_bots")
	_make_body()

func _make_body() -> void:
	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.48
	capsule.height = 1.85
	collision.shape = capsule
	collision.position.y = 0.93
	add_child(collision)

	var body_mesh := MeshInstance3D.new()
	body_mesh.name = "BotBody"
	var capsule_mesh := CapsuleMesh.new()
	capsule_mesh.radius = 0.45
	capsule_mesh.height = 1.8
	body_mesh.mesh = capsule_mesh
	body_mesh.position.y = 0.93
	body_material = StandardMaterial3D.new()
	body_material.albedo_color = Color(0.72, 0.20, 0.14)
	body_material.roughness = 0.78
	body_mesh.material_override = body_material
	add_child(body_mesh)

	var head_mesh_node := MeshInstance3D.new()
	head_mesh_node.name = "BotHead"
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.22
	head_mesh.height = 0.44
	head_mesh_node.mesh = head_mesh
	head_mesh_node.position.y = 1.88
	var head_material := StandardMaterial3D.new()
	head_material.albedo_color = Color(0.22, 0.25, 0.24)
	head_material.metallic = 0.18
	head_material.roughness = 0.64
	head_mesh_node.material_override = head_material
	add_child(head_mesh_node)

	health_label = Label3D.new()
	health_label.text = "BOT  %d HP" % int(health)
	health_label.position = Vector3(0.0, 2.25, 0.0)
	health_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	health_label.font_size = 30
	health_label.pixel_size = 0.006
	health_label.modulate = Color(1.0, 0.9, 0.78)
	add_child(health_label)

func _physics_process(delta: float) -> void:
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	if not is_on_floor():
		velocity.y -= GRAVITY * delta

	var player := get_tree().get_first_node_in_group("player") as Node3D
	if not is_instance_valid(player):
		velocity.x = move_toward(velocity.x, 0.0, move_speed * delta)
		velocity.z = move_toward(velocity.z, 0.0, move_speed * delta)
		move_and_slide()
		return

	var offset: Vector3 = player.global_position - global_position
	offset.y = 0.0
	var distance := offset.length()
	var move_direction := Vector3.ZERO

	if distance > 0.1:
		look_at(Vector3(player.global_position.x, global_position.y, player.global_position.z), Vector3.UP)

	if distance > STOP_RANGE:
		move_direction = offset.normalized()
		var strafe_strength := sin(float(Time.get_ticks_msec()) * 0.001 + strafe_phase) * 0.25
		var strafe := Vector3(-move_direction.z, 0.0, move_direction.x) * strafe_strength
		move_direction = (move_direction + strafe).normalized()
	elif distance < BACK_OFF_RANGE:
		move_direction = -offset.normalized()

	if move_direction.length_squared() > 0.01:
		move_direction = _avoid_obstacles(move_direction)

	velocity.x = move_direction.x * move_speed
	velocity.z = move_direction.z * move_speed
	move_and_slide()

	if distance <= ATTACK_RANGE and attack_cooldown <= 0.0:
		attack_cooldown = attack_interval
		if player.has_method("take_damage"):
			player.call("take_damage", attack_damage)

func _avoid_obstacles(desired_direction: Vector3) -> Vector3:
	var forward := Vector3(desired_direction.x, 0.0, desired_direction.z).normalized()
	if forward.length_squared() < 0.0001:
		return Vector3.ZERO
	var ray_origin := global_position + Vector3.UP * 0.95
	if not _path_blocked(ray_origin, forward, 2.4):
		return forward
	var left := Vector3(-forward.z, 0.0, forward.x)
	var blocked_left := _path_blocked(ray_origin, left, 1.8)
	var blocked_right := _path_blocked(ray_origin, -left, 1.8)
	return _calculate_obstacle_steer(forward, true, blocked_left, blocked_right)

func _path_blocked(ray_origin: Vector3, direction: Vector3, distance: float) -> bool:
	var query := PhysicsRayQueryParameters3D.create(
		ray_origin,
		ray_origin + direction.normalized() * distance
	)
	query.exclude = [get_rid()]
	query.collision_mask = collision_mask
	return not get_world_3d().direct_space_state.intersect_ray(query).is_empty()

func _calculate_obstacle_steer(
	desired_direction: Vector3,
	blocked_ahead: bool,
	blocked_left: bool,
	blocked_right: bool
) -> Vector3:
	var forward := Vector3(desired_direction.x, 0.0, desired_direction.z).normalized()
	if forward.length_squared() < 0.0001:
		return Vector3.ZERO
	if not blocked_ahead:
		return forward
	if blocked_left and blocked_right:
		return -forward

	var prefer_left := sin(strafe_phase) >= 0.0
	if prefer_left and blocked_left:
		prefer_left = false
	elif not prefer_left and blocked_right:
		prefer_left = true
	var side := Vector3(-forward.z, 0.0, forward.x) * (1.0 if prefer_left else -1.0)
	return (forward * 0.18 + side * 0.98).normalized()

func take_damage(amount: float) -> void:
	if health <= 0.0:
		return
	health = maxf(0.0, health - amount)
	if is_instance_valid(health_label):
		health_label.text = "BOT  %d HP" % int(health)
	if is_instance_valid(body_material):
		body_material.albedo_color = Color(1.0, 0.62, 0.18) if health > 0.0 else Color(0.18, 0.18, 0.18)
	if health <= 0.0:
		eliminated.emit()
		queue_free()
