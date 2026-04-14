class_name InteractableConfig
extends Resource

## Configuration resource for interactable objects.
## Stores interaction parameters as exported properties for editor configuration.
## Can be shared across multiple interactables or customized per-instance.

## Types of interaction an interactable can support
enum InteractionType {
	USE,      ## Generic use action (workbench, terminal, lever)
	EXAMINE,  ## Inspect for information (signs, notes, objects)
	PICKUP,   ## Add to inventory (items, loot)
	TALK      ## Start dialogue (NPCs, radios)
}

## Maximum distance in pixels for interaction to be available
@export var interaction_range: float = 80.0

## Text shown in the interaction prompt UI
@export var prompt_text: String = "Press E to interact"

## Cooldown between interactions in seconds
@export var interaction_cooldown: float = 0.5

## Whether interaction requires unobstructed line of sight (future use)
@export var requires_line_of_sight: bool = false

## Type of interaction this object supports
@export var interaction_type: InteractionType = InteractionType.USE


## Factory method to create a default configuration.
static func create_default() -> InteractableConfig:
	var config := InteractableConfig.new()
	# All properties use their default values
	return config


## Factory method to create a configuration with custom parameters.
static func create(
	p_range: float = 80.0,
	p_prompt: String = "Press E to interact",
	p_cooldown: float = 0.5,
	p_type: InteractionType = InteractionType.USE
) -> InteractableConfig:
	var config := InteractableConfig.new()
	config.interaction_range = p_range
	config.prompt_text = p_prompt
	config.interaction_cooldown = p_cooldown
	config.interaction_type = p_type
	return config


## Get interaction type as human-readable string
func get_type_name() -> String:
	match interaction_type:
		InteractionType.USE:
			return "USE"
		InteractionType.EXAMINE:
			return "EXAMINE"
		InteractionType.PICKUP:
			return "PICKUP"
		InteractionType.TALK:
			return "TALK"
	return "UNKNOWN"
