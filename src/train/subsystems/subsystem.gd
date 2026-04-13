class_name Subsystem
extends Node

## Abstract base class for all train subsystems.
## Provides state management and signal contracts for subsystem state changes.

## Subsystem states for V1 (Damaged/Upgraded deferred)
enum SubsystemState {
	OFFLINE,      ## Not powered or not installed
	OPERATIONAL   ## Normal function
}

## Emitted when subsystem state changes
signal state_changed(old_state: SubsystemState, new_state: SubsystemState)

## Current state of the subsystem
var current_state: SubsystemState = SubsystemState.OFFLINE:
	set(value):
		if current_state != value:
			var old = current_state
			current_state = value
			state_changed.emit(old, value)

## Display name for UI purposes
@export var display_name: String = "Subsystem"

## Whether this subsystem requires power from another subsystem
@export var requires_power: bool = false


func _ready() -> void:
	_initialize_subsystem()


## Override in subclasses for subsystem-specific initialization
func _initialize_subsystem() -> void:
	pass


## Transition to operational state
func bring_online() -> void:
	if can_go_online():
		current_state = SubsystemState.OPERATIONAL


## Transition to offline state
func take_offline() -> void:
	current_state = SubsystemState.OFFLINE


## Check if subsystem can go online (override for dependency checks)
func can_go_online() -> bool:
	return true


## Check if currently operational
func is_operational() -> bool:
	return current_state == SubsystemState.OPERATIONAL


## Get state as human-readable string
func get_state_string() -> String:
	match current_state:
		SubsystemState.OFFLINE:
			return "Offline"
		SubsystemState.OPERATIONAL:
			return "Operational"
		_:
			return "Unknown"
