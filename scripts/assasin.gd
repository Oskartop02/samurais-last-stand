extends CharacterBody2D
@export var speed = 420
@export var health = 1  # Zdrowie przeciwnika
@export var damage = 50  # Obrażenia zadawane przez przeciwnika (instant kill)
@export var detection_range = 200  # Zasięg wykrywania gracza
var direction = 0  # Domyślnie przeciwnik się nie porusza
var is_dead = false  # Flaga sprawdzająca, czy przeciwnik jest martwy
var player_in_range = false  # Czy gracz jest w zasięgu
var _player_ref = null  # Referencja do gracza (dla spawned assasynów)
var _has_detection_area = false  # Czy ma DetectionArea z sceny
var _wall_escape_time = 0.0  # Krótki cooldown po odbiciu od ściany
var _wall_escape_direction = 0
var _bossroom_rebound_time = 0.0  # Czas chwilowego patrolu po odbiciu od granicy bossroomu

func _ready():
	$AnimatedSprite2D.play("asasin_l")
	
	# Szukaj hitbox - różne nazwy w scenie vs packed scene
	var hitbox = get_node_or_null("hitbox6")
	if !hitbox:
		hitbox = get_node_or_null("hitbox")
	if hitbox:
		if !hitbox.is_connected("body_entered", Callable(self, "_hitbox_body_entered")):
			hitbox.connect("body_entered", Callable(self, "_hitbox_body_entered"))
	else:
		print("[ASSASIN] Brak hitbox!")
	
	# Podłącz DetectionArea jeśli istnieje (scena)
	var detect = get_node_or_null("DetectionArea")
	if detect:
		_has_detection_area = true
		if !detect.is_connected("body_entered", Callable(self, "_on_player_entered")):
			detect.connect("body_entered", Callable(self, "_on_player_entered"))
		if !detect.is_connected("body_exited", Callable(self, "_on_player_exited")):
			detect.connect("body_exited", Callable(self, "_on_player_exited"))
	else:
		# Spawned assasin - auto-szukaj gracza
		_has_detection_area = false
		print("[ASSASIN] Brak DetectionArea - tryb auto-chase")

func _physics_process(delta):
	if is_dead:
		return

	if _bossroom_rebound_time > 0.0:
		_bossroom_rebound_time -= delta
	if _wall_escape_time > 0.0:
		_wall_escape_time -= delta
	
	# Spawned assasin bez DetectionArea - automatycznie szukaj gracza
	if !_has_detection_area and !player_in_range:
		_find_player()

	# Poruszanie przeciwnikiem
	if _bossroom_rebound_time > 0.0:
		direction = _wall_escape_direction
		velocity.x = direction * speed
	elif _wall_escape_time > 0.0:
		direction = _wall_escape_direction
		velocity.x = direction * speed
	elif player_in_range:
		# Śledź gracza
		if _player_ref and is_instance_valid(_player_ref):
			var new_dir = sign(_player_ref.global_position.x - global_position.x)
			if new_dir != 0 and new_dir != direction:
				direction = new_dir
				update_animation()
		velocity.x = direction * speed
	else:
		velocity.x = 0

	move_and_slide()

	if is_on_wall():
		_start_wall_escape()

func force_bossroom_rebound(new_direction: int, duration: float = 0.55) -> void:
	_wall_escape_direction = new_direction
	_bossroom_rebound_time = duration
	_wall_escape_time = max(_wall_escape_time, 0.12)
	direction = new_direction
	update_animation()

func _start_wall_escape():
	_wall_escape_time = 0.2
	if direction < 0:
		_wall_escape_direction = 1
	elif direction > 0:
		_wall_escape_direction = -1
	else:
		_wall_escape_direction = 1
	direction = _wall_escape_direction
	update_animation()

func _find_player():
	var tree = get_tree()
	if tree == null:
		return
	var player = tree.current_scene.get_node_or_null("PostacTestowa")
	if player and is_instance_valid(player):
		_player_ref = player
		player_in_range = true
		direction = sign(player.global_position.x - global_position.x)
		if direction == 0:
			direction = -1
		update_animation()
		$AnimatedSprite2D.hide()
		$AnimatedSprite2D3.show()

func update_animation():
	if direction == -1:
		$AnimatedSprite2D.play("asasin_l")
	elif direction == 1:
		$AnimatedSprite2D.play("asasin_r")
	if player_in_range == true:
		if direction == -1:
			$AnimatedSprite2D3.play("atak_l")
		elif direction == 1:
			$AnimatedSprite2D3.play("atak_r")


func take_damage(damage: int, death_type: String = "normal") -> void:
	health -= damage
	if health <= 0:
		die(death_type)

func die(death_type: String) -> void:
	is_dead = true
	$AnimatedSprite2D.hide()
	$AnimatedSprite2D3.hide()
	# Usuń hitbox i collision (różne nazwy)
	var hb = get_node_or_null("hitbox6")
	if !hb:
		hb = get_node_or_null("hitbox")
	if hb:
		hb.queue_free()
	var ec = get_node_or_null("EnemyCollision")
	if ec:
		ec.queue_free()

	if death_type == "kunai":
		$AnimatedSprite2D2.show()
		if direction == 1:
			$AnimatedSprite2D2.play("ded_kunai_r")
		else:
			$AnimatedSprite2D2.play("ded_kunai_l")
		$AnimatedSprite2D2.connect("animation_finished", Callable(self, "_on_death_animation_finished"))
	else:
		print(death_type)
		$AnimatedSprite2D4.show()
		if direction == 1:
			$AnimatedSprite2D4.play("dead_sword_r")
		else:
			$AnimatedSprite2D4.play("dead_sword_l")
		$AnimatedSprite2D4.connect("animation_finished", Callable(self, "_on_death_animation_finished"))

func _on_death_animation_finished():
	queue_free()

# Funkcja obsługująca wykrycie gracza w zasięgu (z DetectionArea w scenie)
func _on_player_entered(body):
	if is_dead:
		return
	if body.name == "PostacTestowa":
		_player_ref = body
		player_in_range = true
		direction = sign(body.global_position.x - global_position.x)
		if direction == 0:
			direction = -1
		update_animation()
		$AnimatedSprite2D.hide()
		$AnimatedSprite2D3.show()
		if direction == -1:
			$AnimatedSprite2D3.play("atak_l")
		elif direction == 1:
			$AnimatedSprite2D3.play("atak_r")

# Funkcja obsługująca opuszczenie zasięgu przez gracza
func _on_player_exited(body):
	pass

# Hitbox - zadaj obrażenia graczowi przy kontakcie
func _hitbox_body_entered(body):
	if is_dead:
		return
	if body.name == "PostacTestowa" and body.has_method("take_damage_p"):
		body.take_damage_p(damage)
		print("[ASSASIN] Trafiono gracza! ", damage, " dmg")
