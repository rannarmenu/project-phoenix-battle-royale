extends Node3D

const LOOT_TABLE: Array[Dictionary] = [
	{"type": &"ammo", "amount": 90},
	{"type": &"medkit", "amount": 1},
	{"type": &"armor", "amount": 45},
	{"type": &"weapon_smg", "amount": 90},
	{"type": &"weapon_shotgun", "amount": 24},
	{"type": &"weapon_sniper", "amount": 10},
	{"type": &"weapon_pistol", "amount": 36}
]

var opened: bool = false
var nearby_player: Node3D
var crate_material: StandardMaterial3D
var lid_material: StandardMaterial3D
var prompt_label: Label3D
var trigger_area: Area3D

func _ready() -> void:
	add_to_group("loot_crates")
	_build_crate_visuals()
	_build_collision()
	_build_trigger()

func _build_crate_visuals() -> void:
	var crate_body := MeshInstance3D.new()
	crate_body.name = "CrateBodyVisual"
	var body_mesh := BoxMesh.new()
	body_mesh.size = Vector3(1.5, 0.82, 1.1)
	crate_body.mesh = body_mesh
	crate_body.position.y = 0.48
	crate_material = StandardMaterial3D.new()
	crate_material.albedo_color = Color(0.16, 0.31, 0.26)
	crate_material.roughness = 0.72
	crate_material.metallic = 0.12
	crate_body.material_override = crate_material
	add_child(crate_body)

	var lid := MeshInstance3D.new()
	lid.name = "CrateLidVisual"
	var lid_mesh := BoxMesh.new()
	lid_mesh.size = Vector3(1.58, 0.18, 1.18)
	lid.mesh = lid_mesh
	lid.position.y = 0.98
	lid_material = StandardMaterial3D.new()
	lid_material.albedo_color = Color(0.78, 0.55, 0.19)
	lid_material.metallic = 0.28
	lid_material.roughness = 0.46
	lid.material_override = lid_material
	add_child(lid)

	for side in [-1.0, 1.0]:
		var strap := MeshInstance3D.new()
		var strap_mesh := BoxMesh.new()
		strap_mesh.size = Vector3(0.12, 0.86, 1.13)
		strap.mesh = strap_mesh
		strap.position = Vector3(side * 0.48, 0.49, 0.0)
		var strap_material := StandardMaterial3D.new()
		strap_material.albedo_color = Color(0.08, 0.12, 0.11)
		strap_material.metallic = 0.35
		strap_material.roughness = 0.55
		strap.material_override = strap_material
		add_child(strap)

	var light := OmniLight3D.new()
	light.name = "LootBeacon"
	light.position.y = 1.55
	light.light_color = Color(1.0, 0.68, 0.24)
	light.light_energy = 0.8
	light.omni_range = 4.0
	add_child(light)

	prompt_label = Label3D.new()
	prompt_label.name = "CratePrompt"
	prompt_label.text = "SUPPLY CRATE"
	prompt_label.position = Vector3(0.0, 1.85, 0.0)
	prompt_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	prompt_label.font_size = 30
	prompt_label.pixel_size = 0.007
	prompt_label.modulate = Color(1.0, 0.88, 0.56)
	add_child(prompt_label)

func _build_collision() -> void:
	var blocker := StaticBody3D.new()
	blocker.name = "CrateCollision"
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.48, 1.0, 1.08)
	collision.shape = shape
	collision.position.y = 0.5
	blocker.add_child(collision)
	add_child(blocker)

func _build_trigger() -> void:
	trigger_area = Area3D.new()
	trigger_area.name = "CrateInteractionArea"
	trigger_area.collision_layer = 0
	trigger_area.collision_mask = 1
	var trigger := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 3.3
	trigger.shape = sphere
	trigger.position.y = 0.8
	trigger_area.add_child(trigger)
	add_child(trigger_area)
	trigger_area.body_entered.connect(_on_body_entered)
	trigger_area.body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node3D) -> void:
	if opened or not body.is_in_group("player"):
		return
	nearby_player = body
	_update_prompt()

func _on_body_exited(body: Node3D) -> void:
	if body == nearby_player:
		nearby_player = null
		_update_prompt()

func _update_prompt() -> void:
	if not is_instance_valid(prompt_label) or opened:
		return
	prompt_label.text = "SUPPLY CRATE\nTAP LOOT / PRESS E" if is_instance_valid(nearby_player) else "SUPPLY CRATE"

func open_for(body: Node) -> bool:
	if opened or not is_instance_valid(body) or not body.has_method("add_loot"):
		return false
	if body is Node3D and (body as Node3D).global_position.distance_to(global_position) > 4.0:
		return false

	var start_index := randi_range(0, LOOT_TABLE.size() - 1)
	for offset in range(LOOT_TABLE.size()):
		var reward: Dictionary = LOOT_TABLE[(start_index + offset) % LOOT_TABLE.size()]
		var item_type := StringName(str(reward.get("type", "ammo")))
		var amount := int(reward.get("amount", 1))
		if bool(body.call("add_loot", item_type, amount)):
			_mark_opened()
			return true
	return false

func _mark_opened() -> void:
	opened = true
	nearby_player = null
	if is_instance_valid(trigger_area):
		trigger_area.monitoring = false
	if is_instance_valid(prompt_label):
		prompt_label.text = "CRATE OPENED"
		prompt_label.modulate = Color(0.72, 0.82, 0.72)
	if is_instance_valid(crate_material):
		crate_material.albedo_color = Color(0.16, 0.19, 0.17)
	if is_instance_valid(lid_material):
		lid_material.albedo_color = Color(0.34, 0.34, 0.29)
