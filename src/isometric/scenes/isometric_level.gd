# Main isometric level scene controller
# Initializes and coordinates all isometric subsystems

class_name IsoLevel
extends Node2D

@onready var canvas: IsoCanvas = $IsoCanvas
@onready var camera: IsoCameraController = $IsoCamera
@onready var tilemap_adapter: IsoTilemapAdapter = $IsoCanvas/WorldLayer/IsoTilemapAdapter


func _ready() -> void:
	_initialize_level()


func _initialize_level() -> void:
	# Camera starts at origin
	camera.global_position = Vector2.ZERO

	# Generate a simple test floor (5x5 grid)
	_generate_test_floor()


func _generate_test_floor() -> void:
	if not tilemap_adapter or not tilemap_adapter.tilemap:
		push_warning("TileMapLayer not ready")
		return

	# Fill a 5x5 area with floor tiles
	for x in range(-2, 3):
		for y in range(-2, 3):
			tilemap_adapter.set_tile(Vector2i(x, y), 0, Vector2i(0, 0))


# Set camera follow target
func set_camera_target(target: Node2D) -> void:
	camera.follow_target = target


# Get the tilemap adapter for external access
func get_tilemap() -> IsoTilemapAdapter:
	return tilemap_adapter
