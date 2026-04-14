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


## Create a ProfessionData instance from a dictionary.
## Centralized factory method used by ContentRegistry and ModAPI.
static func from_dict(data: Dictionary) -> ProfessionData:
	var id_val: String = data.get("id", "")
	if id_val.is_empty():
		return null

	var profession := ProfessionData.new()
	profession.id = id_val
	profession.name = data.get("name", id_val)
	profession.description = data.get("description", "")
	profession.primary_car = data.get("primary_car", "")
	profession.field_role = data.get("field_role", "")
	profession.priority = data.get("priority", 3)

	var secondary = data.get("secondary_cars", [])
	if secondary is Array:
		profession.secondary_cars = []
		for car in secondary:
			profession.secondary_cars.append(str(car))

	var synergies = data.get("synergies", [])
	if synergies is Array:
		profession.synergies = []
		for syn in synergies:
			profession.synergies.append(str(syn))

	var bonuses = data.get("passive_bonuses", [])
	if bonuses is Array:
		profession.passive_bonuses = []
		for bonus in bonuses:
			profession.passive_bonuses.append(str(bonus))

	var abilities = data.get("active_abilities", [])
	if abilities is Array:
		profession.active_abilities = []
		for ability in abilities:
			if ability is Dictionary:
				profession.active_abilities.append(ability.duplicate())

	return profession


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
