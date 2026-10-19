extends Node
## Autoload: background music + the player's audio preferences.
##
## Tracks are plain files dropped into res://assets/audio/music/ named
## bgm_<track>.ogg (.mp3 / .wav also work). A missing file just means silence,
## so the game runs fine before any music has been downloaded.
##
##   bgm_title     attach + level select
##   bgm_gameplay  while investigating (also bgm_gameplay_2 ... picked at random)
##   bgm_result    summary screen (falls back to bgm_title)
##
## Preferences (music_on / sfx_on) persist in user://settings.cfg and are
## toggled from the BGM / SFX buttons on the attach screen.

signal settings_changed

const DIR := "res://assets/audio/music/"
const EXTS := ["ogg", "mp3", "wav"]
const SETTINGS := "user://settings.cfg"
const VOLUME_DB := -8.0
const FADE := 0.7
const FALLBACK := {&"result": &"title"}

var music_on := true:
	set(v):
		music_on = v
		_apply_music()
		_save()
		settings_changed.emit()
var sfx_on := true:
	set(v):
		sfx_on = v
		Sfx.muted = not v
		_save()
		settings_changed.emit()

var _players: Array[AudioStreamPlayer] = []
var _active := 0
var _track: StringName = &""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in 2:
		var p := AudioStreamPlayer.new()
		p.volume_db = -80.0
		add_child(p)
		_players.append(p)
	_load()


## Switch to a track with a short crossfade. Same track = keep playing.
func play(track: StringName) -> void:
	if track == _track and _players[_active].playing:
		return
	_track = track
	_apply_music()


func stop() -> void:
	_track = &""
	_apply_music()


func toggle_music() -> void:
	music_on = not music_on


func toggle_sfx() -> void:
	sfx_on = not sfx_on


# ---------------------------------------------------------------- internals
func _apply_music() -> void:
	if _players.is_empty():
		return
	var stream: AudioStream = _find(_track) if (music_on and _track != &"") else null
	var old := _players[_active]
	if stream == null:
		_fade(old, -80.0, true)
		return
	if old.playing and old.stream == stream:
		_fade(old, VOLUME_DB, false)
		return
	_active = 1 - _active
	var nxt := _players[_active]
	nxt.stream = stream
	nxt.volume_db = -40.0
	nxt.play()
	_fade(nxt, VOLUME_DB, false)
	_fade(old, -80.0, true)


func _fade(p: AudioStreamPlayer, to_db: float, stop_after: bool) -> void:
	if not p.playing:
		return
	var tw := create_tween()
	tw.tween_property(p, "volume_db", to_db, FADE)
	if stop_after:
		tw.tween_callback(p.stop)


## bgm_<track>.<ext>; gameplay may have numbered variants picked at random.
func _find(track: StringName) -> AudioStream:
	var found: Array[AudioStream] = []
	for suffix in ["", "_2", "_3", "_4"]:
		var s := _load_stream(DIR + "bgm_%s%s" % [track, suffix])
		if s:
			found.append(s)
	if found.is_empty():
		return _find(FALLBACK[track]) if FALLBACK.has(track) else null
	return found.pick_random()


func _load_stream(base: String) -> AudioStream:
	for ext in EXTS:
		var path := "%s.%s" % [base, ext]
		if ResourceLoader.exists(path):
			var s := load(path) as AudioStream
			_set_loop(s)
			return s
	return null


func _set_loop(s: AudioStream) -> void:
	if s is AudioStreamOggVorbis or s is AudioStreamMP3:
		s.loop = true
	elif s is AudioStreamWAV:
		s.loop_mode = AudioStreamWAV.LOOP_FORWARD
		if s.loop_end <= 0:
			s.loop_end = int(s.get_length() * s.mix_rate)


func _load() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS) == OK:
		music_on = bool(cfg.get_value("audio", "music_on", true))
		sfx_on = bool(cfg.get_value("audio", "sfx_on", true))
	else:
		Sfx.muted = not sfx_on


func _save() -> void:
	if not is_node_ready():
		return
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "music_on", music_on)
	cfg.set_value("audio", "sfx_on", sfx_on)
	cfg.save(SETTINGS)
