extends CharacterBody2D

@export var speed = 100
@export var health = 30  # Zdrowie przeciwnika
@export var damage = 20 # Obrażenia zadawane przez przeciwnika
var direction = -1
var is_dead = false  # Flaga sprawdzająca, czy przeciwnik jest martwy

func _ready():
	# Ustaw domyślną animację
	$AnimatedSprite2D.play("samurai_left")
	
	# Podłączenie sygnału kolizji z bohaterem do hitbox (Area2D)
	var hitbox = get_node_or_null("hitbox3")
	if !hitbox:
		hitbox = get_node_or_null("hitbox")
	if hitbox:
		hitbox.connect("body_entered", Callable(self, "_hitbox_body_entered"))
	else:
		print("Error: Hitbox not found!")

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
		$AnimatedSprite2D.play("samurai_left")
	else:
		$AnimatedSprite2D.play("samurai_right")

# Funkcja do odbierania obrażeń
func take_damage(damage: int) -> void:
	health -= damage
	if health > 0: 
		var hit_color = Color(1, 0, 0)  # Red color to indicate hit
		var original_color = modulate  # Save the original color of the character
		var tweener = create_tween()
		tweener.tween_property(self, "modulate", hit_color, 0.1)  # Tween to hit color over 0.1 seconds
		tweener.tween_property(self, "modulate", original_color, 0.1).set_delay(0.1)
	if health <= 0:
		die()

# Funkcja do obsługi śmierci przeciwnika
func die() -> void:
	is_dead = true
	$AnimatedSprite2D.hide()
	$AnimatedSprite2D2.show()
	# Usuń hitbox i collision (różne nazwy w różnych scenach)
	var hb = get_node_or_null("hitbox3")
	if !hb:
		hb = get_node_or_null("hitbox")
	if hb:
		hb.queue_free()
	var ec = get_node_or_null("EnemyCollision")
	if ec:
		ec.queue_free()
	if direction == -1:
		$AnimatedSprite2D2.play("samurai_dead_left")
	else:
		$AnimatedSprite2D2.play("samurai_dead_right")

	$AnimatedSprite2D2.connect("animation_finished", Callable(self, "_on_death_animation_finished"))

# Custom function to handle the end of the death animation
func _on_death_animation_finished():
	queue_free()

# Hitbox - zadaj obrażenia graczowi przy kontakcie
func _hitbox_body_entered(body):
	if is_dead:
		return
	if body.name == "PostacTestowa" and body.has_method("take_damage_p"):
		body.take_damage_p(damage)
		print("[SAMURAI] Trafiono gracza! ", damage, " dmg")
