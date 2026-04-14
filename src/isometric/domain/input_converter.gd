# Converts WASD input vectors to isometric screen directions
# Pure domain logic — no node dependencies

class_name InputConverter
extends RefCounted

const DEAD_ZONE_SQUARED := 0.01


static func wasd_to_isometric(input: Vector2) -> Vector2:
	if input.length_squared() < DEAD_ZONE_SQUARED:
		return Vector2.ZERO
	var iso := Vector2(input.x - input.y, (input.x + input.y) * 0.5)
	return iso.normalized()
