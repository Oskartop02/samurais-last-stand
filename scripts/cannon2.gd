extends CharacterBody2D

@export var shoot_interval = 0.7
@onready var arrow = preload("res://characters/bolt.tscn")

func _ready():
	set_process(true)
	timeout()  # Rozpocznij strzelanie

func timeout():
	shoot()
	await get_tree().create_timer(shoot_interval).timeout
	timeout()

func shoot():
	var instance = arrow.instantiate()
	instance.direction = 1  # Strzelanie w dół
	instance.launcher_rid = get_rid()
	var spawn_offset = Vector2(0, 120)  # Pozycja poniżej collidera działka
	instance.global_position = global_position + spawn_offset
	get_tree().get_current_scene().add_child(instance)
