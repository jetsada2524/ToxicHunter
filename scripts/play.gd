extends Node
## The play screen.
##
## Painted levels (data/painted_rooms.gd, e.g. the condo) show the room art over
## game_play_bg with invisible hotspots on the painted items. Other levels fall
## back to the placeholder 3D room. Both share the same HUD
## (scenes/components/play_hud.tscn), the same reveal card and Game.on_pick.
##
## Rooms are a line, left to right (e.g. ห้องนอน <- ห้องนั่งเล่น -> ห้องน้ำ):
## the arrows walk along it and the plaque under each arrow names the room it
## leads to. Painted levels open on their "start" room.

const Ui := preload("res://scripts/ui_kit.gd")
const Items := preload("res://data/items.gd")
const ItemProp := preload("res://scripts/item_prop.gd")
const RevealCard := preload("res://scripts/reveal_card.gd")
const PaintedRooms := preload("res://data/painted_rooms.gd")
const CheckMark := preload("res://scripts/components/check_mark.gd")
const HudScene := preload("res://scenes/components/play_hud.tscn")

signal round_over
signal quit_to_menu

var _painted: Dictionary = {}
var _rooms: Dictionary = {}         ## room name -> Control (painted) / Node3D (3D)
var _room_names: Array = []
var _room_index := 0
var _busy := false                  ## true while a reveal card is up
var _found_entries: Array = []      ## toxic entries found, in order
var _hud
var _reveal: RevealCard
var _tick_at := 0.0

# 3D fallback only
var _world: Node3D
var _cam_pivot: Node3D
var _cam: Camera3D
var _dragging := false


func _ready() -> void:
    var lid: String = Game.level.get("id", "")
    var start := 0
    if PaintedRooms.has_level(lid):
        _painted = PaintedRooms.get_level(lid)
        _room_names = PaintedRooms.room_names(lid)
        _build_painted()
        start = maxi(0, _room_names.find(_painted.get("start", "")))
    else:
        _room_names = Game.level.get("rooms", ["ห้อง"])
        _build_world()
        _populate_rooms()
    _build_hud()
    _show_room(start)
    Game.score_changed.connect(_hud.set_score)
    _hud.set_score(Game.score)
    _refresh_found()


# ----------------------------------------------------------- painted rooms
func _build_painted() -> void:
    var layer := CanvasLayer.new()
    layer.layer = 0
    add_child(layer)
    var root := Control.new()
    root.set_anchors_preset(Control.PRESET_FULL_RECT)
    root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    layer.add_child(root)

    var bg := TextureRect.new()
    bg.texture = Ui.art(PaintedRooms.BACKGROUND)
    bg.set_anchors_preset(Control.PRESET_FULL_RECT)
    bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
    root.add_child(bg)

    var screen := get_viewport().get_visible_rect().size
    for room in _painted["rooms"]:
        var holder := Control.new()
        holder.set_anchors_preset(Control.PRESET_FULL_RECT)
        holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
        holder.visible = false
        root.add_child(holder)
        _rooms[room["name"]] = holder

        var tex := Ui.art(room["art"])
        if tex == null:
            continue
        # fit the art to the screen; hotspots map onto this rect
        var s := minf(screen.x / tex.get_width(), screen.y / tex.get_height())
        var art_size := tex.get_size() * s
        var art_pos := (screen - art_size) * 0.5
        var art := TextureRect.new()
        art.texture = tex
        art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        art.stretch_mode = TextureRect.STRETCH_SCALE
        art.position = art_pos
        art.size = art_size
        art.mouse_filter = Control.MOUSE_FILTER_IGNORE
        # rooms painted as a cut-away box have a black backdrop around them;
        # a mask (assets/ui/game_play_scene_mask/<scene>.png, white = keep)
        # hides it so game_play_bg.png shows through. The room art itself
        # is never edited.
        var mask := Ui.art("game_play_scene_mask/%s.png" % String(room["art"]).get_file().get_basename())
        if mask:
            var mat := ShaderMaterial.new()
            mat.shader = _mask_shader()
            mat.set_shader_parameter("mask", mask)
            art.material = mat
        holder.add_child(art)
        var extra := Ui.art(room.get("overlay", "")) if room.has("overlay") else null
        if extra:
            var ov := TextureRect.new()
            ov.texture = extra
            ov.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
            ov.stretch_mode = TextureRect.STRETCH_SCALE
            ov.position = art_pos
            ov.size = art_size
            ov.mouse_filter = Control.MOUSE_FILTER_IGNORE
            holder.add_child(ov)

        var seen := {}
        var art_stem: String = String(room["art"]).get_file().get_basename()
        for entry in Game.items_in_room(room["name"]):
            var r: Array = entry["rect"]
            var btn := Button.new()
            btn.flat = true
            btn.focus_mode = Control.FOCUS_NONE
            # plain cursor on purpose: no hover hint, the child has to look
            btn.mouse_default_cursor_shape = Control.CURSOR_ARROW
            for k in ["normal", "hover", "pressed", "focus", "hover_pressed", "disabled"]:
                btn.add_theme_stylebox_override(k, StyleBoxEmpty.new())
            btn.position = art_pos + Vector2(r[0], r[1]) / 100.0 * art_size
            btn.size = Vector2(r[2] - r[0], r[3] - r[1]) / 100.0 * art_size
            btn.pressed.connect(_on_hotspot.bind(entry, btn))
            holder.add_child(btn)
            # item picture (FOUND panel + popup + summary): the icon cut from
            # this room's item sheet (assets/ui/items_icons/<scene>/<id>.png),
            # then the level's old icon folder if one is set, then the generic
            # item_<id>.png, then a cut-out of this object from the room art
            # (assets/ui/room_items/<room>/<id>.png, <id>_2.png for a second
            # one in the same room), then a plain crop of the room art.
            # Hotspot positions: docs/items_position_report.md
            var n: int = seen.get(entry["id"], 0) + 1
            seen[entry["id"]] = n
            var cutout: Texture2D = Ui.art("items_icons/%s/%s.png" % [art_stem, entry["id"]])
            if cutout == null and _painted.has("icons"):
                cutout = Ui.art("%s/%s.png" % [_painted["icons"], entry["id"]])
            if cutout == null:
                cutout = Ui.art("item_%s.png" % entry["id"])
            if cutout == null:
                var cut_name: String = entry["id"] if n == 1 else "%s_%d" % [entry["id"], n]
                cutout = Ui.art("room_items/%s/%s.png" % [art_stem, cut_name])
            entry["icon"] = cutout if cutout else _crop_icon(tex, r)


static var _mask_sh: Shader


func _mask_shader() -> Shader:
    if _mask_sh == null:
        _mask_sh = Shader.new()
        _mask_sh.code = """shader_type canvas_item;
uniform sampler2D mask : filter_linear;
void fragment() {
    vec4 c = texture(TEXTURE, UV);
    c.a *= texture(mask, UV).r;
    COLOR = c;
}
"""
    return _mask_sh


## Square crop around a hotspot - used as the item's picture in the FOUND panel.
func _crop_icon(tex: Texture2D, r: Array) -> Texture2D:
    var ts := tex.get_size()
    var rect := Rect2(Vector2(r[0], r[1]) / 100.0 * ts, Vector2(r[2] - r[0], r[3] - r[1]) / 100.0 * ts)
    var side := maxf(rect.size.x, rect.size.y) * 1.12
    var c := rect.get_center()
    var region := Rect2(c - Vector2(side, side) * 0.5, Vector2(side, side))
    region = region.intersection(Rect2(Vector2.ZERO, ts))
    var at := AtlasTexture.new()
    at.atlas = tex
    at.region = region
    return at


func _on_hotspot(entry: Dictionary, btn: Control) -> void:
    if _busy or not Game.playing or entry.get("inspected", false):
        return
    entry["inspected"] = true
    _busy = true
    var result := Game.on_pick(entry)
    Sfx.play(&"reveal")
    _stamp(btn, result["correct"])
    if result["correct"]:
        _found_entries.append(entry)
        _refresh_found()
    result["icon"] = entry.get("icon")
    await get_tree().create_timer(0.5).timeout
    _reveal.show_result(result)


## Tick (toxic, stays) or cross (safe) stamped onto the clicked object.
func _stamp(btn: Control, correct: bool) -> void:
    var mark: Control
    var sz := clampf(minf(btn.size.x, btn.size.y) * 0.9, 44.0, 70.0)
    if correct:
        mark = CheckMark.new()
    else:
        var x := Label.new()
        x.text = "✕"
        x.add_theme_font_override("font", Ui.font(true))
        x.add_theme_font_size_override("font_size", int(sz))
        x.add_theme_color_override("font_color", Color("E05A4A"))
        x.add_theme_color_override("font_outline_color", Color.WHITE)
        x.add_theme_constant_override("outline_size", 10)
        x.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        x.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        mark = x
    mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
    mark.size = Vector2(sz, sz)
    mark.position = btn.position + Vector2(btn.size.x - sz * 0.6, -sz * 0.35)
    mark.pivot_offset = mark.size * 0.5
    mark.scale = Vector2(0.2, 0.2)
    btn.get_parent().add_child(mark)
    var tw := create_tween()
    tw.tween_property(mark, "scale", Vector2(1.2, 1.2), 0.16).set_trans(Tween.TRANS_BACK)
    tw.tween_property(mark, "scale", Vector2.ONE, 0.1)
    if not correct:
        tw.tween_interval(1.2)
        tw.tween_property(mark, "modulate:a", 0.55, 0.4)


# ------------------------------------------------------------------- world
func _build_world() -> void:
    _world = Node3D.new()
    add_child(_world)

    var env := Environment.new()
    env.background_mode = Environment.BG_COLOR
    env.background_color = Game.level.get("accent", Color("2A3550")).darkened(0.55)
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color("8894B0")
    env.ambient_light_energy = 0.9
    env.glow_enabled = true
    env.glow_intensity = 0.35
    var we := WorldEnvironment.new()
    we.environment = env
    _world.add_child(we)

    var key := DirectionalLight3D.new()
    key.light_energy = 1.9
    key.light_color = Color("FFF3E0")
    key.rotation_degrees = Vector3(-42, 40, 0)
    key.shadow_enabled = true
    _world.add_child(key)

    var fill := DirectionalLight3D.new()
    fill.light_energy = 0.5
    fill.light_color = Color("AFC4FF")
    fill.rotation_degrees = Vector3(-18, -120, 0)
    _world.add_child(fill)

    _cam_pivot = Node3D.new()
    _cam_pivot.position = Vector3(0, 1.1, 0)
    _world.add_child(_cam_pivot)

    _cam = Camera3D.new()
    _cam.position = Vector3(0, 0.4, 6.2)
    _cam.fov = 52.0
    _cam_pivot.add_child(_cam)
    _cam.look_at(_cam_pivot.global_position + Vector3(0, -0.2, 0), Vector3.UP)


## A simple soft room shell: floor, back wall, two side walls, tinted to the
## level. Real Blender rooms drop in later by replacing this node.
func _room_shell(accent: Color) -> Node3D:
    var shell := Node3D.new()

    var floor_mat := StandardMaterial3D.new()
    floor_mat.albedo_color = Color("C9BFA8")
    floor_mat.roughness = 0.9
    var wall_mat := StandardMaterial3D.new()
    wall_mat.albedo_color = accent.lightened(0.35)
    wall_mat.roughness = 0.95

    var floor_mi := MeshInstance3D.new()
    var fm := BoxMesh.new()
    fm.size = Vector3(9, 0.2, 7)
    floor_mi.mesh = fm
    floor_mi.material_override = floor_mat
    floor_mi.position = Vector3(0, -0.1, 0)
    shell.add_child(floor_mi)

    var back := MeshInstance3D.new()
    var bm := BoxMesh.new()
    bm.size = Vector3(9, 4.2, 0.2)
    back.mesh = bm
    back.material_override = wall_mat
    back.position = Vector3(0, 2.0, -3.4)
    shell.add_child(back)

    for sx in [-1, 1]:
        var side := MeshInstance3D.new()
        var sm := BoxMesh.new()
        sm.size = Vector3(0.2, 4.2, 7)
        side.mesh = sm
        side.material_override = wall_mat
        side.position = Vector3(sx * 4.4, 2.0, 0)
        shell.add_child(side)

    # a warm shelf against the back wall to stand props on
    var shelf := MeshInstance3D.new()
    var shm := BoxMesh.new()
    shm.size = Vector3(7.5, 0.18, 1.0)
    shelf.mesh = shm
    var shelf_mat := StandardMaterial3D.new()
    shelf_mat.albedo_color = Color("A6835A")
    shelf.material_override = shelf_mat
    shelf.position = Vector3(0, 1.05, -2.8)
    shell.add_child(shelf)
    return shell


func _populate_rooms() -> void:
    var accent: Color = Game.level.get("accent", Ui.TEAL)
    for rname in _room_names:
        var room := Node3D.new()
        room.visible = false
        room.add_child(_room_shell(accent))
        _world.add_child(room)
        _rooms[rname] = room

        # lay this room's items along the shelf, plus a couple on the floor
        var entries: Array = Game.items_in_room(rname)
        var n := entries.size()
        for i in n:
            var entry: Dictionary = entries[i]
            var prop := ItemProp.new(entry, Items.get_item(entry["id"]))
            prop.picked.connect(_on_item_picked)
            var t := (float(i) + 0.5) / float(maxi(1, n))
            var x := lerpf(-3.2, 3.2, t)
            var on_floor := i % 3 == 2
            prop.position = Vector3(x, 1.28 if not on_floor else 0.35,
                -2.7 if not on_floor else -1.2 + (i % 2) * 0.8)
            room.add_child(prop)


# ------------------------------------------------------------------ rooms
func _show_room(index: int) -> void:
    _room_index = clampi(index, 0, _room_names.size() - 1)
    for rname in _rooms:
        _rooms[rname].visible = (rname == _room_names[_room_index])
    _hud.set_nav(
        _room_names[_room_index - 1] if _room_index > 0 else "",
        _room_names[_room_index + 1] if _room_index < _room_names.size() - 1 else "")


# --------------------------------------------------------------- 3D picking
func _on_item_picked(prop) -> void:
    if _busy or not Game.playing:
        return
    if prop.inspected:
        return
    prop.inspected = true
    _busy = true
    var result := Game.on_pick(prop.entry)
    Sfx.play(&"reveal")
    prop.play_float_spin()
    if result["correct"]:
        prop.entry["icon"] = Ui.art("item_%s.png" % prop.entry["id"])
        _found_entries.append(prop.entry)
        _refresh_found()
    result["icon"] = prop.entry.get("icon", Ui.art("item_%s.png" % prop.entry["id"]))
    await get_tree().create_timer(0.55).timeout
    _reveal.show_result(result)


func _on_reveal_closed() -> void:
    _busy = false
    if Game.found_toxic.size() >= Game.total_toxic() and Game.total_toxic() > 0:
        await get_tree().create_timer(0.4).timeout
        _end_round()


# ------------------------------------------------------------------- hud
func _build_hud() -> void:
    var layer := CanvasLayer.new()
    layer.layer = 1
    add_child(layer)
    _hud = HudScene.instantiate()
    layer.add_child(_hud)
    _hud.prev_pressed.connect(func(): _show_room(_room_index - 1))
    _hud.next_pressed.connect(func(): _show_room(_room_index + 1))
    _hud.quit_pressed.connect(func():
        Game.playing = false
        quit_to_menu.emit())

    # under the full-screen HUD so the card centres on screen
    _reveal = RevealCard.new()
    _reveal.closed.connect(_on_reveal_closed)
    _hud.add_child(_reveal)


func _refresh_found() -> void:
    _hud.set_found(_found_entries.map(func(e): return e.get("icon")), Game.total_toxic())


func _end_round() -> void:
    Game.playing = false
    Sfx.play(&"win")
    round_over.emit()


func _process(_delta: float) -> void:
    if _hud == null:
        return
    var t := int(ceil(Game.time_left))
    var warn := Game.playing and t <= 15
    _hud.set_time(t, warn)
    if warn and Game.time_left - floor(Game.time_left) > 0.5 and Time.get_ticks_msec() - _tick_at > 800:
        _tick_at = Time.get_ticks_msec()
        Sfx.play(&"tick")
    if not Game.playing and Game.time_left <= 0.0 and not _busy:
        set_process(false)
        _end_round()


func _unhandled_input(event: InputEvent) -> void:
    if _cam_pivot == null:
        return
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
        _dragging = event.pressed
    elif event is InputEventMouseMotion and _dragging and not _busy:
        var cfg := Game.config()
        _cam_pivot.rotate_y(-event.relative.x * cfg.CAM_ORBIT_SPEED)
        var rx := clampf(_cam_pivot.rotation.x - event.relative.y * cfg.CAM_ORBIT_SPEED,
            cfg.CAM_MIN_PITCH, cfg.CAM_MAX_PITCH)
        _cam_pivot.rotation.x = rx
