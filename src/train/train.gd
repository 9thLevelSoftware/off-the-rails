## Train Scene
## The persistent train environment where players manage crew and resources.
extends Node3D

@onready var train_manager: TrainManager = $TrainManager
@onready var interaction_controller: InteractionController = $InteractionController


func _ready() -> void:
	GameState.register_scene(GameState.GameScene.TRAIN, self)
	print("Train: Scene initialized")
