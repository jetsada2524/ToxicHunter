extends Control
## Dev helper: knowledge popups for items whose names/text had Thai loanwords
## split across lines, plus the summary page. Output: screenshots/th_*.png
const OUT := "res://tools/screenshots/"
const PICKS := [["school", "spray_paint"], ["farm", "bug_spray"], ["factory", "anti_moisture_spray"],
	["farm", "wound_spray"], ["condo", "bleach"], ["factory", "sodium_cyanide"], ["house", "body_scrub"]]

func _ready() -> void:
	get_window().mode = Window.MODE_WINDOWED
	get_window().size = Vector2i(1600, 900)
	var main: Node = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await _settle(10)
	for pk in PICKS:
		main.show_play(pk[0])
		await _settle(20)
		var play: Node = main.get("_current")
		for e in Game.round_items:
			if e["id"] == pk[1]:
				play._show_room(play._room_names.find(e["room"]))
				await _settle(3)
				_button_for(play, e).pressed.emit()
				await get_tree().create_timer(1.2).timeout
				await _settle(2)
				_shot("th_%s.png" % pk[1])
				break
	# summary of the school round with the spray found
	main.show_play("school")
	await _settle(20)
	var play2: Node = main.get("_current")
	for e in Game.round_items:
		if e["toxic"]:
			play2._show_room(play2._room_names.find(e["room"]))
			await _settle(2)
			_button_for(play2, e).pressed.emit()
			await get_tree().create_timer(0.8).timeout
			play2._reveal._close()
			await get_tree().create_timer(0.5).timeout
			if Game.found_toxic.size() >= 3:
				break
	Game.playing = false
	main.show_summary()
	await _settle(150)
	_shot("th_summary_school.png")
	get_tree().quit()

func _button_for(play: Node, e: Dictionary) -> Button:
	for c in play._rooms[e["room"]].get_children():
		if c is Button:
			for conn in c.pressed.get_connections():
				var args: Array = conn["callable"].get_bound_arguments()
				if args.size() > 0 and args[0] is Dictionary and args[0].get("uid", -1) == e["uid"]:
					return c
	return null

func _settle(n: int) -> void:
	for i in n:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw

func _shot(name: String) -> void:
	get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + name))
