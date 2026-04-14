class_name ModManifest
extends RefCounted

## Represents a parsed mod.json manifest with validation.
##
## mod.json schema:
## {
##   "id": "example_mod",           // Required - alphanumeric with underscores, starts with letter
##   "version": "1.0.0",            // Required - semver format X.Y.Z
##   "name": "Example Mod",         // Required - display name
##   "description": "...",          // Optional
##   "author": "Author Name",       // Optional
##   "dependencies": ["other_mod"], // Optional - list of required mod IDs
##   "content_files": ["data/items.json"], // Optional - data files to load
##   "scripts": ["scripts/on_init.gd"]     // Optional - GDScript files to execute
## }

# Required fields
var id: String = ""
var version: String = ""
var name: String = ""

# Optional fields
var description: String = ""
var author: String = ""
var dependencies: Array[String] = []
var content_files: Array[String] = []
var scripts: Array[String] = []

# Metadata
var mod_path: String = ""  # Directory path where the mod lives

# Validation state
var is_valid: bool = false
var validation_errors: Array[String] = []

# Regex patterns for validation
const ID_PATTERN := "^[a-z][a-z0-9_]*$"
const VERSION_PATTERN := "^\\d+\\.\\d+\\.\\d+$"

# Pre-compiled regex instances (shared across all ModManifest instances)
static var _id_regex: RegEx
static var _version_regex: RegEx
static var _regex_initialized: bool = false


## Initialize shared regex instances (called once per session).
static func _ensure_regex_initialized() -> void:
	if _regex_initialized:
		return
	_id_regex = RegEx.new()
	_id_regex.compile(ID_PATTERN)
	_version_regex = RegEx.new()
	_version_regex.compile(VERSION_PATTERN)
	_regex_initialized = true


## Parse a JSON string into a ModManifest.
static func from_json(json_string: String, source_path: String = "") -> ModManifest:
	var manifest := ModManifest.new()
	manifest.mod_path = source_path.get_base_dir() if source_path else ""

	var json := JSON.new()
	var parse_result := json.parse(json_string)

	if parse_result != OK:
		manifest.validation_errors.append("JSON parse error at line %d: %s" % [json.get_error_line(), json.get_error_message()])
		manifest.is_valid = false
		return manifest

	var data = json.data
	if not data is Dictionary:
		manifest.validation_errors.append("Root element must be a JSON object")
		manifest.is_valid = false
		return manifest

	# Extract required fields
	manifest.id = str(data.get("id", ""))
	manifest.version = str(data.get("version", ""))
	manifest.name = str(data.get("name", ""))

	# Extract optional fields
	manifest.description = str(data.get("description", ""))
	manifest.author = str(data.get("author", ""))

	# Extract arrays with type safety
	manifest.dependencies = _extract_string_array(data, "dependencies")
	manifest.content_files = _extract_string_array(data, "content_files")
	manifest.scripts = _extract_string_array(data, "scripts")

	# Validate
	manifest.validate()

	return manifest


## Load and parse mod.json from a file path.
static func from_file(path: String) -> ModManifest:
	var manifest := ModManifest.new()
	manifest.mod_path = path.get_base_dir()

	if not FileAccess.file_exists(path):
		manifest.validation_errors.append("File not found: %s" % path)
		manifest.is_valid = false
		return manifest

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		var error := FileAccess.get_open_error()
		manifest.validation_errors.append("Failed to open file: %s (error %d)" % [path, error])
		manifest.is_valid = false
		return manifest

	var content := file.get_as_text()
	file.close()

	return from_json(content, path)


## Validate all required fields and field formats.
## Populates validation_errors array and sets is_valid.
func validate() -> bool:
	validation_errors.clear()

	_validate_id()
	_validate_version()
	_validate_name()
	_validate_dependencies()
	_validate_content_files()
	_validate_scripts()

	is_valid = validation_errors.is_empty()
	return is_valid


## ID must be non-empty, alphanumeric with underscores only.
## Pattern: ^[a-z][a-z0-9_]*$
func _validate_id() -> bool:
	if id.is_empty():
		validation_errors.append("Required field 'id' is missing or empty")
		return false

	_ensure_regex_initialized()
	if not _id_regex.search(id):
		validation_errors.append("Invalid 'id' format: must start with lowercase letter and contain only lowercase letters, numbers, and underscores. Got: '%s'" % id)
		return false

	return true


## Version must follow semver pattern: X.Y.Z
func _validate_version() -> bool:
	if version.is_empty():
		validation_errors.append("Required field 'version' is missing or empty")
		return false

	_ensure_regex_initialized()
	if not _version_regex.search(version):
		validation_errors.append("Invalid 'version' format: must be semver (X.Y.Z). Got: '%s'" % version)
		return false

	return true


## Name must be non-empty.
func _validate_name() -> bool:
	if name.is_empty():
		validation_errors.append("Required field 'name' is missing or empty")
		return false
	return true


## Validate dependencies array format.
func _validate_dependencies() -> bool:
	_ensure_regex_initialized()

	for i in range(dependencies.size()):
		var dep: String = dependencies[i]
		if dep.is_empty():
			validation_errors.append("Dependency at index %d is empty" % i)
			return false
		if not _id_regex.search(dep):
			validation_errors.append("Invalid dependency ID format at index %d: '%s'" % [i, dep])
			return false

	return true


## Validate content_files paths are reasonable.
func _validate_content_files() -> bool:
	for i in range(content_files.size()):
		var file_path: String = content_files[i]
		if file_path.is_empty():
			validation_errors.append("Content file path at index %d is empty" % i)
			return false
		# Check for path traversal attempts
		if ".." in file_path or file_path.begins_with("/") or file_path.begins_with("\\"):
			validation_errors.append("Invalid content file path at index %d: path traversal not allowed: '%s'" % [i, file_path])
			return false

	return true


## Validate script paths are reasonable.
func _validate_scripts() -> bool:
	for i in range(scripts.size()):
		var script_path: String = scripts[i]
		if script_path.is_empty():
			validation_errors.append("Script path at index %d is empty" % i)
			return false
		# Check for path traversal attempts
		if ".." in script_path or script_path.begins_with("/") or script_path.begins_with("\\"):
			validation_errors.append("Invalid script path at index %d: path traversal not allowed: '%s'" % [i, script_path])
			return false
		# Check file extension
		if not script_path.ends_with(".gd"):
			validation_errors.append("Script at index %d must be a .gd file: '%s'" % [i, script_path])
			return false

	return true


## Extract a string array from JSON data safely.
static func _extract_string_array(data: Dictionary, key: String) -> Array[String]:
	var result: Array[String] = []
	var raw = data.get(key, [])

	if raw is Array:
		for item in raw:
			result.append(str(item))

	return result


## Get the full path to a content file within this mod.
func get_content_file_path(relative_path: String) -> String:
	if mod_path.is_empty():
		return relative_path
	return mod_path.path_join(relative_path)


## Get the full path to a script file within this mod.
func get_script_path(relative_path: String) -> String:
	if mod_path.is_empty():
		return relative_path
	return mod_path.path_join(relative_path)


func _to_string() -> String:
	if is_valid:
		return "[ModManifest] %s v%s (%s)" % [id, version, name]
	else:
		return "[ModManifest] INVALID - %d errors" % validation_errors.size()
