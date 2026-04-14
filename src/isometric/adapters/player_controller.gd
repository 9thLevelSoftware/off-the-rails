# Player character controller with isometric movement
# Converts WASD input to isometric directions, applies acceleration/friction

class_name PlayerController
extends CharacterBody2D

@export var movement_config: MovementConfig

# NOTE: Coupled to PlayerAnimationController. For NPC reuse, consider extracting
# an AnimationHandler interface or using duck-typed has_method() check.
var _animation_controller: PlayerAnimationController


func _ready() -> void:
	if not movement_config:
		movement_config = MovementConfig.new()

	_animation_controller = get_node_or_null("AnimationController")
	if not _animation_controller:
		push_warning("PlayerController: No AnimationController child found")


func _physics_process(delta: float) -> void:
	# Get raw WASD input
	var raw_input := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")

	# Convert to isometric screen direction
	var iso_direction := InputConverter.wasd_to_isometric(raw_input)

	# Apply acceleration/friction for smooth movement
	var target_velocity := iso_direction * movement_config.walk_speed
	if iso_direction != Vector2.ZERO:
		velocity = velocity.move_toward(target_velocity, movement_config.acceleration * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, movement_config.friction * delta)

	move_and_slide()

	# Update animation
	var is_moving := velocity.length() > movement_config.animation_threshold
	if _animation_controller:
		_animation_controller.update_animation(velocity, is_moving)
