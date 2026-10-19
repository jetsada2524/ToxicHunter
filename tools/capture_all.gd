extends Control
## Dev helper: plays every painted level - picks every toxic item (so the
## FOUND panel fills), shoots one toxic + one safe popup, the full FOUND
## panel and the summary. Also logs which picture each item uses.
## Output: tools/screenshots/all_<level>_*.png and all_test.txt

const LEVELS := ["condo", "house", "school", "factory", "farm"]
const OUT := "res://tools/screenshots/"
var _log: PackedStringArray = []


func _ready() -> void:
	get_window().mode = Window.MODE_WINDOWED
	get_window().size = Vector2i(1600, 900)
	var main: Node = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await _settle(10)
	for lv in LEVELS:
		main.show_play(lv)
		await _settle(30)
		var play: Node = main.get("_current")
		var missing := 0
		for e in Game.round_items:
			var ic = e.get("icon")
			var kind := "none"
			if ic is AtlasTexture:
				kind = "CROP"
			elif ic != null:
				kind = "pic"
			if kind != "pic":
				missing += 1
				_log.append("  %s %s/%s -> %s" % [lv, e["room"], e["id"], kind])
		_log.append("%s: %d items, %d toxic, %d without a picture" % [lv, Game.round_items.size(), Game.total_toxic(), missing])
		# one safe pick first (the round ends by itself once every toxic is found)
		for e in Game.round_items:
			if not e["toxic"]:
				play._show_room(play._room_names.find(e["room"]))
				await _settle(3)
				_button_for(play, e).pressed.emit()
				await get_tree().create_timer(1.2).timeout
				await _settle(2)
				_shot("all_%s_reveal_safe.png" % lv)
				play._reveal._close()
				await get_tree().create_timer(0.6).timeout
				await _settle(2)
				break
		var toxics: Array = Game.round_items.filter(func(e): return e["toxic"])
		for i in toxics.size():
			var e: Dictionary = toxics[i]
			play._show_room(play._room_names.find(e["room"]))
			await _settle(3)
			_button_for(play, e).pressed.emit()
			await get_tree().create_timer(1.2).timeout
			await _settle(2)
			if i == 0:
				_shot("all_%s_reveal_toxic.png" % lv)
			if i == toxics.size() - 1:
				_shot("all_%s_found.png" % lv)
				break
			play._reveal._close()
			await get_tree().create_timer(0.6).timeout
			await _settle(2)
		_log.append("%s found %d/%d" % [lv, Game.found_toxic.size(), Game.total_toxic()])
		Game.playing = false
		Game.time_left = 60.0
		main.show_summary()
		await _settle(150)
		_shot("all_%s_summary.png" % lv)
	var fa := FileAccess.open(OUT + "all_test.txt", FileAccess.WRITE)
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
