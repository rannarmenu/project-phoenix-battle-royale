extends Control

const RADIUS: float = 76.0
const KNOB_RADIUS: float = 25.0

var is_active: bool = false
var base_position: Vector2 = Vector2.ZERO
var knob_offset: Vector2 = Vector2.ZERO

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func begin_drag(screen_position: Vector2) -> void:
	is_active = true
	base_position = screen_position
	knob_offset = Vector2.ZERO
	queue_redraw()

func update_drag(screen_position: Vector2) -> void:
	if not is_active:
		return
	knob_offset = (screen_position - base_position).limit_length(RADIUS)
	queue_redraw()

func end_drag() -> void:
	is_active = false
	knob_offset = Vector2.ZERO
	queue_redraw()

func get_move_vector() -> Vector2:
	return Vector2(knob_offset.x, -knob_offset.y) / RADIUS

func _draw() -> void:
	if not is_active:
		return
	draw_circle(base_position, RADIUS, Color(0.02, 0.06, 0.06, 0.28))
	draw_arc(
		base_position, RADIUS, 0.0, TAU, 48,
		Color(0.78, 0.9, 0.84, 0.78), 3.0, true
	)
	draw_arc(
		base_position, RADIUS * 0.65, 0.0, TAU, 36,
		Color(0.78, 0.9, 0.84, 0.2), 1.5, true
	)
	draw_circle(
		base_position + knob_offset, KNOB_RADIUS,
		Color(0.18, 0.55, 0.4, 0.82)
	)
	draw_arc(
		base_position + knob_offset, KNOB_RADIUS, 0.0, TAU, 32,
		Color(0.88, 0.96, 0.9, 0.9), 2.0, true
	)
