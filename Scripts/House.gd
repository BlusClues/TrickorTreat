extends Node3D

@onready var knock_trigger = $KnockTrigger

var knocked: bool = false
var player_in_range: bool = false
var scariness: float = 0.0


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


func knocked_at_door():
	if knocked:
		# print("You FUCKING knocked?")
		# print(scariness)
		if scariness > 0.5:
			if randf() < scariness:
				# print("You were tricked. Now your dead!")
				GameManager.got_tricked.emit(self)
			else:
				# print("Your safe")
				GameManager.got_candy.emit(self)
		else:
			# print("Your safe")
			GameManager.got_candy.emit(self)



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