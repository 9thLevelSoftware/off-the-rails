class_name TrainCarFactory
extends RefCounted

## Factory for creating train car instances from scene templates.
## Supports both direct car_id creation and data-driven configuration.

const CAR_SCENES := {
	"engine": "res://src/train/cars/engine.tscn",
	"workshop": "res://src/train/cars/workshop.tscn"
}

var _scene_cache: Dictionary = {}


## Create a train car instance by car_id.
## Returns null if car_id is unknown or scene fails to load.
func create_car(car_id: String) -> TrainCar:
	var scene_path = CAR_SCENES.get(car_id)
	if not scene_path:
		push_error("TrainCarFactory: Unknown car_id '%s'" % car_id)
		return null

	var scene = _get_or_load_scene(scene_path)
	if not scene:
		push_error("TrainCarFactory: Failed to load scene '%s'" % scene_path)
		return null

	var car_instance = scene.instantiate() as TrainCar
	if not car_instance:
		push_error("TrainCarFactory: Scene '%s' root is not a TrainCar" % scene_path)
		return null

	return car_instance


## Create a train car from a data resource.
## The resource must implement get_car_id() and optionally apply_to_car().
func create_car_from_data(car_data: Resource) -> TrainCar:
	if not car_data or not car_data.has_method("get_car_id"):
		push_error("TrainCarFactory: Invalid car data resource")
		return null

	var car = create_car(car_data.get_car_id())
	if car and car_data.has_method("apply_to_car"):
		car_data.apply_to_car(car)
	return car


## Create the default starting cars for a new game.
## Returns an array containing engine and workshop cars.
func create_starting_cars() -> Array[TrainCar]:
	var cars: Array[TrainCar] = []
	var engine = create_car("engine")
	if engine:
		cars.append(engine)
	var workshop = create_car("workshop")
	if workshop:
		cars.append(workshop)
	return cars


## Load scene from cache or disk.
func _get_or_load_scene(path: String) -> PackedScene:
	if _scene_cache.has(path):
		return _scene_cache[path]
	var scene = load(path) as PackedScene
	if scene:
		_scene_cache[path] = scene
	return scene


## Clear the scene cache (useful for hot-reloading during development).
func clear_cache() -> void:
	_scene_cache.clear()


## Returns array of all available car_ids.
static func get_available_car_ids() -> Array[String]:
	var ids: Array[String] = []
	for key in CAR_SCENES.keys():
		ids.append(key)
	return ids
