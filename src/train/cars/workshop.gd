class_name WorkshopCar
extends TrainCar

## Workshop car containing the Fabricator subsystem.
## Provides crafting capabilities when connected to engine power.

@onready var fabricator: Fabricator = $Fabricator

## Interaction layer constant (layer 2)
const INTERACTION_LAYER: int = 2


func _on_car_ready() -> void:
	car_id = "workshop"
	car_name = "Workshop"
	car_position = 1


func _setup_interaction_area() -> void:
	if interaction_area:
		# Clear all layers, then set only the interaction layer
		interaction_area.collision_layer = 0
		interaction_area.set_collision_layer_value(INTERACTION_LAYER, true)
		interaction_area.collision_mask = 0


## Connect this workshop to a power provider car.
## Queries the car for a PowerSource subsystem rather than requiring a specific car type.
func connect_to_power_provider(car: TrainCar) -> void:
	if not fabricator:
		push_warning("WorkshopCar: No fabricator to connect")
		return

	var power_subsystem = car.get_subsystem_by_name("Power Grid")
	if power_subsystem and power_subsystem is PowerSource:
		fabricator.set_power_source(power_subsystem)
	else:
		push_warning("WorkshopCar: Car '%s' does not provide power" % car.car_name)


## Returns true if fabricator is ready for crafting.
func can_craft() -> bool:
	return fabricator != null and fabricator.is_ready_for_crafting()


## Returns the current crafting speed from fabricator subsystem.
func get_crafting_speed() -> float:
	return fabricator.get_crafting_speed() if fabricator else 0.0


## Activate the workshop by bringing fabricator online.
func activate_workshop() -> void:
	if fabricator and fabricator.can_go_online():
		fabricator.bring_online()


## Deactivate the workshop by taking fabricator offline.
func deactivate_workshop() -> void:
	if fabricator:
		fabricator.take_offline()
