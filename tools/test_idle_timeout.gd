extends Control
## Dev check: idle timeout returns to attach and keeps the BGM/SFX choices.

var _lines: PackedStringArray = []


func _ready() -> void:
    var main: Node = load("res://scenes/main.tscn").instantiate()
    add_child(main)
    main.idle_timeout_sec = 1.5   # shortened for the test
    await get_tree().process_frame
    # player turns BGM off, SFX stays on, then starts playing a level
    main.get("_current").get_node("AudioToggles/BgmToggle").button_pressed = false
    main.get("_current").get_node("StartButton").pressed.emit()
    await get_tree().process_frame
    main.get("_current").get_node("Cards").get_child(1).get_node("%StartButton").pressed.emit()
    await get_tree().process_frame
    _lines.append("before idle: screen=%s playing=%s" % [main.get("_current").get_script().resource_path, Game.playing])
    await get_tree().create_timer(2.2).timeout
    var cur: Node = main.get("_current")
    _lines.append("after idle: screen=%s playing=%s" % [cur.scene_file_path, Game.playing])
    _lines.append("toggles: %s / %s  music_on=%s sfx_on=%s" % [
        cur.get_node("AudioToggles/BgmToggle").text, cur.get_node("AudioToggles/SfxToggle").text,
        Music.music_on, Music.sfx_on])
    await get_tree().create_timer(2.0).timeout
    _lines.append("still on attach after more idle: %s" % (main.get("_current") == cur))
    Music.music_on = true   # restore default for real play
    var fa := FileAccess.open("res://tools/screenshots/idle_test.txt", FileAccess.WRITE)
    fa.store_string("\n".join(_lines))
    fa.close()
    get_tree().quit()
