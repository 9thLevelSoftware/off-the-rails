class_name DataLoader
extends RefCounted

## Infrastructure layer - converts JSON files to Godot Dictionaries.
## Domain code never uses this directly; ContentRegistry mediates all access.
##
## Usage:
##   var loader := DataLoader.new()
##   var data := loader.load_json("res://data/base_items.json")
##   if data.is_empty():
##       push_error("Failed to load items")


## Load and parse a JSON file, returning the parsed Dictionary.
## Returns empty Dictionary on any error (file not found, parse failure).
func load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_error("DataLoader: JSON file not found: %s" % path)
		return {}

	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		var error := FileAccess.get_open_error()
		push_error("DataLoader: Cannot open JSON file: %s (error %d)" % [path, error])
		return {}

	var content := file.get_as_text()
	file.close()

	return load_json_from_string(content, path)


## Parse a JSON string directly, with optional source path for error messages.
## Returns empty Dictionary on parse failure.
func load_json_from_string(content: String, source_path: String = "<string>") -> Dictionary:
	if content.strip_edges().is_empty():
		push_error("DataLoader: Empty JSON content from %s" % source_path)
		return {}

	var json := JSON.new()
	var error := json.parse(content)

	if error != OK:
		push_error("DataLoader: JSON parse error in %s at line %d: %s" % [
			source_path,
			json.get_error_line(),
			json.get_error_message()
		])
		return {}

	var data = json.get_data()
	if not data is Dictionary:
		push_error("DataLoader: JSON root must be an object in %s, got %s" % [
			source_path,
			typeof(data)
		])
		return {}

	return data


## Save a Dictionary as a formatted JSON file.
## Used for mod development tools and debugging.
## Returns true on success.
func save_json(path: String, data: Dictionary, indent: int = 2) -> bool:
	var json_string := JSON.stringify(data, _make_indent(indent))

	var file := FileAccess.open(path, FileAccess.WRITE)
	if not file:
		var error := FileAccess.get_open_error()
		push_error("DataLoader: Cannot create JSON file: %s (error %d)" % [path, error])
		return false

	file.store_string(json_string)
	file.close()
	return true


## Load all JSON files in a directory, returning array of parsed Dictionaries.
## Useful for loading mod content directories.
func load_json_directory(dir_path: String) -> Array[Dictionary]:
	var results: Array[Dictionary] = []

	var dir := DirAccess.open(dir_path)
	if not dir:
		push_error("DataLoader: Cannot open directory: %s" % dir_path)
		return results

	dir.list_dir_begin()
	var file_name := dir.get_next()

	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".json"):
			var full_path := dir_path.path_join(file_name)
			var data := load_json(full_path)
			if not data.is_empty():
				# Include source file info for debugging
				data["_source_file"] = full_path
				results.append(data)
		file_name = dir.get_next()

	dir.list_dir_end()
	return results


## Create indent string for JSON formatting.
func _make_indent(spaces: int) -> String:
	if spaces <= 0:
		return ""
	var result := ""
	for i in range(spaces):
		result += " "
	return result
