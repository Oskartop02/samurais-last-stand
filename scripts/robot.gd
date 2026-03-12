extends CharacterBody2D

@export var speed = 25
@export var chase_speed_min = 50
@export var chase_speed_max = 100
@export var chase_acceleration = 15.0
@export var health = 100
@export var damage = 3
@export var contact_damage = 30
@export var contact_damage_cooldown = 0.8
@export var attack_range = 150.0
@export var cooldown_time = 1.0
@export var cooldown_speed = 15

var current_chase_speed = 50.0
var turn_cooldown = 0.0
const TURN_DELAY = 0.6
const DIRECTION_DEAD_ZONE = 60.0
const VISUAL_CENTER_OFFSET = -70.0

var direction = -1
var is_dead = false
var player_ref = null
var is_attacking = false
var is_first_attack = true
var is_on_cooldown = false
var can_deal_damage = false
var can_deal_contact_damage = true

enum State { IDLE, CHASE, ATTACK, COOLDOWN }
var current_state = State.IDLE

func _ready():
	print("[ROBOT] === ROBOT READY === hp:", health, " pos:", global_position)
	$AnimatedSprite2D.play("robot_left")
	$AnimatedSprite2D2.hide()
	$AnimatedSprite2D3.hide()
	
	$DetectionArea.connect("body_entered", Callable(self, "_on_player_entered"))
	$DetectionArea.connect("body_exited", Callable(self, "_on_player_exited"))
	$AnimatedSprite2D2.connect("animation_finished", Callable(self, "_on_attack_animation_finished"))
	
	var body_hitbox = get_node_or_null("hitbox")
	if body_hitbox:
		body_hitbox.connect("body_entered", Callable(self, "_on_body_hitbox_entered"))
		print("[ROBOT] Hitbox ciała podłączony")
	print("[ROBOT] Sygnaly podłączone. Stan: IDLE")

func _physics_process(delta):
	if is_dead:
		return
	match current_state:
		State.IDLE:
			_state_idle(delta)
		State.CHASE:
			_state_chase(delta)
		State.ATTACK:
			_state_attack(delta)
		State.COOLDOWN:
			_state_cooldown(delta)
	move_and_slide()

var _last_logged_state = -1
var wall_bounce_cooldown = 0.0

func _state_idle(delta):
	if _last_logged_state != State.IDLE:
		print("[ROBOT] Stan -> IDLE (patrol) | dir:", direction)
		_last_logged_state = State.IDLE
	
	wall_bounce_cooldown -= delta
	velocity.x = direction * speed
	if is_on_wall() and wall_bounce_cooldown <= 0:
		direction *= -1
		wall_bounce_cooldown = 0.5  # Nie sprawdzaj ściany przez 0.5s po odbiciu
		print("[ROBOT] Odbicie od ściany -> dir:", direction)
	_update_walk_animation()

func _state_chase(delta):
	if _last_logged_state != State.CHASE:
		print("[ROBOT] Stan -> CHASE | speed=", snapped(current_chase_speed, 0.1))
		_last_logged_state = State.CHASE
	if player_ref == null or !is_instance_valid(player_ref):
		current_state = State.IDLE
		return
	current_chase_speed = min(current_chase_speed + chase_acceleration * delta, chase_speed_max)
	turn_cooldown -= delta
	var robot_center_x = global_position.x + VISUAL_CENTER_OFFSET
	var diff_x = player_ref.global_position.x - robot_center_x
	var dist = abs(diff_x)
	var desired_dir = sign(diff_x)
	if dist > DIRECTION_DEAD_ZONE and desired_dir != direction and turn_cooldown <= 0:
		direction = desired_dir
		turn_cooldown = TURN_DELAY
	if dist <= attack_range:
		print("[ROBOT] Gracz w zasięgu! dist=", snapped(dist, 0.1))
		_start_attack()
	else:
		velocity.x = direction * current_chase_speed
		_update_walk_animation()

func _state_attack(_delta):
	if _last_logged_state != State.ATTACK:
		_last_logged_state = State.ATTACK
	velocity.x = 0

func _state_cooldown(delta):
	if _last_logged_state != State.COOLDOWN:
		print("[ROBOT] Stan -> COOLDOWN")
		_last_logged_state = State.COOLDOWN
	if player_ref == null or !is_instance_valid(player_ref):
		velocity.x = direction * cooldown_speed
		if is_on_wall():
			direction *= -1
	else:
		turn_cooldown -= delta
		var robot_center_x = global_position.x + VISUAL_CENTER_OFFSET
		var diff_x = player_ref.global_position.x - robot_center_x
		var desired_dir = sign(diff_x)
		if abs(diff_x) > DIRECTION_DEAD_ZONE and desired_dir != direction and turn_cooldown <= 0:
			direction = desired_dir
			turn_cooldown = TURN_DELAY
		velocity.x = direction * cooldown_speed
	_update_walk_animation()
	if !is_dead:
		var pulse = abs(sin(Time.get_ticks_msec() * 0.005)) * 0.5
		modulate = Color(1.0 + pulse, 1.0 + pulse, 1.0 + pulse, 1.0)

func _start_attack():
	print("[ROBOT] >>> ATAK! dir=", direction, " first=", is_first_attack)
	current_state = State.ATTACK
	is_attacking = true
	can_deal_damage = false
	
	# Pierwszy atak ma dodatkowe opóźnienie - gracz ma czas zareagować
	if is_first_attack:
		is_first_attack = false
		print("[ROBOT] Pierwszy atak - czekam 0.8s...")
		velocity.x = 0
		if get_tree() == null: return
		await get_tree().create_timer(0.8).timeout
		if is_dead or !is_attacking: return
	
	$AnimatedSprite2D.hide()
	$AnimatedSprite2D2.show()
	if direction == -1:
		$AnimatedSprite2D2.play("attack_left")
	else:
		$AnimatedSprite2D2.play("attack_right")
	$Eksplozja.play()
	
	if get_tree() == null: return
	await get_tree().create_timer(0.5).timeout
	if is_attacking and !is_dead:
		can_deal_damage = true
		print("[ROBOT] >>> UDERZENIE! <<<")
		_deal_shockwave_damage()
	if get_tree() == null: return
	await get_tree().create_timer(0.3).timeout
	_finish_attack()

func _on_attack_animation_finished():
	if is_attacking and !is_dead:
		_finish_attack()

func _deal_shockwave_damage():
	if player_ref == null or !is_instance_valid(player_ref):
		return
	var robot_center_x = global_position.x + VISUAL_CENTER_OFFSET
	var dist = abs(player_ref.global_position.x - robot_center_x)
	var shockwave_range = attack_range + 50.0
	if dist <= shockwave_range and player_ref.has_method("take_damage_p"):
		print("[ROBOT] SHOCKWAVE TRAFIŁ! dist=", snapped(dist, 0.1))
		player_ref.take_damage_p(30)

func _finish_attack():
	if !is_attacking:
		return
	if is_dead:
		return
	is_attacking = false
	can_deal_damage = false
	current_state = State.COOLDOWN
	is_on_cooldown = true
	print("[ROBOT] COOLDOWN START (", cooldown_time, "s)")
	$AnimatedSprite2D2.stop()
	$AnimatedSprite2D2.hide()
	$AnimatedSprite2D.show()
	_update_walk_animation()
	if get_tree() == null: return
	await get_tree().create_timer(cooldown_time).timeout
	if is_dead:
		return
	is_on_cooldown = false
	modulate = Color(1, 1, 1, 1)
	print("[ROBOT] COOLDOWN KONIEC")
	if player_ref != null and is_instance_valid(player_ref):
		current_state = State.CHASE
	else:
		current_state = State.IDLE

func _update_walk_animation():
	$AnimatedSprite2D2.hide()
	$AnimatedSprite2D.show()
	if direction == -1:
		$AnimatedSprite2D.play("robot_left")
	else:
		$AnimatedSprite2D.play("robot_right")

func take_damage(damage_amount: int) -> void:
	health -= damage_amount
	print("[ROBOT] DMG! HP:", health, "/100 | stan:", State.keys()[current_state])
	if health > 0:
		var tweener = create_tween()
		tweener.tween_property(self, "modulate", Color(1, 0, 0), 0.1)
		tweener.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.1).set_delay(0.1)
	if health <= 0:
		die()

func die() -> void:
	print("[ROBOT] UMIERA dir=", direction)
	is_dead = true
	can_deal_damage = false
	current_state = State.IDLE
	$DetectionArea.queue_free()
	$AnimatedSprite2D.hide()
	$AnimatedSprite2D2.hide()
	if direction == -1:
		$AnimatedSprite2D3.show()
		$hitbox7.queue_free()
		$EnemyCollision.queue_free()
		$AnimatedSprite2D3.play("ded_l")
	else:
		$AnimatedSprite2D3.show()
		$hitbox7.queue_free()
		$EnemyCollision.queue_free()
		$AnimatedSprite2D3.play("ded_r")
	$AnimatedSprite2D3.connect("animation_finished", Callable(self, "_on_death_animation_finished"))

func _on_death_animation_finished():
	var current_scene = get_tree().current_scene.scene_file_path
	if current_scene == "res://scenes/scena_numer_dwa.tscn":
		get_tree().change_scene_to_file("res://scenes/scena_numer_trzy.tscn")

func _on_body_hitbox_entered(body):
	if is_dead:
		return
	if body.name == "PostacTestowa" and can_deal_contact_damage:
		print("[ROBOT] Kontakt! ", contact_damage, " dmg")
		if body.has_method("take_damage_p"):
			body.take_damage_p(contact_damage)
			can_deal_contact_damage = false
			if get_tree() != null:
				await get_tree().create_timer(contact_damage_cooldown).timeout
				can_deal_contact_damage = true

func _on_player_entered(body):
	if is_dead:
		return
	if body.name == "PostacTestowa":
		print("[ROBOT] GRACZ WYKRYTY!")
		player_ref = body
		current_chase_speed = chase_speed_min
		if !is_attacking and !is_on_cooldown:
			current_state = State.CHASE

func _on_player_exited(body):
	if body.name == "PostacTestowa":
		print("[ROBOT] Gracz wyszedł z zasięgu")
		player_ref = null
		if !is_attacking and !is_on_cooldown:
			current_state = State.IDLE
