extends StaticBody2D

@export var docelowa_wysokosc = 2375
@export var predkosc = 200

var poczatkowa_pozycja : Vector2

func _ready():
	poczatkowa_pozycja = position
	constant_linear_velocity = Vector2.ZERO
	if $CollisionShape2D and $Sprite2D:
		print("Początkowa pozycja: ", poczatkowa_pozycja)
	else:
		print("Brak CollisionShape2D lub Sprite2D!")

func _physics_process(delta):
	if $CollisionShape2D and $Sprite2D:
		var docelowe_y = poczatkowa_pozycja.y + abs(docelowa_wysokosc)
		var moved_distance = 0.0
		if position.y < docelowe_y:
			var ruch = predkosc * delta
			var nowe_y = min(position.y + ruch, docelowe_y)
			moved_distance = nowe_y - position.y
			position.y = nowe_y
		constant_linear_velocity = Vector2(0, moved_distance / max(delta, 0.0166667))
	else:
		constant_linear_velocity = Vector2.ZERO
		print("Brak CollisionShape2D lub Sprite2D!")
