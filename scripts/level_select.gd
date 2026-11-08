extends Control
## Location picker. Layout (background, header, card row) lives in
## scenes/screens/level_select.tscn; this script spawns one
## scenes/components/level_card.tscn per entry in THLevels.
## Choosing a card opens the "วิธีเล่น" window (scripts/how_to_play.gd); the
## round starts from its "เริ่มเกม" button. The "กลับ" button in the
## bottom-left corner goes back to the attach (title) screen.

const Levels := preload("res://data/levels.gd")
const CardScene := preload("res://scenes/components/level_card.tscn")
const HowToPlay := preload("res://scripts/how_to_play.gd")
const GlossyButtonScript := preload("res://scripts/components/glossy_button.gd")

signal level_chosen(id: String)
signal back_pressed

const BACK_SIZE := Vector2(240, 88)
const BACK_MARGIN := Vector2(28, 24)

@onready var _cards: HBoxContainer = $Cards
var _how: Control


func _ready() -> void:
	# exhibition build opens everything; classroom build would gate on progress,
	# but until save data exists we simply open the first level
	for i in Levels.LIST.size():
		var lv: Dictionary = Levels.LIST[i]
		var open: bool = Game.config().EXHIBITION_UNLOCK_ALL or i == 0
		var card := CardScene.instantiate()
		_cards.add_child(card)
		card.setup(lv, open)
		card.chosen.connect(_on_card_chosen)

	# back to the attach screen, bottom-left
	var back := GlossyButtonScript.new()
	back.text = "กลับ"
	back.color = Color("4FA6E0")
	back.font_size = 42
	back.anchor_left = 0.0
	back.anchor_right = 0.0
	back.anchor_top = 1.0
	back.anchor_bottom = 1.0
	back.offset_left = BACK_MARGIN.x
	back.offset_right = BACK_MARGIN.x + BACK_SIZE.x
	back.offset_top = -BACK_MARGIN.y - BACK_SIZE.y
	back.offset_bottom = -BACK_MARGIN.y
	back.pressed.connect(func(): back_pressed.emit())
	add_child(back)

	# how-to-play window (on top of everything)
	_how = HowToPlay.new()
	add_child(_how)
	_how.start_pressed.connect(func(id: String): level_chosen.emit(id))


func _on_card_chosen(id: String) -> void:
	_how.open(Levels.by_id(id))
