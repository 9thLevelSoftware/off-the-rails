class_name AbilityManager
extends Node

## Manages profession abilities: cooldowns, input, and activation.

signal ability_activated(ability: AbilityData)
signal ability_ready(ability_id: String)
signal cooldown_started(ability_id: String, duration: float)

var _profession: ProfessionData = null
var _abilities: Array[AbilityData] = []
var _cooldowns: Dictionary = {}
var _effects_handler: AbilityEffects = null


func _ready() -> void:
	_effects_handler = AbilityEffects.new()
	_effects_handler.name = "AbilityEffects"
	add_child(_effects_handler)


func set_profession(profession: ProfessionData) -> void:
	_profession = profession
	_abilities.clear()
	_cooldowns.clear()

	if profession == null:
		return

	_abilities = AbilityData.from_profession(profession)
	for ability in _abilities:
		_cooldowns[ability.id] = 0.0

	print("[AbilityManager] Loaded %d abilities for %s" % [_abilities.size(), profession.name])


func _process(delta: float) -> void:
	_update_cooldowns(delta)


func _update_cooldowns(delta: float) -> void:
	for ability_id in _cooldowns:
		if _cooldowns[ability_id] > 0:
			_cooldowns[ability_id] = maxf(0.0, _cooldowns[ability_id] - delta)
			if _cooldowns[ability_id] == 0.0:
				ability_ready.emit(ability_id)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ability_1"):
		_try_activate_slot(0)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ability_2"):
		_try_activate_slot(1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ability_3"):
		_try_activate_slot(2)
		get_viewport().set_input_as_handled()


func _try_activate_slot(slot_index: int) -> bool:
	if slot_index < 0 or slot_index >= _abilities.size():
		return false

	var ability := _abilities[slot_index]

	if _cooldowns[ability.id] > 0:
		print("[AbilityManager] %s on cooldown (%.1fs remaining)" % [ability.display_name, _cooldowns[ability.id]])
		return false

	_cooldowns[ability.id] = ability.cooldown_seconds
	cooldown_started.emit(ability.id, ability.cooldown_seconds)
	ability_activated.emit(ability)
	_effects_handler.execute_ability(ability, get_parent())

	return true


func get_cooldown_remaining(ability_id: String) -> float:
	return _cooldowns.get(ability_id, 0.0)


func get_cooldown_progress(ability_id: String) -> float:
	for ability in _abilities:
		if ability.id == ability_id:
			if ability.cooldown_seconds <= 0:
				return 0.0
			return _cooldowns.get(ability_id, 0.0) / ability.cooldown_seconds
	return 0.0


func get_ability_at_slot(slot_index: int) -> AbilityData:
	if slot_index < 0 or slot_index >= _abilities.size():
		return null
	return _abilities[slot_index]


func get_ability_count() -> int:
	return _abilities.size()
