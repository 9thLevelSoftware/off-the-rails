class_name IsometricInteractionController
extends Node

## Main interaction controller that orchestrates the interaction system.
## Tracks player position, manages proximity detection, handles input,
## and shows/hides the visual prompt.

## Scene to instantiate for the interaction prompt UI
@export var prompt_scene: PackedScene

## Emitted when player presses interact and interaction is valid
signal interaction_requested(interactable_id: String)

## Emitted when player enters range of an interactable
signal interactable_entered(interactable_id: String)

## Emitted when player exits range of all interactables
signal interactable_exited()

## Reference to the player node (looked up via group)
var _player: CharacterBody2D = null

## Proximity detector for range queries
var _detector: IsometricProximityDetector

## State machine for interaction lifecycle
var _state_machine: InteractionStateMachine

## Visual prompt instance
var _prompt: InteractionPromptDisplay = null

## Registry of interactables: id -> {node: Node2D, config: InteractableConfig}
var _interactables: Dictionary = {}


func _ready() -> void:
	# Create infrastructure instances
	_detector = IsometricProximityDetector.new()
	_state_machine = InteractionStateMachine.new()

	# Connect state machine signals
	_state_machine.entered_range.connect(_on_entered_range)
	_state_machine.exited_range.connect(_on_exited_range)
	_state_machine.interaction_started.connect(_on_interaction_started)
	_state_machine.interaction_ended.connect(_on_interaction_ended)

	# Instantiate prompt if scene is set
	if prompt_scene:
		_prompt = prompt_scene.instantiate() as InteractionPromptDisplay
		if _prompt:
			add_child(_prompt)
			# Connect prompt_label export to the child label
			var label := _prompt.get_node_or_null("PromptLabel")
			if label:
				_prompt.prompt_label = label

	# Defer player lookup to allow scene tree to be ready
	call_deferred("_find_player")


func _physics_process(delta: float) -> void:
	# Tick the state machine for cooldown management
	_state_machine.tick(delta)

	# Skip if no player
	if not _player or not is_instance_valid(_player):
		return

	# Update state machine with player position
	_state_machine.update(_player.global_position, _detector)

	# Update prompt position if visible and we have a target
	if _prompt and _state_machine.current_target != "":
		var data := _interactables.get(_state_machine.current_target, {}) as Dictionary
		if data.has("node") and is_instance_valid(data.node):
			var target_node: Node2D = data.node
			# Get interaction position if available, otherwise use global_position
			var target_pos: Vector2
			if target_node.has_method("get_interaction_position"):
				target_pos = target_node.get_interaction_position()
			else:
				target_pos = target_node.global_position
			_prompt.update_position(target_pos)


func _unhandled_input(event: InputEvent) -> void:
	# Handle interact action press
	if event.is_action_pressed("interact"):
		if _state_machine.try_interact():
			get_viewport().set_input_as_handled()


## Register an interactable with the system.
func register_interactable(id: String, node: Node2D, config: InteractableConfig) -> void:
	if id.is_empty():
		push_warning("IsometricInteractionController: Cannot register interactable with empty ID")
		return

	if not node or not is_instance_valid(node):
		push_warning("IsometricInteractionController: Cannot register invalid node for ID: %s" % id)
		return

	# Store in registry
	_interactables[id] = {
		"node": node,
		"config": config
	}

	# Get position for detector
	var pos: Vector2
	if node.has_method("get_interaction_position"):
		pos = node.get_interaction_position()
	else:
		pos = node.global_position

	# Register with detector
	_detector.register(id, pos, config)


## Unregister an interactable from the system.
func unregister_interactable(id: String) -> void:
	if _interactables.has(id):
		_interactables.erase(id)
		_detector.unregister(id)


## Find the player via group lookup.
func _find_player() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		_player = players[0] as CharacterBody2D
		if not _player:
			push_warning("IsometricInteractionController: Player node is not a CharacterBody2D")
	else:
		push_warning("IsometricInteractionController: No node found in 'player' group")


## Called when player enters range of an interactable.
func _on_entered_range(interactable_id: String) -> void:
	interactable_entered.emit(interactable_id)

	# Show prompt
	if _prompt:
		var data := _interactables.get(interactable_id, {}) as Dictionary
		if data.has("config") and data.has("node"):
			var config: InteractableConfig = data.config
			var node: Node2D = data.node
			var pos: Vector2
			if node.has_method("get_interaction_position"):
				pos = node.get_interaction_position()
			else:
				pos = node.global_position
			_prompt.show_prompt(config.prompt_text, pos)


## Called when player exits range of all interactables.
func _on_exited_range() -> void:
	interactable_exited.emit()

	# Hide prompt
	if _prompt:
		_prompt.hide_prompt()


## Called when interaction starts.
func _on_interaction_started(interactable_id: String) -> void:
	interaction_requested.emit(interactable_id)

	# Call on_interact on the interactable node if it has the method
	var data := _interactables.get(interactable_id, {}) as Dictionary
	if data.has("node") and is_instance_valid(data.node):
		var node: Node2D = data.node
		if node.has_method("on_interact"):
			node.on_interact()

	# End interaction immediately (for simple use-type interactions)
	# Complex interactions (dialogue, menus) would call end_interaction() later
	_state_machine.end_interaction()


## Called when interaction ends.
func _on_interaction_ended(_interactable_id: String) -> void:
	# Prompt remains hidden during cooldown, will reshow if still in range
	pass
