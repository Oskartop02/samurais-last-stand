extends Area2D

@export var next_scene_path = "res://scenes/scena_testowa.tscn"

func _on_body_entered(body: Node) -> void:
	# Sprawdź, czy ciało, które weszło w obszar, jest typu CharacterBody2D (bohater)
	if body is CharacterBody2D:
		get_tree().change_scene_to_file(next_scene_path)
		queue_free()  # Usuń orb po zebraniu
