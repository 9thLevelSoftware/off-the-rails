class_name AbilityEffects
extends Node

## Handles ability effect execution with signals for system integration.
##
## PHASE 7 INTEGRATION: These effect methods emit signals that train subsystems,
## health components, and other game systems should connect to. Current implementations
## are stubs that print and emit - actual gameplay effects are wired in Phase 7.
##
## Signal consumers (to be implemented):
## - emergency_repair_activated -> TrainSubsystem.on_emergency_repair()
## - power_reroute_activated -> PowerSource.on_power_reroute()
## - system_overclock_activated -> TrainSubsystem.on_overclock()
## - field_surgery_activated -> HealthComponent.on_field_surgery()
## - stabilize_activated -> HealthComponent.on_stabilize()
## - purge_activated -> StatusEffectManager.on_purge()

signal emergency_repair_activated(caster: Node)
signal power_reroute_activated(caster: Node)
signal system_overclock_activated(caster: Node)
signal field_surgery_activated(caster: Node)
signal stabilize_activated(caster: Node)
signal purge_activated(caster: Node)


func execute_ability(ability: AbilityData, caster: Node) -> void:
	match ability.id:
		"emergency_repair":
			_do_emergency_repair(caster)
		"power_reroute":
			_do_power_reroute(caster)
		"system_overclock":
			_do_system_overclock(caster)
		"field_surgery":
			_do_field_surgery(caster)
		"stabilize":
			_do_stabilize(caster)
		"purge":
			_do_purge(caster)
		_:
			push_warning("AbilityEffects: Unknown ability '%s'" % ability.id)


func _do_emergency_repair(caster: Node) -> void:
	print("[Ability] Emergency Repair activated!")
	emergency_repair_activated.emit(caster)


func _do_power_reroute(caster: Node) -> void:
	print("[Ability] Power Reroute activated!")
	power_reroute_activated.emit(caster)


func _do_system_overclock(caster: Node) -> void:
	print("[Ability] System Overclock activated!")
	system_overclock_activated.emit(caster)


func _do_field_surgery(caster: Node) -> void:
	print("[Ability] Field Surgery activated!")
	field_surgery_activated.emit(caster)


func _do_stabilize(caster: Node) -> void:
	print("[Ability] Stabilize activated!")
	stabilize_activated.emit(caster)


func _do_purge(caster: Node) -> void:
	print("[Ability] Purge activated!")
	purge_activated.emit(caster)
