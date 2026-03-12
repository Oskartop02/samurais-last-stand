extends Node

var current_room_path: String = "start"

func set_current_room(room_path: String):
	current_room_path = room_path
	print("Current room path set to:", current_room_path)

func get_current_room_path() -> String:
	return current_room_path
