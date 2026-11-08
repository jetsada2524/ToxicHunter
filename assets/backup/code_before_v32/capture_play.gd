extends Control
## Dev helper: plays the condo level and saves screenshots of the new gameplay
## UI to tools/screenshots/play_*.png.

const OUT := "res://tools/screenshots/"
var _log: PackedStringArray = []


func _ready() -> void:
	get_window().mode = Window.MODE_WINDOWED
	get_window().size = Vector2i(1600, 900)
	var main: Node = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await _settle(10)
	main.show_play("condo")
	await _settle(30)
	var play: Node = main.get("_current")
	_log.append("rooms=%s start=%s" % [play._room_names, play._room_names[play._room_index]])
	_shot("play_1_living.png")

	# find the two toxic items in the living room
	var picks := 0
	for e in Game.items_in_room("ห้องนั่งเล่น"):
		if e["toxic"]:
			var btn: Button = _button_for(play, e)
			btn.pressed.emit()
			await _settle(50)
			if picks == 0:
				_shot("play_2_reveal.png")
			play._reveal._close()
			await _settle(30)
			picks += 1
	# and one safe item (wrong pick)
	for e in Game.items_in_room("ห้องนั่งเล่น"):
		if not e["toxic"]:
			_button_for(play, e).pressed.emit()
			await _settle(40)
			play._reveal._close()
			await _settle(30)
			break
	await _settle(10)
	_log.append("found=%d/%d score=%d" % [Game.found_toxic.size(), Game.total_toxic(), Game.score])
	_shot("play_3_found.png")

	play._hud.prev_pressed.emit()
	await _settle(10)
	_log.append("after prev: %s" % play._room_names[play._room_index])
	_shot("play_4_bedroom.png")
	for e in Game.items_in_room("ห้องนอน"):
		if e["id"] == "sleeping_pills":
			_button_for(play, e).pressed.emit()
			await _settle(50)
			_shot("play_7_safe_popup.png")
			play._reveal._close()
			await _settle(30)
	_log.append("bedroom items: %s" % [Game.items_in_room("ห้องนอน").map(func(x): return x["id"])])
	play._hud.next_pressed.emit()
	play._hud.next_pressed.emit()
	await _settle(10)
	_log.append("after next x2: %s" % play._room_names[play._room_index])
	_shot("play_5_bathroom.png")

	play._end_round()
	await _settle(40)
	_shot("play_6_summary.png")
	Game.playing = false
	var fa := FileAccess.open(OUT + "play_test.txt", FileAccess.WRITE)
	fa.store_string("\n".join(_log))
	fa.close()
	get_tree().quit()


func _button_for(play: Node, e: Dictionary) -> Button:
	var holder: Control = play._rooms[e["room"]]
	for c in holder.get_children():
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
