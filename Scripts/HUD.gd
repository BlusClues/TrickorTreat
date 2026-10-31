extends Node2D

@onready var candy_label = $CanvasLayer/NormalGameControl/CandyLabel
@onready var candy_label_increase = $CanvasLayer/NormalGameControl/CandyLabel2
@onready var knock_label = $CanvasLayer/NormalGameControl/KnockLabel
@onready var timer_label = $CanvasLayer/NormalGameControl/TimerLabel
@onready var timer = $Timer
@onready var tricked_label = $CanvasLayer/NormalGameControl/TrickedLabel
@onready var trick_flash = $CanvasLayer/NormalGameControl/TrickFlash
@onready var gameover_screen = $CanvasLayer/GameOverControl
@onready var normal_game_screen = $CanvasLayer/NormalGameControl
@onready var final_candy_label = $CanvasLayer/GameOverControl/TotalCandyEnd
@onready var door_knock_sound = $DoorKnock
@onready var question_sound = $KidTrickOrTreat
@onready var question_sound2 = $KidTrickOrTreat2
@onready var jumpscare = $Jumpscare
@onready var crickets = $Crickets

var candy_amount = 0

const STARTING_TIMER_AMOUNT = 180.0


func _ready() -> void:
	crickets.play()
	candy_label.text = str(0)
	gameover_screen.visible = false
	normal_game_screen.visible = true
	candy_label_increase.modulate.a = 0.0
	tricked_label.modulate.a = 0.0
	trick_flash.modulate.a = 0.0
	knock_label.visible = false
	timer.wait_time = STARTING_TIMER_AMOUNT
	timer.start()
	GameManager.in_range.connect(_on_house_in_range)
	GameManager.out_range.connect(_on_house_out_range)
	GameManager.has_been_knocked.connect(_on_house_has_been_knocked)
	GameManager.just_knocked.connect(_on_house_just_knocked)

func _process(delta: float) -> void:
	var seconds = ceili(timer.time_left)
	timer_label.text = "%d:%02d" % [seconds / 60, seconds % 60]

func _on_player_was_tricked(lost_amount: int) -> void:
	tricked_label.text = "You were tricked!\n" + str(lost_amount) + " candy was stolen!"
	tricked_label.modulate.a = 1.0
	var tween = create_tween()
	tween.tween_property(tricked_label, "modulate:a", 0.0, 2.0)
	
	jumpscare.play()
	trick_flash.modulate.a = 0.0
	var flash = create_tween()
	flash.tween_property(trick_flash, "modulate:a", 0.8, 0.05)
	flash.tween_property(trick_flash, "modulate:a", 0.0, 1.25)

func _on_player_candy_increased(amount: int) -> void:
	var increased_amount = amount - candy_amount
	candy_amount = amount
	candy_label.text = str(candy_amount)
	
	if increased_amount > 0:
		candy_label_increase.text = "+" + str(increased_amount)
	else:
		candy_label_increase.text = str(increased_amount)
	
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

## Game over screen functions
func _on_timer_timeout() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().paused = true
	normal_game_screen.visible = false
	gameover_screen.visible = true
	final_candy_label.text = "Total Amount of Candy : " + str(candy_amount)

func _on_retry_button_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_quit_button_pressed() -> void:
	get_tree().quit()


func _on_house_just_knocked() -> void:
	print("Should be working")
	door_knock_sound.play()
	if randf() < 0.5:
		question_sound.play()
	else:
		question_sound2.play()
	