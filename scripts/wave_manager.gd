extends Node2D

# ============================================================
# WAVE MANAGER - System fal boss fightu scena 3
# 4 generatory = 4 fale wrogów
# Po zabiciu wrogów z fali -> generator staje się niszczalny
# Po zniszczeniu generatora -> następna fala
# Po zniszczeniu 4 generatorów -> AI boss umiera
# ============================================================

# Sceny wrogów do spawnowania
var enemy_scenes = {
	"zombie": preload("res://characters/wrog_testowy.tscn"),
	"samurai": preload("res://characters/samurai.tscn"),
	"assasin": preload("res://characters/assasin.tscn"),
}

# Konfiguracja fal
# Każda fala: tablica wrogów do zespawnowania
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

# Pozycje generatorów (w kolejności fal) - nazwy node'ów
var generator_names = ["generator", "generator3", "generator4", "generator2"]

# Spawn area (X zakres w boss roomie)
var spawn_x_min = 5800.0
var spawn_x_max = 8800.0
var spawn_y = 1669.0  # Poziom podłogi

var current_wave = -1  # -1 = jeszcze nie zaczęto
var wave_active = false
var enemies_alive = 0
var spawned_enemies = []  # Referencje do żywych wrogów
var generators_destroyed = 0
var boss_fight_started = false

var current_generator = null  # Aktualny generator do odblokowania

func _ready():
	add_to_group("wave_manager")
	print("[WAVE] Wave Manager gotowy. Czekam na wejście do boss roomu.")

func start_boss_fight():
	if boss_fight_started:
		return
	boss_fight_started = true
	print("[WAVE] === BOSS FIGHT START ===")
	# Krótkie opóźnienie przed pierwszą falą
	await get_tree().create_timer(2.0).timeout
	start_next_wave()

func start_next_wave():
	current_wave += 1
	if current_wave >= waves.size():
		print("[WAVE] Wszystkie fale ukończone!")
		return
	
	wave_active = true
	enemies_alive = 0
	spawned_enemies.clear()
	
	print("[WAVE] === FALA ", current_wave + 1, "/", waves.size(), " ===")
	print("[WAVE] Wrogów do zespawnowania: ", waves[current_wave].size())
	
	# Spawn wrogów z opóźnieniem (nie wszystkich naraz)
	var wave_enemies = waves[current_wave]
	for i in range(wave_enemies.size()):
		if get_tree() == null:
			return
		await get_tree().create_timer(0.8).timeout  # Opóźnienie między spawnami
		if get_tree() == null:
			return
		spawn_enemy(wave_enemies[i])

func spawn_enemy(enemy_type: String):
	if !enemy_scenes.has(enemy_type):
		print("[WAVE] Nieznany typ wroga: ", enemy_type)
		return
	
	var enemy_scene = enemy_scenes[enemy_type]
	var enemy = enemy_scene.instantiate()
	
	# Losowa pozycja X w boss roomie
	var spawn_x = randf_range(spawn_x_min, spawn_x_max)
	# Spawn nad podłogą — grawitacja je ściągnie
	enemy.global_position = Vector2(spawn_x, spawn_y - 200)
	
	# Dodaj do sceny
	get_tree().current_scene.add_child(enemy)
	
	enemies_alive += 1
	spawned_enemies.append(enemy)
	
	print("[WAVE] Zespawnowano: ", enemy_type, " na X=", snapped(spawn_x, 1), " | żywi: ", enemies_alive)

func _physics_process(_delta):
	if !wave_active:
		return
	
	# Monitoruj żywych wrogów
	var alive_count = 0
	for enemy in spawned_enemies:
		if is_instance_valid(enemy) and !enemy.is_dead:
			alive_count += 1
	
	if alive_count != enemies_alive:
		enemies_alive = alive_count
		print("[WAVE] Wrogów pozostało: ", enemies_alive)
	
	# Jeśli wszyscy zabici - fala ukończona
	if enemies_alive == 0 and spawned_enemies.size() > 0:
		wave_cleared()

func wave_cleared():
	wave_active = false
	print("[WAVE] === FALA ", current_wave + 1, " UKOŃCZONA! ===")
	print("[WAVE] Odblokowanie generatora: ", generator_names[current_wave])
	
	# Odblokuj odpowiedni generator
	if current_wave < generator_names.size():
		var gen_name = generator_names[current_wave]
		var generator = get_tree().current_scene.get_node_or_null(gen_name)
		if generator and generator.has_method("make_vulnerable"):
			generator.make_vulnerable()
			current_generator = generator
			print("[WAVE] Generator ", gen_name, " odblokowany!")
		else:
			print("[WAVE] BŁĄD: Nie znaleziono generatora: ", gen_name)

func on_generator_destroyed():
	generators_destroyed += 1
	print("[WAVE] Generator zniszczony! (", generators_destroyed, "/4)")
	current_generator = null
	
	# Następna fala po krótkim opóźnieniu
	if current_wave + 1 < waves.size():
		if get_tree() == null:
			return
		await get_tree().create_timer(2.0).timeout
		start_next_wave()
	else:
		print("[WAVE] === WSZYSTKIE GENERATORY ZNISZCZONE! ===")
		# AI boss umiera (obsługiwane przez ai.gd sprawdzające GameControler.zniszczone)
