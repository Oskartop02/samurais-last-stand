extends Node

const FALLBACK_SCENE := "res://scenes/level_zero.tscn"
const NON_GAMEPLAY_SCENES := {
	"res://scenes/main_menu.tscn": true,
	"res://scenes/GameOver.tscn": true,
	"res://scenes/to_be_continued.tscn": true,
}

var current_room_path: String = "start"
var last_gameplay_scene_path: String = FALLBACK_SCENE

func set_current_room(room_path: String):
	current_room_path = room_path
	if room_path != "" and !NON_GAMEPLAY_SCENES.has(room_path):
		last_gameplay_scene_path = room_path
	print("Current room path set to:", current_room_path)

func get_current_room_path() -> String:
	return current_room_path

func get_retry_scene_path() -> String:
	if current_room_path != "" and current_room_path != "start" and !NON_GAMEPLAY_SCENES.has(current_room_path):
		return current_room_path
	if last_gameplay_scene_path != "":
		return last_gameplay_scene_path
	return FALLBACK_SCENE
