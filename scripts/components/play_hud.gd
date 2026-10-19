extends Control
## Gameplay HUD (scenes/components/play_hud.tscn):
##   top-left  timer pill        top-right  SCORE pill + star
##   left/right  arrow buttons with a wooden name plaque under each
##   bottom      FOUND panel: one slot per toxic item - "?" until found,
##               then the item picture with a green tick
## play.gd drives it through set_time / set_score / set_nav / set_found.

const Ui := preload("res://scripts/ui_kit.gd")
const CheckMark := preload("res://scripts/components/check_mark.gd")

signal prev_pressed
signal next_pressed
signal quit_pressed

const NAVY := Color("33415E")
const NAVY_EDGE := Color("E9EEF5")
const WOOD := Color("B8783E")
const GOLD := Color("FFC531")
const CREAM := Color("FBF3E3")
const SLOT_BG := Color("F1DDBA")
const SLOT := 100.0
const SLOT_GAP := 20.0
const PANEL_PAD := 36.0

@onready var _time: Label = %TimeLabel
@onready var _score: Label = %ScoreLabel
@onready var _star: Label = %StarLabel
@onready var _prev_nav: Control = %PrevNav
@onready var _next_nav: Control = %NextNav
@onready var _prev_label: Label = %PrevLabel
@onready var _next_label: Label = %NextLabel
@onready var _found_panel: Control = %FoundPanel
@onready var _slots: HBoxContainer = %Slots
@onready var _found_label: RichTextLabel = %FoundLabel

var _shown_found := 0
## how far (px) the room arrows sway toward the room they lead to
const ARROW_SWAY := 12.0
## room names wider than this (px) go onto two lines
const PLAQUE_MAX_W := 250.0
## where to break long room names (add new long names here)
const PLAQUE_SPLIT := {
	"โรงเรือนเก็บวัสดุและสารเคมี": "โรงเรือนเก็บวัสดุ\nและสารเคมี",
	"โรงซ่อมบำรุงเครื่องจักรฟาร์ม": "โรงซ่อมบำรุง\nเครื่องจักรฟาร์ม",
	"โรงเรือนเลี้ยงสัตว์": "โรงเรือน\nเลี้ยงสัตว์",
	"ห้องวิทยาศาสตร์": "ห้อง\nวิทยาศาสตร์",
}


func _ready() -> void:
	var pill := _pill(NAVY, NAVY_EDGE, 34, 4, 0.7)
	%TimerPill.add_theme_stylebox_override("panel", pill)
	%ScorePill.add_theme_stylebox_override("panel", pill)
	%FoundTab.add_theme_stylebox_override("panel", _pill(NAVY, NAVY_EDGE, 34, 4))
	# the "ค้นพบ x/y" tab is hidden on purpose; the slots already show progress
	%FoundTab.visible = false
	var plaque := _pill(NAVY, WOOD, 16, 6)
	plaque.content_margin_left = 22
	plaque.content_margin_right = 22
	%PrevPlaque.add_theme_stylebox_override("panel", plaque)
	%NextPlaque.add_theme_stylebox_override("panel", plaque)
	%FoundInner.add_theme_stylebox_override("panel", _flat(CREAM, 30))
	%FoundFrame.add_theme_stylebox_override("panel", _flat(Color.WHITE, 38))

	for l in [_time, _score, _star, _prev_label, _next_label]:
		l.add_theme_font_override("font", Ui.font(true))
	_found_label.add_theme_font_override("normal_font", Ui.font(true))

	# name plaque sits above its arrow
	%PrevNav.move_child(%PrevPlaque, 0)
	%NextNav.move_child(%NextPlaque, 0)
	var arrow := Ui.art("arrow.png")
	%PrevArrow.texture_normal = arrow
	%NextArrow.texture_normal = arrow
	for b in [%PrevArrow, %NextArrow]:
		b.mouse_entered.connect(_bump.bind(b, 1.08))
		b.mouse_exited.connect(_bump.bind(b, 1.0))
		b.resized.connect(func(): b.pivot_offset = b.size * 0.5)
	%PrevArrow.pressed.connect(func(): Sfx.play(&"tap"); prev_pressed.emit())
	%NextArrow.pressed.connect(func(): Sfx.play(&"tap"); next_pressed.emit())
	_sway_arrow(%PrevArrow, -1.0)
	_sway_arrow(%NextArrow, 1.0)

	var star_tex := Ui.art("icon_star.png")
	if star_tex:
		var star_rect := TextureRect.new()
		star_rect.texture = star_tex
		star_rect.custom_minimum_size = Vector2(49, 49)
		star_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		star_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_star.add_sibling(star_rect)
		_star.visible = false

	# exit button: same pill shape and size as the timer box, bottom-right
	var quit: Button = %QuitButton
	quit.add_theme_font_override("font", Ui.font(true))
	var q := _pill(Color("E05A4A"), NAVY_EDGE, 34, 4, 0.7)
	quit.add_theme_stylebox_override("normal", q)
	quit.add_theme_stylebox_override("hover", _pill(Color("EC6E5E"), NAVY_EDGE, 34, 4, 0.7))
	%TimerPill.resized.connect(_match_quit_to_timer)
	_match_quit_to_timer.call_deferred()
	quit.add_theme_stylebox_override("pressed", q)
	quit.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	quit.pressed.connect(func(): Sfx.play(&"tap"); quit_pressed.emit())


## Nudge an arrow sideways (dir -1 = left, 1 = right) forever so children see
## it can be pressed. The arrow is moved into a plain holder first: inside the
## VBox the container would snap it back, and the name plaque must stay still.
func _sway_arrow(b: Control, dir: float) -> void:
	var nav := b.get_parent()
	var holder := Control.new()
	holder.custom_minimum_size = b.custom_minimum_size
	holder.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	nav.add_child(holder)
	nav.move_child(holder, b.get_index())
	b.reparent(holder, false)
	b.position = Vector2.ZERO
	b.size = b.custom_minimum_size
	var tw := create_tween().set_loops()
	tw.tween_property(b, "position:x", dir * ARROW_SWAY, 0.55) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(b, "position:x", 0.0, 0.55) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _match_quit_to_timer() -> void:
	var quit: Button = %QuitButton
	var sz: Vector2 = %TimerPill.size
	# quit sits in the bottom-right corner (timer pill took the top-left)
	quit.anchor_left = 1.0
	quit.anchor_top = 1.0
	quit.anchor_right = 1.0
	quit.anchor_bottom = 1.0
	quit.offset_left = -18.0 - sz.x
	quit.offset_top = -16.0 - sz.y
	quit.offset_right = -18.0
	quit.offset_bottom = -16.0


# ------------------------------------------------------------------ public
func set_time(seconds: int, warn: bool) -> void:
	_time.text = "%02d:%02d" % [int(seconds / 60.0), seconds % 60]
	_time.add_theme_color_override("font_color", Color("FF6B5B") if warn else Color.WHITE)


func set_score(v: int) -> void:
	_score.text = "คะแนน: %d" % v


## Room names the arrows lead to; "" hides that arrow (end of the line).
func set_nav(prev_room: String, next_room: String) -> void:
	_prev_nav.visible = prev_room != ""
	_next_nav.visible = next_room != ""
	_fit_plaque(_prev_label, prev_room)
	_fit_plaque(_next_label, next_room)


## Long room names go onto two lines so the plaque stays narrow and doesn't
## cover the items near the screen edge. Thai has no spaces, so the split
## point for each long name is listed in PLAQUE_SPLIT; a long name that is not
## listed falls back to wrapping at about half its width.
func _fit_plaque(l: Label, text: String) -> void:
	var f: Font = l.get_theme_font("font")
	var fs: int = l.get_theme_font_size("font_size")
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	l.custom_minimum_size.x = 0
	var w := f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	if w <= PLAQUE_MAX_W:
		l.text = text
	elif PLAQUE_SPLIT.has(text):
		l.text = PLAQUE_SPLIT[text]
	elif text.contains(" "):
		var mid := text.length() / 2
		var k := text.rfind(" ", mid)
		if k < 0:
			k = text.find(" ")
		l.text = text.substr(0, k) + "\n" + text.substr(k + 1)
	else:
		l.text = text
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size.x = ceilf(w * 0.6)


## icons: pictures of the toxic items found so far (in the order found).
func set_found(icons: Array, total: int) -> void:
	_found_label.text = "[center]ค้นพบ [color=#%s]%d/%d[/color][/center]" % [
		GOLD.to_html(false), icons.size(), total]
	for c in _slots.get_children():
		c.queue_free()
	for i in total:
		var slot := _found_slot(icons[i]) if i < icons.size() else _unknown_slot()
		_slots.add_child(slot)
		if i == icons.size() - 1 and icons.size() > _shown_found:
			_pop(slot)
	_shown_found = icons.size()
	var w := total * SLOT + maxf(total - 1, 0) * SLOT_GAP + PANEL_PAD * 2
	_found_panel.offset_left = -w * 0.5
	_found_panel.offset_right = w * 0.5


# ---------------------------------------------------------------- building
func _unknown_slot() -> Control:
	var t := TextureRect.new()
	t.texture = Ui.art("question_mask_ui.png")
	t.custom_minimum_size = Vector2(SLOT, SLOT)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	return t


func _found_slot(icon: Texture2D) -> Control:
	var slot := Control.new()
	slot.custom_minimum_size = Vector2(SLOT, SLOT)
	slot.pivot_offset = Vector2(SLOT, SLOT) * 0.5
	var circle := Panel.new()
	circle.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	circle.set_anchors_preset(Control.PRESET_FULL_RECT)
	circle.add_theme_stylebox_override("panel", _flat(SLOT_BG, int(SLOT * 0.5)))
	slot.add_child(circle)
	if icon:
		var t := TextureRect.new()
		t.texture = icon
		t.set_anchors_preset(Control.PRESET_FULL_RECT)
		t.offset_left = 8
		t.offset_top = 8
		t.offset_right = -8
		t.offset_bottom = -8
		t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		circle.add_child(t)
	var tick := CheckMark.new()
	tick.position = Vector2(SLOT * 0.52, -SLOT * 0.08)
	tick.size = Vector2(SLOT * 0.5, SLOT * 0.5)
	slot.add_child(tick)
	return slot


func _pill(bg: Color, border: Color, radius: int, bw: int, k: float = 1.0) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(radius)
	sb.set_border_width_all(bw)
	sb.border_color = border
	sb.corner_detail = 12
	sb.content_margin_left = 18 * k
	sb.content_margin_right = 28 * k
	sb.content_margin_top = 6 * k
	sb.content_margin_bottom = 8 * k
	sb.shadow_color = Color(0.05, 0.08, 0.14, 0.35)
	sb.shadow_size = int(8 * k)
	sb.shadow_offset = Vector2(0, 4 * k)
	return sb


func _flat(bg: Color, radius: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(radius)
	sb.corner_detail = 12
	return sb


func _pop(c: Control) -> void:
	c.scale = Vector2(0.3, 0.3)
	var tw := create_tween()
	tw.tween_property(c, "scale", Vector2(1.15, 1.15), 0.18).set_trans(Tween.TRANS_BACK)
	tw.tween_property(c, "scale", Vector2.ONE, 0.12)


func _bump(c: Control, s: float) -> void:
	create_tween().tween_property(c, "scale", Vector2(s, s), 0.1)
