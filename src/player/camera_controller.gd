extends Node3D
## Camera controller placeholder for follow camera or cinematic camera modes.
## Currently a minimal implementation - expand as needed for different camera behaviors.

# Target to follow
@export var follow_target: Node3D

# Offset from target position
@export var follow_offset: Vector3 = Vector3(0, 2, 5)

# Interpolation speed for smooth following
@export var follow_speed: float = 5.0


func _physics_process(delta: float) -> void:
	if follow_target:
		var target_position := follow_target.global_position + follow_offset
		global_position = global_position.lerp(target_position, follow_speed * delta)
		look_at(follow_target.global_position, Vector3.UP)
