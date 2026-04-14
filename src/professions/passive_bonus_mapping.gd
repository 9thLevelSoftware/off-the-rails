class_name PassiveBonusMapping
extends RefCounted

## Maps passive bonus descriptions to structured modifiers.

const BONUS_MAP := {
	# Engineer passives
	"25% faster repair speed": {"stat": "repair_speed", "value": 1.25, "type": "multiply"},
	"15% reduced material cost for repairs": {"stat": "repair_cost", "value": 0.85, "type": "multiply"},
	"Early warning on system failures": {"stat": "failure_warning", "value": 1.0, "type": "flag"},

	# Medic passives
	"30% faster healing rate": {"stat": "healing_rate", "value": 1.30, "type": "multiply"},
	"20% reduced medical supply consumption": {"stat": "medical_cost", "value": 0.80, "type": "multiply"},
	"Diagnose conditions faster": {"stat": "diagnosis_speed", "value": 1.5, "type": "multiply"},

	# Scavenger passives (for future)
	"40% increased carry capacity": {"stat": "carry_capacity", "value": 1.40, "type": "multiply"},
	"Better quality rolls on loot tables": {"stat": "loot_quality", "value": 1.0, "type": "flag"},
	"Detect hidden containers": {"stat": "hidden_detection", "value": 1.0, "type": "flag"},

	# Security passives (for future)
	"15% weapon handling improvement": {"stat": "weapon_handling", "value": 1.15, "type": "multiply"},
	"10% reduced ammo consumption": {"stat": "ammo_cost", "value": 0.90, "type": "multiply"},
	"Faster threat identification": {"stat": "threat_id_speed", "value": 1.5, "type": "multiply"},
}


static func get_bonus(description: String) -> Dictionary:
	return BONUS_MAP.get(description, {})


static func get_bonuses_for_profession(profession: ProfessionData) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for bonus_text in profession.passive_bonuses:
		var bonus := get_bonus(bonus_text)
		if not bonus.is_empty():
			result.append(bonus)
		else:
			push_warning("PassiveBonusMapping: Unknown bonus '%s'" % bonus_text)
	return result


static func has_bonus(profession: ProfessionData, stat: String) -> bool:
	for bonus_text in profession.passive_bonuses:
		var bonus := get_bonus(bonus_text)
		if bonus.get("stat") == stat:
			return true
	return false
