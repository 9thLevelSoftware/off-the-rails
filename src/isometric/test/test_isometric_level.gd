# Test scene for verifying isometric foundation
# R1: TileMapLayer + Y-sort verification
# R2: Camera follow + zoom verification
# R3: Player character with isometric movement

class_name TestIsoLevel
extends Node2D

@onready var iso_level: IsoLevel = $IsoLevel

const PlayerScene := preload("res://src/isometric/player/player.tscn")

var player: CharacterBody2D


func _ready() -> void:
	call_deferred("_initialize_test")


func _initialize_test() -> void:
	if not iso_level:
		push_error("TestIsoLevel: IsoLevel child not found")
		return

	# Wait for tilemap adapter to be ready
	var tilemap_adapter := iso_level.get_tilemap()
	if tilemap_adapter and not tilemap_adapter.is_ready():
		push_warning("TileMapLayer adapter not yet initialized, waiting...")
		await get_tree().process_frame

	# Spawn player into the Y-sorted entity layer
	player = PlayerScene.instantiate()
	player.global_position = Vector2.ZERO
	iso_level.canvas.add_entity(player)

	# Camera follows the player
	iso_level.set_camera_target(player)

	print("Isometric Foundation Test")
	print("========================")
	print("WASD: Move player (isometric)")
	print("Mouse wheel: Zoom in/out")
	print("Watch Y-sorting as player moves")
