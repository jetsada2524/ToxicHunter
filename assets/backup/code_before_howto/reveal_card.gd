extends Control
## The knowledge card that pops when an item is inspected.
##
## Painted windows (art by the team):
##   correct (toxic)  assets/ui/correct_popup_info.png
##   wrong (safe)     assets/ui/incorrect_popup_info.png
## Layout references: assets/ref/correct_popup_info_ref.png and
## assets/ref/incorrect_popup_info_ref.png.
##
## Everything below is placed in the art's own pixel space (ART_SIZE) and the
## whole card is scaled to fit the screen, so the numbers in L stay valid at
## any resolution. To nudge a text block, edit its rect in L.
##
## Correct (toxic): name, what it is, why it's dangerous, where to store it, how
## to dispose of it, plus the GHS hazard icons - the safety payload of the game.
## Wrong (safe): what it actually is and why it's harmless, phrased kindly so a
## child never feels scolded, just a small score dip.

const Ui := preload("res://scripts/ui_kit.gd")

const ART_OK := "correct_popup_info.png"
const ART_NO := "incorrect_popup_info.png"
const ART_SIZE := Vector2(1346, 1276)
## 0.72 = popup size relative to "fill the screen height" (was 0.6, +20%)
const CARD_SCALE := 0.72

## rects in art pixels: [x, y, w, h]
const L := {
    "title": [372, 72, 616, 112],      # green / red banner
    "badge": [1012, 62, 222, 152],     # yellow / orange score blob
    "pic": [180, 275, 196, 196],       # beige item box (158-398 x 253-495) minus padding
    "name": [430, 262, 520, 230],      # item name, left of the GHS icons
    "ghs_right": 1228,                 # GHS icons line up to this x
    "ghs_y": 377,                      # ... centred on this y
    "ghs_size": 112,
    "rows_x": 298,                     # text column right of the round icons
    "rows_w": 930,
    "rows_y": [582, 718, 854, 990],    # centres of the four painted icons
    "button": [250, 1094, 852, 118],   # bottom capsule
}

const INK := Color("1F2A44")
const BODY := Color("3A4152")
const TIP_SAFE := "สารพิษมักมีป้ายเตือน รูปหัวกะโหลก หรือสัญลักษณ์อันตรายบนฉลาก ลองสังเกตให้ดีก่อนเลือกนะ"
const CARE_SAFE := "ใช้ตามฉลาก และเก็บให้พ้นมือเด็กเล็ก"

signal closed

var _dim: ColorRect
var _card: Control
var _art: TextureRect
var _layer: Control


func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    visible = false

    _dim = ColorRect.new()
    _dim.color = Color(0, 0, 0, 0.5)
    _dim.set_anchors_preset(Control.PRESET_FULL_RECT)
    _dim.mouse_filter = Control.MOUSE_FILTER_STOP
    add_child(_dim)

    _card = Control.new()
    _card.size = ART_SIZE
    _card.pivot_offset = ART_SIZE * 0.5
    _card.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(_card)

    _art = TextureRect.new()
    _art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    _art.stretch_mode = TextureRect.STRETCH_SCALE
    _art.size = ART_SIZE
    _art.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _card.add_child(_art)

    _layer = Control.new()
    _layer.size = ART_SIZE
    _layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _card.add_child(_layer)

    get_viewport().size_changed.connect(_fit_card)


func show_result(result: Dictionary) -> void:
    var correct: bool = result["correct"]
    var d: Dictionary = result["data"]
    var delta: int = result["delta"]
    var accent: Color = Color("2F8F3A") if correct else Color("B8322A")

    _art.texture = Ui.art(ART_OK if correct else ART_NO)
    for c in _layer.get_children():
        c.queue_free()

    # banner title + score badge
    _line("ใช่เลย! สารพิษ" if correct else "เกือบไปแล้ว! ปลอดภัยนะ", L["title"], 66,
        Color.WHITE, accent.darkened(0.35), 12)
    var b: Array = L["badge"]
    var pts := ("+%d" % delta) if delta >= 0 else str(delta)
    var badge_ink := Color("8A4B00") if correct else Color("7A1A12")
    _line(pts, [b[0], b[1] + 6, b[2], 92], 66, Color.WHITE, badge_ink, 12)
    _line("คะแนน", [b[0], b[1] + 94, b[2], 50], 34, Color.WHITE, badge_ink, 9)

    # item picture
    var icon: Texture2D = result.get("icon")
    if icon:
        var p: Array = L["pic"]
        var pic := TextureRect.new()
        # expand_mode before size, or the texture's own size wins
        pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        pic.texture = icon
        pic.position = Vector2(p[0], p[1])
        pic.size = Vector2(p[2], p[3])
        pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
        _layer.add_child(pic)

    # GHS icons, right-aligned; the name gets whatever room is left
    var ghs: Array = d.get("ghs", [])
    var gs: int = L["ghs_size"]
    var gx: float = L["ghs_right"] - gs * ghs.size() - 8 * maxi(ghs.size() - 1, 0)
    for i in ghs.size():
        var ic := TextureRect.new()
        ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        ic.texture = Ui.ghs_texture(ghs[i], 128)
        ic.position = Vector2(gx + i * (gs + 8), L["ghs_y"] - gs * 0.5)
        ic.size = Vector2(gs, gs)
        ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
        _layer.add_child(ic)
    var n: Array = L["name"].duplicate()
    if ghs.size() > 0:
        n[2] = minf(n[2], gx - 16 - n[0])
    _block(d.get("name", "?"), n, 76, 40, INK, true, HORIZONTAL_ALIGNMENT_LEFT)

    # the four rows next to the painted icons
    if correct:
        _row(0, "นี่คืออะไร?", d.get("chemical", ""))
        _row(1, "อันตรายอย่างไร?", d.get("danger", ""))
        _row(2, "ควรเก็บไว้ที่ไหน?", d.get("store", ""))
        _row(3, "ทิ้งอย่างไรให้ปลอดภัย?", d.get("dispose", ""))
    else:
        _row(0, "จริง ๆ แล้วคืออะไร?", d.get("chemical", ""))
        _row(1, "ทำไมไม่ใช่สารพิษ?", d.get("safe", ""))
        var care: String = d.get("care", "")
        _row(2, "ข้อควรระวัง", care if care.strip_edges() != "" else CARE_SAFE)
        _row(3, "เคล็ดลับนักสืบ", TIP_SAFE)

    # bottom capsule = the button
    var r: Array = L["button"]
    var btn := Button.new()
    btn.text = "เข้าใจแล้ว! สืบต่อ"
    btn.position = Vector2(r[0], r[1])
    btn.size = Vector2(r[2], r[3])
    btn.focus_mode = Control.FOCUS_NONE
    btn.add_theme_font_override("font", Ui.font(true))
    btn.add_theme_font_size_override("font_size", 56)
    for k in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
        btn.add_theme_color_override(k, Color.WHITE)
    btn.add_theme_color_override("font_outline_color", accent.darkened(0.35))
    btn.add_theme_constant_override("outline_size", 12)
    var hover := StyleBoxFlat.new()
    hover.bg_color = Color(1, 1, 1, 0.14)
    hover.set_corner_radius_all(56)
    var press := StyleBoxFlat.new()
    press.bg_color = Color(0, 0, 0, 0.12)
    press.set_corner_radius_all(56)
    btn.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
    btn.add_theme_stylebox_override("hover", hover)
    btn.add_theme_stylebox_override("pressed", press)
    btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
    btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
    btn.pressed.connect(_close)
    _layer.add_child(btn)

    # pop in
    if size == Vector2.ZERO:
        size = get_viewport_rect().size
    visible = true
    var s := _fit_card()
    _card.scale = Vector2(s, s) * 0.85
    _dim.modulate.a = 0.0
    var tw := create_tween().set_parallel(true)
    tw.tween_property(_dim, "modulate:a", 1.0, 0.2)
    tw.tween_property(_card, "scale", Vector2(s, s), 0.35).set_trans(Tween.TRANS_BACK)


## Scale + centre the card for the current screen; returns the scale.
func _fit_card() -> float:
    var vp := get_viewport_rect().size
    var s := minf(vp.y * 0.95 / ART_SIZE.y, vp.x * 0.92 / ART_SIZE.x) * CARD_SCALE
    _card.position = (vp - ART_SIZE) * 0.5
    if visible and _card.scale.x > 0.0:
        _card.scale = Vector2(s, s)
    return s


func _row(i: int, label: String, text: String) -> void:
    var cy: float = L["rows_y"][i]
    var x: float = L["rows_x"]
    var w: float = L["rows_w"]
    _line(label, [x, cy - 66, w, 52], 40, INK, Color(0, 0, 0, 0), 0,
        HORIZONTAL_ALIGNMENT_LEFT)
    _block(text, [x, cy - 12, w, 78], 32, 20, BODY, false, HORIZONTAL_ALIGNMENT_LEFT,
        VERTICAL_ALIGNMENT_TOP)


## One line of text, shrunk until it fits the rect's width.
func _line(text: String, r: Array, max_fs: int, col: Color, outline: Color,
        outline_px: int, align := HORIZONTAL_ALIGNMENT_CENTER) -> Label:
    var f := Ui.font(true)
    var fs := max_fs
    while fs > 14 and f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + outline_px > r[2]:
        fs -= 2
    var l := _label(text, r, fs, col, true, align, VERTICAL_ALIGNMENT_CENTER)
    if outline_px > 0:
        l.add_theme_color_override("font_outline_color", outline)
        l.add_theme_constant_override("outline_size", outline_px)
    return l


## Wrapped text, shrunk until every line fits inside the rect.
func _block(text: String, r: Array, max_fs: int, min_fs: int, col: Color, bold: bool,
        align := HORIZONTAL_ALIGNMENT_LEFT, valign := VERTICAL_ALIGNMENT_CENTER) -> Label:
    var f := Ui.font(bold)
    var fs := max_fs
    while fs > min_fs:
        var sz := f.get_multiline_string_size(text, align, r[2], fs, -1,
            TextServer.BREAK_MANDATORY | TextServer.BREAK_WORD_BOUND | TextServer.BREAK_ADAPTIVE)
        if sz.y <= r[3]:
            break
        fs -= 2
    var l := _label(text, r, fs, col, bold, align, valign)
    l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    l.clip_text = true
    return l


func _label(text: String, r: Array, fs: int, col: Color, bold: bool,
        align: HorizontalAlignment, valign: VerticalAlignment) -> Label:
    var l := Label.new()
    l.text = text
    l.position = Vector2(r[0], r[1])
    l.size = Vector2(r[2], r[3])
    l.horizontal_alignment = align
    l.vertical_alignment = valign
    l.add_theme_font_override("font", Ui.font(bold))
    l.add_theme_font_size_override("font_size", fs)
    l.add_theme_color_override("font_color", col)
    l.add_theme_constant_override("line_spacing", -4)
    l.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _layer.add_child(l)
    return l


func _close() -> void:
    Sfx.play(&"tap")
    var s := _card.scale
    var tw := create_tween().set_parallel(true)
    tw.tween_property(_dim, "modulate:a", 0.0, 0.2)
    tw.tween_property(_card, "scale", s * 0.85, 0.2)
    tw.chain().tween_callback(func():
        visible = false
        closed.emit()
    )
