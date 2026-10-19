extends Control
## Location picker. Layout (background, header, card row) lives in
## scenes/screens/level_select.tscn; this script just spawns one
## scenes/components/level_card.tscn per entry in THLevels.

const Levels := preload("res://data/levels.gd")
const CardScene := preload("res://scenes/components/level_card.tscn")

signal level_chosen(id: String)

@onready var _cards: HBoxContainer = $Cards


func _ready() -> void:
	# exhibition build opens everything; classroom build would gate on progress,
	# but until save data exists we simply open the first level
	for i in Levels.LIST.size():
		var lv: Dictionary = Levels.LIST[i]
		var open: bool = Game.config().EXHIBITION_UNLOCK_ALL or i == 0
		var card := CardScene.instantiate()
		_cards.add_child(card)
		card.setup(lv, open)
		card.chosen.connect(func(id: String): level_chosen.emit(id))
