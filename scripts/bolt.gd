extends CharacterBody2D

@export var attack_damage = 50
@export var SPEED = 700
@export var MAX_RANGE = 69420
@export var arm_time = 0.08

var direction: int = 1  # Kierunek strzały: 1 (w dół) lub -1 (w górę)
var distance_travelled: float = 0
var _arm_left: float = 0.0

func _ready():
	collision_layer = 0
	collision_mask = 0
	_arm_left = arm_time

func _physics_process(delta):
	var motion = Vector2(0, SPEED * direction) * delta

	if _arm_left > 0.0:
		position += motion
		distance_travelled += motion.length()
		_arm_left -= delta
		if distance_travelled > MAX_RANGE:
			queue_free()
		return

	var from_pos = global_position
	var to_pos = global_position + motion
	var ray_hit = _raycast_hit(from_pos, to_pos)
	if ray_hit:
		_handle_hit(ray_hit)
		return

	position = to_pos
	
	# Aktualizacja przebytej odległości
	distance_travelled += motion.length()
	
	# Usuń strzałę, jeśli przebyła maksymalny zasięg
	if distance_travelled > MAX_RANGE:
		queue_free()
func _handle_hit(body: Node):
	# Zadaj obrażenia, jeśli obiekt ma metodę "take_damage"
	if body.name == "PostacTestowa":
		if body.has_method("die"):
			body.die()
		elif body.has_method("take_damage_p"):
			body.take_damage_p(attack_damage)
	elif body.has_method("take_damage_p"):
		body.take_damage_p(attack_damage)
	queue_free()

func _raycast_hit(from_pos: Vector2, to_pos: Vector2) -> Node:
	if from_pos.distance_to(to_pos) < 0.001:
		return null
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(from_pos, to_pos)
	query.collision_mask = 1
	query.exclude = [get_rid()]
	query.hit_from_inside = true
	var result = space_state.intersect_ray(query)
	if result.has("collider"):
		return result["collider"] as Node
	return null
