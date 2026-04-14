class_name FloorLayoutLoader
extends RefCounted

## Infrastructure service for loading FloorLayout from .tres resource files.
## Provides static methods for resource loading and parsing.
## Handles validation and error reporting.

## Load a FloorLayout from a resource file.
## Returns null if loading fails.
static func load_from_resource(resource_path: String) -> FloorLayout:
	if resource_path == null or resource_path.is_empty():
		push_error("FloorLayoutLoader: Resource path is null or empty")
		return null

	if not ResourceLoader.exists(resource_path):
		push_error("FloorLayoutLoader: Resource not found: %s" % resource_path)
		return null

	var resource = load(resource_path)
	if resource == null:
		push_error("FloorLayoutLoader: Failed to load resource: %s" % resource_path)
		return null

	return _parse_resource(resource, resource_path)


## Parse a loaded resource into a FloorLayout.
## Expects resource to have: layout_id, width_tiles, height_tiles, equipment (Array)
static func _parse_resource(resource: Resource, source_path: String) -> FloorLayout:
	if resource == null:
		push_error("FloorLayoutLoader: Cannot parse null resource")
		return null

	# Validate required fields
	var layout_id: String = ""
	var width_tiles: int = 0
	var height_tiles: int = 0

	# Get layout_id
	if resource.get("layout_id") != null:
		layout_id = str(resource.get("layout_id"))
	else:
		# Fall back to filename
		layout_id = source_path.get_file().get_basename()
		push_warning("FloorLayoutLoader: Missing layout_id, using filename: %s" % layout_id)

	# Get dimensions
	if resource.get("width_tiles") != null:
		width_tiles = int(resource.get("width_tiles"))
	else:
		push_error("FloorLayoutLoader: Missing required field 'width_tiles' in %s" % source_path)
		return null

	if resource.get("height_tiles") != null:
		height_tiles = int(resource.get("height_tiles"))
	else:
		push_error("FloorLayoutLoader: Missing required field 'height_tiles' in %s" % source_path)
		return null

	# Validate dimensions
	if width_tiles <= 0 or height_tiles <= 0:
		push_error("FloorLayoutLoader: Invalid dimensions %dx%d in %s" % [
			width_tiles, height_tiles, source_path
		])
		return null

	# Create layout
	var layout := FloorLayout.create(layout_id, width_tiles, height_tiles)

	# Parse equipment array
	var equipment_data = resource.get("equipment")
	if equipment_data != null and equipment_data is Array:
		for item in equipment_data:
			var equipment := _parse_equipment_data(item)
			if equipment != null:
				layout.add_equipment(equipment)
	elif equipment_data != null:
		push_warning("FloorLayoutLoader: 'equipment' field is not an Array in %s" % source_path)

	return layout


## Parse a single equipment entry from resource data.
## Expects: { equipment_id, type, tile_x, tile_y, [state], [collision_width], [collision_height], [sprite_path] }
static func _parse_equipment_data(data) -> EquipmentEntity:
	if data == null:
		push_warning("FloorLayoutLoader: Null equipment data entry")
		return null

	# Handle Dictionary data
	if data is Dictionary:
		return _parse_equipment_dict(data)

	# Handle Resource data (nested resource)
	if data is Resource:
		return _parse_equipment_resource(data)

	push_warning("FloorLayoutLoader: Unsupported equipment data type: %s" % typeof(data))
	return null


## Parse equipment from Dictionary
static func _parse_equipment_dict(data: Dictionary) -> EquipmentEntity:
	# Validate required fields
	if not data.has("equipment_id"):
		push_error("FloorLayoutLoader: Equipment missing required field 'equipment_id'")
		return null

	if not data.has("type"):
		push_error("FloorLayoutLoader: Equipment missing required field 'type'")
		return null

	var equipment_id: String = str(data.get("equipment_id", ""))
	var type_str: String = str(data.get("type", "WORKBENCH"))
	var equipment_type := EquipmentEntity.parse_type(type_str)

	# Parse position
	var tile_x: int = int(data.get("tile_x", 0))
	var tile_y: int = int(data.get("tile_y", 0))
	var tile_position := Vector2i(tile_x, tile_y)

	# Parse collision size (defaults to one tile)
	var collision_width: float = float(data.get("collision_width", 64.0))
	var collision_height: float = float(data.get("collision_height", 32.0))
	var collision_size := Vector2(collision_width, collision_height)

	# Create entity
	var entity := EquipmentEntity.create(equipment_id, equipment_type, tile_position, collision_size)

	# Parse optional fields
	if data.has("state"):
		var state_str: String = str(data.get("state", "OPERATIONAL"))
		entity.state = EquipmentEntity.parse_state(state_str)

	if data.has("sprite_path"):
		entity.sprite_path = str(data.get("sprite_path", ""))

	return entity


## Parse equipment from Resource
static func _parse_equipment_resource(data: Resource) -> EquipmentEntity:
	# Convert resource properties to dictionary and parse
	var dict := {}

	if data.get("equipment_id") != null:
		dict["equipment_id"] = data.get("equipment_id")
	if data.get("type") != null:
		dict["type"] = data.get("type")
	if data.get("tile_x") != null:
		dict["tile_x"] = data.get("tile_x")
	if data.get("tile_y") != null:
		dict["tile_y"] = data.get("tile_y")
	if data.get("state") != null:
		dict["state"] = data.get("state")
	if data.get("collision_width") != null:
		dict["collision_width"] = data.get("collision_width")
	if data.get("collision_height") != null:
		dict["collision_height"] = data.get("collision_height")
	if data.get("sprite_path") != null:
		dict["sprite_path"] = data.get("sprite_path")

	return _parse_equipment_dict(dict)


## Create a FloorLayout directly from data (for testing or runtime generation)
static func create_from_data(
	layout_id: String,
	width_tiles: int,
	height_tiles: int,
	equipment_list: Array = []
) -> FloorLayout:
	if layout_id == null or layout_id.is_empty():
		push_error("FloorLayoutLoader: layout_id is null or empty")
		return null

	if width_tiles <= 0 or height_tiles <= 0:
		push_error("FloorLayoutLoader: Invalid dimensions %dx%d" % [width_tiles, height_tiles])
		return null

	var layout := FloorLayout.create(layout_id, width_tiles, height_tiles)

	for item in equipment_list:
		var equipment := _parse_equipment_data(item)
		if equipment != null:
			layout.add_equipment(equipment)

	return layout
