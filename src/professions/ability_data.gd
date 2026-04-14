class_name AbilityData
extends RefCounted

## Typed wrapper for ability dictionary from ProfessionData.
## Provides typed access and cooldown parsing.

var id: String
var display_name: String
var description: String
var cooldown_seconds: float  # Parsed from "120s" → 120.0
var raw_data: Dictionary


func _init(ability_dict: Dictionary) -> void:
	raw_data = ability_dict
	id = ability_dict.get("id", "")
	display_name = ability_dict.get("name", "")
	description = ability_dict.get("description", "")
	cooldown_seconds = ProfessionUtils.parse_cooldown(ability_dict.get("cooldown", "0s"))


static func from_profession(profession: ProfessionData) -> Array[AbilityData]:
	var abilities: Array[AbilityData] = []
	for ability_dict in profession.active_abilities:
		abilities.append(AbilityData.new(ability_dict))
	return abilities
