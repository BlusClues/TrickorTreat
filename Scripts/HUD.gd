extends Node2D

@onready var candy_label = $CanvasLayer/CandyLabel

var candy_amount = 0


func _ready() -> void:
	candy_label.text = str(0)
	
func _on_player_candy_increased(amount: int) -> void:
	candy_amount = amount
	candy_label.text = str(candy_amount)
