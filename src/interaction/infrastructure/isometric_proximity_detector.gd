class_name IsometricProximityDetector
extends RefCounted

## Infrastructure class for querying nearby interactables in isometric space.
## Tracks registered interactables and provides efficient proximity queries.
## No Node dependencies - operates on pure position and config data.

## Internal storage for registered interactables
## Each entry: {id: String, position: Vector2, config: InteractableConfig}
var _interactables: Array[Dictionary] = []


## Register an interactable with its position and configuration.
func register(id: String, position: Vector2, config: InteractableConfig) -> void:
	# Check for duplicate registration
	for i in range(_interactables.size()):
		if _interactables[i]["id"] == id:
			# Update existing entry instead of adding duplicate
			_interactables[i]["position"] = position
			_interactables[i]["config"] = config
			return

	_interactables.append({
		"id": id,
		"position": position,
		"config": config
	})


## Unregister an interactable by ID.
func unregister(id: String) -> void:
	for i in range(_interactables.size() - 1, -1, -1):
		if _interactables[i]["id"] == id:
			_interactables.remove_at(i)
			return


## Update the position of a registered interactable.
func update_position(id: String, new_position: Vector2) -> void:
	for entry in _interactables:
		if entry["id"] == id:
			entry["position"] = new_position
			return
	push_warning("IsometricProximityDetector: Cannot update position for unregistered ID: %s" % id)


## Query all interactables within range of a position.
## If range_override > 0, uses that range instead of each interactable's config range.
## Returns array of IDs that are in range.
func query_in_range(from: Vector2, range_override: float = -1.0) -> Array[String]:
	var result: Array[String] = []

	for entry in _interactables:
		var config: InteractableConfig = entry["config"]
		var check_range := range_override if range_override > 0 else config.interaction_range

		if InteractionRange.is_in_range(from, entry["position"], check_range):
			result.append(entry["id"])

	return result


## Find the nearest interactable within range of a position.
## If range_override > 0, uses that range instead of each interactable's config range.
## Returns the ID of the nearest interactable, or empty string if none in range.
func find_nearest_in_range(from: Vector2, range_override: float = -1.0) -> String:
	var nearest_id := ""
	var nearest_distance_sq := INF

	for entry in _interactables:
		var config: InteractableConfig = entry["config"]
		var check_range := range_override if range_override > 0 else config.interaction_range
		var range_sq := check_range * check_range

		var distance_sq := from.distance_squared_to(entry["position"])
		if distance_sq <= range_sq and distance_sq < nearest_distance_sq:
			nearest_distance_sq = distance_sq
			nearest_id = entry["id"]

	return nearest_id


## Get the configuration for a registered interactable.
## Returns null if ID is not registered.
func get_config(id: String) -> InteractableConfig:
	for entry in _interactables:
		if entry["id"] == id:
			return entry["config"]
	return null


## Get the position of a registered interactable.
## Returns Vector2.ZERO if ID is not registered.
func get_position(id: String) -> Vector2:
	for entry in _interactables:
		if entry["id"] == id:
			return entry["position"]
	return Vector2.ZERO


## Get the count of registered interactables.
func get_count() -> int:
	return _interactables.size()


## Check if an ID is registered.
func is_registered(id: String) -> bool:
	for entry in _interactables:
		if entry["id"] == id:
			return true
	return false


## Clear all registered interactables.
func clear() -> void:
	_interactables.clear()
