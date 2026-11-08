extends Control
## "วิธีเล่น" window shown on the level-select screen after a card is chosen.
## The round starts only when the player presses "เริ่มเกม"; "กลับ" closes the
## window and stays on the picker. Built in code; open() fills it per level.

const Ui := preload("res://scripts/ui_kit.gd")
const GlossyButtonScript := preload("res://scripts/components/glossy_button.gd")
const PaintedRooms := preload("res://data/painted_rooms.gd")

signal start_pressed(level_id: String)
signal closed

const CARD_SIZE := Vector2(1180, 820)
const BUTTON_SIZE := Vector2(340, 100)

var _dim: ColorRect
var _card: PanelContainer
var _title: Label
var _rows: VBoxContainer
var _start: GlossyButtonScript
var _back: GlossyButtonScript
var _level_id := ""


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false

	_dim = ColorRect.new()
	_dim.color = Color(0, 0, 0, 0.55)
	_dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_dim)

	_card = PanelContainer.new()
	_card.custom_minimum_size = CARD_SIZE
	_card.size = CARD_SIZE
	_card.pivot_offset = CARD_SIZE * 0.5
	add_child(_card)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 22)
	_card.add_child(box)

	_title = Ui.title("วิธีเล่น", 64, Ui.INK)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_title)

	_rows = VBoxContainer.new()
	_rows.add_theme_constant_override("separation", 18)
	_rows.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(_rows)

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 40)
	box.add_child(buttons)
	_back = _glossy("กลับ", Color("8C9BAA"), BUTTON_SIZE)
	_back.pressed.connect(_on_back)
	buttons.add_child(_back)
	_start = _glossy("เริ่มเกม", Color("6CC72E"), BUTTON_SIZE)
	_start.pressed.connect(_on_start)
	buttons.add_child(_start)

	get_viewport().size_changed.connect(_center)


func open(lv: Dictionary) -> void:
	_level_id = lv["id"]
	var accent: Color = lv.get("accent", Ui.TEAL)
	var sb := Ui.card(Ui.PAPER, accent, 40, 8)
	sb.set_content_margin_all(44)
	_card.add_theme_stylebox_override("panel", sb)
	_title.text = "วิธีเล่น · ด่าน%s" % lv["name"]
	_title.add_theme_color_override("font_color", accent.darkened(0.4))
	_start.color = accent

	var secs := int(lv.get("time", 120))
	var rooms := _room_count(lv)
	var toxic := _toxic_count(lv)
	# take the old rows out right away: queue_free() alone keeps them in the
	# layout until the end of the frame, so the card measured old + new rows
	# and grew every time the window was reopened
	for c in _rows.get_children():
		_rows.remove_child(c)
		c.queue_free()
	_row(Ui.art("cursor_magnifier.png"), "",
		"สำรวจแต่ละห้อง แล้ว[b]กดที่ของใช้[/b]ที่คิดว่าเป็น[b]สารพิษ[/b]")
	_row(null, "✅",
		"เลือก[b]ถูก[/b] ได้คะแนน · เลือก[b]ผิด[/b] ❌ ถูกหักคะแนน แต่ได้รู้ว่าทำไมของชิ้นนั้นปลอดภัย")
	_row(Ui.art("arrow.png"), "",
		"กด[b]ลูกศรซ้าย–ขวา[/b] เพื่อเดินไปห้องอื่น (ด่านนี้มี %d ห้อง)" % rooms, true)
	_row(null, "⏱",
		"หาสารพิษให้ครบ [b]%d ชิ้น[/b] ภายใน [b]%d:%02d นาที[/b]" % [toxic, int(secs / 60.0), secs % 60])
	_row(null, "💡",
		"อ่านความรู้ที่เด้งขึ้นมาทุกครั้ง ว่าสารพิษนั้นอันตรายอย่างไร ควรเก็บและทิ้งอย่างไร")

	visible = true
	_card.size = CARD_SIZE  # shrink back to the minimum after refilling
	_center()
	_center.call_deferred()
	_card.scale = Vector2(0.85, 0.85)
	_dim.modulate.a = 0.0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_dim, "modulate:a", 1.0, 0.2)
	tw.tween_property(_card, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK)


func _center() -> void:
	_card.reset_size()
	var vp := get_viewport_rect().size
	_card.pivot_offset = _card.size * 0.5
	_card.position = (vp - _card.size) * 0.5


## One instruction line: an icon (texture or emoji) then rich text.
func _row(tex: Texture2D, emoji: String, bbcode: String, flip := false) -> void:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 26)
	_rows.add_child(h)
	if tex:
		var t := TextureRect.new()
		t.texture = tex
		t.custom_minimum_size = Vector2(76, 76)
		t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		t.flip_h = flip
		t.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(t)
	else:
		var e := Ui.title(emoji, 54, Ui.INK)
		e.custom_minimum_size = Vector2(76, 76)
		e.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		e.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		h.add_child(e)
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = true
	r.scroll_active = false
	r.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# a width up front, or fit_content + autowrap measures at width 0 (one glyph per line)
	r.custom_minimum_size.x = CARD_SIZE.x - 88 - 76 - 26
	r.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	r.add_theme_font_override("normal_font", Ui.font(false))
	r.add_theme_font_override("bold_font", Ui.font(true))
	r.add_theme_font_size_override("normal_font_size", 34)
	r.add_theme_font_size_override("bold_font_size", 34)
	r.add_theme_color_override("default_color", Ui.INK)
	r.text = Ui.th(bbcode)
	h.add_child(r)


func _glossy(t: String, c: Color, s: Vector2) -> GlossyButtonScript:
	var b := GlossyButtonScript.new()
	b.custom_minimum_size = s
	b.size = s
	b.font_size = 46
	b.text = t
	b.color = c
	return b


func _room_count(lv: Dictionary) -> int:
	if PaintedRooms.has_level(lv["id"]):
		return PaintedRooms.get_level(lv["id"])["rooms"].size()
	return lv.get("rooms", []).size()


## Toxic hotspots the player will actually have to find (same rule as
## Game.start_level: a hotspot counts only if its id is in the level's list).
func _toxic_count(lv: Dictionary) -> int:
	if not PaintedRooms.has_level(lv["id"]):
		return lv.get("toxic", []).size()
	var n := 0
	for room in PaintedRooms.get_level(lv["id"])["rooms"]:
		for h in room["hotspots"]:
			if h["id"] in lv.get("toxic", []):
				n += 1
	return n


func _on_start() -> void:
	start_pressed.emit(_level_id)


func _on_back() -> void:
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_dim, "modulate:a", 0.0, 0.18)
	tw.tween_property(_card, "scale", Vector2(0.85, 0.85), 0.18)
	tw.chain().tween_callback(func():
		visible = false
		closed.emit()
	)
