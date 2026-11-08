extends Control
## One location card on the level-select screen. Structure lives in
## scenes/components/level_card.tscn; this script only fills it from a
## THLevels entry and tints every layer from the level's accent colour.

const Ui := preload("res://scripts/ui_kit.gd")

const GlossyButtonScript := preload("res://scripts/components/glossy_button.gd")

signal chosen(level_id: String)

const STAR_ON := Color("FFC531")
const STAR_ON_EDGE := Color("B9770E")
const STAR_OFF := Color("C9C9C9")
const STAR_OFF_EDGE := Color("8F8F8F")
const RADIUS := 36

var level_id := ""

@onready var _frame: Panel = $Frame
@onready var _border: Panel = $Border
@onready var _name: Label = %NameLabel
@onready var _stars: HBoxContainer = %Stars
@onready var _thumb: PanelContainer = %Thumb
@onready var _art: TextureRect = %Art
@onready var _info: Label = %InfoLabel
@onready var _subtitle: Label = %SubtitleLabel
@onready var _button: GlossyButtonScript = %StartButton


func setup(lv: Dictionary, open: bool) -> void:
	if not is_node_ready():
		await ready
	level_id = lv["id"]
	var accent: Color = lv.get("accent", Ui.TEAL)

	# frame: accent-tinted glass with a white rim
	var f := StyleBoxFlat.new()
	f.bg_color = accent.lerp(Color.WHITE, 0.62)
	f.set_corner_radius_all(RADIUS)
	f.shadow_color = Color(0.1, 0.2, 0.08, 0.35)
	f.shadow_size = 17
	f.shadow_offset = Vector2(0, 10)
	_frame.add_theme_stylebox_override("panel", f)

	var b := StyleBoxFlat.new()
	b.draw_center = false
	b.set_corner_radius_all(RADIUS)
	b.set_border_width_all(7)
	b.border_color = Color(1, 1, 1, 0.92)
	_border.add_theme_stylebox_override("panel", b)

	# title + stars
	_name.text = lv["name"]
	_name.add_theme_color_override("font_color", accent.darkened(0.45))
	var n := int(lv.get("stars", 1))
	var stars := _stars.get_children()
	for i in stars.size():
		var s := stars[i] as Label
		s.add_theme_color_override("font_color", STAR_ON if i < n else STAR_OFF)
		s.add_theme_color_override("font_outline_color", STAR_ON_EDGE if i < n else STAR_OFF_EDGE)

	# thumbnail
	var t := StyleBoxFlat.new()
	t.bg_color = Color.WHITE
	t.set_corner_radius_all(24)
	t.set_border_width_all(5)
	t.border_color = accent.lightened(0.15)
	t.set_content_margin_all(6)
	_thumb.add_theme_stylebox_override("panel", t)
	_art.texture = Ui.art("ai_room_%s.png" % level_id)

	# stats + subtitle
	var secs := int(lv.get("time", 120))
	_info.text = "🏠 %d ห้อง   ⚠ %d ชิ้น   ⏱ %d:%02d" % [
		lv["rooms"].size(), lv["toxic"].size(), int(secs / 60.0), secs % 60]
	_subtitle.text = lv.get("subtitle", "")

	# start button
	_button.color = accent
	_button.disabled = not open
	_button.text = "เริ่มสืบ" if open else "🔐 ล็อก"
	if not _button.pressed.is_connected(_on_start):
		_button.pressed.connect(_on_start)
	if not open:
		modulate = Color(0.75, 0.75, 0.75)


func _on_start() -> void:
	chosen.emit(level_id)
