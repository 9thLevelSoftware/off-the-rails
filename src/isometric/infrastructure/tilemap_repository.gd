# Infrastructure service for tilemap scene persistence
# Handles saving and loading tilemap configurations

class_name IsoTilemapRepository
extends RefCounted

const TILEMAP_DATA_DIR = "user://tilemaps/"


# Save tilemap layer data to file
func save_layer_data(layer_name: String, cells: Dictionary) -> Error:
	var dir = DirAccess.open("user://")
	if dir and not dir.dir_exists(TILEMAP_DATA_DIR):
		dir.make_dir(TILEMAP_DATA_DIR)

	var path = TILEMAP_DATA_DIR + layer_name + ".json"
	var file = FileAccess.open(path, FileAccess.WRITE)
	if not file:
		return FileAccess.get_open_error()

	file.store_string(JSON.stringify(cells))
	return OK


# Load tilemap layer data from file
func load_layer_data(layer_name: String) -> Dictionary:
	var path = TILEMAP_DATA_DIR + layer_name + ".json"
	if not FileAccess.file_exists(path):
		return {}

	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		return {}

	var json = JSON.new()
	var error = json.parse(file.get_as_text())
	if error != OK:
		push_error("Failed to parse tilemap data: " + path)
		return {}

	# Validate parsed data is a Dictionary
	if json.data is Dictionary:
		return json.data
	push_error("Tilemap data is not a Dictionary: " + path)
	return {}


# Check if saved data exists for a layer
func has_saved_data(layer_name: String) -> bool:
	var path = TILEMAP_DATA_DIR + layer_name + ".json"
	return FileAccess.file_exists(path)


# Delete saved layer data
func delete_layer_data(layer_name: String) -> Error:
	var path = TILEMAP_DATA_DIR + layer_name + ".json"
	if FileAccess.file_exists(path):
		return DirAccess.remove_absolute(path)
	return OK
