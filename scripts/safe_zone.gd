extends Node3D

@export var start_radius: float = 38.0
@export var final_radius: float = 8.0
@export var shrink_delay: float = 15.0
@export var shrink_duration: float = 180.0
@export var damage_per_second: int = 5

var elapsed_time: float = 0.0
var zone_radius: float = 38.0
var damage_timer: float = 0.0
var ring_visual: MeshInstance3D
var ring_material: StandardMaterial3D

func _ready() -> void:
	zone_radius = start_radius
	_make_zone_visual()
	_update_zone_radius()

func _process(delta: float) -> void:
	elapsed_time += delta
	_update_zone_radius()

func _physics_process(delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if not is_instance_valid(player) or is_position_safe(player.global_position):
		damage_timer = 0.0
		return

	damage_timer += delta
	if damage_timer >= 1.0:
		damage_timer = 0.0
		apply_zone_damage_to(player)

func _make_zone_visual() -> void:
	ring_visual = MeshInstance3D.new()
	ring_visual.name = "SafeZoneBoundary"
	var torus := TorusMesh.new()
	torus.inner_radius = 0.985
	torus.outer_radius = 1.0
	torus.rings = 64
	torus.ring_segments = 6
	ring_visual.mesh = torus
	ring_visual.position.y = 0.08

	ring_material = StandardMaterial3D.new()
	ring_material.albedo_color = Color(0.12, 0.62, 1.0, 0.9)
	ring_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ring_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ring_material.emission_enabled = true
	ring_material.emission = Color(0.08, 0.36, 0.95)
	ring_material.emission_energy_multiplier = 1.2
	ring_visual.material_override = ring_material
	add_child(ring_visual)

func _update_zone_radius() -> void:
	var shrink_time := maxf(0.01, shrink_duration)
	var progress := clampf((elapsed_time - shrink_delay) / shrink_time, 0.0, 1.0)
	zone_radius = lerpf(start_radius, final_radius, progress)
	if is_instance_valid(ring_visual):
		ring_visual.scale = Vector3(zone_radius, 1.0, zone_radius)
	if is_instance_valid(ring_material):
		if elapsed_time >= shrink_delay:
			ring_material.albedo_color = Color(0.22, 0.42, 1.0, 0.92)
		else:
			ring_material.albedo_color = Color(0.12, 0.62, 1.0, 0.82)

func is_position_safe(world_position: Vector3) -> bool:
	var horizontal_distance := Vector2(
		world_position.x - global_position.x,
		world_position.z - global_position.z
	).length()
	return horizontal_distance <= zone_radius

func get_zone_status_for_position(world_position: Vector3) -> String:
	return "SAFE" if is_position_safe(world_position) else "OUTSIDE ZONE"

func get_status_text_for_position(world_position: Vector3) -> String:
	var state := get_zone_status_for_position(world_position)
	var radius_text := "%dm" % int(round(zone_radius))
	if elapsed_time < shrink_delay:
		return "ZONE %s | SHRINK IN %ds | %s" % [
			radius_text, int(ceil(shrink_delay - elapsed_time)), state
		]
	if elapsed_time < shrink_delay + shrink_duration:
		return "ZONE SHRINKING %s | %s" % [radius_text, state]
	return "FINAL ZONE %s | %s" % [radius_text, state]

func apply_zone_damage_to(player: Node) -> void:
	if is_instance_valid(player) and player.has_method("take_damage"):
		player.call("take_damage", damage_per_second)

func get_current_radius() -> float:
	return zone_radius
