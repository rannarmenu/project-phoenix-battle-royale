extends StaticBody3D

signal eliminated

@export var max_health: float = 100.0
var health: float = 100.0
var body_material: StandardMaterial3D
var health_label: Label3D

func _ready() -> void:
	health = max_health
	collision_layer = 1
	collision_mask = 1

	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.52
	capsule.height = 1.9
	collision.shape = capsule
	collision.position.y = 0.95
	add_child(collision)

	var body_mesh := MeshInstance3D.new()
	var capsule_mesh := CapsuleMesh.new()
	capsule_mesh.radius = 0.5
	capsule_mesh.height = 1.85
	body_mesh.mesh = capsule_mesh
	body_mesh.position.y = 0.95
	body_material = StandardMaterial3D.new()
	body_material.albedo_color = Color(0.86, 0.25, 0.15)
	body_material.roughness = 0.72
	body_mesh.material_override = body_material
	add_child(body_mesh)

	health_label = Label3D.new()
	health_label.text = "TARGET  100"
	health_label.position = Vector3(0.0, 2.25, 0.0)
	health_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	health_label.font_size = 32
	health_label.pixel_size = 0.006
	health_label.modulate = Color(1.0, 0.9, 0.78)
	add_child(health_label)

func take_damage(amount: float) -> void:
	if health <= 0.0:
		return
	health = maxf(0.0, health - amount)
	health_label.text = "TARGET  %d" % int(health)
	body_material.albedo_color = Color(1.0, 0.74, 0.24) if health > 0.0 else Color(0.22, 0.22, 0.22)
	if health <= 0.0:
		eliminated.emit()
		queue_free()
