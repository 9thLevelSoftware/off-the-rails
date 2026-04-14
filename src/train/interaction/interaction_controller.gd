class_name InteractionController
extends Node

## Handles player interaction input and delegates to nearby TrainCars.
## Uses deferred initialization to avoid timing issues with player group lookup.

var _player: Node3D = null
var _current_target: TrainCar = null


func _ready() -> void:
	call_deferred("_deferred_find_player")


func _deferred_find_player() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		_player = players[0]
	else:
		push_warning("InteractionController: No player found in 'player' group")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		_on_interact_pressed()


func _on_interact_pressed() -> void:
	if not _player:
		_deferred_find_player()
		if not _player:
			return

	var target = _find_nearest_train_car()
	if target:
		target.interact(_player)


func _find_nearest_train_car() -> TrainCar:
	if not _player:
		return null

	var train_cars = get_tree().get_nodes_in_group("train_car")
	if train_cars.is_empty():
		return null

	var nearest: TrainCar = null
	var nearest_distance := INF
	var player_pos: Vector3 = _player.global_position

	for car in train_cars:
		if car is TrainCar:
			var distance = player_pos.distance_squared_to(car.global_position)
			if distance < nearest_distance:
				nearest_distance = distance
				nearest = car

	# Only return if within interaction range (5 units squared = ~2.2 units)
	if nearest and nearest_distance < 25.0:
		return nearest
	return null


## Returns the currently targeted train car, if any.
func get_current_target() -> TrainCar:
	return _current_target


## Manually set the player reference (useful for testing).
func set_player(player: Node3D) -> void:
	_player = player
