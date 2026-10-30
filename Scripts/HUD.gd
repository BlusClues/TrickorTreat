extends Node2D

@onready var candy_label = $CanvasLayer/CandyLabel
@onready var candy_label_increase = $CanvasLayer/CandyLabel2
@onready var knock_label = $CanvasLayer/KnockLabel
@onready var timer_label = $CanvasLayer/TimerLabel
@onready var timer = $Timer

var candy_amount = 0

const STARTING_TIMER_AMOUNT = 180.0


func _ready() -> void:
	candy_label.text = str(0)
	candy_label_increase.modulate.a = 0.0
	knock_label.visible = false
	timer.wait_time = STARTING_TIMER_AMOUNT
	timer.start()
	GameManager.in_range.connect(_on_house_in_range)
	GameManager.out_range.connect(_on_house_out_range)
	GameManager. has_been_knocked.connect(_on_house_has_been_knocked)

func _process(delta: float) -> void:
	var seconds = ceili(timer.time_left)
	timer_label.text = "%d:%02d" % [seconds / 60, seconds % 60]


func _on_player_candy_increased(amount: int) -> void:
	var increased_amount = amount - candy_amount
	candy_amount = amount
	candy_label.text = str(candy_amount)

	candy_label_increase.text = "+" + str(increased_amount)
	candy_label_increase.modulate.a = 1.0
	var tween = create_tween()
	tween.tween_property(candy_label_increase, "modulate:a", 0.0, 2.0)

func _on_house_in_range() -> void:
	knock_label.visible = true

func _on_house_out_range() -> void:
	knock_label.visible = false
	
func _on_house_has_been_knocked(knocked: bool) -> void:
	if knocked:
		knock_label.visible = false
	else:
		knock_label.visible = true