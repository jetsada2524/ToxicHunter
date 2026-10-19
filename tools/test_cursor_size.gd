extends Control
func _ready() -> void:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	var t: Texture2D = main._cursor_tex("cursor_magnifier.png")
	var a: Node = main.get("_current")
	var b: Control = a.get_node("AudioToggles/BgmToggle")
	var fa := FileAccess.open("res://tools/screenshots/cursor_test.txt", FileAccess.WRITE)
	fa.store_string("cursor size=%s  bgm button size=%s pos=%s" % [t.get_size(), b.size, b.global_position])
	fa.close()
	get_tree().quit()
