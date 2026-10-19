extends Control
## Attract / title screen ("หน้า attach"). Layout lives in
## scenes/screens/attach.tscn: full-bleed key art (title + mascot baked in),
## one GlossyButton, and the BGM / SFX on-off toggles (top right).
## No settings button on this screen by design.

const GlossyButtonScript := preload("res://scripts/components/glossy_button.gd")
const PillToggle := preload("res://scripts/components/pill_toggle.gd")

signal start_pressed

@onready var _start: GlossyButtonScript = $StartButton
@onready var _bgm: PillToggle = $AudioToggles/BgmToggle
@onready var _sfx: PillToggle = $AudioToggles/SfxToggle


func _ready() -> void:
	_start.pressed.connect(func(): start_pressed.emit())
	_bgm.on = Music.music_on
	_sfx.on = Music.sfx_on
	_bgm.toggled.connect(func(v: bool): Music.music_on = v)
	_sfx.toggled.connect(func(v: bool): Music.sfx_on = v)
