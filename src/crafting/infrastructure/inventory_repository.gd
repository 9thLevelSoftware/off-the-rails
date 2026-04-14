class_name InventoryRepository
extends RefCounted

## Repository interface for inventory operations.
## Provides abstraction over GameState's inventory system.
## Enables testability by allowing mock implementations.


## Check if inventory has at least the specified quantity of a resource.
func has_resource(resource_id: String, quantity: int = 1) -> bool:
	return GameState.has_inventory_quantity(resource_id, quantity)


## Get current quantity of a resource in inventory.
func get_resource_quantity(resource_id: String) -> int:
	return GameState.get_inventory_quantity(resource_id)


## Consume multiple resources from inventory atomically.
## Returns true if successful, false if any resource was missing.
func consume_resources(resources: Dictionary) -> bool:
	return GameState.consume_inventory(resources)


## Add multiple resources to inventory.
func add_resources(resources: Dictionary) -> void:
	GameState.add_all_inventory(resources)


## Get all resources currently in inventory.
## Returns Dictionary {resource_id: quantity}
func get_all_resources() -> Dictionary:
	return GameState.inventory.duplicate()


## Check if inventory has all specified resources.
## resources: {resource_id: quantity_needed}
func has_all_resources(resources: Dictionary) -> bool:
	return GameState.has_all_inventory(resources)
