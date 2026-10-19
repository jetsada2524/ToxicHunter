extends Control
## Dev helper: boots the real game at a couple of window shapes and saves PNGs of
## attach -> level select (via the real button signal) -> play.
## Run tools/capture_attach.tscn; output goes to tools/screenshots/<WxH>_*.png.

const OUT := "res://tools/screenshots/"
## 16:9 is the design shape; 4:3 is captured to check the letterbox bars.
const SIZES := [
	Vector2i(1920, 1080),  # 16:9 (native)
	Vector2i(1024, 768),   # 4:3 -> black bars top/bottom
]


func _ready() -> void:
	var win := get_window()
	win.mode = Window.MODE_WINDOWED
	for sz in SIZES:
		win.size = sz
		await _settle(10)
		var tag := "%dx%d" % [sz.x, sz.y]
		var main: Node = load("res://scenes/main.tscn").instantiate()
		add_child(main)
		await _settle(30)
		print("[capture] ", tag, " vp=", get_viewport().get_visible_rect().size)
		_shot(tag + "_attach.png")

		main.get("_current").get_node("StartButton").pressed.emit()
		await _settle(20)
		_shot(tag + "_level_select.png")

		var first_card: Node = main.get("_current").get_node("Cards").get_child(0)
		first_card.get_node("%StartButton").pressed.emit()
		await _settle(40)
		_shot(tag + "_play.png")

		Game.playing = false
		main.queue_free()
		await _settle(5)
	get_tree().quit()


func _settle(frames: int) -> void:
	for i in frames:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw


func _shot(file: String) -> void:
	var img := get_viewport().get_texture().get_image()
	var err := img.save_png(ProjectSettings.globalize_path(OUT + file))
	print("[capture] saved ", file, " err=", err)
