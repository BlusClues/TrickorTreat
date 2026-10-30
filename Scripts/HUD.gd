extends Node2D

@onready var candy_label = $CanvasLayer/CandyLabel
@onready var candy_label_increase = $CanvasLayer/CandyLabel2
@onready var knock_label = $CanvasLayer/KnockLabel

var candy_amount = 0


func _ready() -> void:
	candy_label.text = str(0)
	candy_label_increase.modulate.a = 0.0
	knock_label.visible = false
	GameManager.can_knock.connect(_on_house_can_knock)
	GameManager.cant_knock.connect(_on_player_cant_knock)
	
func _on_player_candy_increased(amount: int) -> void:
	var increased_amount = amount - candy_amount
	candy_amount = amount
	candy_label.text = str(candy_amount)

	candy_label_increase.text = "+" + str(increased_amount)
	candy_label_increase.modulate.a = 1.0
	var tween = create_tween()
	tween.tween_property(candy_label_increase, "modulate:a", 0.0, 2.0)

func _on_house_can_knock() -> void:
	knock_label.visible = true

func _on_player_cant_knock() -> void:
	knock_label.visible = false