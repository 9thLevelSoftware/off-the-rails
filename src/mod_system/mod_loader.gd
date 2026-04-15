extends Node
## ModLoader autoload — access via the autoload name, not class_name.
## (class_name removed to avoid shadowing the autoload singleton)

## Mod discovery and loading autoload.
##
## Discovers mods in user://mods/, validates manifests, initializes mod content.
## Handles all errors gracefully — never crashes on malformed mods.
##
## CRITICAL: EventHooks autoload MUST load before ModLoader in project.godot.

signal mod_discovered(mod_id: String, manifest: ModManifest)
signal mod_loaded(mod_id: String)
signal mod_load_failed(mod_id: String, error: ModErrorHandler.ModError)
signal all_mods_loaded(count: int)

const MODS_DIR := "user://mods/"

var _discovered_mods: Dictionary = {}  # mod_id -> ModManifest
var _loaded_mods: Array[String] = []
var _failed_mods: Dictionary = {}  # mod_id -> true for mods that failed to load
var _script_instances: Dictionary = {}  # mod_id -> Array[RefCounted]
var _error_handler: ModErrorHandler
var _content_registry: ContentRegistry
var _mod_api: ModAPI
var _initialized: bool = false  # CRITICAL: initialization guard
var _event_hooks: Node  # Cached reference to EventHooks autoload


func _ready() -> void:
	# CRITICAL: Use call_deferred to ensure EventHooks is ready
	call_deferred("_initialize")


## Initialize the mod system after autoloads are ready.
func _initialize() -> void:
	# Guard against multiple initialization
	if _initialized:
		push_warning("[ModLoader] Already initialized")
		return

	# CRITICAL: Get EventHooks reference via get_node (class_name removed to avoid shadowing)
	# Debug: print available root children
	var root = get_tree().root
	print("[ModLoader] Root children: ", root.get_children().map(func(n): return n.name))

	_event_hooks = root.get_node_or_null("EventHooks")
	if not _event_hooks:
		push_error("[ModLoader] FATAL: EventHooks not available. Check autoload order.")
		return

	_error_handler = ModErrorHandler.new()
	_error_handler.name = "ModErrorHandler"
	add_child(_error_handler)

	# Initialize content registry and mod API
	_content_registry = ContentRegistry.new()
	_mod_api = ModAPI.new(_content_registry)

	# Ensure mods directory exists
	_ensure_mods_directory()

	# Load base game content first
	if not _content_registry.load_base_content():
		push_error("[ModLoader] Failed to load base game content")
		# Continue anyway - mods might not need base content

	# Discover and load all mods
	var _manifests := discover_mods()
	var loaded := load_all_mods()

	_initialized = true
	print("[ModLoader] Initialization complete - %d mods loaded" % loaded)
	_event_hooks.game_ready.emit()


## Check if ModLoader has completed initialization.
func is_ready() -> bool:
	return _initialized


## Get the content registry.
func get_content_registry() -> ContentRegistry:
	return _content_registry


## Get the mod API for external access.
func get_mod_api() -> ModAPI:
	return _mod_api


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
	if manifest.validation_errors.size() > 0 and not manifest.is_valid:
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

	# Emit mod loading signal
	if _event_hooks:
		_event_hooks.mod_loading.emit(mod_id)

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

	# Emit mod loaded signal
	if _event_hooks:
		_event_hooks.mod_loaded.emit(mod_id)

	print("[ModLoader] Loaded mod: %s" % mod_id)

	return true


## Check if all dependencies are available and loaded successfully.
func _check_dependencies(manifest: ModManifest) -> bool:
	for dep_id in manifest.dependencies:
		# First check if dependency was discovered
		if dep_id not in _discovered_mods:
			var error := _error_handler.handle_error(
				manifest.id,
				ModErrorHandler.ErrorType.DEPENDENCY_MISSING,
				"Required dependency not found: %s" % dep_id,
				{"dependency": dep_id}
			)
			mod_load_failed.emit(manifest.id, error)
			return false
		# Then check if dependency loaded successfully (not failed)
		if dep_id in _failed_mods:
			var error := _error_handler.handle_error(
				manifest.id,
				ModErrorHandler.ErrorType.DEPENDENCY_MISSING,
				"Required dependency failed to load: %s" % dep_id,
				{"dependency": dep_id}
			)
			mod_load_failed.emit(manifest.id, error)
			return false
	return true


## Load content files for a mod and merge into ContentRegistry.
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

		print("[ModLoader] Loading content file: %s" % full_path)

	# Merge all content from this mod into the registry
	if _content_registry and manifest.content_files.size() > 0:
		var merged_count := _content_registry.merge_mod_content(manifest.id, manifest)
		print("[ModLoader] Merged %d content items from mod: %s" % [merged_count, manifest.id])

	return true


## Load and execute scripts for a mod with ModAPI context.
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

		# Execute the mod script
		if not _execute_mod_script(manifest.id, script_path, full_path):
			return false

	return true


## Execute a mod script with ModAPI context.
## Uses FileAccess + GDScript.new() to load scripts from user:// paths.
func _execute_mod_script(mod_id: String, script_path: String, full_path: String) -> bool:
	# CRITICAL: Validate .gd extension
	if not full_path.ends_with(".gd"):
		var error := _error_handler.handle_error(
			mod_id,
			ModErrorHandler.ErrorType.SCRIPT_INVALID,
			"Script must have .gd extension: %s" % script_path,
			{"path": full_path}
		)
		mod_load_failed.emit(mod_id, error)
		return false

	# Load the script using FileAccess (works for user:// paths)
	var file := FileAccess.open(full_path, FileAccess.READ)
	if not file:
		var error := _error_handler.handle_error(
			mod_id,
			ModErrorHandler.ErrorType.SCRIPT_LOAD_FAILED,
			"Cannot open script: %s (error %d)" % [script_path, FileAccess.get_open_error()],
			{"path": full_path}
		)
		mod_load_failed.emit(mod_id, error)
		return false

	var source_code := file.get_as_text()
	file.close()

	# Create GDScript from source
	var script := GDScript.new()
	script.source_code = source_code
	var err := script.reload()
	if err != OK:
		var error := _error_handler.handle_error(
			mod_id,
			ModErrorHandler.ErrorType.SCRIPT_LOAD_FAILED,
			"Compile error in script: %s (error %d)" % [script_path, err],
			{"path": full_path}
		)
		mod_load_failed.emit(mod_id, error)
		return false

	# Create instance and call _mod_init if available
	var instance = script.new()
	if instance == null:
		var error := _error_handler.handle_error(
			mod_id,
			ModErrorHandler.ErrorType.SCRIPT_EXECUTION_ERROR,
			"Failed to instantiate script: %s" % script_path,
			{"path": full_path}
		)
		mod_load_failed.emit(mod_id, error)
		return false

	# Create a bound API instance for this mod to prevent context issues in callbacks
	var bound_api := _mod_api.create_bound_api(mod_id)

	# Call _mod_init if the script has it
	if instance.has_method("_mod_init"):
		print("[ModLoader] Executing _mod_init for: %s" % full_path)
		instance.call("_mod_init", bound_api)

	# Store instance to prevent memory leaks (especially if it connects signals)
	if not _script_instances.has(mod_id):
		_script_instances[mod_id] = []
	_script_instances[mod_id].append(instance)

	_mod_api.script_executed.emit(mod_id, script_path)
	print("[ModLoader] Executed script: %s" % full_path)

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
## Uses topological sort. Mods with cycles are excluded and marked as failed.
func _compute_load_order() -> Array[String]:
	var order: Array[String] = []
	var visited: Dictionary = {}
	var in_progress: Dictionary = {}

	for mod_id in _discovered_mods:
		if mod_id not in visited and mod_id not in _failed_mods:
			_visit_for_sort(mod_id, visited, in_progress, order)

	return order


## Recursive helper for topological sort.
## Returns true if the mod can be added to order, false if it's part of a cycle.
func _visit_for_sort(mod_id: String, visited: Dictionary, in_progress: Dictionary, order: Array[String]) -> bool:
	if mod_id in _failed_mods:
		return false

	if mod_id in visited:
		return true

	if mod_id in in_progress:
		# Circular dependency detected - mark as failed
		var error := _error_handler.handle_error(
			mod_id,
			ModErrorHandler.ErrorType.DEPENDENCY_CYCLE,
			"Circular dependency detected"
		)
		_failed_mods[mod_id] = true
		mod_load_failed.emit(mod_id, error)
		return false

	if mod_id not in _discovered_mods:
		return false

	in_progress[mod_id] = true

	var manifest: ModManifest = _discovered_mods[mod_id]
	for dep_id in manifest.dependencies:
		if not _visit_for_sort(dep_id, visited, in_progress, order):
			# Dependency failed (cycle or other error) - this mod fails too
			in_progress.erase(mod_id)
			_failed_mods[mod_id] = true
			var error := _error_handler.handle_error(
				mod_id,
				ModErrorHandler.ErrorType.DEPENDENCY_MISSING,
				"Dependency '%s' is part of a cycle or failed to load" % dep_id,
				{"dependency": dep_id}
			)
			mod_load_failed.emit(mod_id, error)
			return false

	in_progress.erase(mod_id)
	visited[mod_id] = true
	order.append(mod_id)
	return true


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
	# Cleanup script instances for all loaded mods
	for mod_id in _loaded_mods:
		_cleanup_mod_scripts(mod_id)

	# Emit unload signals for all currently loaded mods
	if _event_hooks:
		for mod_id in _loaded_mods:
			_event_hooks.mod_unloaded.emit(mod_id)

	_discovered_mods.clear()
	_loaded_mods.clear()
	_failed_mods.clear()
	_error_handler.clear()

	# Clear and reload content registry
	if _content_registry:
		_content_registry.clear_all()
		_content_registry.load_base_content()

	discover_mods()
	return load_all_mods()


## Cleanup script instances for a mod, calling _mod_exit if available.
func _cleanup_mod_scripts(mod_id: String) -> void:
	if not _script_instances.has(mod_id):
		return

	for instance in _script_instances[mod_id]:
		if is_instance_valid(instance) and instance.has_method("_mod_exit"):
			instance.call("_mod_exit")

	_script_instances.erase(mod_id)
