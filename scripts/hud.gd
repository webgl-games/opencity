extends CanvasLayer
## Readout for whatever the player is currently controlling, plus the
## context prompt for getting in and out of cars.

@onready var _speed: Label = $Speed
@onready var _prompt: Label = $Prompt

var _game: Node


func _ready() -> void:
	_game = get_tree().get_first_node_in_group("game")


func _process(_delta: float) -> void:
	if _game == null:
		_game = get_tree().get_first_node_in_group("game")
		return

	var active: Node = _game.get_active()
	if active == null:
		return

	if _game.driving != null:
		_speed.text = "%d km/h" % roundi(active.get_speed_kmh())
		if active.boosting:
			_speed.text += "   BOOST"
			_speed.modulate = Color(1.0, 0.72, 0.3)
		else:
			_speed.modulate = Color.WHITE
		_prompt.text = "E   get out"
	else:
		_speed.text = "on foot"
		_speed.modulate = Color.WHITE
		_prompt.text = "E   get in" if _game.nearest_vehicle() != null else ""
