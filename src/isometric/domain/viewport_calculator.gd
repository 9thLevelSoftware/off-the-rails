# Y-sort depth calculation and projection math for isometric rendering
# Pure functions, no scene tree dependencies

class_name IsoViewportCalculator
extends RefCounted

# Isometric tile dimensions (2:1 ratio)
const TILE_WIDTH: int = 64
const TILE_HEIGHT: int = 32

# Calculate Y-sort depth from isometric position
static func calculate_depth(iso_position: Vector2) -> float:
	return iso_position.x + iso_position.y

# Convert screen coordinates to isometric grid coordinates
static func screen_to_iso(screen_pos: Vector2) -> Vector2:
	var iso_x = (screen_pos.x / (TILE_WIDTH * 0.5) + screen_pos.y / (TILE_HEIGHT * 0.5)) / 2.0
	var iso_y = (screen_pos.y / (TILE_HEIGHT * 0.5) - screen_pos.x / (TILE_WIDTH * 0.5)) / 2.0
	return Vector2(iso_x, iso_y)

# Convert isometric grid coordinates to screen coordinates
static func iso_to_screen(iso_pos: Vector2) -> Vector2:
	var screen_x = (iso_pos.x - iso_pos.y) * (TILE_WIDTH * 0.5)
	var screen_y = (iso_pos.x + iso_pos.y) * (TILE_HEIGHT * 0.5)
	return Vector2(screen_x, screen_y)
