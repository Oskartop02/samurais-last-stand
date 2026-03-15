extends Node

# ============================================================
# GAME CONTROLLER + WAVE MANAGER
# Singleton (autoload) zarządzający boss fightem scena 3
# ============================================================

var zniszczone = 0  # Liczba zniszczonych generatorów

# --- WAVE SYSTEM ---
var enemy_scenes = {}
var waves = [
	# Fala 1 - łatwa (zombie)
	["zombie", "zombie", "zombie", "zombie", "zombie"],
	# Fala 2 - średnia (zombie + samuraje)
	["zombie", "zombie", "samurai", "samurai", "zombie", "samurai"],
	# Fala 3 - trudna (samuraje + assasin)
	["samurai", "samurai", "assasin", "zombie", "samurai", "assasin"],
	# Fala 4 - boss rush (assasiny + samuraje)
	["assasin", "samurai", "assasin", "samurai", "assasin", "samurai", "assasin"],
]

var generator_names = ["generator", "generator3", "generator4", "generator2"]

var spawn_x_min = 6200.0  # Wewnątrz bossroomu (za pierwszym generatorem)
var spawn_x_max = 8400.0  # Wewnątrz bossroomu (przed ostatnim generatorem)
var spawn_y = 1818.0  # Pozycja podłogi bossroomu (taka jak istniejące zombie)
var enemy_spawn_min_player_distance = 700.0

# Granice bossroomu - wrogowie nie mogą wyjść poza ten zakres
var bossroom_x_min = 5400.0
var bossroom_x_max = 9100.0

var current_wave = -1
var wave_active = false
var enemies_alive = 0
var spawned_enemies = []
var boss_fight_started = false
var scenes_loaded = false
var spawn_complete = false
var wave_spawn_time = 0.0  # Czas od zakończenia spawnu fali
var WAVE_MIN_TIME = 1.5  # Min. czas po spawnie zanim fala może się skończyć
var _fight_session_id = 0

func on_enemy_died():
	zniszczone += 1
	print("[GAME] Zniszczono generatorów: " + str(zniszczone) + "/4")

func _load_enemy_scenes():
	if scenes_loaded:
		return
	enemy_scenes = {
		"zombie": load("res://characters/wrog_testowy.tscn"),
		"samurai": load("res://characters/samurai.tscn"),
		"assasin": load("res://characters/assasin.tscn"),
	}
	_load_enemy_scripts()
	scenes_loaded = true
	print("[WAVE] Sceny wrogów załadowane")

func reset_waves():
	_fight_session_id += 1
	zniszczone = 0
	current_wave = -1
	wave_active = false
	boss_fight_started = false
	spawn_complete = false
	for enemy in spawned_enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	spawned_enemies.clear()
	enemies_alive = 0
	wave_spawn_time = 0.0

func start_boss_fight():
	if boss_fight_started:
		return
	_fight_session_id += 1
	var session_id = _fight_session_id
	boss_fight_started = true
	_load_enemy_scenes()
	print("[WAVE] === BOSS FIGHT START ===")
	var tree = Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	await tree.create_timer(2.0).timeout
	if session_id != _fight_session_id or !boss_fight_started:
		return
	start_next_wave(session_id)

func start_next_wave(session_id: int = _fight_session_id):
	if session_id != _fight_session_id or !boss_fight_started:
		return
	current_wave += 1
	if current_wave >= waves.size():
		print("[WAVE] Wszystkie fale ukończone!")
		return
	
	wave_active = true
	enemies_alive = 0
	spawned_enemies.clear()
	spawn_complete = false
	
	print("[WAVE] === FALA ", current_wave + 1, "/", waves.size(), " ===")
	
	var wave_enemies = waves[current_wave]
	for i in range(wave_enemies.size()):
		var tree = Engine.get_main_loop() as SceneTree
		if tree == null:
			return
		await tree.create_timer(0.8).timeout
		if session_id != _fight_session_id or !boss_fight_started:
			return
		spawn_enemy(wave_enemies[i])
	
	spawn_complete = true
	wave_spawn_time = 0.0  # Reset timera - zaczynamy liczyć od teraz
	print("[WAVE] Wszyscy wrogowie zespawnowani: ", spawned_enemies.size())

# Skrypty wrogów (zombie nie ma skryptu w tscn, trzeba przypisać ręcznie)
var enemy_scripts = {}

func _load_enemy_scripts():
	enemy_scripts = {
		"zombie": load("res://scripts/wrog_testowy.gd"),
		"samurai": load("res://scripts/samurai.gd"),
		"assasin": load("res://scripts/assasin.gd"),
	}

func _get_spawn_floor_y(scene_root: Node) -> float:
	var reference_names = ["wrog_testowy6", "wrog_testowy7", "wrog_testowy8", "Samurai", "Samurai2", "assasin", "assasin2"]
	for node_name in reference_names:
		var reference_enemy = scene_root.get_node_or_null(node_name)
		if reference_enemy and reference_enemy is Node2D:
			return reference_enemy.position.y
	return spawn_y

func _setup_spawned_enemy_collisions(enemy: CharacterBody2D, scene_root: Node) -> void:
	var player = scene_root.get_node_or_null("PostacTestowa")
	if player and player is PhysicsBody2D:
		enemy.add_collision_exception_with(player)
	for child in scene_root.get_children():
		if child == enemy:
			continue
		if child is PhysicsBody2D and child.has_method("take_damage"):
			enemy.add_collision_exception_with(child)
			child.add_collision_exception_with(enemy)

func spawn_enemy(enemy_type: String):
	if !enemy_scenes.has(enemy_type):
		print("[WAVE] Nieznany typ: ", enemy_type)
		return
	
	var tree = Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	var scene_root = tree.current_scene
	if scene_root == null:
		return
	
	var enemy = enemy_scenes[enemy_type].instantiate()
	var spawn_x = _get_spawn_x_with_player_distance(scene_root, enemy_type)
	var floor_y = _get_spawn_floor_y(scene_root)
	enemy.position = Vector2(spawn_x, floor_y)
	
	# Przypisz skrypt jeśli go nie ma (zombie nie ma skryptu w tscn)
	if enemy.get_script() == null and enemy_scripts.has(enemy_type):
		enemy.set_script(enemy_scripts[enemy_type])
		print("[WAVE] Przypisano skrypt dla: ", enemy_type)
	
	# Layer 2 = wróg, mask 2 = platformy/sceneria z bitem 2.
	# Dzięki temu graczowy AttackArea (mask 3) trafia wrogów,
	# ale lasery/pociski na layer 1 nie blokują ich fizycznie.
	enemy.collision_layer = 2
	enemy.collision_mask = 2
	
	scene_root.add_child(enemy)
	_setup_spawned_enemy_collisions(enemy, scene_root)
	
	enemies_alive += 1
	spawned_enemies.append(enemy)
	
	print("[WAVE] Spawn: ", enemy_type, " X=", snapped(spawn_x, 1), " Y=", floor_y, " | żywi: ", enemies_alive)

func _get_spawn_x_with_player_distance(scene_root: Node, enemy_type: String) -> float:
	var player = scene_root.get_node_or_null("PostacTestowa")
	if player == null or !(player is Node2D):
		return randf_range(spawn_x_min, spawn_x_max)

	var player_x = (player as Node2D).position.x
	var forbidden_min = player_x - enemy_spawn_min_player_distance
	var forbidden_max = player_x + enemy_spawn_min_player_distance

	var left_min = spawn_x_min
	var left_max = min(spawn_x_max, forbidden_min)
	var right_min = max(spawn_x_min, forbidden_max)
	var right_max = spawn_x_max

	var left_width = max(0.0, left_max - left_min)
	var right_width = max(0.0, right_max - right_min)

	if left_width > 0.0 and right_width > 0.0:
		var total_width = left_width + right_width
		if randf() < left_width / total_width:
			return randf_range(left_min, left_max)
		return randf_range(right_min, right_max)
	if left_width > 0.0:
		return randf_range(left_min, left_max)
	if right_width > 0.0:
		return randf_range(right_min, right_max)

	var left_x = spawn_x_min
	var right_x = spawn_x_max
	if abs(left_x - player_x) > abs(right_x - player_x):
		return left_x
	return right_x

func _physics_process(delta):
	if !wave_active or !spawn_complete:
		return
	var tree = Engine.get_main_loop() as SceneTree
	if tree and tree.current_scene:
		_update_bossroom_bounds(tree.current_scene)
	
	# Odliczaj czas od zakończenia spawnu
	wave_spawn_time += delta
	
	# Ogranicz pozycje wrogów do bossroomu (koordynaty lokalne)
	for enemy in spawned_enemies:
		if is_instance_valid(enemy) and enemy.get("is_dead") == false:
			if enemy.position.x < bossroom_x_min:
				enemy.position.x = bossroom_x_min
				if enemy.has_method("force_bossroom_rebound"):
					enemy.force_bossroom_rebound(1)
				elif enemy.get("direction") != null:
					enemy.direction = 1
					if enemy.has_method("update_animation"):
						enemy.update_animation()
			elif enemy.position.x > bossroom_x_max:
				enemy.position.x = bossroom_x_max
				if enemy.has_method("force_bossroom_rebound"):
					enemy.force_bossroom_rebound(-1)
				elif enemy.get("direction") != null:
					enemy.direction = -1
					if enemy.has_method("update_animation"):
						enemy.update_animation()
	
	if wave_spawn_time < WAVE_MIN_TIME:
		return  # Za wcześnie - daj czas na inicjalizację wrogów
	
	var alive_count = 0
	for enemy in spawned_enemies:
		if is_instance_valid(enemy) and enemy.get("is_dead") == false:
			alive_count += 1
	
	if alive_count != enemies_alive:
		enemies_alive = alive_count
		print("[WAVE] Pozostało: ", enemies_alive)
	
	if enemies_alive == 0:
		wave_cleared()

func wave_cleared():
	wave_active = false
	print("[WAVE] === FALA ", current_wave + 1, " UKOŃCZONA! ===")
	
	if current_wave < generator_names.size():
		var tree = Engine.get_main_loop() as SceneTree
		if tree == null:
			return
		var gen = tree.current_scene.get_node_or_null(generator_names[current_wave])
		if gen and gen.has_method("make_vulnerable"):
			gen.make_vulnerable()
			print("[WAVE] Generator ", generator_names[current_wave], " odblokowany!")
		else:
			print("[WAVE] BŁĄD: Nie znaleziono generatora: ", generator_names[current_wave])

func on_generator_destroyed():
	print("[WAVE] Generator zniszczony! Następna fala za 2s...")
	if current_wave + 1 < waves.size():
		var session_id = _fight_session_id
		var tree = Engine.get_main_loop() as SceneTree
		if tree == null:
			return
		await tree.create_timer(2.0).timeout
		if session_id != _fight_session_id or !boss_fight_started:
			return
		start_next_wave(session_id)
	else:
		print("[WAVE] === WSZYSTKIE GENERATORY ZNISZCZONE! ===")

func _update_bossroom_bounds(scene_root: Node) -> void:
	var bossroom_area = scene_root.get_node_or_null("Bosroom")
	if bossroom_area == null:
		return
	var cs = bossroom_area.get_node_or_null("CollisionShape2D")
	if cs == null:
		return
	if !(cs.shape is RectangleShape2D):
		return
	var rect_shape = cs.shape as RectangleShape2D
	var center_x = bossroom_area.position.x + cs.position.x
	var half_width = rect_shape.size.x * 0.5
	var margin = 40.0
	bossroom_x_min = center_x - half_width + margin
	bossroom_x_max = center_x + half_width - margin
