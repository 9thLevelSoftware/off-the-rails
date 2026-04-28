class_name ProfessionRegistry
extends RefCounted

## Registry for Profession content type.
## Wraps ProfessionData resources with ID-based lookup.
##
## The registry supports two data sources:
## 1. Godot Resource files (.tres) - for base game content
## 2. JSON dictionaries - for mod content
##
## Both are converted to ProfessionData for uniform access.

signal profession_registered(profession_id: String)
signal profession_overwritten(profession_id: String, old_source: String, new_source: String)

var _professions: Dictionary = {}  # id -> ProfessionData
var _sources: Dictionary = {}      # id -> source string (e.g., "base" or mod_id)


## Register a profession from a ProfessionData resource.
func register_profession(profession: ProfessionData, source: String = "base") -> void:
	if not profession or profession.id.is_empty():
		push_warning("ProfessionRegistry: Attempted to register invalid profession")
		return

	if _professions.has(profession.id):
		var old_source: String = _sources.get(profession.id, "unknown")
		profession_overwritten.emit(profession.id, old_source, source)

	_professions[profession.id] = profession
	_sources[profession.id] = source
	profession_registered.emit(profession.id)


## Get a profession by ID, returns null if not found.
func get_profession(id: String) -> ProfessionData:
	return _professions.get(id)


## Get all registered professions.
func get_all() -> Array[ProfessionData]:
	var result: Array[ProfessionData] = []
	for profession in _professions.values():
		result.append(profession)
	return result


## Get all profession IDs.
func get_all_ids() -> Array[String]:
	var result: Array[String] = []
	for id in _professions.keys():
		result.append(id)
	return result


## Check if a profession is registered.
func has_profession(id: String) -> bool:
	return id in _professions


## Get the source of a profession (which mod or "base").
func get_profession_source(id: String) -> String:
	return _sources.get(id, "")


## Get count of registered professions.
func count() -> int:
	return _professions.size()


## Get professions by primary car assignment.
func get_by_primary_car(car_id: String) -> Array[ProfessionData]:
	var result: Array[ProfessionData] = []
	for profession in _professions.values():
		if profession.primary_car == car_id:
			result.append(profession)
	return result


## Get professions that can work at a specific car.
func get_for_car(car_id: String) -> Array[ProfessionData]:
	var result: Array[ProfessionData] = []
	for profession in _professions.values():
		if profession.can_work_at(car_id):
			result.append(profession)
	return result


## Get professions by field role.
func get_by_field_role(role: String) -> Array[ProfessionData]:
	var result: Array[ProfessionData] = []
	for profession in _professions.values():
		if profession.field_role == role:
			result.append(profession)
	return result


## Get professions sorted by priority (recruitment order).
func get_sorted_by_priority() -> Array[ProfessionData]:
	var result := get_all()
	result.sort_custom(func(a: ProfessionData, b: ProfessionData) -> bool:
		return a.priority < b.priority
	)
	return result


## Load professions from a JSON data dictionary.
## Expected format: {"professions": [{id, name, description, abilities, ...}, ...]}
## Returns count of professions loaded.
func load_from_data(data: Dictionary, source: String = "base") -> int:
	if not data.has("professions"):
		return 0

	var professions_array = data.get("professions")
	if not professions_array is Array:
		push_warning("ProfessionRegistry: 'professions' must be an array")
		return 0

	var loaded_count := 0
	for profession_data in professions_array:
		if not profession_data is Dictionary:
			continue
		var profession := _create_from_dict(profession_data)
		if profession:
			register_profession(profession, source)
			loaded_count += 1

	return loaded_count


## Create a ProfessionData from a dictionary.
## Handles the conversion from JSON format to Godot resource.
func _create_from_dict(data: Dictionary) -> ProfessionData:
	var id: String = data.get("id", "")
	if id.is_empty():
		push_warning("ProfessionRegistry: Profession missing required 'id' field")
		return null

	var profession := ProfessionData.new()
	profession.id = id
	profession.name = data.get("name", id)
	profession.description = data.get("description", "")
	profession.primary_car = data.get("primary_car", "")
	profession.field_role = data.get("field_role", "")
	profession.priority = data.get("priority", 3)

	# Handle secondary_cars array
	var secondary = data.get("secondary_cars", [])
	if secondary is Array:
		profession.secondary_cars = []
		for car in secondary:
			profession.secondary_cars.append(str(car))

	# Handle synergies array
	var synergies = data.get("synergies", [])
	if synergies is Array:
		profession.synergies = []
		for syn in synergies:
			profession.synergies.append(str(syn))

	# Handle passive_bonuses array
	var bonuses = data.get("passive_bonuses", [])
	if bonuses is Array:
		profession.passive_bonuses = []
		for bonus in bonuses:
			profession.passive_bonuses.append(str(bonus))

	# Handle active_abilities array of dictionaries
	var abilities = data.get("active_abilities", [])
	if abilities is Array:
		profession.active_abilities = []
		for ability in abilities:
			if ability is Dictionary:
				profession.active_abilities.append(ability.duplicate())

	return profession


## Clear all registered professions.
func clear() -> void:
	_professions.clear()
	_sources.clear()
