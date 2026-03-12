extends Node2D

func _ready() -> void:
	var current_scene = get_tree().current_scene.scene_file_path
	Pokoj.set_current_room(current_scene)
	# Reset wave systemu na starcie sceny
	if current_scene == "res://scenes/scena_numer_trzy.tscn":
		GameControler.reset_waves()
		print("[MANAGER] Reset wave systemu dla sceny 3")
