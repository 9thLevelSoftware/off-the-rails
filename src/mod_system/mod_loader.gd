class_name ModLoader
extends Node

## Mod discovery and loading autoload.
##
## Discovers mods in user://mods/, validates manifests, initializes mod content.
## Handles all errors gracefully — never crashes on malformed mods.

signal mod_discovered(mod_id: String, manifest: ModManifest)
signal mod_loaded(mod_id: String)
signal mod_load_failed(mod_id: String, error: ModErrorHandler.ModError)
signal all_mods_loaded(count: int)

const MODS_DIR := "user://mods/"

var _discovered_mods: Dictionary = {}  # mod_id -> ModManifest
var _loaded_mods: Array[String] = []
var _error_handler: ModErrorHandler


func _ready() -> void:
	_error_handler = ModErrorHandler.new()
	_error_handler.name = "ModErrorHandler"
	add_child(_error_handler)

	# Ensure mods directory exists
	_ensure_mods_directory()


## Ensure the mods directory exists, creating it if necessary.
func _ensure_mods_directory() -> void:
	if not DirAccess.dir_exists_absolute(MODS_DIR):
		var err := DirAccess.make_dir_recursive_absolute(MODS_DIR)
		if err != OK:
			push_warning("[ModLoader] Could not create mods directory: %s (error %d)" % [MODS_DIR, err])
		else:
			print("[ModLoader] Created mods directory: %s" % MODS_DIR)


## Scan user://mods/ for directories containing mod.json.
## Returns array of valid ModManifest objects.
func discover_mods() -> Array[ModManifest]:
	_discovered_mods.clear()
	var manifests: Array[ModManifest] = []

	var dir := DirAccess.open(MODS_DIR)
	if dir == null:
		var error := DirAccess.get_open_error()
		if error != ERR_FILE_NOT_FOUND:
			push_warning("[ModLoader] Could not open mods directory: %s (error %d)" % [MODS_DIR, error])
		return manifests

	# Scan for subdirectories
	dir.list_dir_begin()
	var dir_name := dir.get_next()

	while dir_name != "":
		if dir.current_is_dir() and not dir_name.begins_with("."):
			var mod_dir_path := MODS_DIR.path_join(dir_name)
			var manifest_path := mod_dir_path.path_join("mod.json")

			var manifest := _try_load_manifest(dir_name, manifest_path)
			if manifest != null:
				manifests.append(manifest)

		dir_name = dir.get_next()

	dir.list_dir_end()

	print("[ModLoader] Discovered %d mod(s)" % manifests.size())
	return manifests


## Attempt to load a manifest from a path.
## Returns null if loading fails (error is logged).
func _try_load_manifest(dir_name: String, manifest_path: String) -> ModManifest:
	# Check if mod.json exists
	if not FileAccess.file_exists(manifest_path):
		_error_handler.handle_error(
			dir_name,
			ModErrorHandler.ErrorType.MANIFEST_NOT_FOUND,
			"No mod.json found in mod directory",
			{"path": manifest_path}
		)
		return null

	# Try to parse the manifest
	var manifest := ModManifest.from_file(manifest_path)

	# Check for parse errors (stored in validation_errors before validate() is called)
	if not manifest.validation_errors.is_empty() and not manifest.is_valid:
		# Check if this is a parse error vs validation error
		var first_error: String = manifest.validation_errors[0]
		if first_error.begins_with("JSON parse error") or first_error.begins_with("File not found") or first_error.begins_with("Failed to open"):
			_error_handler.handle_error(
				dir_name,
				ModErrorHandler.ErrorType.MANIFEST_PARSE_FAILED,
				first_error,
				{"path": manifest_path}
			)
			return null

	# Check validation
	if not manifest.is_valid:
		_error_handler.handle_error(
			manifest.id if manifest.id else dir_name,
			ModErrorHandler.ErrorType.MANIFEST_INVALID,
			"Manifest validation failed",
			{"errors": manifest.validation_errors}
		)
		return null

	# Check for duplicate mod IDs
	if manifest.id in _discovered_mods:
		_error_handler.handle_warning(
			manifest.id,
			ModErrorHandler.WarningType.CONTENT_OVERRIDE,
			"Duplicate mod ID detected, using latest discovered"
		)

	# Store and emit
	_discovered_mods[manifest.id] = manifest
	mod_discovered.emit(manifest.id, manifest)
	print("[ModLoader] Discovered mod: %s v%s" % [manifest.id, manifest.version])

	return manifest


## Load a discovered mod's content.
## Returns true on success, false on failure.
func load_mod(mod_id: String) -> bool:
	if mod_id not in _discovered_mods:
		_error_handler.handle_error(
			mod_id,
			ModErrorHandler.ErrorType.MANIFEST_NOT_FOUND,
			"Mod not discovered, cannot load"
		)
		return false

	if mod_id in _loaded_mods:
		push_warning("[ModLoader] Mod '%s' is already loaded" % mod_id)
		return true

	var manifest: ModManifest = _discovered_mods[mod_id]

	# Check dependencies first
	if not _check_dependencies(manifest):
		return false

	# Load content files
	if not _load_content_files(manifest):
		return false

	# Load and execute scripts
	if not _load_scripts(manifest):
		return false

	_loaded_mods.append(mod_id)
	mod_loaded.emit(mod_id)
	print("[ModLoader] Loaded mod: %s" % mod_id)

	return true


## Check if all dependencies are available.
func _check_dependencies(manifest: ModManifest) -> bool:
	for dep_id in manifest.dependencies:
		if dep_id not in _discovered_mods:
			var error := _error_handler.handle_error(
				manifest.id,
				ModErrorHandler.ErrorType.DEPENDENCY_MISSING,
				"Required dependency not found: %s" % dep_id,
				{"dependency": dep_id}
			)
			mod_load_failed.emit(manifest.id, error)
			return false
	return true


## Load content files for a mod (placeholder for future implementation).
func _load_content_files(manifest: ModManifest) -> bool:
	for content_file in manifest.content_files:
		var full_path := manifest.get_content_file_path(content_file)

		# Verify file exists
		if not FileAccess.file_exists(full_path):
			var error := _error_handler.handle_error(
				manifest.id,
				ModErrorHandler.ErrorType.CONTENT_LOAD_FAILED,
				"Content file not found: %s" % content_file,
				{"path": full_path}
			)
			mod_load_failed.emit(manifest.id, error)
			return false

		# TODO: Actually load and register content based on file type
		# This will be implemented in future phases
		print("[ModLoader] Found content file: %s" % full_path)

	return true


## Load and validate scripts for a mod (placeholder for future implementation).
func _load_scripts(manifest: ModManifest) -> bool:
	for script_path in manifest.scripts:
		var full_path := manifest.get_script_path(script_path)

		# Verify file exists
		if not FileAccess.file_exists(full_path):
			var error := _error_handler.handle_error(
				manifest.id,
				ModErrorHandler.ErrorType.SCRIPT_LOAD_FAILED,
				"Script file not found: %s" % script_path,
				{"path": full_path}
			)
			mod_load_failed.emit(manifest.id, error)
			return false

		# TODO: Actually load and execute scripts
		# This will be implemented in future phases with sandboxing
		print("[ModLoader] Found script: %s" % full_path)

	return true


## Load all discovered mods in dependency order.
## Returns count of successfully loaded mods.
func load_all_mods() -> int:
	# Build load order respecting dependencies
	var load_order := _compute_load_order()
	var loaded_count := 0

	for mod_id in load_order:
		if load_mod(mod_id):
			loaded_count += 1

	all_mods_loaded.emit(loaded_count)
	print("[ModLoader] Loaded %d/%d mod(s)" % [loaded_count, _discovered_mods.size()])

	return loaded_count


## Compute a load order that respects dependencies.
## Uses topological sort.
func _compute_load_order() -> Array[String]:
	var order: Array[String] = []
	var visited: Dictionary = {}
	var in_progress: Dictionary = {}

	for mod_id in _discovered_mods:
		if mod_id not in visited:
			_visit_for_sort(mod_id, visited, in_progress, order)

	return order


## Recursive helper for topological sort.
func _visit_for_sort(mod_id: String, visited: Dictionary, in_progress: Dictionary, order: Array[String]) -> void:
	if mod_id in visited:
		return

	if mod_id in in_progress:
		# Circular dependency detected
		_error_handler.handle_error(
			mod_id,
			ModErrorHandler.ErrorType.DEPENDENCY_MISSING,
			"Circular dependency detected"
		)
		return

	if mod_id not in _discovered_mods:
		return

	in_progress[mod_id] = true

	var manifest: ModManifest = _discovered_mods[mod_id]
	for dep_id in manifest.dependencies:
		_visit_for_sort(dep_id, visited, in_progress, order)

	in_progress.erase(mod_id)
	visited[mod_id] = true
	order.append(mod_id)


## Get a mod's manifest by ID.
func get_mod_manifest(mod_id: String) -> ModManifest:
	return _discovered_mods.get(mod_id)


## Check if a mod is loaded.
func is_mod_loaded(mod_id: String) -> bool:
	return mod_id in _loaded_mods


## Check if a mod is discovered.
func is_mod_discovered(mod_id: String) -> bool:
	return mod_id in _discovered_mods


## Get all discovered mod IDs.
func get_discovered_mod_ids() -> Array[String]:
	var result: Array[String] = []
	for mod_id in _discovered_mods:
		result.append(mod_id)
	return result


## Get all loaded mod IDs.
func get_loaded_mod_ids() -> Array[String]:
	return _loaded_mods.duplicate()


## Get the error handler for external access.
func get_error_handler() -> ModErrorHandler:
	return _error_handler


## Reload all mods (clears state and rediscovers).
func reload_mods() -> int:
	_discovered_mods.clear()
	_loaded_mods.clear()
	_error_handler.clear()

	discover_mods()
	return load_all_mods()
