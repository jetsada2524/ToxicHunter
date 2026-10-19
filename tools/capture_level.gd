extends Control
## Dev helper: plays one painted level and saves tools/screenshots/<level>_*.png
## - every room (walking the arrows), a toxic reveal and a safe reveal.
## Change LEVEL to test another level.

const LEVEL := "farm"
const OUT := "res://tools/screenshots/"
var _log: PackedStringArray = []


func _ready() -> void:
	get_window().mode = Window.MODE_WINDOWED
	get_window().size = Vector2i(1600, 900)
	var main: Node = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await _settle(10)
	main.show_play(LEVEL)
	await _settle(30)
	var play: Node = main.get("_current")
	var names: Array = play._room_names
	_log.append("rooms=%s start=%s toxic=%d" % [names, names[play._room_index], Game.total_toxic()])

	# walk to the leftmost room, then shoot every room going right
	for i in names.size():
		play._hud.prev_pressed.emit()
	await _settle(5)
	for i in names.size():
		var room: String = names[play._room_index]
		_log.append("%d %s: %s" % [i, room, Game.items_in_room(room).map(func(e): return e["id"])])
		_shot("%s_room%d.png" % [LEVEL, i])
		play._hud.next_pressed.emit()
		await _settle(5)

	# back to the start room and open one toxic + one safe reveal there
	play._show_room(names.find(play._painted.get("start", "")))
	await _settle(5)
	var room_items: Array = Game.items_in_room(names[play._room_index])
	for want_toxic in [true, false]:
		for e in room_items:
			if e["toxic"] == want_toxic:
				_button_for(play, e).pressed.emit()
				await get_tree().create_timer(1.2).timeout
				await _settle(2)
				_shot("%s_reveal_%s.png" % [LEVEL, "toxic" if want_toxic else "safe"])
				play._reveal._close()
				await _settle(30)
				break
	Game.playing = false
	var fa := FileAccess.open(OUT + LEVEL + "_test.txt", FileAccess.WRITE)
	fa.store_string("\n".join(_log))
	fa.close()
	get_tree().quit()


func _button_for(play: Node, e: Dictionary) -> Button:
	for c in play._rooms[e["room"]].get_children():
		if c is Button:
			for conn in c.pressed.get_connections():
				var args: Array = conn["callable"].get_bound_arguments()
				if args.size() > 0 and args[0] is Dictionary and args[0].get("uid", -1) == e["uid"]:
					return c
	return null


func _settle(frames: int) -> void:
	for i in frames:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw


func _shot(file: String) -> void:
	get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + file))
