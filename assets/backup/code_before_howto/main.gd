extends Control
## Root orchestrator: owns the screen stack (attach -> level select -> play -> summary)
## and the shared theme. Main is a full-screen Control (scenes/main.tscn), so
## every screen added under it anchors to the whole viewport.
##
## Scene layout:
##   scenes/main.tscn                     root, swaps screens in and out
##   scenes/screens/attach.tscn           title / attract screen
##   scenes/screens/level_select.tscn     location picker
##   scenes/components/level_card.tscn    one card on the picker
##   scripts/components/glossy_button.gd  GlossyButton, shared bubbly button
##   scenes/screens/summary.tscn          end-of-round result
## Play is still built in code (play.gd).

const Ui := preload("res://scripts/ui_kit.gd")
const LevelSelectScene := preload("res://scenes/screens/level_select.tscn")
const PlayScreen := preload("res://scripts/play.gd")
const SummaryScene := preload("res://scenes/screens/summary.tscn")
const AttachScene := preload("res://scenes/screens/attach.tscn")

const Config := preload("res://data/config.gd")

var _current: Node
## Seconds of no input before returning to the attach screen (0 = off).
var idle_timeout_sec: float = Config.IDLE_TIMEOUT_SEC
var _last_input_ms := 0


func _ready() -> void:
    var t := Theme.new()
    t.default_font = Ui.font(false)
    t.default_font_size = 26
    get_window().theme = t
    _set_cursors()
    show_attach()


# ---------------------------------------------------------------- idle timeout
## _input sees every event before the GUI consumes it, so clicks on buttons,
## mouse movement, touches and keys all count as activity.
func _input(event: InputEvent) -> void:
    if event is InputEventMouse or event is InputEventKey \
            or event is InputEventScreenTouch or event is InputEventScreenDrag \
            or event is InputEventJoypadButton:
        _last_input_ms = Time.get_ticks_msec()


func _process(_delta: float) -> void:
    if idle_timeout_sec <= 0.0 or _on_attach():
        return
    if Time.get_ticks_msec() - _last_input_ms >= idle_timeout_sec * 1000.0:
        _on_idle_timeout()


func _on_attach() -> bool:
    return _current != null and is_instance_valid(_current) \
            and _current.scene_file_path == AttachScene.resource_path


## Abandon whatever was happening (stop the round clock) and go back to the
## title screen. Audio prefs live in the Music autoload / settings.cfg, so the
## BGM / SFX toggles come back exactly as the player left them.
func _on_idle_timeout() -> void:
    Game.playing = false
    show_attach()


## F11 flips between fullscreen and a window (handy while developing; the
## game starts fullscreen via project.godot display/window/size/mode).
func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo \
            and event.keycode == KEY_F11:
        var w := get_window()
        w.mode = Window.MODE_WINDOWED if w.mode == Window.MODE_FULLSCREEN \
                or w.mode == Window.MODE_EXCLUSIVE_FULLSCREEN else Window.MODE_FULLSCREEN
        get_viewport().set_input_as_handled()


func _swap(node: Node) -> void:
    if _current and is_instance_valid(_current):
        _current.queue_free()
    _current = node
    add_child(node)
    _last_input_ms = Time.get_ticks_msec()


## Magnifying-glass mouse cursor. Hotspot = centre of the lens, so you "look"
## at what you click. Buttons (pointing-hand shape) get a glowing variant.
## The image is resized to CURSOR_SIZE at startup, so the on-screen size is set
## here no matter what resolution the PNG is.
const CURSOR_SIZE := 45
const CURSOR_HOTSPOT := Vector2(17, 17)   # lens centre at 45 px

func _set_cursors() -> void:
    var normal := _cursor_tex("cursor_magnifier.png")
    var hover := _cursor_tex("cursor_magnifier_hover.png")
    if normal:
        Input.set_custom_mouse_cursor(normal, Input.CURSOR_ARROW, CURSOR_HOTSPOT)
        Input.set_custom_mouse_cursor(hover if hover else normal,
                Input.CURSOR_POINTING_HAND, CURSOR_HOTSPOT)


func _cursor_tex(file: String) -> Texture2D:
    var tex := Ui.art(file)
    if tex == null:
        return null
    var img := tex.get_image()
    if img.is_compressed():
        img.decompress()
    if img.get_width() != CURSOR_SIZE:
        img.resize(CURSOR_SIZE, CURSOR_SIZE, Image.INTERPOLATE_LANCZOS)
    return ImageTexture.create_from_image(img)


func show_attach() -> void:
    var a := AttachScene.instantiate()
    a.start_pressed.connect(func(): show_level_select())
    _swap(a)
    Music.play(&"title")


func show_level_select() -> void:
    var s := LevelSelectScene.instantiate()
    s.level_chosen.connect(func(id: String): show_play(id))
    _swap(s)
    Music.play(&"title")


func show_play(level_id: String) -> void:
    Game.start_level(level_id)
    var p := PlayScreen.new()
    p.round_over.connect(func(): show_summary())
    p.quit_to_menu.connect(func(): show_level_select())
    _swap(p)
    Music.play(&"gameplay")


func show_summary() -> void:
    var s := SummaryScene.instantiate()
    s.replay.connect(func(): show_play(Game.level["id"]))
    s.to_menu.connect(func(): show_level_select())
    _swap(s)
    Music.play(&"result")
