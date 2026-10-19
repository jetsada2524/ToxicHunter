extends Control
## Dev helper: screenshots the summary screen for a full find (win) and a
## partial find (try again). Output: tools/screenshots/summary_*.png

const LEVEL := "farm"
const OUT := "res://tools/screenshots/"


func _ready() -> void:
	get_window().mode = Window.MODE_WINDOWED
	get_window().size = Vector2i(1600, 900)
	var main: Node = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await _settle(10)

	# win: every toxic item found with time to spare
	main.show_play(LEVEL)
	await _settle(20)
	for e in Game.round_items:
		if e["toxic"]:
			Game.on_pick(e)
	Game.time_left = 70.0
	main.show_summary()
	await _settle(150)
	_shot("summary_win.png")

	# try again: one found, clock ran out
	main.show_play(LEVEL)
	await _settle(20)
	for e in Game.round_items:
		if e["toxic"]:
			Game.on_pick(e)
			break
	Game.time_left = 0.0
	main.show_summary()
	await _settle(150)
	_shot("summary_try.png")
	get_tree().quit()


func _settle(frames: int) -> void:
	for i in frames:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw


func _shot(file: String) -> void:
	get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + file))
