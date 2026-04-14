class_name TrainCarFactory
extends RefCounted

## Factory for creating train car instances from CarData resources.
## Loads car configurations from data/cars/ directory for data-driven instantiation.

const CAR_DATA_DIR := "res://data/cars/"

var _scene_cache: Dictionary = {}
var _car_data_cache: Dictionary = {}  # car_id -> CarData


func _init() -> void:
	_load_car_data_resources()


## Load all CarData resources from the data directory.
func _load_car_data_resources() -> void:
	_car_data_cache.clear()
	var dir = DirAccess.open(CAR_DATA_DIR)
	if not dir:
		push_error("TrainCarFactory: Cannot open car data directory '%s'" % CAR_DATA_DIR)
		return

	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var resource_path = CAR_DATA_DIR + file_name
			var car_data = load(resource_path) as CarData
			if car_data and car_data.car_id != "":
				_car_data_cache[car_data.car_id] = car_data
		file_name = dir.get_next()
	dir.list_dir_end()


## Get CarData for a car_id, or null if not found.
func get_car_data(car_id: String) -> CarData:
	return _car_data_cache.get(car_id)


## Create a train car instance by car_id.
## Uses CarData resource for scene_path lookup.
## Returns null if car_id is unknown or scene fails to load.
func create_car(car_id: String) -> TrainCar:
	var car_data = get_car_data(car_id)
	if not car_data:
		push_error("TrainCarFactory: Unknown car_id '%s'" % car_id)
		return null

	if car_data.scene_path == "":
		push_error("TrainCarFactory: CarData '%s' has empty scene_path" % car_id)
		return null

	var scene = _get_or_load_scene(car_data.scene_path)
	if not scene:
		push_error("TrainCarFactory: Failed to load scene '%s'" % car_data.scene_path)
		return null

	var car_instance = scene.instantiate() as TrainCar
	if not car_instance:
		push_error("TrainCarFactory: Scene '%s' root is not a TrainCar" % car_data.scene_path)
		return null

	return car_instance


## Create a train car from a CarData resource directly.
func create_car_from_data(car_data: CarData) -> TrainCar:
	if not car_data:
		push_error("TrainCarFactory: Invalid car data resource")
		return null

	return create_car(car_data.car_id)


## Get all starting car data resources sorted by default_position.
## Returns array of CarData for engine and workshop cars.
func get_starting_car_data() -> Array[CarData]:
	var starting_ids := ["engine", "workshop"]
	var car_data_list: Array[CarData] = []

	for car_id in starting_ids:
		var car_data = get_car_data(car_id)
		if car_data:
			car_data_list.append(car_data)

	# Sort by default_position
	car_data_list.sort_custom(func(a: CarData, b: CarData) -> bool:
		return a.default_position < b.default_position
	)

	return car_data_list


## Load scene from cache or disk.
func _get_or_load_scene(path: String) -> PackedScene:
	if _scene_cache.has(path):
		return _scene_cache[path]
	var scene = load(path) as PackedScene
	if scene:
		_scene_cache[path] = scene
	return scene


## Clear all caches (useful for hot-reloading during development).
func clear_cache() -> void:
	_scene_cache.clear()
	_car_data_cache.clear()
	_load_car_data_resources()


## Returns array of all available car_ids from loaded CarData resources.
func get_available_car_ids() -> Array[String]:
	var ids: Array[String] = []
	for key in _car_data_cache.keys():
		ids.append(key)
	return ids
