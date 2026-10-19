extends Node3D

@onready var road_spawn_trigger = $SpawnTrigger

var id = 0
var house_list = []

signal spawn_road()
signal current_road_id(current_id: int)


# only make a new road if the player crosses trigger
func _on_spawn_trigger_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		print("spawning road")
		current_road_id.emit(id)
		spawn_road.emit()
