extends Control
const Ui := preload("res://scripts/ui_kit.gd")
const Items := preload("res://data/items.gd")
func _ready() -> void:
	var out: PackedStringArray = []
	var f := Ui.font(false)
	for id in ["bug_spray", "spray_paint", "weed_killer"]:
		for key in ["chemical", "danger"]:
			for mode in ["raw", "th"]:
				var t: String = Items.get_item(id)[key]
				if mode == "th": t = Ui.th(t)
				var fs := 32
				var l := Label.new()
				l.text = t; l.size = Vector2(930, 78); l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				l.clip_text = true
				l.add_theme_font_override("font", f); l.add_theme_font_size_override("font_size", fs)
				l.add_theme_constant_override("line_spacing", -4)
				add_child(l)
				while fs > 20 and l.get_line_count() > l.get_visible_line_count():
					fs -= 2
					l.add_theme_font_size_override("font_size", fs)
				await get_tree().process_frame
				out.append("%s.%s %s fs=%d lines=%d visible=%d" % [id, key, mode, fs, l.get_line_count(), l.get_visible_line_count()])
	var fo := FileAccess.open("res://tools/screenshots/wrap_probe.txt", FileAccess.WRITE); fo.store_string("\n".join(out)); fo.close()
	get_tree().quit()
