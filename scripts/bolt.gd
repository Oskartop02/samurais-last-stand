extends CharacterBody2D

@export var attack_damage = 50
@export var SPEED = 700
@export var MAX_RANGE = 69420

var direction: int = 1  # Kierunek strzały: 1 (w dół) lub -1 (w górę)
var distance_travelled: float = 0

@onready var area: Area2D = $shoot

func _ready():
	# Sprawdź poprawność obiektu Area2D
	if not area:
		print("Error: Area2D not found!")
		return
	
	# Podłącz sygnał kolizji do funkcji
	area.body_entered.connect(Callable(self, "_on_body_entered"))

func _physics_process(delta):
	# Ruch strzały wyłącznie w pionie (oś Y)
	position += Vector2(0, SPEED * direction) * delta
	
	# Aktualizacja przebytej odległości
	distance_travelled += SPEED * delta
	
	# Usuń strzałę, jeśli przebyła maksymalny zasięg
	if distance_travelled > MAX_RANGE:
		queue_free()
	if is_on_wall():
		queue_free()

func _on_body_entered(body: Node):
	# Zadaj obrażenia, jeśli obiekt ma metodę "take_damage"
	if body.has_method("take_damage_p"):
		body.take_damage_p(attack_damage)
		queue_free()
