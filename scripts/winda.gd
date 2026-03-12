extends StaticBody2D

@export var docelowa_wysokosc = 2375
@export var predkosc = 200

var poczatkowa_pozycja : Vector2
var _ostatnia_pozycja : Vector2

func _ready():
	poczatkowa_pozycja = position
	_ostatnia_pozycja = global_position
	constant_linear_velocity = Vector2.ZERO
	if $CollisionShape2D and $Sprite2D:
		print("Początkowa pozycja: ", poczatkowa_pozycja)
	else:
		print("Brak CollisionShape2D lub Sprite2D!")

func _physics_process(delta):
	if $CollisionShape2D and $Sprite2D:
		var docelowe_y = poczatkowa_pozycja.y + abs(docelowa_wysokosc)
		if position.y < docelowe_y:
			var ruch = predkosc * delta
			position.y = min(position.y + ruch, docelowe_y)
		var nowa_pozycja = global_position
		constant_linear_velocity = (nowa_pozycja - _ostatnia_pozycja) / max(delta, 0.0001)
		_ostatnia_pozycja = nowa_pozycja
	else:
		constant_linear_velocity = Vector2.ZERO
		print("Brak CollisionShape2D lub Sprite2D!")
