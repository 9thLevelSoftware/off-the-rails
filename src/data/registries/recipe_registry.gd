class_name RecipeRegistry
extends RefCounted

## Registry for Recipe content type.
## Wraps RecipeData resources with ID-based lookup.
##
## The registry supports two data sources:
## 1. Godot Resource files (.tres) - for base game content
## 2. JSON dictionaries - for mod content
##
## Both are converted to RecipeData for uniform access.

signal recipe_registered(recipe_id: String)
signal recipe_overwritten(recipe_id: String, old_source: String, new_source: String)

var _recipes: Dictionary = {}  # id -> RecipeData
var _sources: Dictionary = {}  # id -> source string (e.g., "base" or mod_id)


## Register a recipe from a RecipeData resource.
func register_recipe(recipe: RecipeData, source: String = "base") -> void:
	if not recipe or recipe.id.is_empty():
		push_warning("RecipeRegistry: Attempted to register invalid recipe")
		return

	if _recipes.has(recipe.id):
		var old_source: String = _sources.get(recipe.id, "unknown")
		recipe_overwritten.emit(recipe.id, old_source, source)

	_recipes[recipe.id] = recipe
	_sources[recipe.id] = source
	recipe_registered.emit(recipe.id)


## Get a recipe by ID, returns null if not found.
func get_recipe(id: String) -> RecipeData:
	return _recipes.get(id)


## Get all registered recipes.
func get_all() -> Array[RecipeData]:
	var result: Array[RecipeData] = []
	for recipe in _recipes.values():
		result.append(recipe)
	return result


## Get all recipe IDs.
func get_all_ids() -> Array[String]:
	var result: Array[String] = []
	for id in _recipes.keys():
		result.append(id)
	return result


## Check if a recipe is registered.
func has_recipe(id: String) -> bool:
	return id in _recipes


## Get the source of a recipe (which mod or "base").
func get_recipe_source(id: String) -> String:
	return _sources.get(id, "")


## Get count of registered recipes.
func count() -> int:
	return _recipes.size()


## Get recipes by station.
func get_by_station(station: String) -> Array[RecipeData]:
	var result: Array[RecipeData] = []
	for recipe in _recipes.values():
		if recipe.station == station:
			result.append(recipe)
	return result


## Get recipes by category.
func get_by_category(category: String) -> Array[RecipeData]:
	var result: Array[RecipeData] = []
	for recipe in _recipes.values():
		if recipe.category == category:
			result.append(recipe)
	return result


## Get recipes that produce a specific item.
func get_recipes_for_output(item_id: String) -> Array[RecipeData]:
	var result: Array[RecipeData] = []
	for recipe in _recipes.values():
		if item_id in recipe.output:
			result.append(recipe)
	return result


## Get recipes that require a specific input.
func get_recipes_using_input(item_id: String) -> Array[RecipeData]:
	var result: Array[RecipeData] = []
	for recipe in _recipes.values():
		if item_id in recipe.inputs:
			result.append(recipe)
	return result


## Get all unlocked-by-default recipes.
func get_default_unlocked() -> Array[RecipeData]:
	var result: Array[RecipeData] = []
	for recipe in _recipes.values():
		if recipe.is_default_unlocked():
			result.append(recipe)
	return result


## Load recipes from a JSON data dictionary.
## Expected format: {"recipes": [{id, name, station, inputs, output, ...}, ...]}
## Returns count of recipes loaded.
func load_from_data(data: Dictionary, source: String = "base") -> int:
	if not data.has("recipes"):
		return 0

	var recipes_array = data.get("recipes")
	if not recipes_array is Array:
		push_warning("RecipeRegistry: 'recipes' must be an array")
		return 0

	var loaded_count := 0
	for recipe_data in recipes_array:
		if not recipe_data is Dictionary:
			continue
		var recipe := _create_from_dict(recipe_data)
		if recipe:
			register_recipe(recipe, source)
			loaded_count += 1

	return loaded_count


## Create a RecipeData from a dictionary.
## Handles the conversion from JSON format to Godot resource.
func _create_from_dict(data: Dictionary) -> RecipeData:
	var id: String = data.get("id", "")
	if id.is_empty():
		push_warning("RecipeRegistry: Recipe missing required 'id' field")
		return null

	var recipe := RecipeData.new()
	recipe.id = id
	recipe.name = data.get("name", id)
	recipe.description = data.get("description", "")
	recipe.category = data.get("category", "consumable")
	recipe.recipe_category = data.get("recipe_category", "")
	recipe.station = data.get("station", "workshop")
	recipe.craft_time = data.get("craft_time", 60)
	recipe.unlock = data.get("unlock", "default")
	recipe.profession_bonus = data.get("profession_bonus", "")

	# Handle inputs dictionary or array format
	var inputs_data = data.get("inputs", {})
	if inputs_data is Dictionary:
		recipe.inputs = inputs_data.duplicate()
	elif inputs_data is Array:
		# Convert array format [{item_id, quantity}, ...] to dict
		recipe.inputs = {}
		for input_entry in inputs_data:
			if input_entry is Dictionary:
				var item_id: String = input_entry.get("item_id", "")
				var quantity: int = input_entry.get("quantity", 1)
				if not item_id.is_empty():
					recipe.inputs[item_id] = quantity

	# Handle output dictionary or object format
	var output_data = data.get("output", {})
	if output_data is Dictionary:
		# Check if it's {item_id, quantity} format or {item_id: quantity} format
		if output_data.has("item_id"):
			var item_id: String = output_data.get("item_id", "")
			var quantity: int = output_data.get("quantity", 1)
			recipe.output = {item_id: quantity}
		else:
			recipe.output = output_data.duplicate()

	return recipe


## Clear all registered recipes.
func clear() -> void:
	_recipes.clear()
	_sources.clear()
