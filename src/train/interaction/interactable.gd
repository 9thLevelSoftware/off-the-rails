class_name Interactable
extends Node

## Interface for interactive elements on train cars.
## Provides interaction signals and prompt management.

signal interaction_started(interactor: Node)
signal interaction_ended(interactor: Node)

@export var interaction_prompt: String = "Press E to interact"
@export var is_interactable: bool = true


## Called when an interactor attempts to interact with this node.
## Returns true if interaction was successful.
func interact(interactor: Node) -> bool:
	if not is_interactable:
		return false
	interaction_started.emit(interactor)
	_on_interact(interactor)
	return true


## Called when the interaction ends.
func end_interaction(interactor: Node) -> void:
	interaction_ended.emit(interactor)
	_on_interaction_end(interactor)


## Override in subclasses for custom interaction behavior.
func _on_interact(_interactor: Node) -> void:
	pass


## Override in subclasses for custom end-interaction behavior.
func _on_interaction_end(_interactor: Node) -> void:
	pass


## Returns the interaction prompt if interactable, empty string otherwise.
func get_interaction_prompt() -> String:
	return interaction_prompt if is_interactable else ""
