class_name EquipmentEntity
extends RefCounted

## Pure domain entity representing equipment in a train car.
## Stores position, type, state, and collision data.
## No Node dependencies - suitable for use in domain layer.

enum EquipmentType {
	WORKBENCH,
	LOCKER,
	CRATE,
	SHELVING
}

enum EquipmentState {
	OPERATIONAL,
	DAMAGED,
	OFFLINE
}

## Isometric tile dimensions for coordinate conversion
const TILE_HALF_WIDTH: int = 32
const TILE_HALF_HEIGHT: int = 16

## Unique identifier for this equipment instance
var equipment_id: String = ""

## Type of equipment
var equipment_type: EquipmentType = EquipmentType.WORKBENCH

## Current operational state
var state: EquipmentState = EquipmentState.OPERATIONAL

## Position in tile coordinates (grid position)
var tile_position: Vector2i = Vector2i.ZERO

## Collision rectangle in isometric world coordinates
var collision_rect: Rect2 = Rect2()

## Path to sprite resource for adapter to load
var sprite_path: String = ""


## Private constructor - use static create() instead
func _init() -> void:
	pass


## Factory method to create a new EquipmentEntity
static func create(
	p_equipment_id: String,
	p_equipment_type: EquipmentType,
	p_tile_position: Vector2i = Vector2i.ZERO,
	p_collision_size: Vector2 = Vector2(64, 32)
) -> EquipmentEntity:
	var entity := EquipmentEntity.new()
	entity.equipment_id = p_equipment_id
	entity.equipment_type = p_equipment_type
	entity.set_position(p_tile_position, p_collision_size)
	return entity


## Set position from tile coordinates and calculate world collision rect.
## Isometric conversion: world_x = (tile_x - tile_y) * 32, world_y = (tile_x + tile_y) * 16
func set_position(p_tile_position: Vector2i, collision_size: Vector2 = Vector2(64, 32)) -> void:
	tile_position = p_tile_position
	var world_pos := tile_to_world(p_tile_position)
	# Center the collision rect on the world position
	collision_rect = Rect2(
		world_pos - collision_size * 0.5,
		collision_size
	)


## Convert tile coordinates to world (screen) coordinates.
## Uses standard isometric projection: 2:1 ratio with 64x32 tiles
static func tile_to_world(tile_pos: Vector2i) -> Vector2:
	var world_x := float((tile_pos.x - tile_pos.y) * TILE_HALF_WIDTH)
	var world_y := float((tile_pos.x + tile_pos.y) * TILE_HALF_HEIGHT)
	return Vector2(world_x, world_y)


## Convert world coordinates back to tile coordinates.
## Inverse of tile_to_world
static func world_to_tile(world_pos: Vector2) -> Vector2i:
	var iso_x := (world_pos.x / TILE_HALF_WIDTH + world_pos.y / TILE_HALF_HEIGHT) / 2.0
	var iso_y := (world_pos.y / TILE_HALF_HEIGHT - world_pos.x / TILE_HALF_WIDTH) / 2.0
	return Vector2i(roundi(iso_x), roundi(iso_y))


## Get world position (center of collision rect)
func get_world_position() -> Vector2:
	return collision_rect.get_center()


## Check if a world position is within this equipment's collision area
func contains_point(world_pos: Vector2) -> bool:
	return collision_rect.has_point(world_pos)


## Check if this equipment's collision overlaps with a rect
func overlaps_rect(rect: Rect2) -> bool:
	return collision_rect.intersects(rect)


## Set equipment state
func set_state(new_state: EquipmentState) -> void:
	state = new_state


## Check if equipment is operational
func is_operational() -> bool:
	return state == EquipmentState.OPERATIONAL


## Check if equipment is damaged
func is_damaged() -> bool:
	return state == EquipmentState.DAMAGED


## Check if equipment is offline
func is_offline() -> bool:
	return state == EquipmentState.OFFLINE


## Get type as string for serialization/debugging
func get_type_name() -> String:
	match equipment_type:
		EquipmentType.WORKBENCH:
			return "WORKBENCH"
		EquipmentType.LOCKER:
			return "LOCKER"
		EquipmentType.CRATE:
			return "CRATE"
		EquipmentType.SHELVING:
			return "SHELVING"
	return "UNKNOWN"


## Get state as string for serialization/debugging
func get_state_name() -> String:
	match state:
		EquipmentState.OPERATIONAL:
			return "OPERATIONAL"
		EquipmentState.DAMAGED:
			return "DAMAGED"
		EquipmentState.OFFLINE:
			return "OFFLINE"
	return "UNKNOWN"


## Parse equipment type from string
static func parse_type(type_str: String) -> EquipmentType:
	match type_str.to_upper():
		"WORKBENCH":
			return EquipmentType.WORKBENCH
		"LOCKER":
			return EquipmentType.LOCKER
		"CRATE":
			return EquipmentType.CRATE
		"SHELVING":
			return EquipmentType.SHELVING
	push_warning("EquipmentEntity: Unknown type string: %s, defaulting to WORKBENCH" % type_str)
	return EquipmentType.WORKBENCH


## Parse equipment state from string
static func parse_state(state_str: String) -> EquipmentState:
	match state_str.to_upper():
		"OPERATIONAL":
			return EquipmentState.OPERATIONAL
		"DAMAGED":
			return EquipmentState.DAMAGED
		"OFFLINE":
			return EquipmentState.OFFLINE
	push_warning("EquipmentEntity: Unknown state string: %s, defaulting to OPERATIONAL" % state_str)
	return EquipmentState.OPERATIONAL


func _to_string() -> String:
	return "[EquipmentEntity:%s %s at %s %s]" % [
		equipment_id,
		get_type_name(),
		tile_position,
		get_state_name()
	]
