extends CharacterBody2D

@export var attack_damage = 10
@export var SPEED = 700
@export var MAX_RANGE = 800

var dir : float
var spawnPos : Vector2
var spawnRot : float
var distance_travelled : float = 0

@onready var area : Area2D = $shoot  # Poprawnie przypisany węzeł Area2D

func _ready():
	position = spawnPos
	rotation = spawnRot
	
	collision_layer = 0  # Pocisk nie ma fizycznej warstwy (nie przepycha ciał)
	collision_mask = 1   # Pocisk koliduje fizycznie tylko ze ścianami (warstwa 1), nie z wrogami

	# Sprawdzamy, czy Area2D jest prawidłowo przypisane
	if not area:
		print("Error: Area2D not found!")  # Debugging line to check for missing Area2D
		return
	
	# Podłącz sygnał body_entered z węzła Area2D
	area.body_entered.connect(Callable(self, "_on_body_entered"))

func _physics_process(delta):
	var move_vector = Vector2(SPEED, 0).rotated(dir)
	position += move_vector * delta  # Ruch pocisku

	# Zliczaj pokonaną odległość
	distance_travelled += move_vector.length() * delta

	# Usuń pocisk, jeśli przekroczy maksymalny zasięg
	if distance_travelled > MAX_RANGE:
		queue_free()
	if is_on_wall():
		queue_free()

# Funkcja wykrywająca kolizje
func _on_body_entered(body: Node):
	# Sprawdź, czy obiekt posiada metodę "take_damage"
	if body.has_method("take_damage"):
		# Assasin przyjmuje drugi argument (death_type)
		if body.get("player_in_range") != null:
			body.take_damage(attack_damage, "kunai")
		else:
			body.take_damage(attack_damage)
		queue_free()  # Zniszcz pocisk po trafieniu
