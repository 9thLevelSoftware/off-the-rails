class_name PowerGrid
extends PowerSource

## Power Grid subsystem for the Engine car.
## Provides power to all other subsystems on the train.

@export var power_output: float = 100.0


func _initialize_subsystem() -> void:
	display_name = "Power Grid"
	requires_power = false  # This IS the power source


func _ready() -> void:
	super._ready()
	# CRITIQUE-FIX: Connect to own state_changed to guarantee power signal emission
	state_changed.connect(_on_state_changed)


func _on_state_changed(_old_state: SubsystemState, _new_state: SubsystemState) -> void:
	# CRITIQUE-FIX: Always emit power signal on ANY state change
	power_availability_changed.emit(is_operational())
	print("[PowerGrid] State changed - Power available: %s" % is_operational())


func is_providing_power() -> bool:
	return is_operational()


func get_power_output() -> float:
	return power_output if is_operational() else 0.0
