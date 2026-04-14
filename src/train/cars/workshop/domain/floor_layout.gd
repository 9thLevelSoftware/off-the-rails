class_name FloorLayout
extends RefCounted

## Pure domain class representing a train car floor layout.
## Stores floor dimensions and equipment slots.
## No Node dependencies - suitable for use in domain layer.

## Isometric tile dimensions
const TILE_WIDTH: int = 64
const TILE_HEIGHT: int = 32

## Floor dimensions in tile units
var width_tiles: int = 0
var height_tiles: int = 0

## Floor boundaries in isometric world coordinates
var bounds: Rect2 = Rect2()

## Equipment entities on this floor
var _equipment: Array[EquipmentEntity] = []

## Layout identifier
var layout_id: String = ""


## Private constructor - use static create() instead
func _init() -> void:
	pass


## Factory method to create a new FloorLayout
static func create(p_layout_id: String, p_width_tiles: int, p_height_tiles: int) -> FloorLayout:
	var layout := FloorLayout.new()
	layout.layout_id = p_layout_id
	layout.width_tiles = p_width_tiles
	layout.height_tiles = p_height_tiles
	layout._calculate_bounds()
	return layout


## Calculate world bounds from tile dimensions.
## For isometric projection, bounds form a diamond shape.
## We use an AABB that encompasses the entire diamond.
func _calculate_bounds() -> void:
	# Calculate the four corners of the isometric floor in world coords
	# Top corner (tile 0,0)
	var top := EquipmentEntity.tile_to_world(Vector2i(0, 0))
	# Right corner (tile width-1, 0)
	var right := EquipmentEntity.tile_to_world(Vector2i(width_tiles - 1, 0))
	# Bottom corner (tile width-1, height-1)
	var bottom := EquipmentEntity.tile_to_world(Vector2i(width_tiles - 1, height_tiles - 1))
	# Left corner (tile 0, height-1)
	var left := EquipmentEntity.tile_to_world(Vector2i(0, height_tiles - 1))

	# Find bounding box
	var min_x := minf(minf(top.x, right.x), minf(bottom.x, left.x))
	var max_x := maxf(maxf(top.x, right.x), maxf(bottom.x, left.x))
	var min_y := minf(minf(top.y, right.y), minf(bottom.y, left.y))
	var max_y := maxf(maxf(top.y, right.y), maxf(bottom.y, left.y))

	# Add padding for tile dimensions
	bounds = Rect2(
		min_x - TILE_WIDTH * 0.5,
		min_y - TILE_HEIGHT * 0.5,
		max_x - min_x + TILE_WIDTH,
		max_y - min_y + TILE_HEIGHT
	)


## Add equipment to the floor layout
func add_equipment(equipment: EquipmentEntity) -> bool:
	if equipment == null:
		push_error("FloorLayout: Cannot add null equipment")
		return false

	# Check if position is within bounds
	if not _is_tile_in_bounds(equipment.tile_position):
		push_warning("FloorLayout: Equipment %s at %s is outside floor bounds" % [
			equipment.equipment_id,
			equipment.tile_position
		])

	# Check for duplicate ID
	for existing in _equipment:
		if existing.equipment_id == equipment.equipment_id:
			push_error("FloorLayout: Duplicate equipment ID: %s" % equipment.equipment_id)
			return false

	_equipment.append(equipment)
	return true


## Remove equipment by ID
func remove_equipment(equipment_id: String) -> bool:
	for i in range(_equipment.size()):
		if _equipment[i].equipment_id == equipment_id:
			_equipment.remove_at(i)
			return true
	return false


## Get equipment at a specific tile position
func get_equipment_at(tile_pos: Vector2i) -> EquipmentEntity:
	for equipment in _equipment:
		if equipment.tile_position == tile_pos:
			return equipment
	return null


## Get equipment at a world position (checks collision rects)
func get_equipment_at_world(world_pos: Vector2) -> EquipmentEntity:
	for equipment in _equipment:
		if equipment.contains_point(world_pos):
			return equipment
	return null


## Get all equipment overlapping a world rect
func get_equipment_in_rect(rect: Rect2) -> Array[EquipmentEntity]:
	var result: Array[EquipmentEntity] = []
	for equipment in _equipment:
		if equipment.overlaps_rect(rect):
			result.append(equipment)
	return result


## Get all equipment of a specific type
func get_equipment_by_type(equipment_type: EquipmentEntity.EquipmentType) -> Array[EquipmentEntity]:
	var result: Array[EquipmentEntity] = []
	for equipment in _equipment:
		if equipment.equipment_type == equipment_type:
			result.append(equipment)
	return result


## Get all equipment in a specific state
func get_equipment_by_state(state: EquipmentEntity.EquipmentState) -> Array[EquipmentEntity]:
	var result: Array[EquipmentEntity] = []
	for equipment in _equipment:
		if equipment.state == state:
			result.append(equipment)
	return result


## Get equipment by ID
func get_equipment_by_id(equipment_id: String) -> EquipmentEntity:
	for equipment in _equipment:
		if equipment.equipment_id == equipment_id:
			return equipment
	return null


## Get all equipment
func get_all_equipment() -> Array[EquipmentEntity]:
	return _equipment.duplicate()


## Get equipment count
func get_equipment_count() -> int:
	return _equipment.size()


## Check if a tile position is within floor bounds
func _is_tile_in_bounds(tile_pos: Vector2i) -> bool:
	return tile_pos.x >= 0 and tile_pos.x < width_tiles \
		and tile_pos.y >= 0 and tile_pos.y < height_tiles


## Check if a tile position is occupied by equipment
func is_tile_occupied(tile_pos: Vector2i) -> bool:
	return get_equipment_at(tile_pos) != null


## Check if a world position is inside the floor bounds
func is_point_in_bounds(world_pos: Vector2) -> bool:
	return bounds.has_point(world_pos)


## Get floor dimensions as Vector2i
func get_dimensions() -> Vector2i:
	return Vector2i(width_tiles, height_tiles)


## Clear all equipment
func clear() -> void:
	_equipment.clear()


func _to_string() -> String:
	return "[FloorLayout:%s %dx%d tiles, %d equipment]" % [
		layout_id,
		width_tiles,
		height_tiles,
		_equipment.size()
	]
