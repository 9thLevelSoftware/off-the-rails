# Grid layout calculations for isometric tilemaps
# Used for determining tile positions and bounds

class_name IsoTilemapLayoutCalculator
extends RefCounted

const ViewportCalc = preload("res://src/isometric/domain/viewport_calculator.gd")

# Get the bounding rect for a tilemap region
static func get_region_bounds(grid_start: Vector2i, grid_size: Vector2i) -> Rect2:
	var top_left = ViewportCalc.iso_to_screen(Vector2(grid_start))
	var bottom_right = ViewportCalc.iso_to_screen(Vector2(grid_start + grid_size))
	return Rect2(top_left, bottom_right - top_left)

# Check if a screen position is within a tile
static func is_point_in_tile(screen_pos: Vector2, tile_center: Vector2) -> bool:
	var relative = screen_pos - tile_center
	var half_width = ViewportCalc.TILE_WIDTH * 0.5
	var half_height = ViewportCalc.TILE_HEIGHT * 0.5
	return (absf(relative.x) / half_width + absf(relative.y) / half_height) <= 1.0

# Get adjacent tile positions (4-direction)
static func get_adjacent_tiles(grid_pos: Vector2i) -> Array[Vector2i]:
	return [
		grid_pos + Vector2i(1, 0),   # East
		grid_pos + Vector2i(-1, 0),  # West
		grid_pos + Vector2i(0, 1),   # South
		grid_pos + Vector2i(0, -1),  # North
	]
