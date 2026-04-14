class_name TrainManager
extends Node

## Manages train car creation, placement, and inter-car dependencies.
## Uses two-phase initialization to ensure all nodes are ready before wiring.
## Wire dependencies generically by capability, not by concrete car type.

var _factory: TrainCarFactory
var _cars: Array[TrainCar] = []

## Container node for train cars. Set via export or found via unique name.
@export var train_cars_container: Node3D

signal cars_ready
signal train_started


func _ready() -> void:
	_factory = TrainCarFactory.new()
	# Phase 1: Wait for tree to settle
	await get_tree().process_frame
	# Phase 2: Resolve container reference if not exported
	_resolve_container()
	# Phase 3: Create cars (no wiring)
	_create_starting_cars()
	# Phase 4: Wait again for instances to initialize
	await get_tree().process_frame
	# Phase 5: Wire dependencies
	_connect_car_dependencies()
	# Phase 6: Start the train
	_start_train()


func _resolve_container() -> void:
	if train_cars_container:
		return
	# Try unique node reference first, then fallback to relative path
	train_cars_container = get_node_or_null("%TrainCars")
	if not train_cars_container:
		train_cars_container = get_node_or_null("../TrainCars")
	if not train_cars_container:
		push_error("TrainManager: TrainCars container node not found")


func _create_starting_cars() -> void:
	if not train_cars_container:
		return

	# Create engine car at origin
	var engine = _factory.create_car("engine")
	if engine:
		engine.add_to_group("train_car")
		train_cars_container.add_child(engine)
		engine.global_position = Vector3.ZERO
		_cars.append(engine)

	# Create workshop car behind engine
	var workshop = _factory.create_car("workshop")
	if workshop:
		workshop.add_to_group("train_car")
		train_cars_container.add_child(workshop)
		workshop.global_position = Vector3(0, 0, 10)
		_cars.append(workshop)

	cars_ready.emit()


## Wires power dependencies between cars generically.
## Finds power provider(s) by checking for PowerSource subsystems,
## then connects power consumers (subsystems with requires_power) to them.
func _connect_car_dependencies() -> void:
	var power_provider: TrainCar = _find_power_provider()
	if not power_provider:
		push_warning("TrainManager: No power provider car found")
		return

	for car in _cars:
		if car == power_provider:
			continue
		_connect_power_consumer(car, power_provider)


## Finds the first car that has a PowerSource subsystem.
func _find_power_provider() -> TrainCar:
	for car in _cars:
		var power_subsystem = car.get_subsystem_by_name("Power Grid")
		if power_subsystem and power_subsystem is PowerSource:
			return car
	return null


## Connects a car's power-requiring subsystems to a power provider.
func _connect_power_consumer(consumer_car: TrainCar, provider_car: TrainCar) -> void:
	# If consumer car has a connect_to_power_provider method, use it
	if consumer_car.has_method("connect_to_power_provider"):
		consumer_car.connect_to_power_provider(provider_car)


func _start_train() -> void:
	# Find and start the engine car by checking for locomotion capability
	for car in _cars:
		if car.has_method("start_engine"):
			car.start_engine()
			break
	train_started.emit()


## Returns all train cars managed by this manager.
func get_cars() -> Array[TrainCar]:
	return _cars


## Returns a car by its car_id, or null if not found.
func get_car_by_id(car_id: String) -> TrainCar:
	for car in _cars:
		if car.car_id == car_id:
			return car
	return null


## Add a new car to the train at the specified position.
func add_car(car: TrainCar, position: Vector3) -> void:
	if not train_cars_container:
		push_error("TrainManager: TrainCars container node not found")
		return

	car.add_to_group("train_car")
	train_cars_container.add_child(car)
	car.global_position = position
	_cars.append(car)
