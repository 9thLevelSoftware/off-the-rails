class_name FloorCollisionGrid
extends RefCounted

## Spatial query system for efficient O(1) collision detection.
## Uses a grid-based approach where each cell maps to equipment entities.
## Equipment spanning multiple cells is registered in all relevant cells.

## Cell size matches one isometric tile
const CELL_SIZE := Vector2(64, 32)

## Grid storage: Dictionary mapping cell_key -> Array[EquipmentEntity]
var _grid: Dictionary = {}

## Reference to the floor layout (for bounds checking)
var _floor_layout: FloorLayout = null

## Cached bounds for quick rejection
var _bounds: Rect2 = Rect2()


## Private constructor - use static create() instead
func _init() -> void:
	pass


## Factory method to create and initialize a FloorCollisionGrid from a FloorLayout
static func create(floor_layout: FloorLayout) -> FloorCollisionGrid:
	if floor_layout == null:
		push_error("FloorCollisionGrid: Cannot create from null FloorLayout")
		return null

	var grid := FloorCollisionGrid.new()
	grid._floor_layout = floor_layout
	grid._bounds = floor_layout.bounds
	grid._build_grid()
	return grid


## Build the grid from the floor layout's equipment
func _build_grid() -> void:
	_grid.clear()

	if _floor_layout == null:
		return

	for equipment in _floor_layout.get_all_equipment():
		_register_equipment(equipment)


## Register an equipment entity in all cells it overlaps
func _register_equipment(equipment: EquipmentEntity) -> void:
	var cells := _get_overlapping_cells(equipment.collision_rect)
	for cell_key in cells:
		if not _grid.has(cell_key):
			_grid[cell_key] = []
		if equipment not in _grid[cell_key]:
			_grid[cell_key].append(equipment)


## Get all cell keys that overlap with a rect
func _get_overlapping_cells(rect: Rect2) -> Array[String]:
	var cells: Array[String] = []

	# Calculate cell range
	var min_cell := _world_to_cell(rect.position)
	var max_cell := _world_to_cell(rect.position + rect.size)

	# Include all cells in the range
	for x in range(min_cell.x, max_cell.x + 1):
		for y in range(min_cell.y, max_cell.y + 1):
			cells.append(_make_cell_key(x, y))

	return cells


## Convert world position to cell coordinates
func _world_to_cell(world_pos: Vector2) -> Vector2i:
	return Vector2i(
		floori(world_pos.x / CELL_SIZE.x),
		floori(world_pos.y / CELL_SIZE.y)
	)


## Create a string key from cell coordinates
func _make_cell_key(x: int, y: int) -> String:
	return "%d,%d" % [x, y]


## Query equipment at a world position.
## Returns all equipment whose collision rect contains the point.
func query_at(world_pos: Vector2) -> Array[EquipmentEntity]:
	var result: Array[EquipmentEntity] = []

	# Quick bounds check
	if not _bounds.has_point(world_pos):
		return result

	var cell_key := _make_cell_key(
		floori(world_pos.x / CELL_SIZE.x),
		floori(world_pos.y / CELL_SIZE.y)
	)

	if not _grid.has(cell_key):
		return result

	# Check each equipment in the cell for actual collision
	for equipment: EquipmentEntity in _grid[cell_key]:
		if equipment.contains_point(world_pos):
			result.append(equipment)

	return result


## Check if a world position is blocked by any equipment.
## Returns true if any equipment collision rect contains the point.
func is_blocked(world_pos: Vector2) -> bool:
	# Quick bounds check - positions outside bounds are not blocked by equipment
	if not _bounds.has_point(world_pos):
		return false

	var cell_key := _make_cell_key(
		floori(world_pos.x / CELL_SIZE.x),
		floori(world_pos.y / CELL_SIZE.y)
	)

	if not _grid.has(cell_key):
		return false

	# Check each equipment in the cell
	for equipment: EquipmentEntity in _grid[cell_key]:
		if equipment.contains_point(world_pos):
			return true

	return false


## Query all equipment overlapping a rect.
## Returns all equipment whose collision rect intersects the query rect.
func query_rect(rect: Rect2) -> Array[EquipmentEntity]:
	var result: Array[EquipmentEntity] = []
	var seen: Dictionary = {}  # Track seen equipment to avoid duplicates

	# Get all potentially overlapping cells
	var cells := _get_overlapping_cells(rect)

	for cell_key in cells:
		if not _grid.has(cell_key):
			continue

		for equipment: EquipmentEntity in _grid[cell_key]:
			# Skip if already processed
			if seen.has(equipment.equipment_id):
				continue

			# Check actual collision
			if equipment.overlaps_rect(rect):
				result.append(equipment)
				seen[equipment.equipment_id] = true

	return result


## Rebuild the grid (call after equipment changes)
func rebuild() -> void:
	_build_grid()


## Update grid for a single equipment entity (more efficient than full rebuild)
func update_equipment(equipment: EquipmentEntity) -> void:
	if equipment == null:
		return

	# Remove from all current cells
	_remove_equipment_from_grid(equipment)

	# Re-register in new cells
	_register_equipment(equipment)


## Remove equipment from all grid cells
func _remove_equipment_from_grid(equipment: EquipmentEntity) -> void:
	for cell_key in _grid.keys():
		var cell_array: Array = _grid[cell_key]
		var idx := cell_array.find(equipment)
		if idx >= 0:
			cell_array.remove_at(idx)


## Get count of occupied cells (for debugging)
func get_occupied_cell_count() -> int:
	var count := 0
	for cell_key in _grid.keys():
		if _grid[cell_key].size() > 0:
			count += 1
	return count


## Get total grid entries (equipment may appear in multiple cells)
func get_total_entries() -> int:
	var count := 0
	for cell_key in _grid.keys():
		count += _grid[cell_key].size()
	return count


## Clear the grid
func clear() -> void:
	_grid.clear()


func _to_string() -> String:
	return "[FloorCollisionGrid: %d cells, %d entries]" % [
		get_occupied_cell_count(),
		get_total_entries()
	]
