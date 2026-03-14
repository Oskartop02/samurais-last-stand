extends CharacterBody2D

@export var speed = 150
@export var health = 100  # Zdrowie przeciwnika
@export var damage = 10  # Obrażenia zadawane przez przeciwnika
var direction = -1
var is_dead = false  # Flaga sprawdzająca, czy przeciwnik jest martwy
var _damage_flash_tween: Tween = null

func _ready():
	# Ustaw domyślną animację
	$AnimatedSprite2D.play("szogun_left")
	
	# Podłączenie sygnału kolizji z bohaterem do hitbox (Area2D)
	var hitbox = $hitbox4  # Odniesienie do Area2D o nazwie "hitbox2"
	if hitbox:
		# Użyj funkcji Callable do poprawnego połączenia sygnału
		hitbox.connect("body_entered", Callable(self, "_hitbox_body_entered"))
	else:
		print("Error: Node 'hitbox4' not found!")

func _physics_process(delta):
	# Jeśli przeciwnik jest martwy, nie wykonuj dalszej logiki
	if is_dead:
		return

	velocity.x = direction * speed
	move_and_slide()

	# Zmiana kierunku po dotarciu do ściany
	if is_on_wall():
		direction *= -1
		update_animation()

# Funkcja do aktualizacji animacji w zależności od kierunku
func update_animation():
	if direction == -1:
		$AnimatedSprite2D.play("szogun_left")
	else:
		$AnimatedSprite2D.play("szogun_right")

# Funkcja do odbierania obrażeń
func take_damage(damage: int) -> void:
	health -= damage
	if health > 0: 
		_play_damage_flash()
	if health <= 0:
		die()

# Funkcja do obsługi śmierci przeciwnika
func die() -> void:
	is_dead = true
	if _damage_flash_tween:
		_damage_flash_tween.kill()
		_damage_flash_tween = null
	modulate = Color(1, 1, 1, 1)
	$AnimatedSprite2D.hide()
	if direction == -1:
		$AnimatedSprite2D2.show()
		$hitbox4.queue_free()
		$EnemyCollision.queue_free()
		$AnimatedSprite2D2.play("szogun_dead_l")
	else:
		$AnimatedSprite2D3.show()
		$hitbox4.queue_free()
		$EnemyCollision.queue_free()
		$AnimatedSprite2D3.play("szogun_dead_r")

	$AnimatedSprite2D2.connect("animation_finished", Callable(self, "_on_death_animation_finished"))
	$AnimatedSprite2D3.connect("animation_finished", Callable(self, "_on_death_animation_finished"))

# Custom function to handle the end of the death animation
func _on_death_animation_finished():
	var current_scene = get_tree().current_scene.scene_file_path
	if current_scene == "res://scenes/scena_testowa.tscn":
		var next_scene_path = "res://scenes/scena_numer_dwa.tscn"
		get_tree().change_scene_to_file(next_scene_path)
	elif current_scene == "res://scenes/scena_numer_dwa.tscn":
		var next_scene_path = "res://scenes/to_be_continued.tscn"
		get_tree().change_scene_to_file(next_scene_path)

func _play_damage_flash() -> void:
	if _damage_flash_tween:
		_damage_flash_tween.kill()
	_damage_flash_tween = create_tween()
	_damage_flash_tween.tween_property(self, "modulate", Color(1, 0, 0, 1), 0.06)
	_damage_flash_tween.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.1)
