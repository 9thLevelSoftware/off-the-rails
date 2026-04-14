class_name WorkshopFloorLayoutData
extends Resource

## Resource class for storing workshop floor layout data.
## Can be edited in the Godot inspector and saved as .tres files.
## Used by FloorLayoutLoader to create FloorLayout domain objects.

## Floor dimensions in tiles
@export var width_tiles: int = 5
@export var height_tiles: int = 6

## Layout identifier (derived from filename if not set)
@export var layout_id: String = ""

## Equipment definitions as an array of dictionaries.
## Each dictionary should contain:
## - equipment_id: String (required)
## - type: String (WORKBENCH, LOCKER, CRATE, SHELVING)
## - tile_x: int
## - tile_y: int
## - collision_width: float (optional, default 64)
## - collision_height: float (optional, default 32)
## - sprite_path: String (optional)
## - state: String (OPERATIONAL, DAMAGED, OFFLINE) (optional)
@export var equipment: Array[Dictionary] = []


## Get layout data as a dictionary for FloorLayoutLoader
func get_data() -> Dictionary:
	return {
		"layout_id": layout_id,
		"width_tiles": width_tiles,
		"height_tiles": height_tiles,
		"equipment": equipment
	}
