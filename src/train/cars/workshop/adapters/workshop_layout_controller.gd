class_name WorkshopLayoutController
extends Node2D

## Controller that orchestrates Workshop scene rendering.
## Loads layout from data resource, sets up floor tiles, and renders equipment.
## Acts as the composition root for the Workshop scene.

const FloorLayoutClass = preload("res://src/train/cars/workshop/domain/floor_layout.gd")
const FloorCollisionGridClass = preload("res://src/train/cars/workshop/infrastructure/floor_collision_grid.gd")
const FloorLayoutLoaderClass = preload("res://src/train/cars/workshop/infrastructure/floor_layout_loader.gd")
const WorkshopSpatialAdapterClass = preload("res://src/train/cars/workshop/adapters/workshop_spatial_adapter.gd")

## Path to the layout data resource
@export var layout_resource_path: String = "res://src/train/cars/workshop/data/workshop_floor_layout.tres"

## Domain objects
var _floor_layout: FloorLayout = null
var _collision_grid: FloorCollisionGrid = null

## Child node references
@onready var _spatial_adapter: WorkshopSpatialAdapter = $WorkshopSpatialAdapter
@onready var _floor_tilemap: TileMapLayer = $FloorTileMap
@onready var _workshop_adapter: WorkshopAdapter = $WorkshopAdapter

## Emitted when the workshop is fully initialized and ready
signal workshop_ready


func _ready() -> void:
	_validate_children()
	_load_layout()
	_setup_floor_tiles()
	_render_equipment()
	workshop_ready.emit()

	# Register with GameState so player spawning works when session is active
	GameState.register_scene(GameState.GameScene.TRAIN, self)

	# Wire WorkshopAdapter to workbench after equipment is rendered
	call_deferred("_wire_workshop_adapter")


## Validate that required child nodes exist
func _validate_children() -> void:
	if not _spatial_adapter:
		push_error("WorkshopLayoutController: WorkshopSpatialAdapter child not found")
	if not _floor_tilemap:
		push_error("WorkshopLayoutController: FloorTileMap child not found")
	if not _workshop_adapter:
		push_error("WorkshopLayoutController: WorkshopAdapter child not found")


## Load layout from resource and create collision grid
func _load_layout() -> void:
	if layout_resource_path.is_empty():
		push_error("WorkshopLayoutController: layout_resource_path is empty")
		return

	# Load and parse the layout data resource
	_floor_layout = FloorLayoutLoader.load_from_resource(layout_resource_path)

	if _floor_layout == null:
		push_error("WorkshopLayoutController: Failed to load layout from %s" % layout_resource_path)
		return

	# Create collision grid from layout
	_collision_grid = FloorCollisionGrid.create(_floor_layout)

	if _collision_grid == null:
		push_warning("WorkshopLayoutController: Failed to create collision grid")


## Fill the TileMapLayer with floor tiles based on layout dimensions
func _setup_floor_tiles() -> void:
	if not _floor_tilemap:
		return

	if _floor_layout == null:
		return

	# Clear existing tiles
	_floor_tilemap.clear()

	# Fill floor area with tiles
	# Using source_id 0 and atlas coords (0, 0) for the basic floor tile
	var source_id := 0
	var atlas_coords := Vector2i(0, 0)

	for x in range(_floor_layout.width_tiles):
		for y in range(_floor_layout.height_tiles):
			_floor_tilemap.set_cell(Vector2i(x, y), source_id, atlas_coords)


## Render equipment using the spatial adapter
func _render_equipment() -> void:
	if not _spatial_adapter:
		return

	if _floor_layout == null:
		return

	_spatial_adapter.setup(_floor_layout)


## Check if a world position is blocked by equipment.
## Delegates to the FloorCollisionGrid for O(1) lookup.
func is_position_blocked(world_pos: Vector2) -> bool:
	if _collision_grid == null:
		return false
	return _collision_grid.is_blocked(world_pos)


## Get equipment at a world position.
## Returns the first EquipmentEntity at the position, or null if none.
func get_equipment_at(world_pos: Vector2) -> EquipmentEntity:
	if _collision_grid == null:
		return null

	var results := _collision_grid.query_at(world_pos)
	if results.is_empty():
		return null
	return results[0]


## Get the FloorLayout domain object
func get_floor_layout() -> FloorLayout:
	return _floor_layout


## Get the FloorCollisionGrid
func get_collision_grid() -> FloorCollisionGrid:
	return _collision_grid


## Get floor dimensions in tiles
func get_floor_dimensions() -> Vector2i:
	if _floor_layout == null:
		return Vector2i.ZERO
	return _floor_layout.get_dimensions()


## Check if a tile position is within floor bounds
func is_tile_in_bounds(tile_pos: Vector2i) -> bool:
	if _floor_layout == null:
		return false
	return tile_pos.x >= 0 and tile_pos.x < _floor_layout.width_tiles \
		and tile_pos.y >= 0 and tile_pos.y < _floor_layout.height_tiles


## Wire WorkshopAdapter to the workbench equipment.
## Called deferred to ensure equipment interactables are ready.
func _wire_workshop_adapter() -> void:
	if not _workshop_adapter:
		push_warning("[WorkshopLayoutController] No WorkshopAdapter found to wire")
		return

	var workbench := _spatial_adapter.get_interactable_by_type("WORKBENCH")
	if workbench:
		_workshop_adapter.connect_to_workbench(workbench)
		print("[WorkshopLayoutController] Wired WorkshopAdapter to workbench")
	else:
		push_warning("[WorkshopLayoutController] No workbench found to wire")
