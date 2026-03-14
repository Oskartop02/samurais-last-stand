extends CharacterBody2D

@export var speed = 100
@export var health = 10
@export var damage = 10

@onready var arrow = preload("res://characters/arrow.tscn")

var direction = -1
var is_dead = false
var _damage_flash_tween: Tween = null

func _ready():
	add_to_group("enemy")
	$AnimatedSprite2D.play("archer_l")
	$AnimatedSprite2D.connect("frame_changed", Callable(self, "_on_frame_changed"))

	var hitbox = $hitbox5
	if hitbox:
		hitbox.connect("body_entered", Callable(self, "_hitbox_body_entered"))
	else:
		print("Error: Node 'hitbox5' not found!")

# Funkcja wywoływana przy każdej zmianie klatki
func _on_frame_changed():
	var sprite = $AnimatedSprite2D
	if sprite.frame == sprite.sprite_frames.get_frame_count(sprite.animation) - 1:
		shoot()

# Funkcja strzelania
func shoot():
	if is_dead != true:
		var instance = arrow.instantiate()
		instance.direction = direction
		# Ustaw pozycję strzały na odpowiedniej wysokości (np. ramiona)
		var spawn_offset = Vector2(20, 45) if direction == 1 else Vector2(-20, 45)
		instance.global_position = global_position + spawn_offset
		get_tree().get_current_scene().add_child(instance)


func take_damage(damage: int) -> void:
	print("Wróg otrzymał obrażenia:", damage)
	health -= damage
	if health > 0:
		_play_damage_flash()
	else:
		die()


func die() -> void:
	pass
	is_dead = true
	if _damage_flash_tween:
		_damage_flash_tween.kill()
		_damage_flash_tween = null
	modulate = Color(1, 1, 1, 1)
	$AnimatedSprite2D.hide()
	if direction == -1:
		$AnimatedSprite2D2.show()
		$hitbox5.queue_free()
		$EnemyCollision.queue_free()
		$AnimatedSprite2D2.play("dead_l")
	else:
		$AnimatedSprite2D2.show()
		$hitbox5.queue_free()
		$EnemyCollision.queue_free()
		$AnimatedSprite2D2.play("dead_r")

	$AnimatedSprite2D2.connect("animation_finished", Callable(self, "_on_death_animation_finished"))

func _on_death_animation_finished():
	queue_free()

func _play_damage_flash() -> void:
	if _damage_flash_tween:
		_damage_flash_tween.kill()
	_damage_flash_tween = create_tween()
	_damage_flash_tween.tween_property(self, "modulate", Color(1, 0, 0, 1), 0.06)
	_damage_flash_tween.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.1)
