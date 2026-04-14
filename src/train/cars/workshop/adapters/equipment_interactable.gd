class_name EquipmentInteractable
extends Node2D

## Adapter that makes EquipmentEntity interactable.
## Bridges between the domain entity and the interaction system.
## Created as a child of equipment nodes by WorkshopSpatialAdapter.

## Emitted when player interacts with this equipment
signal interaction_triggered(equipment_id: String, equipment_type: String)

## Unique identifier for this equipment (set from EquipmentEntity)
@export var equipment_id: String = ""

## Configuration for interaction behavior
@export var config: InteractableConfig

## Reference to the domain entity
var _entity: EquipmentEntity = null


func _ready() -> void:
	# Add to interactable group for easy lookup
	add_to_group("interactable")


## Set up the interactable from an EquipmentEntity.
## Called by WorkshopSpatialAdapter after adding to tree.
func setup(entity: EquipmentEntity) -> void:
	if entity == null:
		push_error("EquipmentInteractable: Cannot setup with null entity")
		return

	_entity = entity
	equipment_id = entity.equipment_id

	# Create default config if not exported
	if not config:
		config = InteractableConfig.create_default()
		# Customize prompt based on equipment type
		config.prompt_text = "Press E to use %s" % entity.get_type_name().to_lower()

	# Position is relative to parent equipment node (which is already positioned)
	# Keep at origin since we're a child of the equipment node
	position = Vector2.ZERO

	# Use deferred registration for timing safety
	call_deferred("_register_with_controller")


## Register with the interaction controller.
## Deferred to ensure controller is ready in scene tree.
func _register_with_controller() -> void:
	# Find the interaction controller in the tree
	var controller := _find_controller()
	if controller:
		controller.register_interactable(equipment_id, self, config)
	else:
		push_warning("EquipmentInteractable: No IsometricInteractionController found for %s" % equipment_id)


## Find IsometricInteractionController via group lookup (O(1) instead of tree traversal).
func _find_controller() -> IsometricInteractionController:
	var controllers := get_tree().get_nodes_in_group("interaction_controller")
	if controllers.size() > 0:
		return controllers[0] as IsometricInteractionController
	return null


## Get the world position for the interaction prompt.
## Returns the global position of the parent equipment node.
func get_interaction_position() -> Vector2:
	return global_position


## Called when player interacts with this equipment.
## Invoked by IsometricInteractionController.
func on_interact() -> void:
	var type_name := ""
	if _entity:
		type_name = _entity.get_type_name()

	# Emit signal for external handlers
	interaction_triggered.emit(equipment_id, type_name)

	# Print placeholder feedback (debug only)
	if OS.is_debug_build():
		print("Interacted with %s" % equipment_id)


func _exit_tree() -> void:
	# Unregister when removed from tree
	var controller := _find_controller()
	if controller:
		controller.unregister_interactable(equipment_id)
