class_name ProfessionData
extends Resource
## Data resource for player professions/specializations.
## Generated from professions.yaml by yaml_to_tres.py

# Core properties
@export var id: String = ""
@export var name: String = ""
@export var description: String = ""

# Role assignment
@export var primary_car: String = ""
@export var secondary_cars: Array[String] = []
@export var field_role: String = ""

# Abilities - stored as array of dictionaries
# Each ability: {id: String, name: String, description: String, cooldown: String}
@export var active_abilities: Array[Dictionary] = []

# Bonuses - stored as simple string array
@export var passive_bonuses: Array[String] = []

# Synergies with other professions
@export var synergies: Array[String] = []

# Recruitment priority (1 = highest)
@export var priority: int = 3


func _to_string() -> String:
	return "[ProfessionData:%s]" % id


## Get an ability by ID
func get_ability(ability_id: String) -> Dictionary:
	for ability in active_abilities:
		if ability.get("id") == ability_id:
			return ability
	return {}


## Check if this profession has synergy with another
func has_synergy_with(profession_id: String) -> bool:
	return profession_id in synergies


## Check if this profession can work at a specific car
func can_work_at(car_id: String) -> bool:
	return car_id == primary_car or car_id in secondary_cars
