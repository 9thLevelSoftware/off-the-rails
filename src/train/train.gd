## Train Scene
## The persistent train environment where players manage crew and resources.
extends Node3D

@onready var train_manager: TrainManager = $TrainManager
@onready var interaction_controller: InteractionController = $InteractionController
@onready var expedition_trigger: Area3D = $ExpeditionTrigger


func _ready() -> void:
	GameState.register_scene(GameState.GameScene.TRAIN, self)
	if expedition_trigger:
		# Configure collision - only detect layer 1 (player/physics bodies)
		expedition_trigger.set_collision_layer_value(1, false)
		expedition_trigger.set_collision_mask_value(1, true)
		expedition_trigger.body_entered.connect(_on_expedition_trigger_body_entered)
	print("Train: Scene initialized")


func _on_expedition_trigger_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		GameState.transition_to_expedition()
