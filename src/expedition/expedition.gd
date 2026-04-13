## Expedition Scene
## The procedurally generated expedition environment for combat and exploration.
extends Node3D

@onready var exit_trigger: Area3D = $ExitTrigger


func _ready() -> void:
	if GameState:
		GameState.register_scene(GameState.GameScene.EXPEDITION, self)
	if exit_trigger:
		exit_trigger.body_entered.connect(_on_exit_trigger_body_entered)
	print("Expedition: Scene initialized")


func _on_exit_trigger_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D:
		GameState.transition_to_train()
