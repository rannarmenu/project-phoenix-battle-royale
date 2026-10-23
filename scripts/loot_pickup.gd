extends Area3D

@export var item_type: StringName = &"ammo"
@export var amount: int = 30

var pickup_mesh: MeshInstance3D
var label: Label3D
var collected := false

func _ready() -> void:
	name = name if not name.is_empty() else "LootPickup"
	collision_layer = 0
	collision_mask = 1
	monitoring = true
	monitorable = false
	add_to_group("loot_pickups")
	_make_pickup_visual()
	var trigger := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 1.35
	trigger.shape = sphere
	trigger.position.y = 0.75
	add_child(trigger)
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	if is_instance_valid(pickup_mesh):
		pickup_mesh.rotate_y(delta * 1.1)

func _make_pickup_visual() -> void:
	pickup_mesh = MeshInstance3D.new()
	pickup_mesh.name = "PickupVisual"
	var material := StandardMaterial3D.new()
	material.roughness = 0.35
	material.metallic = 0.18
	match item_type:
		&"ammo":
			var ammo_box := BoxMesh.new()
			ammo_box.size = Vector3(0.52, 0.38, 0.38)
			pickup_mesh.mesh = ammo_box
			material.albedo_color = Color(0.92, 0.62, 0.16)
		&"medkit":
			var medkit_box := BoxMesh.new()
			medkit_box.size = Vector3(0.48, 0.48, 0.42)
			pickup_mesh.mesh = medkit_box
			material.albedo_color = Color(0.18, 0.76, 0.43)
		&"armor":
			var cylinder := CylinderMesh.new()
			cylinder.top_radius = 0.30
			cylinder.bottom_radius = 0.36
			cylinder.height = 0.36
			pickup_mesh.mesh = cylinder
			material.albedo_color = Color(0.18, 0.62, 0.98)
		_:
			var fallback_box := BoxMesh.new()
			fallback_box.size = Vector3(0.42, 0.42, 0.42)
			pickup_mesh.mesh = fallback_box
			material.albedo_color = Color(0.8, 0.8, 0.8)
	pickup_mesh.position.y = 0.75
	pickup_mesh.material_override = material
	add_child(pickup_mesh)

	if item_type == &"medkit":
		var cross_material := StandardMaterial3D.new()
		cross_material.albedo_color = Color(1.0, 1.0, 0.92)
		var vertical := MeshInstance3D.new()
		var vertical_mesh := BoxMesh.new()
		vertical_mesh.size = Vector3(0.12, 0.30, 0.055)
		vertical.mesh = vertical_mesh
		vertical.position = Vector3(0.0, 0.75, -0.218)
		vertical.material_override = cross_material
		add_child(vertical)
		var horizontal := MeshInstance3D.new()
		var horizontal_mesh := BoxMesh.new()
		horizontal_mesh.size = Vector3(0.30, 0.12, 0.055)
		horizontal.mesh = horizontal_mesh
		horizontal.position = Vector3(0.0, 0.75, -0.218)
		horizontal.material_override = cross_material
		add_child(horizontal)

	label = Label3D.new()
	label.text = _get_display_name()
	label.position = Vector3(0.0, 1.45, 0.0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 26
	label.pixel_size = 0.007
	label.modulate = Color(0.94, 0.97, 0.94)
	add_child(label)

func _get_display_name() -> String:
	match item_type:
		&"ammo":
			return "AMMO +%d" % amount
		&"medkit":
			return "MEDKIT +%d" % amount
		&"armor":
			return "ARMOR +%d" % amount
	return "SUPPLY"

func _on_body_entered(body: Node3D) -> void:
	collect(body)

func collect(body: Node) -> void:
	if collected or not is_instance_valid(body) or not body.has_method("add_loot"):
		return
	var accepted: bool = body.call("add_loot", item_type, amount)
	if accepted:
		collected = true
		queue_free()
