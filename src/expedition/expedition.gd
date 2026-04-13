## Expedition Scene
## The procedurally generated expedition environment for combat and exploration.
extends Node3D

@onready var exit_trigger: Area3D = $ExitTrigger


func _ready() -> void:
	if GameState:
		GameState.register_scene(GameState.GameScene.EXPEDITION, self)
	if exit_trigger:
		# Configure collision - only detect layer 1 (player/physics bodies)
		exit_trigger.set_collision_layer_value(1, false)  # Area doesn't need to be on layer 1
		exit_trigger.set_collision_mask_value(1, true)    # Detect layer 1 bodies
		exit_trigger.body_entered.connect(_on_exit_trigger_body_entered)
	print("Expedition: Scene initialized")


func _on_exit_trigger_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		GameState.transition_to_train()
