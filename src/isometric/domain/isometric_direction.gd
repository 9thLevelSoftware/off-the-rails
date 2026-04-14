# Isometric direction enum and conversion utilities
# Pure domain logic — no node dependencies

class_name IsometricDirection
# Static-only utility class. Extends RefCounted as GDScript namespace convention
# (no abstract/static class keyword available).
extends RefCounted

enum Direction {
	NONE = 0,
	N = 1,
	NE = 2,
	E = 3,
	SE = 4,
	S = 5,
	SW = 6,
	W = 7,
	NW = 8,
}

const DEAD_ZONE := 0.1

# Unit vectors for each direction (screen-space, Y-down)
const _DIRECTION_VECTORS := {
	Direction.NONE: Vector2.ZERO,
	Direction.N: Vector2(0.0, -1.0),
	Direction.NE: Vector2(0.707107, -0.707107),  # sqrt(2)/2 ≈ 0.707107
	Direction.E: Vector2(1.0, 0.0),
	Direction.SE: Vector2(0.707107, 0.707107),
	Direction.S: Vector2(0.0, 1.0),
	Direction.SW: Vector2(-0.707107, 0.707107),
	Direction.W: Vector2(-1.0, 0.0),
	Direction.NW: Vector2(-0.707107, -0.707107),
}

static func from_vector(input: Vector2) -> Direction:
	if input.length() < DEAD_ZONE:
		return Direction.NONE

	# Angle in radians, 0 = right, positive = clockwise (Y-down)
	var angle := input.angle()
	# Snap to nearest 45-degree sector
	# Shift by half-sector (PI/8) so boundaries fall between directions
	var sector := wrapi(roundi(angle / (PI / 4.0)), 0, 8)

	# Sector 0 = East (angle ~0), going clockwise
	match sector:
		0: return Direction.E
		1: return Direction.SE
		2: return Direction.S
		3: return Direction.SW
		4: return Direction.W
		5: return Direction.NW
		6: return Direction.N
		7: return Direction.NE
		_: return Direction.NONE


static func to_vector(dir: Direction) -> Vector2:
	return _DIRECTION_VECTORS.get(dir, Vector2.ZERO)
