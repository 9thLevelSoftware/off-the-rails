class_name Fabricator
extends Subsystem

## Fabricator subsystem for the Workshop car.
## Handles crafting station functionality (queue system deferred to Phase 6).

var power_source: PowerGrid = null

@export var crafting_speed: float = 1.0

signal fabricator_ready_changed(is_ready: bool)


func _initialize_subsystem() -> void:
	display_name = "Fabricator"
	requires_power = true


## CRITIQUE-FIX: Validates power_grid is not null before storing
func set_power_source(power_grid: PowerGrid) -> void:
	if power_grid == null:
		push_warning("Fabricator: Attempted to set null power source")
		return
	
	# Disconnect from old power source if exists
	if power_source and is_instance_valid(power_source) and power_source.power_availability_changed.is_connected(_on_power_changed):
		power_source.power_availability_changed.disconnect(_on_power_changed)
	
	power_source = power_grid
	
	# Connect to new power source
	if power_source:
		power_source.power_availability_changed.connect(_on_power_changed)
		_on_power_changed(power_source.is_providing_power())


func _on_power_changed(power_available: bool) -> void:
	if not power_available and is_operational():
		take_offline()
		fabricator_ready_changed.emit(false)


## CRITIQUE-FIX: Includes explicit null guard for power_source
func can_go_online() -> bool:
	if power_source == null:
		push_warning("Fabricator: No power source configured")
		return false
	if not is_instance_valid(power_source):
		push_warning("Fabricator: Power source reference is invalid")
		return false
	return power_source.is_providing_power()


func bring_online() -> void:
	if can_go_online():
		current_state = SubsystemState.OPERATIONAL
		fabricator_ready_changed.emit(true)


func is_ready_for_crafting() -> bool:
	return is_operational() and (power_source != null and power_source.is_providing_power())


func get_crafting_speed() -> float:
	return crafting_speed if is_ready_for_crafting() else 0.0
