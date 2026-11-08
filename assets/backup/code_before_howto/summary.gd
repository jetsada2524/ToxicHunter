extends Control
## End-of-round summary (scenes/screens/summary.tscn) on result_bg.png:
##   - speech bubble above the mascot: congratulations, or encouragement
##   - panel: Thai title ribbon, one tile per toxic item (picture + tick when
##     found, question mark when missed - the name is always shown), total
##     score, score breakdown, 0-5 star rating, and the two buttons
##   - confetti only when every toxic item was found

const Ui := preload("res://scripts/ui_kit.gd")
const Items := preload("res://data/items.gd")
const CheckMark := preload("res://scripts/components/check_mark.gd")

signal replay
signal to_menu

const TITLE_WIN := "หาสารพิษครบแล้ว!"
const TITLE_TRY := "หาสารพิษเกือบครบแล้ว!"
const BUBBLE_WIN := "เก่งมากเลย! 🎉\nหาสารพิษเจอครบทุกชิ้น\nคนที่คุณรักปลอดภัยแล้ว!"
const BUBBLE_TRY := "ไม่เป็นไรนะ สู้ ๆ! 💪\nเจอแล้ว %d จาก %d ชิ้น\nลองอีกครั้ง ต้องหาเจอครบแน่!"

## Window art: the title bar, trophy and button icons are painted in.
const BOX_WIN := "result_win_box.png"
const BOX_TRY := "result_not_win_box.png"
## Title text area inside each box (fractions of the box): the win box has the
## trophy on the left of its bar, the red bar has no icon.
const TITLE_AREA_WIN := Rect2(0.27, 0.09, 0.53, 0.135)
const TITLE_AREA_TRY := Rect2(0.15, 0.09, 0.67, 0.135)
## Text inside the painted buttons stays left of the painted icon.
const BUTTON_ICON_ROOM := 0.22
const TILE := Color("F4E3C3")
const TILE_EDGE := Color("E2C996")
const STAR_ON := Color("FFC531")
const STAR_ON_EDGE := Color("B9770E")
const STAR_OFF := Color("E3DCCB")
const STAR_OFF_EDGE := Color("B9B09C")
const SCORE_COLORS := ["E8483F", "F28A2E", "F2C12E", "5DB04F", "3E8EE0", "8E5BD6"]

@onready var _confetti: CPUParticles2D = $Confetti


func _ready() -> void:
    var result := Game.finish()
    var total: int = result["total"]
    var found: int = result["found"].size()
    var won := total > 0 and found >= total

    _style_box(won)
    %TitleLabel.text = TITLE_WIN if won else TITLE_TRY

    %BubbleLabel.text = BUBBLE_WIN if won else BUBBLE_TRY % [found, total]
    _build_items()
    _build_score(result)
    _build_stars(Game.star_rating(result["score"]), result)

    %ReplayButton.pressed.connect(func(): Sfx.play(&"tap"); replay.emit())
    %MenuButton.pressed.connect(func(): Sfx.play(&"tap"); to_menu.emit())

    if won:
        _start_confetti()
    _intro()


# ------------------------------------------------------------------ panel
func _style_box(won: bool) -> void:
    %BoxArt.texture = Ui.art(BOX_WIN if won else BOX_TRY)
    var area: Rect2 = TITLE_AREA_WIN if won else TITLE_AREA_TRY
    var title: Label = %TitleLabel
    title.anchor_left = area.position.x
    title.anchor_top = area.position.y
    title.anchor_right = area.end.x
    title.anchor_bottom = area.end.y
    title.add_theme_color_override("font_outline_color",
        Color("2A5C24") if won else Color("6E1218"))

    # the buttons are painted into the box art: overlay invisible buttons that
    # only lighten on hover / darken on press, with the text left of the icon
    for b in [%ReplayButton, %MenuButton]:
        var w: float = (b.anchor_right - b.anchor_left) * %Box.size.x
        b.add_theme_stylebox_override("normal", _btn_style(Color(0, 0, 0, 0), w))
        b.add_theme_stylebox_override("hover", _btn_style(Color(1, 1, 1, 0.18), w))
        b.add_theme_stylebox_override("pressed", _btn_style(Color(0, 0, 0, 0.12), w))
        b.add_theme_stylebox_override("hover_pressed", _btn_style(Color(0, 0, 0, 0.12), w))
        b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

    var bubble := StyleBoxFlat.new()
    bubble.bg_color = Color.WHITE
    bubble.set_corner_radius_all(44)
    bubble.set_border_width_all(6)
    bubble.border_color = Color("F0A83D")
    bubble.shadow_color = Color(0.1, 0.25, 0.08, 0.25)
    bubble.shadow_size = 10
    bubble.shadow_offset = Vector2(0, 5)
    %BubblePanel.add_theme_stylebox_override("panel", bubble)


func _btn_style(c: Color, w: float) -> StyleBoxFlat:
    var sb := StyleBoxFlat.new()
    sb.bg_color = c
    sb.set_corner_radius_all(48)
    sb.content_margin_right = w * BUTTON_ICON_ROOM
    sb.content_margin_left = 12
    return sb


## One tile per toxic item in the round, in room order.
## Width the item row may use (the cream area of the box, minus padding).
const ITEMS_MAX_WIDTH := 820.0
const ITEM_GAP := 18.0

func _build_items() -> void:
    # shrink the tiles when there are many items so the row stays in the box
    var n := 0
    for e in Game.round_items:
        if e["toxic"]:
            n += 1
    var col_w: float = minf(176.0, (ITEMS_MAX_WIDTH - ITEM_GAP * maxi(n - 1, 0)) / maxi(n, 1))
    var k: float = col_w / 176.0
    var tile_px: float = 112.0 * k
    %Items.add_theme_constant_override("separation", int(ITEM_GAP))
    for e in Game.round_items:
        if not e["toxic"]:
            continue
        var is_found: bool = e.get("found", false)
        var col := VBoxContainer.new()
        col.custom_minimum_size = Vector2(col_w, 0)
        col.add_theme_constant_override("separation", 2)
        %Items.add_child(col)

        var tile := Panel.new()
        tile.custom_minimum_size = Vector2(tile_px, tile_px)
        tile.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
        var sb := StyleBoxFlat.new()
        sb.bg_color = TILE
        sb.set_corner_radius_all(24)
        sb.set_border_width_all(4)
        sb.border_color = Color("8CCB6E") if is_found else TILE_EDGE
        tile.add_theme_stylebox_override("panel", sb)
        col.add_child(tile)

        var pic := TextureRect.new()
        pic.texture = e.get("icon") if is_found and e.get("icon") else Ui.art("question_mask_ui.png")
        pic.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
        var inset := (12 if is_found else 8) * k
        pic.offset_left = inset
        pic.offset_top = inset
        pic.offset_right = -inset
        pic.offset_bottom = -inset
        pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        tile.add_child(pic)
        if is_found:
            var badge := Panel.new()
            var bb := StyleBoxFlat.new()
            bb.bg_color = Color.WHITE
            bb.set_corner_radius_all(int(22 * k))
            badge.add_theme_stylebox_override("panel", bb)
            badge.position = Vector2(tile_px - 36 * k, -14 * k)
            badge.size = Vector2(44, 44) * k
            tile.add_child(badge)
            var tick := CheckMark.new()
            tick.position = Vector2(5, 5) * k
            tick.size = Vector2(34, 34) * k
            badge.add_child(tick)

        var nm := Ui.title(Items.get_item(e["id"]).get("name", e["id"]), int(24 * minf(1.0, k + 0.08)), Ui.INK)
        nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        nm.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        col.add_child(nm)
        var st := Ui.title("ค้นพบแล้ว" if is_found else "ยังหาไม่เจอ", int(20 * minf(1.0, k + 0.08)),
            Ui.GREEN.darkened(0.1) if is_found else Color("9A9384"), false)
        st.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        col.add_child(st)


func _build_score(result: Dictionary) -> void:
    var digits := _with_commas(int(result["score"]))
    var bb := "[center]"
    var i := 0
    for ch in digits:
        if ch == ",":
            bb += "[color=#6B6F75],[/color]"
            continue
        bb += "[color=#%s]%s[/color]" % [SCORE_COLORS[i % SCORE_COLORS.size()], ch]
        i += 1
    bb += " [color=#8E5BD6]คะแนน![/color][/center]"
    %ScoreLabel.text = bb

    var parts := PackedStringArray([
        "คะแนนจากการสืบ %s" % _with_commas(int(result["base"])),
        "โบนัสเวลา +%s" % _with_commas(int(result["time_bonus"])),
    ])
    if result["wrong"].size() > 0:
        parts.append("เลือกผิด %d ครั้ง" % result["wrong"].size())
    %Breakdown.text = "  ·  ".join(parts)


func _build_stars(n: int, result: Dictionary) -> void:
    for i in 5:
        var s := Label.new()
        s.text = "★"
        s.add_theme_font_size_override("font_size", 78)
        s.add_theme_color_override("font_color", STAR_ON if i < n else STAR_OFF)
        s.add_theme_color_override("font_outline_color", STAR_ON_EDGE if i < n else STAR_OFF_EDGE)
        s.add_theme_constant_override("outline_size", 10)
        %Stars.add_child(s)
    %RatingCaption.text = "ระดับนักสืบ: %s  (%d/5 ดาว)" % [result["rank"], n]


func _with_commas(v: int) -> String:
    var s := str(absi(v))
    var out := ""
    while s.length() > 3:
        out = "," + s.substr(s.length() - 3) + out
        s = s.substr(0, s.length() - 3)
    return ("-" if v < 0 else "") + s + out


# ------------------------------------------------------------- animation
func _start_confetti() -> void:
    var img := Image.create(14, 8, false, Image.FORMAT_RGBA8)
    img.fill(Color.WHITE)
    _confetti.texture = ImageTexture.create_from_image(img)
    var g := Gradient.new()
    g.offsets = PackedFloat32Array([0.0, 0.2, 0.4, 0.6, 0.8, 1.0])
    g.colors = PackedColorArray([Color("E8483F"), Color("F2C12E"), Color("5DB04F"),
        Color("3E8EE0"), Color("8E5BD6"), Color("F06EB0")])
    g.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT
    _confetti.color_initial_ramp = g
    _confetti.emitting = true


func _intro() -> void:
    var box: Control = %Box
    box.pivot_offset = box.size * 0.5
    box.scale = Vector2(0.9, 0.9)
    create_tween().tween_property(box, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_BACK)

    var bubble: Control = %Bubble
    bubble.pivot_offset = Vector2(300, 200)
    bubble.scale = Vector2(0.2, 0.2)
    var bt := create_tween()
    bt.tween_interval(0.3)
    bt.tween_property(bubble, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK)

    var i := 0
    for s in %Stars.get_children():
        s.pivot_offset = Vector2(40, 50)
        s.scale = Vector2.ZERO
        var st := create_tween()
        st.tween_interval(0.5 + i * 0.12)
        st.tween_property(s, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK)
        i += 1
