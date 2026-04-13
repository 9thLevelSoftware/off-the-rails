class_name WorkshopCar
extends TrainCar

## Workshop car containing the Fabricator subsystem.
## Provides crafting capabilities when connected to engine power.

@onready var fabricator: Fabricator = $Fabricator

var engine_car: EngineCar = null


func _on_car_ready() -> void:
	car_id = "workshop"
	car_name = "Workshop"
	car_position = 1


## Connect this workshop to an engine car for power.
func connect_to_engine(engine: EngineCar) -> void:
	engine_car = engine
	if fabricator and engine and engine.power_grid:
		fabricator.set_power_source(engine.power_grid)


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
