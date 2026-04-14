class_name EngineCar
extends TrainCar

## Engine car containing PowerGrid and Locomotion subsystems.
## The primary power source for the train.

@onready var power_grid: PowerGrid = $PowerGrid
@onready var locomotion: Locomotion = $Locomotion

## Interaction layer constant (layer 2)
const INTERACTION_LAYER: int = 2


func _on_car_ready() -> void:
	car_id = "engine"
	car_name = "Engine"
	car_position = 0
	if locomotion and power_grid:
		power_grid.power_availability_changed.connect(_on_power_changed)


func _setup_interaction_area() -> void:
	if interaction_area:
		# Clear all layers, then set only the interaction layer
		interaction_area.collision_layer = 0
		interaction_area.set_collision_layer_value(INTERACTION_LAYER, true)
		interaction_area.collision_mask = 0


func _on_power_changed(power_available: bool) -> void:
	if power_available:
		locomotion.bring_online()
	else:
		locomotion.take_offline()


## Returns true if locomotion is operational and train can move.
func can_move() -> bool:
	return locomotion != null and locomotion.is_operational()


## Returns the current speed multiplier from locomotion subsystem.
func get_speed_multiplier() -> float:
	return locomotion.get_speed_multiplier() if locomotion else 0.0


## Start the engine by bringing power grid online.
func start_engine() -> void:
	if power_grid:
		power_grid.bring_online()


## Stop the engine by taking locomotion and power offline.
func stop_engine() -> void:
	if locomotion:
		locomotion.take_offline()
	if power_grid:
		power_grid.take_offline()
