extends Control
## Dev helper: every room as the game shows it, with each live hotspot outlined
## (red = toxic, green = safe) and labelled. Also checks that the texture the
## game loaded matches the source image on disk (stale import -> "STALE").
## Output: tools/screenshots/rooms_<level>_<n>.png and rooms_test.txt
const LEVELS := ["condo", "house", "school", "factory", "farm"]
const OUT := "res://tools/screenshots/"
const PaintedRooms := preload("res://data/painted_rooms.gd")
var _log: PackedStringArray = []

func _ready() -> void:
	get_window().mode = Window.MODE_WINDOWED
	get_window().size = Vector2i(1600, 900)
	var main: Node = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await _settle(10)
	for lv in LEVELS:
		main.show_play(lv)
		await _settle(20)
		var play: Node = main.get("_current")
		var rooms: Array = PaintedRooms.get_level(lv)["rooms"]
		for i in play._room_names.size():
			var rname: String = play._room_names[i]
			var room: Dictionary = rooms.filter(func(r): return r["name"] == rname)[0]
			_log.append("%s/%s  art=%s  %s" % [lv, rname, room["art"], _fresh(room["art"])])
			play._show_room(i)
			var marks := Control.new()
			marks.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			marks.mouse_filter = Control.MOUSE_FILTER_IGNORE
			play.add_child(marks)
			var nt := 0
			var ns := 0
			for c in play._rooms[rname].get_children():
				if not (c is Button):
					continue
				for conn in c.pressed.get_connections():
					var a: Array = conn["callable"].get_bound_arguments()
					if a.size() > 0 and a[0] is Dictionary:
						var e: Dictionary = a[0]
						var col := Color.RED if e["toxic"] else Color.LIME
						if e["toxic"]: nt += 1
						else: ns += 1
						var r := ReferenceRect.new()
						r.editor_only = false
						r.border_color = col
						r.border_width = 3
						r.position = c.global_position
						r.size = c.size
						marks.add_child(r)
						var l := Label.new()
						l.text = e["id"]
						l.position = c.global_position + Vector2(2, -22)
						l.add_theme_color_override("font_color", col)
						l.add_theme_color_override("font_outline_color", Color.BLACK)
						l.add_theme_constant_override("outline_size", 6)
						l.add_theme_font_size_override("font_size", 16)
						marks.add_child(l)
			_log.append("    toxic=%d safe=%d" % [nt, ns])
			await _settle(4)
			_shot("rooms_%s_%d.png" % [lv, i + 1])
			marks.queue_free()
	var f := FileAccess.open(OUT + "rooms_test.txt", FileAccess.WRITE)
	f.store_string("\n".join(_log))
	f.close()
	get_tree().quit()

## Compare the imported texture with the file on disk (small thumbnails).
func _fresh(art: String) -> String:
	var path := "res://assets/ui/" + art
	var a: Image = (load(path) as Texture2D).get_image()
	var b := Image.load_from_file(ProjectSettings.globalize_path(path))
	if a.is_compressed(): a.decompress()
	if a.get_size() != b.get_size():
		return "STALE (size %s vs file %s)" % [a.get_size(), b.get_size()]
	a.convert(Image.FORMAT_RGB8); b.convert(Image.FORMAT_RGB8)
	a.resize(64, 36); b.resize(64, 36)
	var d := 0.0
	for y in 36:
		for x in 64:
			var p := a.get_pixel(x, y); var q := b.get_pixel(x, y)
			d += absf(p.r - q.r) + absf(p.g - q.g) + absf(p.b - q.b)
	d /= 64.0 * 36.0 * 3.0
	return ("ok" if d < 0.03 else "STALE") + " (diff %.3f)" % d

func _settle(n: int) -> void:
	for i in n:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw

func _shot(name: String) -> void:
	get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + name))
