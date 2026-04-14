class_name ContentRegistry
extends RefCounted

## Single source of truth for all game content (base + mods).
## Clean Architecture boundary - domain code queries this, never raw files.
##
## Usage:
##   var registry := ContentRegistry.new()
##   registry.load_base_content()
##   # Later, when mods are loaded:
##   registry.merge_mod_content("my_mod", manifest)
##
## Content is loaded in layers:
## 1. Base game content from res://data/ JSON files
## 2. Mod content merged on top (mod wins on ID collision)

signal content_loaded(content_type: String, count: int)
signal content_merged(mod_id: String, content_type: String, count: int)
signal content_conflict(content_type: String, id: String, winner: String)

## Per-content-type registries (composition, not inheritance)
var items: ItemRegistry
var recipes: RecipeRegistry
var professions: ProfessionRegistry
var train_cars: TrainCarRegistry

var _data_loader: DataLoader
var _base_loaded: bool = false
var _loaded_mods: Array[String] = []

## Base content paths (res:// paths for Godot resource system)
const BASE_ITEMS_PATH := "res://data/base_items.json"
const BASE_RECIPES_PATH := "res://data/base_recipes.json"
const BASE_PROFESSIONS_PATH := "res://data/base_professions.json"
const BASE_TRAIN_CARS_PATH := "res://data/base_train_cars.json"


func _init() -> void:
	_data_loader = DataLoader.new()
	items = ItemRegistry.new()
	recipes = RecipeRegistry.new()
	professions = ProfessionRegistry.new()
	train_cars = TrainCarRegistry.new()

	# Connect registry signals for conflict tracking
	items.item_overwritten.connect(_on_item_conflict)
	recipes.recipe_overwritten.connect(_on_recipe_conflict)
	professions.profession_overwritten.connect(_on_profession_conflict)
	train_cars.train_car_overwritten.connect(_on_train_car_conflict)


## Load all base game content from res://data/ JSON files.
## Returns true if all content loaded successfully.
## Should be called once at game startup, before any mods.
func load_base_content() -> bool:
	if _base_loaded:
		push_warning("ContentRegistry: Base content already loaded, skipping")
		return true

	var success := true
	var total_loaded := 0

	# Load items
	var items_data := _data_loader.load_json(BASE_ITEMS_PATH)
	if not items_data.is_empty():
		var count := items.load_from_data(items_data, "base")
		total_loaded += count
		content_loaded.emit("items", count)
	elif FileAccess.file_exists(BASE_ITEMS_PATH):
		push_error("ContentRegistry: Failed to parse %s" % BASE_ITEMS_PATH)
		content_loaded.emit("items", 0)
		success = false

	# Load recipes
	var recipes_data := _data_loader.load_json(BASE_RECIPES_PATH)
	if not recipes_data.is_empty():
		var count := recipes.load_from_data(recipes_data, "base")
		total_loaded += count
		content_loaded.emit("recipes", count)
	elif FileAccess.file_exists(BASE_RECIPES_PATH):
		push_error("ContentRegistry: Failed to parse %s" % BASE_RECIPES_PATH)
		content_loaded.emit("recipes", 0)
		success = false

	# Load professions (optional - may not exist yet)
	if FileAccess.file_exists(BASE_PROFESSIONS_PATH):
		var professions_data := _data_loader.load_json(BASE_PROFESSIONS_PATH)
		if not professions_data.is_empty():
			var count := professions.load_from_data(professions_data, "base")
			total_loaded += count
			content_loaded.emit("professions", count)

	# Load train cars (optional - may not exist yet)
	if FileAccess.file_exists(BASE_TRAIN_CARS_PATH):
		var train_cars_data := _data_loader.load_json(BASE_TRAIN_CARS_PATH)
		if not train_cars_data.is_empty():
			var count := train_cars.load_from_data(train_cars_data, "base")
			total_loaded += count
			content_loaded.emit("train_cars", count)

	_base_loaded = success
	print("ContentRegistry: Base content loaded - %d total items" % total_loaded)
	return success


## Check if base content has been loaded.
func is_base_loaded() -> bool:
	return _base_loaded


## Check if a specific mod has been loaded.
func is_mod_loaded(mod_id: String) -> bool:
	return mod_id in _loaded_mods


## Get list of all loaded mod IDs.
func get_loaded_mods() -> Array[String]:
	return _loaded_mods.duplicate()


## Merge a mod's content into the registries.
## Reads content from mod's content_files and merges into existing registries.
## On ID collision, mod content wins (overwrites base).
## Returns total count of content items merged.
func merge_mod_content(mod_id: String, manifest: ModManifest) -> int:
	if not manifest.is_valid:
		push_error("ContentRegistry: Cannot merge invalid mod manifest for '%s'" % mod_id)
		return 0

	if mod_id in _loaded_mods:
		push_warning("ContentRegistry: Mod '%s' already loaded, skipping duplicate merge" % mod_id)
		return 0

	var total_merged := 0

	# Process each content file declared in the manifest
	for relative_path in manifest.content_files:
		var full_path := manifest.get_content_file_path(relative_path)
		var content_data := _data_loader.load_json(full_path)

		if content_data.is_empty():
			push_warning("ContentRegistry: Failed to load mod content file: %s" % full_path)
			continue

		# Merge based on what content types are present in the file
		total_merged += _merge_content_from_data(mod_id, content_data)

	_loaded_mods.append(mod_id)
	print("ContentRegistry: Merged mod '%s' - %d total items" % [mod_id, total_merged])
	return total_merged


## Internal helper to merge content from a loaded data dictionary.
## Detects content types by checking for known keys.
func _merge_content_from_data(mod_id: String, data: Dictionary) -> int:
	var total := 0

	if data.has("items"):
		var count := _merge_items(mod_id, data.get("items"))
		total += count
		if count > 0:
			content_merged.emit(mod_id, "items", count)

	if data.has("recipes"):
		var count := _merge_recipes(mod_id, data.get("recipes"))
		total += count
		if count > 0:
			content_merged.emit(mod_id, "recipes", count)

	if data.has("professions"):
		var count := _merge_professions(mod_id, data.get("professions"))
		total += count
		if count > 0:
			content_merged.emit(mod_id, "professions", count)

	if data.has("train_cars"):
		var count := _merge_train_cars(mod_id, data.get("train_cars"))
		total += count
		if count > 0:
			content_merged.emit(mod_id, "train_cars", count)

	return total


## Merge items array from mod data.
## IDs are prefixed with mod_id to match ModAPI behavior.
func _merge_items(mod_id: String, items_array) -> int:
	if not items_array is Array:
		push_warning("ContentRegistry: items must be an array in mod '%s'" % mod_id)
		return 0

	var count := 0
	for item_data in items_array:
		if not item_data is Dictionary:
			continue

		var original_id: String = item_data.get("id", "")
		if original_id.is_empty():
			continue

		# Prefix ID with mod_id to avoid collisions (consistent with ModAPI)
		var prefixed_id := "%s:%s" % [mod_id, original_id]

		# Check for conflict before registering
		if items.has_item(prefixed_id):
			var old_source := items.get_item_source(prefixed_id)
			# Signal will be emitted by registry, but we log here too
			print("ContentRegistry: Item '%s' overwritten by mod '%s' (was: %s)" % [prefixed_id, mod_id, old_source])

		# Create prefixed data and use static factory method
		var prefixed_data := item_data.duplicate(true)
		prefixed_data["id"] = prefixed_id
		var item := ResourceItemData.from_dict(prefixed_data)
		if item:
			items.register_item(item, mod_id)
			count += 1

	return count


## Merge recipes array from mod data.
## IDs are prefixed with mod_id to match ModAPI behavior.
func _merge_recipes(mod_id: String, recipes_array) -> int:
	if not recipes_array is Array:
		push_warning("ContentRegistry: recipes must be an array in mod '%s'" % mod_id)
		return 0

	var count := 0
	for recipe_data in recipes_array:
		if not recipe_data is Dictionary:
			continue

		var original_id: String = recipe_data.get("id", "")
		if original_id.is_empty():
			continue

		# Prefix ID with mod_id to avoid collisions (consistent with ModAPI)
		var prefixed_id := "%s:%s" % [mod_id, original_id]

		# Check for conflict before registering
		if recipes.has_recipe(prefixed_id):
			var old_source := recipes.get_recipe_source(prefixed_id)
			print("ContentRegistry: Recipe '%s' overwritten by mod '%s' (was: %s)" % [prefixed_id, mod_id, old_source])

		# Create prefixed data and use static factory method
		var prefixed_data := recipe_data.duplicate(true)
		prefixed_data["id"] = prefixed_id
		var recipe := RecipeData.from_dict(prefixed_data)
		if recipe:
			recipes.register_recipe(recipe, mod_id)
			count += 1

	return count


## Merge professions array from mod data.
## IDs are prefixed with mod_id to match ModAPI behavior.
func _merge_professions(mod_id: String, professions_array) -> int:
	if not professions_array is Array:
		push_warning("ContentRegistry: professions must be an array in mod '%s'" % mod_id)
		return 0

	var count := 0
	for profession_data in professions_array:
		if not profession_data is Dictionary:
			continue

		var original_id: String = profession_data.get("id", "")
		if original_id.is_empty():
			continue

		# Prefix ID with mod_id to avoid collisions (consistent with ModAPI)
		var prefixed_id := "%s:%s" % [mod_id, original_id]

		# Check for conflict before registering
		if professions.has_profession(prefixed_id):
			var old_source := professions.get_profession_source(prefixed_id)
			print("ContentRegistry: Profession '%s' overwritten by mod '%s' (was: %s)" % [prefixed_id, mod_id, old_source])

		# Create prefixed data and use static factory method
		var prefixed_data := profession_data.duplicate(true)
		prefixed_data["id"] = prefixed_id
		var profession := ProfessionData.from_dict(prefixed_data)
		if profession:
			professions.register_profession(profession, mod_id)
			count += 1

	return count


## Merge train_cars array from mod data.
## IDs are prefixed with mod_id to match ModAPI behavior.
func _merge_train_cars(mod_id: String, train_cars_array) -> int:
	if not train_cars_array is Array:
		push_warning("ContentRegistry: train_cars must be an array in mod '%s'" % mod_id)
		return 0

	var count := 0
	for car_data in train_cars_array:
		if not car_data is Dictionary:
			continue

		var original_id: String = car_data.get("id", "")
		if original_id.is_empty():
			continue

		# Prefix ID with mod_id to avoid collisions (consistent with ModAPI)
		var prefixed_id := "%s:%s" % [mod_id, original_id]

		# Check for conflict before registering
		if train_cars.has_train_car(prefixed_id):
			var old_source := train_cars.get_train_car_source(prefixed_id)
			print("ContentRegistry: TrainCar '%s' overwritten by mod '%s' (was: %s)" % [prefixed_id, mod_id, old_source])

		# Create prefixed data and use static factory method
		var prefixed_data := car_data.duplicate(true)
		prefixed_data["id"] = prefixed_id
		var train_car := TrainCarData.from_dict(prefixed_data)
		if train_car:
			train_cars.register_train_car(train_car, mod_id)
			count += 1

	return count


# --- Convenience accessors for common lookups ---

## Get an item by ID.
func get_item(id: String) -> ResourceItemData:
	return items.get_item(id)


## Get a recipe by ID.
func get_recipe(id: String) -> RecipeData:
	return recipes.get_recipe(id)


## Get a profession by ID.
func get_profession(id: String) -> ProfessionData:
	return professions.get_profession(id)


## Get a train car by ID.
func get_train_car(id: String) -> TrainCarData:
	return train_cars.get_train_car(id)


# --- Conflict signal handlers ---

func _on_item_conflict(item_id: String, old_source: String, new_source: String) -> void:
	content_conflict.emit("items", item_id, new_source)


func _on_recipe_conflict(recipe_id: String, old_source: String, new_source: String) -> void:
	content_conflict.emit("recipes", recipe_id, new_source)


func _on_profession_conflict(profession_id: String, old_source: String, new_source: String) -> void:
	content_conflict.emit("professions", profession_id, new_source)


func _on_train_car_conflict(car_id: String, old_source: String, new_source: String) -> void:
	content_conflict.emit("train_cars", car_id, new_source)


## Clear all content and reset to initial state.
## Useful for testing or mod reloading.
func clear_all() -> void:
	items.clear()
	recipes.clear()
	professions.clear()
	train_cars.clear()
	_base_loaded = false
	_loaded_mods.clear()


## Get total count of all content across all registries.
func get_total_count() -> int:
	return items.count() + recipes.count() + professions.count() + train_cars.count()


## Get a summary dictionary of loaded content.
func get_summary() -> Dictionary:
	return {
		"base_loaded": _base_loaded,
		"loaded_mods": _loaded_mods.duplicate(),
		"items": items.count(),
		"recipes": recipes.count(),
		"professions": professions.count(),
		"train_cars": train_cars.count(),
		"total": get_total_count()
	}
