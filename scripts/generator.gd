extends CharacterBody2D

@export var speed = 100
@export var health = 3
@export var damage = 10

var max_health = 3
var is_dead = false
var is_vulnerable = false  # Domyślnie niezniszczalny
var _active_tween: Tween = null  # Śledź aktywne tweeny
var _is_autoload = false  # Czy to instancja autoload (bez sceny)

var animated_sprite2d = null
var animated_sprite2d2 = null

func _ready():
	# Sprawdź czy to autoload (brak dzieci = załadowany jako sam skrypt)
	if get_child_count() == 0:
		_is_autoload = true
		set_physics_process(false)
		print("[GENERATOR] Autoload instance - skipping init")
		return
	
	animated_sprite2d = get_node_or_null("AnimatedSprite2D")
	animated_sprite2d2 = get_node_or_null("AnimatedSprite2D2")
	
	max_health = health
	# Wyłącz fizyczną kolizję - gracz i wrogowie przechodzą przez generator
	collision_layer = 0
	collision_mask = 0
	# Wyłącz fizyczny collision shape
	var phys_shape = get_node_or_null("CollisionShape2D")
	if phys_shape:
		phys_shape.disabled = true
	
	# Generator za postaciami ale nad tłem
	z_index = -1
	z_as_relative = true
	# Upewnij się że tło jest jeszcze niżej
	var bg = get_parent().get_node_or_null("Sprite2D")
	if bg:
		bg.z_index = -2
	
	# Podłącz hitbox do wykrywania ataków gracza (area_entered)
	var hb = get_node_or_null("hitbox69")
	if !hb:
		hb = get_node_or_null("hitbox")
	if hb:
		if !hb.is_connected("area_entered", Callable(self, "_on_hitbox_area_entered")):
			hb.connect("area_entered", Callable(self, "_on_hitbox_area_entered"))
		print("[GENERATOR] Hitbox podłączony: ", hb.name)
	
	# Wizualnie pokaż że jest niezniszczalny (ciemniejszy)
	modulate = Color(0.5, 0.5, 0.5, 1.0)
	print("[GENERATOR] Zainicjalizowany: ", name, " pos=", global_position)

func _on_hitbox_area_entered(area: Area2D):
	# Sprawdź czy to AttackArea gracza
	if area.name == "AttackArea":
		var player = area.get_parent()
		if player and player.name == "PostacTestowa" and player.get("is_attacking") == true:
			var dmg = player.get("attack_damage")
			if dmg == null:
				dmg = 10
			take_damage(dmg)
			print("[GENERATOR] Trafiony przez gracza! DMG: ", dmg)

func _physics_process(_delta):
	if _is_autoload:
		return
	# Pulsowanie gdy jest niszczalny - intensywne czerwone
	if is_vulnerable and !is_dead:
		var pulse = abs(sin(Time.get_ticks_msec() * 0.008)) * 0.5
		modulate = Color(1.0 + pulse, 0.2, 0.2, 1.0)

func make_vulnerable():
	# Zabij aktywne tweeny żeby nie nadpisały modulate
	if _active_tween and _active_tween.is_valid():
		_active_tween.kill()
		_active_tween = null
	is_vulnerable = true
	health = max_health  # Reset HP na pełne
	modulate = Color(1.0, 0.3, 0.3, 1.0)  # Czerwony = niszczalny
	# Efekt pojawienia się - flash + skalowanie
	_active_tween = create_tween()
	_active_tween.tween_property(self, "scale", Vector2(1.15, 1.15), 0.2)
	_active_tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.2)
	print("[GENERATOR] NISZCZ MNIE! HP:", health)

func take_damage(damage_amount: int) -> void:
	if is_dead:
		return
	if !is_vulnerable:
		print("[GENERATOR] Jestem niezniszczalny! Zabij wrogów najpierw!")
		return
	health -= damage_amount
	print("[GENERATOR] HP:", health)
	if health > 0:
		# Flash biały na chwilę
		if _active_tween and _active_tween.is_valid():
			_active_tween.kill()
		_active_tween = create_tween()
		_active_tween.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.1)
		_active_tween.tween_property(self, "modulate", Color(1.0, 0.3, 0.3, 1.0), 0.1).set_delay(0.1)
	if health <= 0:
		die()

func die() -> void:
	if not is_dead:
		is_dead = true
		if _active_tween and _active_tween.is_valid():
			_active_tween.kill()
		if animated_sprite2d:
			animated_sprite2d.hide()
		if animated_sprite2d2:
			animated_sprite2d2.show()
			animated_sprite2d2.play("default")
		
		# Powiadomienie kontrolera gry o śmierci generatora
		GameControler.on_enemy_died()
		
		# Powiadom wave managera o zniszczeniu
		GameControler.on_generator_destroyed()

		if animated_sprite2d2:
			animated_sprite2d2.animation_finished.connect(_on_death_animation_finished)
		else:
			queue_free()

func _on_death_animation_finished() -> void:
	queue_free()
