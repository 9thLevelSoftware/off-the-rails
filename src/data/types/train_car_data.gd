class_name TrainCarData
extends Resource
## Data resource for train cars and subsystems.
## Generated from train-cars.yaml by yaml_to_tres.py

# Core properties
@export var id: String = ""
@export var name: String = ""
@export var description: String = ""

# Car-specific properties (only for type == "car")
@export_enum("engine", "utility", "crew", "production", "specialist") var category: String = ""
@export_enum("starting", "early", "mid", "late") var acquisition: String = ""
@export var subsystems: Array[String] = []
@export var dependencies: Array[String] = []
@export var crew_station: bool = false
@export var upgrade_tree: String = ""

# Subsystem-specific properties (only for type == "subsystem")
@export var damage_effect: String = ""

# Type discriminator
@export_enum("car", "subsystem") var type: String = "car"


func _to_string() -> String:
	return "[TrainCarData:%s]" % id


## Create a TrainCarData instance from a dictionary.
## Centralized factory method used by ContentRegistry and ModAPI.
static func from_dict(data: Dictionary) -> TrainCarData:
	var id_val: String = data.get("id", "")
	if id_val.is_empty():
		return null

	var train_car := TrainCarData.new()
	train_car.id = id_val
	train_car.name = data.get("name", id_val)
	train_car.description = data.get("description", "")
	train_car.type = data.get("type", "car")
	train_car.category = data.get("category", "utility")
	train_car.acquisition = data.get("acquisition", "starting")
	train_car.crew_station = data.get("crew_station", false)
	train_car.upgrade_tree = data.get("upgrade_tree", "")
	train_car.damage_effect = data.get("damage_effect", "")

	var subsystems_data = data.get("subsystems", [])
	if subsystems_data is Array:
		train_car.subsystems = []
		for sub in subsystems_data:
			train_car.subsystems.append(str(sub))

	var dependencies_data = data.get("dependencies", [])
	if dependencies_data is Array:
		train_car.dependencies = []
		for dep in dependencies_data:
			train_car.dependencies.append(str(dep))

	return train_car


## Check if this is a car definition (not a subsystem)
func is_car() -> bool:
	return type == "car"


## Check if this is a subsystem definition
func is_subsystem() -> bool:
	return type == "subsystem"


## Check if this car requires another car
func requires_car(car_id: String) -> bool:
	return car_id in dependencies


## Check if this car has a specific subsystem
func has_subsystem(subsystem_id: String) -> bool:
	return subsystem_id in subsystems
