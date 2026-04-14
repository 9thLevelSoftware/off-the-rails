class_name InteractionRange
extends RefCounted

## Static utility class for isometric distance calculations.
## Operates in world (screen) coordinates, not tile coordinates.
## No Node dependencies - pure math suitable for domain layer.

## Default interaction range in pixels (roughly 1.25 tiles in isometric space)
const DEFAULT_RANGE := 80.0


## Calculate Euclidean distance between two world positions.
static func distance_2d(from: Vector2, to: Vector2) -> float:
	return from.distance_to(to)


## Check if two positions are within the specified range.
## Uses world (screen) coordinates for isometric compatibility.
static func is_in_range(from: Vector2, to: Vector2, range_px: float = DEFAULT_RANGE) -> bool:
	# Use distance_squared for performance, compare against squared range
	var distance_sq := from.distance_squared_to(to)
	return distance_sq <= range_px * range_px


## Find the index of the nearest target position.
## Returns -1 if targets array is empty.
static func find_nearest(from: Vector2, targets: Array[Vector2]) -> int:
	if targets.is_empty():
		return -1

	var nearest_index := 0
	var nearest_distance_sq := from.distance_squared_to(targets[0])

	for i in range(1, targets.size()):
		var distance_sq := from.distance_squared_to(targets[i])
		if distance_sq < nearest_distance_sq:
			nearest_distance_sq = distance_sq
			nearest_index = i

	return nearest_index


## Find nearest target within range. Returns index or -1 if none in range.
static func find_nearest_in_range(from: Vector2, targets: Array[Vector2], range_px: float = DEFAULT_RANGE) -> int:
	if targets.is_empty():
		return -1

	var range_sq := range_px * range_px
	var nearest_index := -1
	var nearest_distance_sq := INF

	for i in range(targets.size()):
		var distance_sq := from.distance_squared_to(targets[i])
		if distance_sq <= range_sq and distance_sq < nearest_distance_sq:
			nearest_distance_sq = distance_sq
			nearest_index = i

	return nearest_index
