extends Node
## Dev helper: every break opportunity Godot's text server finds in each Thai
## string (same rules as AUTOWRAP_WORD_SMART). Output: screenshots/thai_breaks.json
const Ui := preload("res://scripts/ui_kit.gd")

func _ready() -> void:
	var strings: Array = JSON.parse_string(FileAccess.get_file_as_string("res://tools/thai_strings.json"))
	strings.append("สเปรย์ฉีดยุง")
	strings.append("ส\u2060เ\u2060ป\u2060ร\u2060ย\u2060์ฉีดยุง")
	var ts := TextServerManager.get_primary_interface()
	var font: Font = Ui.font(false)
	var out := {}
	for s in strings:
		var rid := ts.create_shaped_text()
		ts.shaped_text_add_string(rid, Ui.th(s), font.get_rids(), 32)
		var br := ts.shaped_text_get_line_breaks(rid, 1.0, 0, TextServer.BREAK_MANDATORY | TextServer.BREAK_WORD_BOUND)
		var pts: Array = []
		for i in range(0, br.size(), 2):
			pts.append(br[i + 1])
		out[Ui.th(s)] = pts
		ts.free_rid(rid)
	var f := FileAccess.open("res://tools/screenshots/thai_breaks.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(out))
	f.close()
	get_tree().quit()
