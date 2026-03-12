extends CharacterBody2D

var is_dead = false

func _physics_process(delta: float) -> void:
	if GameControler.zniszczone == 4:
		die()

func die() -> void:
	if not is_dead:
		is_dead = true
		$AnimatedSprite2D.hide()
		$AnimatedSprite2D2.show()
		$AnimatedSprite2D2.play("default")
		# Powiadomienie kontrolera gry o śmierci przeciwnika

		# Połączenie sygnału animacji śmierci
		$AnimatedSprite2D2.connect("animation_finished", Callable(self, "_on_death_animation_finished"))

func _on_death_animation_finished():
	var next_scene_path = "res://scenes/to_be_continued.tscn"
	get_tree().change_scene_to_file(next_scene_path)
