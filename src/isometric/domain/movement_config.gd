# Movement configuration resource for player/entity movement
# Tunable exported properties for responsive isometric movement

class_name MovementConfig
extends Resource

@export var walk_speed: float = 150.0
@export var run_speed: float = 250.0  # Reserved for sprint mechanic (not yet implemented)
@export var acceleration: float = 800.0
@export var friction: float = 1200.0
@export var animation_threshold: float = 10.0
