class_name TrainManager
extends Node

## Manages train car creation, placement, and inter-car dependencies.
## Uses two-phase initialization to ensure all nodes are ready before wiring.

var _factory: TrainCarFactory
var _cars: Array[TrainCar] = []

var _engine_car: EngineCar = null
var _workshop_car: WorkshopCar = null

signal cars_ready
signal train_started


func _ready() -> void:
	_factory = TrainCarFactory.new()
	# Phase 1: Wait for tree to settle
	await get_tree().process_frame
	# Phase 2: Create cars (no wiring)
	_create_starting_cars()
	# Phase 3: Wait again for instances to initialize
	await get_tree().process_frame
	# Phase 4: Wire dependencies
	connect_car_dependencies()
	# Phase 5: Start the train
	_start_train()


func _create_starting_cars() -> void:
	var train_cars_container = get_node_or_null("../TrainCars")
	if not train_cars_container:
		push_error("TrainManager: TrainCars container node not found")
		return

	# Create engine car at origin
	var engine = _factory.create_car("engine")
	if engine:
		engine.add_to_group("train_car")
		train_cars_container.add_child(engine)
		engine.global_position = Vector3.ZERO
		_cars.append(engine)
		if engine is EngineCar:
			_engine_car = engine

	# Create workshop car behind engine
	var workshop = _factory.create_car("workshop")
	if workshop:
		workshop.add_to_group("train_car")
		train_cars_container.add_child(workshop)
		workshop.global_position = Vector3(0, 0, 10)
		_cars.append(workshop)
		if workshop is WorkshopCar:
			_workshop_car = workshop

	cars_ready.emit()


func connect_car_dependencies() -> void:
	if _workshop_car and _engine_car:
		_workshop_car.connect_to_engine(_engine_car)


func _start_train() -> void:
	if _engine_car:
		_engine_car.start_engine()
	train_started.emit()


## Returns all train cars managed by this manager.
func get_cars() -> Array[TrainCar]:
	return _cars


## Returns the engine car, or null if not created.
func get_engine_car() -> EngineCar:
	return _engine_car


## Returns the workshop car, or null if not created.
func get_workshop_car() -> WorkshopCar:
	return _workshop_car


## Add a new car to the train at the specified position.
func add_car(car: TrainCar, position: Vector3) -> void:
	var train_cars_container = get_node_or_null("../TrainCars")
	if not train_cars_container:
		push_error("TrainManager: TrainCars container node not found")
		return

	car.add_to_group("train_car")
	train_cars_container.add_child(car)
	car.global_position = position
	_cars.append(car)
