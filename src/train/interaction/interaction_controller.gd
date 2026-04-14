class_name InteractionController
extends Node

## Handles player interaction input and delegates to nearby TrainCars or interactables.
## Uses deferred initialization to avoid timing issues with player group lookup.
## Priority: train_car first, then generic interactable group.

## Maximum distance for interaction detection (squared for performance)
const INTERACTION_RANGE_SQ := 25.0  # ~5 units

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

	# Priority 1: Train car interaction
	var train_car := _find_nearest_train_car()
	if train_car:
		train_car.interact(_player)
		return

	# Priority 2: Generic interactable (expedition loot containers, etc.)
	var interactable := _find_nearest_interactable()
	if interactable and interactable.has_method("interact"):
		interactable.interact(_player)


func _find_nearest_train_car() -> TrainCar:
	if not _player:
		return null

	var train_cars := get_tree().get_nodes_in_group("train_car")
	if train_cars.is_empty():
		return null

	var nearest: TrainCar = null
	var nearest_distance := INF
	var player_pos: Vector3 = _player.global_position

	for car in train_cars:
		if car is TrainCar:
			var distance := player_pos.distance_squared_to(car.global_position)
			if distance < nearest_distance:
				nearest_distance = distance
				nearest = car

	if nearest and nearest_distance < INTERACTION_RANGE_SQ:
		return nearest
	return null


## Finds the nearest node in "interactable" group that has an interact() method.
func _find_nearest_interactable() -> Node:
	if not _player:
		return null

	var interactables := get_tree().get_nodes_in_group("interactable")
	if interactables.is_empty():
		return null

	var nearest: Node = null
	var nearest_distance := INF
	var player_pos: Vector3 = _player.global_position

	for interactable in interactables:
		if not interactable.has_method("interact"):
			continue
		# Support both Node3D and Node2D positions
		var interactable_pos: Vector3
		if interactable is Node3D:
			interactable_pos = interactable.global_position
		elif interactable is Node2D:
			interactable_pos = Vector3(interactable.global_position.x, interactable.global_position.y, 0.0)
		else:
			continue

		var distance := player_pos.distance_squared_to(interactable_pos)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest = interactable

	if nearest and nearest_distance < INTERACTION_RANGE_SQ:
		return nearest
	return null


## Returns the currently targeted train car, if any.
func get_current_target() -> TrainCar:
	return _current_target


## Manually set the player reference (useful for testing).
func set_player(player: Node3D) -> void:
	_player = player
