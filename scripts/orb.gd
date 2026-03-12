extends Area2D

func _on_body_entered(body: Node) -> void:
	# Sprawdź, czy ciało, które weszło w obszar, jest typu CharacterBody2D (bohater)
	if body is CharacterBody2D:
		print("Bohater zebrał orb!")
		# Aktywuj logikę, np. nadanie podwójnego skoku lub inne akcje
		body.can_double_jump = true
		queue_free()  # Usuń orb po zebraniu
