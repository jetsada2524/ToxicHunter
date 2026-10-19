@tool
extends Button
## Neon pill ON/OFF toggle (the "BGM ON" / "SFX ON" buttons): solid colour
## capsule, darker rim with a thicker bottom edge, soft outer glow in the same
## colour, white label with a dark outline. OFF state goes grey with no glow.
## Emits Button's own `toggled(on)` signal.

@export var label := "BGM":
	set(v):
		label = v
		_restyle()
@export var color := Color("D14BC4"):
	set(v):
		color = v
		_restyle()
@export var on := true:
	set(v):
		on = v
		set_pressed_no_signal(v)
		_restyle()

const UiKit := preload("res://scripts/ui_kit.gd")
const OFF_COLOR := Color("8E8A9E")


func _ready() -> void:
	toggle_mode = true
	focus_mode = Control.FOCUS_NONE
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	set_pressed_no_signal(on)
	add_theme_font_override("font", UiKit.font(true))
	if not Engine.is_editor_hint():
		toggled.connect(func(v: bool):
			on = v
			Sfx.play(&"tap"))
		mouse_entered.connect(func(): _bump(1.05))
		mouse_exited.connect(func(): _bump(1.0))
		resized.connect(func(): pivot_offset = size * 0.5)
	_restyle()


func _restyle() -> void:
	if not is_node_ready():
		return
	text = "%s %s" % [label, "ON" if on else "OFF"]
	var c := color if on else OFF_COLOR
	add_theme_stylebox_override("normal", _style(c, on))
	add_theme_stylebox_override("hover", _style(c.lightened(0.12), on))
	add_theme_stylebox_override("pressed", _style(c, on))
	add_theme_stylebox_override("hover_pressed", _style(c.lightened(0.12), on))
	add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	for k in ["font_color", "font_hover_color", "font_pressed_color",
			"font_hover_pressed_color", "font_focus_color"]:
		add_theme_color_override(k, Color.WHITE)
	add_theme_color_override("font_outline_color", c.darkened(0.62))
	add_theme_constant_override("outline_size", 8)


func _style(c: Color, glow: bool) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = c
	sb.set_corner_radius_all(int(maxf(size.y, custom_minimum_size.y) * 0.5) + 2)
	sb.corner_detail = 16
	sb.set_border_width_all(3)
	sb.border_width_bottom = 6
	sb.border_color = c.darkened(0.45)
	sb.content_margin_bottom = 3
	if glow:
		sb.shadow_color = Color(c, 0.55)
		sb.shadow_size = 12
	return sb


func _bump(s: float) -> void:
	create_tween().tween_property(self, "scale", Vector2(s, s), 0.1)
