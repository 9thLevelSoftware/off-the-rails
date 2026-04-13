class_name Locomotion
extends Subsystem

## Locomotion subsystem for the Engine car.
## Controls train movement speed and fuel consumption.

@export var speed_multiplier: float = 1.0
@export var fuel_rate: float = 1.0


func _initialize_subsystem() -> void:
	display_name = "Locomotion"
	requires_power = true


func get_speed_multiplier() -> float:
	return speed_multiplier if is_operational() else 0.0


func calculate_fuel_consumption(distance: float) -> float:
	if not is_operational():
		return 0.0
	return distance * fuel_rate
