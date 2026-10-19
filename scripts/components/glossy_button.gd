@tool
class_name GlossyButton
extends Control
## Bubbly capsule button: outer rim, coloured body with a thick darker bottom
## edge, a glossy highlight strip and outlined white text. All shades derive
## from `color`, so one export re-skins it. Used by the attach screen's big
## green button and the "เริ่มสืบ" buttons on the level cards.
##
## Layers are built as INTERNAL children, so they never show up in (or get
## saved into) the scene tree - the .tscn only stores the exported settings.

signal pressed

@export var text := "ปุ่ม":
	set(v):
		text = v
		_rebuild()
@export var color := Color("6CC72E"):
	set(v):
		color = v
		_rebuild()
@export var font_size := 48:
	set(v):
		font_size = v
		_rebuild()
@export var rim_width := 7:
	set(v):
		rim_width = v
		_rebuild()
@export var rim_color := Color(1, 1, 1, 0.95):
	set(v):
		rim_color = v
		_rebuild()
@export var disabled := false:
	set(v):
		disabled = v
		_rebuild()
## Optional icon file in assets/ui/ shown after the text (e.g. "icon_next.png").
@export var icon_file := "":
	set(v):
		icon_file = v
		_rebuild()
## Gentle idle "breathing" to draw the eye (attract screen).
@export var pulse := false
@export var hover_scale := 1.05

const UiKit := preload("res://scripts/ui_kit.gd")

var _body: Panel
var _btn: Button
var _sb_normal: StyleBoxFlat
var _sb_hover: StyleBoxFlat
var _sb_pressed: StyleBoxFlat
var _hovering := false
var _pulse_tw: Tween


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(_on_resized)
	_rebuild()
	if pulse and not Engine.is_editor_hint():
		_start_pulse()


func _on_resized() -> void:
	pivot_offset = size * 0.5
	_rebuild()


func _rebuild() -> void:
	if not is_node_ready():
		return
	for c in get_children(true):
		if c.get_meta(&"gb_layer", false):
			c.queue_free()

	var h := maxf(size.y, 10.0)
	var radius := int(h * 0.5)
	var r_in := maxi(radius - rim_width, 4)
	var base := color if not disabled else Color("9A9A9A")

	_sb_normal = _body_style(base, r_in)
	_sb_hover = _body_style(base.lightened(0.14), r_in)
	_sb_pressed = _body_style(base.darkened(0.12), r_in)

	# rim
	var rim := _layer(Panel.new(), 0)
	var rim_sb := _pill(rim_color, rim_color.darkened(0.35), radius, 2)
	rim_sb.shadow_color = Color(0.05, 0.12, 0.2, 0.4)
	rim_sb.shadow_size = int(h * 0.09)
	rim_sb.shadow_offset = Vector2(0, h * 0.045)
	rim.add_theme_stylebox_override("panel", rim_sb)

	# body
	_body = _layer(Panel.new(), rim_width) as Panel
	_body.add_theme_stylebox_override("panel", _sb_normal)

	# gloss strip across the top
	var gloss := _layer(Panel.new(), 0)
	gloss.set_anchors_preset(Control.PRESET_TOP_WIDE)
	gloss.offset_left = rim_width + r_in * 0.55
	gloss.offset_right = -rim_width - r_in * 0.55
	gloss.offset_top = rim_width + h * 0.06
	gloss.offset_bottom = rim_width + (h - rim_width * 2) * 0.36
	var g_sb := StyleBoxFlat.new()
	g_sb.bg_color = Color(1, 1, 1, 0.3)
	g_sb.set_corner_radius_all(int(h * 0.3))
	gloss.add_theme_stylebox_override("panel", g_sb)

	# transparent clickable label on top
	_btn = _layer(Button.new(), rim_width) as Button
	_btn.text = text
	_btn.disabled = disabled
	_btn.focus_mode = Control.FOCUS_NONE
	_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var clear := StyleBoxEmpty.new()
	clear.content_margin_bottom = h * 0.07
	for k in ["normal", "hover", "pressed", "focus", "hover_pressed", "disabled"]:
		_btn.add_theme_stylebox_override(k, clear)
	_btn.add_theme_font_override("font", UiKit.font(true))
	_btn.add_theme_font_size_override("font_size", font_size)
	for k in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color",
			"font_hover_pressed_color", "font_disabled_color"]:
		_btn.add_theme_color_override(k, Color.WHITE)
	_btn.add_theme_color_override("font_outline_color", base.darkened(0.55))
	_btn.add_theme_constant_override("outline_size", maxi(5, int(font_size * 0.22)))
	if icon_file != "":
		_btn.icon = UiKit.art(icon_file)
		_btn.icon_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		_btn.add_theme_constant_override("icon_max_width", int(font_size * 1.15))
		_btn.add_theme_constant_override("h_separation", int(font_size * 0.3))

	if Engine.is_editor_hint():
		return
	_btn.mouse_entered.connect(_on_hover.bind(true))
	_btn.mouse_exited.connect(_on_hover.bind(false))
	_btn.button_down.connect(_on_down)
	_btn.button_up.connect(_on_up)
	_btn.pressed.connect(func():
		Sfx.play(&"tap")
		pressed.emit())


func _layer(c: Control, inset: float) -> Control:
	c.set_meta(&"gb_layer", true)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.offset_left = inset
	c.offset_top = inset
	c.offset_right = -inset
	c.offset_bottom = -inset
	add_child(c, false, Node.INTERNAL_MODE_FRONT)
	return c


func _pill(bg: Color, border: Color, radius: int, bw: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(radius)
	sb.set_border_width_all(bw)
	sb.border_color = border
	sb.corner_detail = 16
	return sb


func _body_style(bg: Color, radius: int) -> StyleBoxFlat:
	var sb := _pill(bg, bg.darkened(0.32), radius, 4)
	sb.border_width_bottom = maxi(6, int(size.y * 0.07))
	return sb


func _on_hover(inside: bool) -> void:
	if disabled:
		return
	_hovering = inside
	_body.add_theme_stylebox_override("panel", _sb_hover if inside else _sb_normal)
	if inside:
		Sfx.play(&"hover")
		_scale_to(hover_scale, 0.12)
	elif pulse:
		_start_pulse()
	else:
		_scale_to(1.0, 0.12)


func _on_down() -> void:
	_body.add_theme_stylebox_override("panel", _sb_pressed)
	_scale_to(0.95, 0.06)


func _on_up() -> void:
	_body.add_theme_stylebox_override("panel", _sb_hover if _hovering else _sb_normal)
	_scale_to(hover_scale if _hovering else 1.0, 0.1)


func _start_pulse() -> void:
	if _pulse_tw:
		_pulse_tw.kill()
	scale = Vector2.ONE
	_pulse_tw = create_tween().set_loops()
	_pulse_tw.tween_property(self, "scale", Vector2(1.04, 1.04), 0.8) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_pulse_tw.tween_property(self, "scale", Vector2.ONE, 0.8) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _scale_to(s: float, t: float) -> void:
	if _pulse_tw:
		_pulse_tw.kill()
	create_tween().tween_property(self, "scale", Vector2(s, s), t)
