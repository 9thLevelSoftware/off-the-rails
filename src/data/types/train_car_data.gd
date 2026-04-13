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
