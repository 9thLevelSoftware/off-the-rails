class_name LootContainer
extends Node3D

## A container that holds loot items and can be opened via interaction.
## Adds itself to "interactable" group for detection by InteractionController.
## Sealed containers trigger escalation when opened.

## Contents of this container. Assign in editor or via code.
@export var contents: Array[LootItem] = []

## If true, opening this container triggers escalation.
@export var is_sealed: bool = false

## Escalation amount when opening a sealed container.
@export var escalation_on_open: float = 5.0

## Optional node to animate when opened (rotate or hide).
@export var lid_node: Node3D

## Whether this container has been opened.
var is_opened: bool = false

## Emitted when the container is opened, passing its contents.
signal container_opened(loot_contents: Array[LootItem])

## Cached reference to the EscalationManager.
var _escalation_manager: EscalationManager = null


func _ready() -> void:
	add_to_group("interactable")
	call_deferred("_cache_escalation_manager")


## Safely caches the EscalationManager reference via deferred call.
## Uses group-based lookup as the primary discovery method.
func _cache_escalation_manager() -> void:
	_escalation_manager = get_tree().get_first_node_in_group("escalation_manager") as EscalationManager

	if not _escalation_manager and is_sealed:
		push_warning("LootContainer: No EscalationManager found in 'escalation_manager' group - sealed container won't trigger escalation")


## Called by InteractionController when player interacts with this container.
func interact(interactor: Node) -> void:
	if is_opened:
		print("LootContainer: Already opened")
		return

	is_opened = true

	# Handle sealed container escalation
	if is_sealed:
		if _escalation_manager:
			_escalation_manager.add_escalation(escalation_on_open, "opened sealed container")
		else:
			print("LootContainer: WARNING - Sealed container opened but no EscalationManager found")

	# Visual feedback - animate lid
	_animate_open()

	# Emit signal with contents
	container_opened.emit(contents)

	# Debug output
	print("LootContainer: Opened by %s" % interactor.name)
	if contents.is_empty():
		print("  Contents: Empty")
	else:
		for item in contents:
			print("  - %s x%d (%s)" % [item.item_name, item.quantity, item.item_type])


## Animates the lid opening (rotate or hide).
func _animate_open() -> void:
	if not lid_node:
		return

	# Simple animation: rotate lid 90 degrees on X axis
	var tween := create_tween()
	tween.tween_property(lid_node, "rotation_degrees:x", -90.0, 0.3).set_ease(Tween.EASE_OUT)
