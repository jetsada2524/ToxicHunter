extends Control
## Dev check: the BGM/SFX pills drive Music/Sfx and the choice persists.

var _lines: PackedStringArray = []

func _log(a = "", b = "", c = "", d = "", e = "", f = "", g = "", h = "", i = "", j = "", k = "", l = "") -> void:
	_lines.append("".join([str(a), str(b), str(c), str(d), str(e), str(f), str(g), str(h), str(i), str(j), str(k), str(l)]))


func _ready() -> void:
	var a: Control = load("res://scenes/screens/attach.tscn").instantiate()
	add_child(a)
	await get_tree().process_frame
	var bgm: Button = a.get_node("AudioToggles/BgmToggle")
	var sfx: Button = a.get_node("AudioToggles/SfxToggle")
	_log("[audio] start  music_on=", Music.music_on, " sfx_on=", Music.sfx_on, " text=", bgm.text, "/", sfx.text)
	bgm.button_pressed = false   # emits toggled(false)
	sfx.button_pressed = false
	await get_tree().process_frame
	var cfg := ConfigFile.new(); cfg.load("user://settings.cfg")
	_log("[audio] off    music_on=", Music.music_on, " sfx_muted=", Sfx.muted, " text=", bgm.text, "/", sfx.text,
		" saved=", cfg.get_value("audio", "music_on"), ",", cfg.get_value("audio", "sfx_on"))
	bgm.button_pressed = true
	sfx.button_pressed = true
	await get_tree().process_frame
	_log("[audio] on     music_on=", Music.music_on, " sfx_muted=", Sfx.muted, " text=", bgm.text, "/", sfx.text)
	var fa := FileAccess.open("res://tools/screenshots/audio_test.txt", FileAccess.WRITE)
	fa.store_string("\n".join(_lines))
	fa.close()
	get_tree().quit()
