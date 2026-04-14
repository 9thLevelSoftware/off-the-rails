class_name PassiveBonusManager
extends Node

## Manages passive bonus application from profession data.

signal bonuses_changed

var _profession: ProfessionData = null
var _active_bonuses: Array[Dictionary] = []


func set_profession(profession: ProfessionData) -> void:
	_profession = profession
	_active_bonuses.clear()

	if profession == null:
		bonuses_changed.emit()
		return

	_active_bonuses = PassiveBonusMapping.get_bonuses_for_profession(profession)

	print("[PassiveBonusManager] Loaded %d bonuses for %s" % [_active_bonuses.size(), profession.name])
	for bonus in _active_bonuses:
		print("  - %s: %.2f (%s)" % [bonus.stat, bonus.value, bonus.type])

	bonuses_changed.emit()


func apply_modifier(stat: String, base_value: float) -> float:
	for bonus in _active_bonuses:
		if bonus.stat == stat:
			match bonus.type:
				"multiply":
					return base_value * bonus.value
				"add":
					return base_value + bonus.value
				"flag":
					return base_value
	return base_value


func has_bonus(stat: String) -> bool:
	for bonus in _active_bonuses:
		if bonus.stat == stat:
			return true
	return false


func has_flag(stat: String) -> bool:
	for bonus in _active_bonuses:
		if bonus.stat == stat and bonus.type == "flag":
			return true
	return false


func get_bonus_value(stat: String) -> float:
	for bonus in _active_bonuses:
		if bonus.stat == stat:
			return bonus.value
	return 1.0


func get_all_bonuses() -> Array[Dictionary]:
	return _active_bonuses.duplicate()
