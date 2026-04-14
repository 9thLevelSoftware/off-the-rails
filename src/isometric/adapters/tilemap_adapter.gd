# Adapter: TileMapLayer configuration and Y-sort management
# Wraps TileMapLayer node with domain logic integration
# NOTE: Using TileMapLayer (Godot 4.3+) instead of deprecated TileMap

class_name IsoTilemapAdapter
extends Node2D

const ViewportCalc = preload("res://src/isometric/domain/viewport_calculator.gd")
const TilesetLoaderClass = preload("res://src/isometric/infrastructure/tileset_loader.gd")

# Reference to infrastructure
var tileset_loader: IsoTilesetLoader

# The actual TileMapLayer node (child)
@onready var tilemap: TileMapLayer = $TileMapLayer

# Initialization flag
var _initialized: bool = false


func _ready() -> void:
	if not tilemap:
		push_error("IsoTilemapAdapter: TileMapLayer child node not found. Expected child named 'TileMapLayer'")
		return

	tileset_loader = TilesetLoaderClass.new()
	_configure_tilemap()
	_initialized = true


func _configure_tilemap() -> void:
	# Load and apply tileset
	var tileset := tileset_loader.load_tileset()
	if tileset:
		tilemap.tile_set = tileset

	# Enable Y-sorting on the tilemap layer
	tilemap.y_sort_enabled = true


# Check if adapter is ready for use
func is_ready() -> bool:
	return _initialized


# Get tile at screen position
func get_tile_at_screen_pos(screen_pos: Vector2) -> Vector2i:
	if not _initialized:
		push_warning("IsoTilemapAdapter not initialized")
		return Vector2i.ZERO
	var iso_pos := ViewportCalc.screen_to_iso(screen_pos)
	return Vector2i(floori(iso_pos.x), floori(iso_pos.y))


# Get screen position of tile center
func get_tile_screen_pos(grid_pos: Vector2i) -> Vector2:
	return ViewportCalc.iso_to_screen(Vector2(grid_pos))


# Check if a tile exists at grid position
func has_tile_at(grid_pos: Vector2i) -> bool:
	return tilemap.get_cell_source_id(grid_pos) != -1


# Set a tile at grid position
func set_tile(grid_pos: Vector2i, source_id: int, atlas_coords: Vector2i) -> void:
	tilemap.set_cell(grid_pos, source_id, atlas_coords)


# Clear a tile at grid position
func clear_tile(grid_pos: Vector2i) -> void:
	tilemap.erase_cell(grid_pos)
