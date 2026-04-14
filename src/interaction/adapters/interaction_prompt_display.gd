class_name InteractionPromptDisplay
extends Control

## Visual prompt adapter that shows/hides the interaction prompt.
## Uses z_index for correct Y-sort positioning (above equipment, not CanvasLayer).
## Supports smooth fade animations via Tween.

## Reference to the label child node
@export var prompt_label: Label

## Offset above the target position in pixels
@export var offset: Vector2 = Vector2(0, -40)

## Duration of fade in/out animations in seconds
@export var fade_duration: float = 0.15

## Target world position for smooth interpolation
var _target_position: Vector2 = Vector2.ZERO

## Whether the prompt is currently visible
var _is_visible: bool = false

## Active tween for fade animations
var _fade_tween: Tween = null


func _ready() -> void:
	# Render above equipment sprites (z_index 100 ensures visibility)
	z_index = 100

	# Start hidden
	modulate.a = 0.0
	visible = false

	# Mouse should not interact with prompt
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(_delta: float) -> void:
	if _is_visible:
		# Smoothly interpolate to target position
		global_position = global_position.lerp(_target_position + offset, 0.15)


## Show the prompt at a world position with specified text.
func show_prompt(text: String, world_position: Vector2) -> void:
	if prompt_label:
		prompt_label.text = text

	_target_position = world_position
	global_position = world_position + offset

	if not _is_visible:
		_is_visible = true
		visible = true
		_fade_to(1.0)


## Hide the prompt with fade out animation.
func hide_prompt() -> void:
	if _is_visible:
		_is_visible = false
		_fade_to(0.0)


## Update the target position for a moving target.
func update_position(world_position: Vector2) -> void:
	_target_position = world_position


## Fade modulate alpha to target value.
func _fade_to(target_alpha: float) -> void:
	# Kill any existing tween
	if _fade_tween and _fade_tween.is_valid():
		_fade_tween.kill()

	_fade_tween = create_tween()
	_fade_tween.tween_property(self, "modulate:a", target_alpha, fade_duration)

	# Hide when fade out completes
	if target_alpha == 0.0:
		_fade_tween.tween_callback(_on_fade_out_complete)


func _on_fade_out_complete() -> void:
	visible = false
