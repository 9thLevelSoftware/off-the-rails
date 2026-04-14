class_name TrainCar
extends Node3D

## Base class for all train cars.
## Manages subsystem composition and provides car-level state queries.

@export var car_id: String = ""
@export var car_name: String = "Train Car"
@export var car_position: int = 0

## Interaction area for collision-based detection. Configured in _setup_interaction_area().
@onready var interaction_area: Area3D = $InteractionArea

var _subsystems: Array[Subsystem] = []

signal subsystem_state_changed(subsystem: Subsystem, old_state: Subsystem.SubsystemState, new_state: Subsystem.SubsystemState)
signal car_interacted(interactor: Node)


func _ready() -> void:
	_cache_subsystems()
	_connect_subsystem_signals()
	_setup_interaction_area()
	_on_car_ready()


## Cache all Subsystem children for efficient access.
func _cache_subsystems() -> void:
	_subsystems.clear()
	for child in get_children():
		if child is Subsystem:
			_subsystems.append(child)


## Connect to state_changed signals on all cached subsystems.
func _connect_subsystem_signals() -> void:
	for subsystem in _subsystems:
		subsystem.state_changed.connect(_on_subsystem_state_changed.bind(subsystem))


## Setup interaction area collision layers (override in subclasses if needed).
func _setup_interaction_area() -> void:
	pass


## Override in subclasses for car-specific initialization.
func _on_car_ready() -> void:
	pass


func _on_subsystem_state_changed(old_state: Subsystem.SubsystemState, new_state: Subsystem.SubsystemState, subsystem: Subsystem) -> void:
	subsystem_state_changed.emit(subsystem, old_state, new_state)


## Returns array of all subsystems in this car.
func get_subsystems() -> Array[Subsystem]:
	return _subsystems


## Returns subsystem matching the given script type, or null.
func get_subsystem(subsystem_type: GDScript) -> Subsystem:
	for subsystem in _subsystems:
		if subsystem.get_script() == subsystem_type:
			return subsystem
	return null


## Returns subsystem by class name or display_name, or null.
func get_subsystem_by_name(subsystem_name: String) -> Subsystem:
	for subsystem in _subsystems:
		if subsystem.get_class() == subsystem_name or subsystem.display_name == subsystem_name:
			return subsystem
	return null


## Returns true if car has the specified subsystem type and it is operational.
func has_capability(subsystem_type: GDScript) -> bool:
	var subsystem = get_subsystem(subsystem_type)
	return subsystem != null and subsystem.is_operational()


## Bring all subsystems online.
func bring_all_online() -> void:
	for subsystem in _subsystems:
		subsystem.bring_online()


## Take all subsystems offline.
func take_all_offline() -> void:
	for subsystem in _subsystems:
		subsystem.take_offline()


## Returns a dictionary summary of this car and its subsystems.
func get_status_summary() -> Dictionary:
	var summary := {
		"car_name": car_name,
		"car_id": car_id,
		"subsystems": []
	}
	for subsystem in _subsystems:
		summary["subsystems"].append({
			"name": subsystem.display_name,
			"state": subsystem.get_state_string(),
			"operational": subsystem.is_operational()
		})
	return summary


## Called when an interactor attempts to interact with this car.
## Emits car_interacted signal and calls _on_car_interacted for subclass override.
func interact(interactor: Node) -> void:
	car_interacted.emit(interactor)
	_on_car_interacted(interactor)


## Override in subclasses for car-specific interaction behavior.
func _on_car_interacted(_interactor: Node) -> void:
	pass
