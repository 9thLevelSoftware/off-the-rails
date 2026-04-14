class_name RecipeRepository
extends RefCounted

## Repository for loading and filtering crafting recipes.
## Loads .tres files from src/data/recipes/ directory.
## Provides filtering by station, unlock status, and category.

const RECIPES_PATH := "res://src/data/recipes/"

## Cached recipes indexed by ID
var _recipes: Dictionary = {}  # {recipe_id: RecipeData}

## Flag indicating if recipes have been loaded
var _loaded: bool = false


## Load all recipes from the recipes directory.
## Call this once during initialization.
func load_all_recipes() -> void:
	if _loaded:
		return

	_recipes.clear()

	var dir := DirAccess.open(RECIPES_PATH)
	if dir == null:
		push_error("RecipeRepository: Failed to open recipes directory: %s" % RECIPES_PATH)
		return

	dir.list_dir_begin()
	var file_name := dir.get_next()

	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var recipe_path := RECIPES_PATH + file_name
			var recipe := load(recipe_path) as RecipeData
			if recipe:
				_recipes[recipe.id] = recipe
			else:
				push_warning("RecipeRepository: Failed to load recipe: %s" % recipe_path)
		file_name = dir.get_next()

	dir.list_dir_end()
	_loaded = true
	print("[RecipeRepository] Loaded %d recipes" % _recipes.size())


## Get a recipe by ID.
## Returns null if recipe not found.
func get_recipe(recipe_id: String) -> RecipeData:
	_ensure_loaded()
	return _recipes.get(recipe_id, null)


## Get all loaded recipes.
func get_all_recipes() -> Array[RecipeData]:
	_ensure_loaded()
	var result: Array[RecipeData] = []
	for recipe in _recipes.values():
		result.append(recipe)
	return result


## Get recipes filtered by station type.
## station_type: "field", "workshop", "armory", "infirmary", etc.
func get_recipes_by_station(station_type: String) -> Array[RecipeData]:
	_ensure_loaded()
	var result: Array[RecipeData] = []
	for recipe: RecipeData in _recipes.values():
		if recipe.station == station_type:
			result.append(recipe)
	return result


## Get recipes filtered by category.
## category: "consumable", "ammo", "medical", "repair", "tool", etc.
func get_recipes_by_category(category: String) -> Array[RecipeData]:
	_ensure_loaded()
	var result: Array[RecipeData] = []
	for recipe: RecipeData in _recipes.values():
		if recipe.category == category:
			result.append(recipe)
	return result


## Get recipes filtered by recipe_category (YAML source category).
func get_recipes_by_recipe_category(recipe_category: String) -> Array[RecipeData]:
	_ensure_loaded()
	var result: Array[RecipeData] = []
	for recipe: RecipeData in _recipes.values():
		if recipe.recipe_category == recipe_category:
			result.append(recipe)
	return result


## Get available recipes for a station with unlock checks.
## station_type: Station to filter for
## unlock_status: Current unlock status {"schematics": [], "upgrades": [], "research": []}
## Returns only recipes that match station AND are unlocked.
func get_available_recipes(station_type: String, unlock_status: Dictionary = {}) -> Array[RecipeData]:
	_ensure_loaded()
	var result: Array[RecipeData] = []

	for recipe: RecipeData in _recipes.values():
		# Filter by station
		if recipe.station != station_type:
			continue

		# Check unlock status
		if not _is_unlocked(recipe, unlock_status):
			continue

		result.append(recipe)

	return result


## Get all unique categories from loaded recipes.
func get_all_categories() -> Array[String]:
	_ensure_loaded()
	var categories: Array[String] = []
	for recipe: RecipeData in _recipes.values():
		if recipe.category not in categories:
			categories.append(recipe.category)
	categories.sort()
	return categories


## Get all unique recipe_categories (YAML source categories).
func get_all_recipe_categories() -> Array[String]:
	_ensure_loaded()
	var categories: Array[String] = []
	for recipe: RecipeData in _recipes.values():
		if recipe.recipe_category != "" and recipe.recipe_category not in categories:
			categories.append(recipe.recipe_category)
	categories.sort()
	return categories


## Check if a recipe is unlocked based on unlock_status.
func _is_unlocked(recipe: RecipeData, unlock_status: Dictionary) -> bool:
	# Default unlocked recipes are always available
	if recipe.is_default_unlocked():
		return true

	var unlock_type := recipe.unlock

	# Check schematic unlocks
	if unlock_type.begins_with("schematic_"):
		var schematics: Array = unlock_status.get("schematics", [])
		return unlock_type in schematics

	# Check upgrade unlocks
	if unlock_type.begins_with("upgrade_"):
		var upgrades: Array = unlock_status.get("upgrades", [])
		return unlock_type in upgrades

	# Check research unlocks
	if unlock_type == "research":
		var research: Array = unlock_status.get("research", [])
		return recipe.id in research

	# Unknown unlock type - not unlocked
	return false


## Ensure recipes are loaded before accessing.
func _ensure_loaded() -> void:
	if not _loaded:
		load_all_recipes()


## Get count of loaded recipes.
func get_recipe_count() -> int:
	_ensure_loaded()
	return _recipes.size()


## Check if a recipe exists.
func has_recipe(recipe_id: String) -> bool:
	_ensure_loaded()
	return recipe_id in _recipes


## Clear cached recipes (useful for testing).
func clear_cache() -> void:
	_recipes.clear()
	_loaded = false
