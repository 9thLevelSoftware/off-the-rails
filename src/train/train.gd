## Train Scene
## The persistent train environment where players manage crew and resources.
extends Node3D


func _ready() -> void:
	if GameState:
		GameState.register_scene(GameState.GameScene.TRAIN, self)
	print("Train: Scene initialized")
