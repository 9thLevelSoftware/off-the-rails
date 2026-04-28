class_name TrainCarRegistry
extends RefCounted

## Registry for TrainCar content type.
## Wraps TrainCarData resources with ID-based lookup.
##
## The registry supports two data sources:
## 1. Godot Resource files (.tres) - for base game content
## 2. JSON dictionaries - for mod content
##
## Both are converted to TrainCarData for uniform access.
## This registry handles both train cars and subsystems (distinguished by type field).

signal train_car_registered(car_id: String)
signal train_car_overwritten(car_id: String, old_source: String, new_source: String)

var _train_cars: Dictionary = {}  # id -> TrainCarData
var _sources: Dictionary = {}     # id -> source string (e.g., "base" or mod_id)


## Register a train car from a TrainCarData resource.
func register_train_car(train_car: TrainCarData, source: String = "base") -> void:
	if not train_car or train_car.id.is_empty():
		push_warning("TrainCarRegistry: Attempted to register invalid train car")
		return

	if _train_cars.has(train_car.id):
		var old_source: String = _sources.get(train_car.id, "unknown")
		train_car_overwritten.emit(train_car.id, old_source, source)

	_train_cars[train_car.id] = train_car
	_sources[train_car.id] = source
	train_car_registered.emit(train_car.id)


## Get a train car by ID, returns null if not found.
func get_train_car(id: String) -> TrainCarData:
	return _train_cars.get(id)


## Get all registered train cars (both cars and subsystems).
func get_all() -> Array[TrainCarData]:
	var result: Array[TrainCarData] = []
	for train_car in _train_cars.values():
		result.append(train_car)
	return result


## Get all train car IDs.
func get_all_ids() -> Array[String]:
	var result: Array[String] = []
	for id in _train_cars.keys():
		result.append(id)
	return result


## Check if a train car is registered.
func has_train_car(id: String) -> bool:
	return id in _train_cars


## Get the source of a train car (which mod or "base").
func get_train_car_source(id: String) -> String:
	return _sources.get(id, "")


## Get count of registered train cars.
func count() -> int:
	return _train_cars.size()


## Get only car-type entries (not subsystems).
func get_cars_only() -> Array[TrainCarData]:
	var result: Array[TrainCarData] = []
	for train_car in _train_cars.values():
		if train_car.is_car():
			result.append(train_car)
	return result


## Get only subsystem-type entries.
func get_subsystems_only() -> Array[TrainCarData]:
	var result: Array[TrainCarData] = []
	for train_car in _train_cars.values():
		if train_car.is_subsystem():
			result.append(train_car)
	return result


## Get cars by category.
func get_by_category(category: String) -> Array[TrainCarData]:
	var result: Array[TrainCarData] = []
	for train_car in _train_cars.values():
		if train_car.category == category:
			result.append(train_car)
	return result


## Get cars by acquisition phase.
func get_by_acquisition(acquisition: String) -> Array[TrainCarData]:
	var result: Array[TrainCarData] = []
	for train_car in _train_cars.values():
		if train_car.acquisition == acquisition:
			result.append(train_car)
	return result


## Get cars with crew stations.
func get_crew_stations() -> Array[TrainCarData]:
	var result: Array[TrainCarData] = []
	for train_car in _train_cars.values():
		if train_car.crew_station:
			result.append(train_car)
	return result


## Get cars that have a specific subsystem.
func get_cars_with_subsystem(subsystem_id: String) -> Array[TrainCarData]:
	var result: Array[TrainCarData] = []
	for train_car in _train_cars.values():
		if train_car.has_subsystem(subsystem_id):
			result.append(train_car)
	return result


## Load train cars from a JSON data dictionary.
## Expected format: {"train_cars": [{id, name, type, category, subsystems, ...}, ...]}
## Returns count of train cars loaded.
func load_from_data(data: Dictionary, source: String = "base") -> int:
	if not data.has("train_cars"):
		return 0

	var train_cars_array = data.get("train_cars")
	if not train_cars_array is Array:
		push_warning("TrainCarRegistry: 'train_cars' must be an array")
		return 0

	var loaded_count := 0
	for car_data in train_cars_array:
		if not car_data is Dictionary:
			continue
		var train_car := _create_from_dict(car_data)
		if train_car:
			register_train_car(train_car, source)
			loaded_count += 1

	return loaded_count


## Create a TrainCarData from a dictionary.
## Handles the conversion from JSON format to Godot resource.
func _create_from_dict(data: Dictionary) -> TrainCarData:
	var id: String = data.get("id", "")
	if id.is_empty():
		push_warning("TrainCarRegistry: TrainCar missing required 'id' field")
		return null

	var train_car := TrainCarData.new()
	train_car.id = id
	train_car.name = data.get("name", id)
	train_car.description = data.get("description", "")
	train_car.type = data.get("type", "car")
	train_car.category = data.get("category", "utility")
	train_car.acquisition = data.get("acquisition", "starting")
	train_car.crew_station = data.get("crew_station", false)
	train_car.upgrade_tree = data.get("upgrade_tree", "")
	train_car.damage_effect = data.get("damage_effect", "")

	# Handle subsystems array
	var subsystems = data.get("subsystems", [])
	if subsystems is Array:
		train_car.subsystems = []
		for sub in subsystems:
			train_car.subsystems.append(str(sub))

	# Handle dependencies array
	var dependencies = data.get("dependencies", [])
	if dependencies is Array:
		train_car.dependencies = []
		for dep in dependencies:
			train_car.dependencies.append(str(dep))

	return train_car


## Clear all registered train cars.
func clear() -> void:
	_train_cars.clear()
	_sources.clear()
