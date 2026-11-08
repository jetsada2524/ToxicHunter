extends Control
## Dev helper: level select (with back button) + the how-to-play window for
## each level, then checks that Start goes to play and Back goes to attach.
const OUT := "res://tools/screenshots/"
var _log: PackedStringArray = []

func _ready() -> void:
	get_window().mode = Window.MODE_WINDOWED
	get_window().size = Vector2i(1600, 900)
	var main: Node = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await _settle(10)
	main.show_level_select()
	await _settle(20)
	_shot("howto_select.png")
	var sel: Node = main.get("_current")
	var n := 0
	for id in ["condo", "condo", "house", "condo", "farm", "condo"]:
		n += 1
		sel._on_card_chosen(id)
		await get_tree().create_timer(0.6).timeout
		await _settle(3)
		_shot("howto_%d_%s.png" % [n, id])
		_log.append("%s card=%s" % [id, sel._how._card.size])
		for r in sel._how._rows.get_children(): _log.append("   row %s %s" % [r.size, r.get_child(0).size])
		sel._how._back.pressed.emit()
		await get_tree().create_timer(0.4).timeout
		_log.append("%s closed: visible=%s" % [id, sel._how.visible])
	sel._on_card_chosen("condo")
	await _settle(5)
	sel._how._start.pressed.emit()
	await _settle(10)
	_log.append("after start: %s" % main.get("_current").name)
	main.show_level_select()
	await _settle(10)
	main.get("_current").back_pressed.emit()
	await _settle(10)
	_log.append("after back: %s" % main.get("_current").name)
	var f := FileAccess.open(OUT + "howto_test.txt", FileAccess.WRITE)
	f.store_string("\n".join(_log))
	f.close()
	get_tree().quit()

func _settle(n: int) -> void:
	for i in n:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw

func _shot(name: String) -> void:
	get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + name))
