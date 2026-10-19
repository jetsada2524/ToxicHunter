extends Node
## Autoload: all sound effects, synthesised at startup - no .wav files ship.
## Same approach as the sibling projects: render each cue into an
## AudioStreamWAV from oscillators + envelopes so the repo stays asset-free and
## a cue can be retuned by editing numbers.
##
## Any cue can be replaced by a real recording: drop res://assets/audio/sfx/
## <cue>.ogg (or .wav / .mp3) - e.g. correct.ogg - and it is used instead of the
## synthesised version. Cues: tap, hover, correct, wrong, tick, reveal, win.

const FILE_DIR := "res://assets/audio/sfx/"
const FILE_EXTS := ["ogg", "wav", "mp3"]

const RATE := 44100
const VOICES := 8

var muted := false

var _bank: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _next := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_bank["tap"] = _render(0.070, _tap)
	_bank["hover"] = _render(0.045, _hover)
	_bank["correct"] = _render(0.520, _correct)
	_bank["wrong"] = _render(0.360, _wrong)
	_bank["tick"] = _render(0.045, _tick)
	_bank["reveal"] = _render(0.400, _reveal)
	_bank["win"] = _render(0.900, _win)
	_use_recorded_overrides()
	for i in VOICES:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)


func play(cue: StringName, pitch: float = 1.0, volume_db: float = 0.0) -> void:
	if muted or not _bank.has(cue):
		return
	var p := _players[_next]
	_next = (_next + 1) % VOICES
	p.stream = _bank[cue]
	p.pitch_scale = clampf(pitch, 0.4, 2.5)
	p.volume_db = volume_db
	p.play()


## Swap in any recorded files found in assets/audio/sfx/.
func _use_recorded_overrides() -> void:
	for cue in _bank.keys():
		for ext in FILE_EXTS:
			var path := "%s%s.%s" % [FILE_DIR, cue, ext]
			if ResourceLoader.exists(path):
				_bank[cue] = load(path)
				break


# --- rendering --------------------------------------------------------------
func _render(seconds: float, voice: Callable) -> AudioStreamWAV:
	var n := int(seconds * RATE)
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		var t := float(i) / RATE
		var v: float = clampf(voice.call(t, seconds), -1.0, 1.0)
		data.encode_s16(i * 2, int(v * 32000.0))
	var s := AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = RATE
	s.stereo = false
	s.data = data
	return s


func _env(t: float, attack: float, dur: float, curve: float = 2.5) -> float:
	if t < attack:
		return t / maxf(attack, 0.0001)
	var d: float = (t - attack) / maxf(dur - attack, 0.0001)
	return pow(clampf(1.0 - d, 0.0, 1.0), curve)


func _sine(t: float, f: float) -> float:
	return sin(TAU * f * t)


func _noise(t: float) -> float:
	var x: float = sin(t * 12543.7) * 43758.5453
	return (x - floor(x)) * 2.0 - 1.0


# --- voices -----------------------------------------------------------------
func _tap(t: float, dur: float) -> float:
	return _sine(t, 760.0 - 240.0 * (t / dur)) * _env(t, 0.002, dur, 3.0) * 0.45


func _hover(t: float, dur: float) -> float:
	return _sine(t, 1600.0) * _env(t, 0.001, dur, 4.0) * 0.18


func _correct(t: float, dur: float) -> float:
	# a bright two-note "ติ๊ง!" arpeggio - found one
	var a := _sine(t, 880.0) * pow(clampf(1.0 - t / (dur * 0.5), 0.0, 1.0), 2.0)
	var b := 0.0
	if t > 0.12:
		b = _sine(t - 0.12, 1320.0) * pow(clampf(1.0 - (t - 0.12) / (dur * 0.6), 0.0, 1.0), 2.0)
	return (a + b) * 0.42


func _wrong(t: float, dur: float) -> float:
	# soft descending buzz - gentle, never harsh at a kids' station
	var f: float = 300.0 - 120.0 * (t / dur)
	var tone := _sine(t, f) * 0.4
	var grit := _sine(t, f * 2.01) * 0.12
	return (tone + grit) * _env(t, 0.01, dur, 2.2)


func _tick(t: float, dur: float) -> float:
	return _sine(t, 1200.0) * _env(t, 0.001, dur, 4.0) * 0.22


func _reveal(t: float, dur: float) -> float:
	# upward whoosh as the item floats up to be inspected
	var p: float = t / dur
	var tone := _sine(t, 300.0 + 700.0 * pow(p, 1.4)) * 0.32
	var air := _noise(t) * 0.14 * sin(PI * p)
	return (tone + air) * _env(t, 0.02, dur, 1.6)


func _win(t: float, dur: float) -> float:
	# three rising chimes for the summary screen
	var s := 0.0
	for i in 3:
		var off: float = i * 0.16
		if t < off:
			continue
		var lt: float = t - off
		s += _sine(lt, 660.0 * (1.0 + 0.28 * i)) * _env(lt, 0.004, dur - off, 2.0)
	return s * 0.3
