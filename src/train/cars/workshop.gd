class_name WorkshopCar
extends TrainCar

## Workshop car containing the Fabricator subsystem.
## Provides crafting capabilities when connected to engine power.
## Integrates with crafting system via WorkshopAdapter.

@onready var fabricator: Fabricator = $Fabricator

## Crafting system adapter (manages queue and scheduling)
var _workshop_adapter: WorkshopAdapter = null

## Interaction component for opening crafting UI
var _workshop_interactable: WorkshopInteractable = null

## Interaction layer constant (layer 2)
const INTERACTION_LAYER: int = 2


func _on_car_ready() -> void:
	car_id = "workshop"
	car_name = "Workshop"
	car_position = 1

	# Initialize crafting adapter
	_setup_crafting_adapter()


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


## Setup the crafting adapter and interactable.
func _setup_crafting_adapter() -> void:
	# Create and add workshop adapter
	_workshop_adapter = WorkshopAdapter.new()
	_workshop_adapter.name = "WorkshopAdapter"
	add_child(_workshop_adapter)

	# Connect adapter to fabricator
	_workshop_adapter.set_fabricator(fabricator)

	# Create and add interactable component
	_workshop_interactable = WorkshopInteractable.new()
	_workshop_interactable.name = "WorkshopInteractable"
	add_child(_workshop_interactable)

	# Connect interactable to adapter
	_workshop_interactable.set_adapter(_workshop_adapter)

	print("[WorkshopCar] Crafting system initialized")


## Handle car interaction to open crafting UI.
func _on_car_interacted(interactor: Node) -> void:
	if _workshop_interactable:
		_workshop_interactable.interact(interactor)


## Get the workshop adapter for external access.
func get_workshop_adapter() -> WorkshopAdapter:
	return _workshop_adapter
