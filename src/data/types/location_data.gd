class_name LocationData
extends Resource
## Data resource for expedition location archetypes.
## Generated from locations.yaml by yaml_to_tres.py

# Core properties
@export var id: String = ""
@export var name: String = ""
@export var description: String = ""

# Visual/narrative
@export var theme: Array[String] = []
@export var layout_style: String = ""
@export_enum("small", "medium", "large") var size: String = "medium"

# Difficulty
@export_enum("low", "medium", "high", "very_high", "variable") var threat_level: String = "medium"
@export_enum("slow_burn", "noise_sensitive", "alarm_based", "constant_pressure", "social") var escalation_profile: String = "slow_burn"

# Loot tables
@export var primary_loot: Array[String] = []
@export var rare_loot: Array[String] = []

# Mission types
@export var primary_objectives: Array[String] = []

# Combat
@export var enemy_types: Array[String] = []
@export var enemy_density: String = "medium"
@export var elite_chance: String = "10%"

# Environment
@export var environmental_hazards: Array[String] = []
@export var modifier_pool: Array[String] = []

# Key areas - array of dictionaries {name: String, purpose: String}
@export var key_areas: Array[Dictionary] = []

# Profession advantages - dictionary of {profession_id: bonus_description}
@export var profession_advantages: Dictionary = {}


func _to_string() -> String:
	return "[LocationData:%s]" % id


## Check if a resource can drop as primary loot
func has_primary_loot(resource_id: String) -> bool:
	return resource_id in primary_loot


## Check if a resource can drop as rare loot
func has_rare_loot(resource_id: String) -> bool:
	return resource_id in rare_loot


## Check if a resource can drop at all
func can_drop(resource_id: String) -> bool:
	return has_primary_loot(resource_id) or has_rare_loot(resource_id)


## Get profession advantage description
func get_profession_advantage(profession_id: String) -> String:
	return profession_advantages.get(profession_id, "")


## Check if this location is dangerous
func is_dangerous() -> bool:
	return threat_level in ["high", "very_high"]


## Check if this location has a specific hazard
func has_hazard(hazard: String) -> bool:
	return hazard in environmental_hazards


## Get a key area by name
func get_key_area(area_name: String) -> Dictionary:
	for area in key_areas:
		if area.get("name") == area_name:
			return area
	return {}
