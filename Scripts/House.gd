extends Node3D

@onready var knock_trigger = $KnockTrigger
# @onready var candy_curve = preload("res://CandyCurve.tres")

var knocked: bool = false
var player_in_range: bool = false
var scariness: float = 0.0

const MIN_CANDY = 1
const MAX_CANDY = 5
const CANDY_SPREAD = 0.8

# connect the functions to each of the houses
func _ready() -> void:
	# Connect the area signals
	knock_trigger.body_entered.connect(_on_knock_trigger_body_entered)
	knock_trigger.body_exited.connect(_on_knock_trigger_body_exited)


# Handle the knock at the door
func _unhandled_input(event: InputEvent) -> void:
	if !knocked:
		if event.is_action_pressed("knock") and player_in_range:
			knocked = true
			knocked_at_door()


# Checking what happens at the door when you knock
func knocked_at_door():
	if knocked:
		if scariness > 0.5:
			if randf() < scariness:
				GameManager.got_tricked.emit(self)
			else:
				GameManager.got_candy.emit(self, calc_candy_amount())
		else:
			GameManager.got_candy.emit(self, calc_candy_amount())


# calculate the amount of candy each house gives
func calc_candy_amount() -> int:
	var target = lerpf(MIN_CANDY, MAX_CANDY, clampf(scariness, 0.0, 1.0))
	var amount = roundi(randfn(target, CANDY_SPREAD))
	return clampi(amount, MIN_CANDY, MAX_CANDY)

# check if the player has entered the door range
func _on_knock_trigger_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_in_range = true
		print("entered door")


# check if the player has exited the door range
func _on_knock_trigger_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		print("door exited")
		player_in_range = false
		knocked = false