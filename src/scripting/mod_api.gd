class_name ModAPI
extends RefCounted

## Typed API for mod scripts to interact with game systems.
##
## Mods call these methods to register content — no direct registry access.
## Design principles:
## - Mods can ADD content, not mutate or delete existing content
## - ID prefixing prevents collisions between mods
## - Read methods return copies (Dictionaries), not references

signal content_registered(mod_id: String, content_type: String, content_id: String)
@warning_ignore("unused_signal")  # Reserved for future mod script execution tracking
signal script_executed(mod_id: String, script_path: String)

var _content_registry: ContentRegistry
var _current_mod_id: String = ""
var _bound_mod_id: String = ""  # If set, this API instance is bound to a specific mod


func _init(content_registry: ContentRegistry, bound_mod_id: String = "") -> void:
	_content_registry = content_registry
	_bound_mod_id = bound_mod_id


## Create a bound API instance for a specific mod.
## The returned instance will always use the specified mod_id for registration,
## preventing context issues when callbacks are invoked later.
func create_bound_api(mod_id: String) -> ModAPI:
	return ModAPI.new(_content_registry, mod_id)


## Set the current mod context for ID prefixing.
## NOTE: Prefer using create_bound_api() for callbacks to avoid context issues.
func set_current_mod(mod_id: String) -> void:
	_current_mod_id = mod_id


## Get the current mod ID (returns bound ID if this is a bound instance).
func get_current_mod() -> String:
	if not _bound_mod_id.is_empty():
		return _bound_mod_id
	return _current_mod_id


## Get the effective mod ID for registration operations.
func _get_effective_mod_id() -> String:
	if not _bound_mod_id.is_empty():
		return _bound_mod_id
	return _current_mod_id


# --- Content Registration Methods ---

## Register a new item from mod.
## Item ID is automatically prefixed with mod_id to avoid collisions.
## Returns true on success, false on validation failure.
func register_item(item_data: Dictionary) -> bool:
	var mod_id := _get_effective_mod_id()
	if mod_id.is_empty():
		push_error("[ModAPI] Cannot register item: no mod context set")
		return false

	if not _validate_item_data(item_data):
		return false

	# Prefix ID with mod_id to avoid collisions
	var original_id: String = item_data.get("id", "")
	var prefixed_id := "%s:%s" % [mod_id, original_id]

	var prefixed_data: Dictionary = item_data.duplicate(true)
	prefixed_data["id"] = prefixed_id

	# Create item from data and register
	var item := _create_item_from_dict(prefixed_data)
	if item == null:
		return false

	_content_registry.items.register_item(item, mod_id)
	content_registered.emit(mod_id, "item", prefixed_id)

	# Emit to EventHooks if available (access via Engine since RefCounted has no tree)
	var event_hooks: Node = Engine.get_main_loop().root.get_node_or_null("/root/EventHooks")
	if event_hooks:
		event_hooks.item_registered.emit(prefixed_id, mod_id)

	print("[ModAPI] Registered item: %s" % prefixed_id)
	return true


## Register a new recipe from mod.
## Recipe ID is automatically prefixed with mod_id.
## Returns true on success, false on validation failure.
func register_recipe(recipe_data: Dictionary) -> bool:
	var mod_id := _get_effective_mod_id()
	if mod_id.is_empty():
		push_error("[ModAPI] Cannot register recipe: no mod context set")
		return false

	if not _validate_recipe_data(recipe_data):
		return false

	var original_id: String = recipe_data.get("id", "")
	var prefixed_id := "%s:%s" % [mod_id, original_id]

	var prefixed_data: Dictionary = recipe_data.duplicate(true)
	prefixed_data["id"] = prefixed_id

	var recipe := _create_recipe_from_dict(prefixed_data)
	if recipe == null:
		return false

	_content_registry.recipes.register_recipe(recipe, mod_id)
	content_registered.emit(mod_id, "recipe", prefixed_id)

	var event_hooks_2: Node = Engine.get_main_loop().root.get_node_or_null("/root/EventHooks")
	if event_hooks_2:
		event_hooks_2.recipe_registered.emit(prefixed_id, mod_id)

	print("[ModAPI] Registered recipe: %s" % prefixed_id)
	return true


## Register a new profession from mod.
## Profession ID is automatically prefixed with mod_id.
## Returns true on success, false on validation failure.
func register_profession(profession_data: Dictionary) -> bool:
	var mod_id := _get_effective_mod_id()
	if mod_id.is_empty():
		push_error("[ModAPI] Cannot register profession: no mod context set")
		return false

	if not _validate_profession_data(profession_data):
		return false

	var original_id: String = profession_data.get("id", "")
	var prefixed_id := "%s:%s" % [mod_id, original_id]

	var prefixed_data: Dictionary = profession_data.duplicate(true)
	prefixed_data["id"] = prefixed_id

	var profession := _create_profession_from_dict(prefixed_data)
	if profession == null:
		return false

	_content_registry.professions.register_profession(profession, mod_id)
	content_registered.emit(mod_id, "profession", prefixed_id)

	print("[ModAPI] Registered profession: %s" % prefixed_id)
	return true


## Register a new train car from mod.
## Train car ID is automatically prefixed with mod_id.
## Returns true on success, false on validation failure.
func register_train_car(car_data: Dictionary) -> bool:
	var mod_id := _get_effective_mod_id()
	if mod_id.is_empty():
		push_error("[ModAPI] Cannot register train car: no mod context set")
		return false

	if not _validate_train_car_data(car_data):
		return false

	var original_id: String = car_data.get("id", "")
	var prefixed_id := "%s:%s" % [mod_id, original_id]

	var prefixed_data: Dictionary = car_data.duplicate(true)
	prefixed_data["id"] = prefixed_id

	var train_car := _create_train_car_from_dict(prefixed_data)
	if train_car == null:
		return false

	_content_registry.train_cars.register_train_car(train_car, mod_id)
	content_registered.emit(mod_id, "train_car", prefixed_id)

	print("[ModAPI] Registered train car: %s" % prefixed_id)
	return true


# --- Read-Only Query Methods (return COPIES, not references) ---

## Get an item by ID as a Dictionary copy.
## Returns empty Dictionary if not found.
func get_item(id: String) -> Dictionary:
	var item := _content_registry.get_item(id)
	return _item_to_dict(item) if item else {}


## Get all item IDs.
func get_all_item_ids() -> Array[String]:
	var ids: Array[String] = []
	for item in _content_registry.items.get_all():
		ids.append(item.id)
	return ids


## Check if an item exists by ID.
func item_exists(id: String) -> bool:
	return _content_registry.items.has_item(id)


## Get a recipe by ID as a Dictionary copy.
func get_recipe(id: String) -> Dictionary:
	var recipe := _content_registry.get_recipe(id)
	return _recipe_to_dict(recipe) if recipe else {}


## Get all recipe IDs.
func get_all_recipe_ids() -> Array[String]:
	var ids: Array[String] = []
	for recipe in _content_registry.recipes.get_all():
		ids.append(recipe.id)
	return ids


## Check if a recipe exists by ID.
func recipe_exists(id: String) -> bool:
	return _content_registry.recipes.has_recipe(id)


## Get a profession by ID as a Dictionary copy.
func get_profession(id: String) -> Dictionary:
	var profession := _content_registry.get_profession(id)
	return _profession_to_dict(profession) if profession else {}


## Get all profession IDs.
func get_all_profession_ids() -> Array[String]:
	var ids: Array[String] = []
	for profession in _content_registry.professions.get_all():
		ids.append(profession.id)
	return ids


## Check if a profession exists by ID.
func profession_exists(id: String) -> bool:
	return _content_registry.professions.has_profession(id)


## Get a train car by ID as a Dictionary copy.
func get_train_car(id: String) -> Dictionary:
	var train_car := _content_registry.get_train_car(id)
	return _train_car_to_dict(train_car) if train_car else {}


## Get all train car IDs.
func get_all_train_car_ids() -> Array[String]:
	var ids: Array[String] = []
	for car in _content_registry.train_cars.get_all():
		ids.append(car.id)
	return ids


## Check if a train car exists by ID.
func train_car_exists(id: String) -> bool:
	return _content_registry.train_cars.has_train_car(id)


## Get a summary of all registered content.
func get_content_summary() -> Dictionary:
	return _content_registry.get_summary()


# --- Validation Methods ---

func _validate_item_data(data: Dictionary) -> bool:
	if not data.has("id") or data.get("id", "").is_empty():
		push_error("[ModAPI] Item data missing required 'id' field")
		return false
	return true


func _validate_recipe_data(data: Dictionary) -> bool:
	if not data.has("id") or data.get("id", "").is_empty():
		push_error("[ModAPI] Recipe data missing required 'id' field")
		return false
	return true


func _validate_profession_data(data: Dictionary) -> bool:
	if not data.has("id") or data.get("id", "").is_empty():
		push_error("[ModAPI] Profession data missing required 'id' field")
		return false
	return true


func _validate_train_car_data(data: Dictionary) -> bool:
	if not data.has("id") or data.get("id", "").is_empty():
		push_error("[ModAPI] Train car data missing required 'id' field")
		return false
	return true


# --- Serialization Methods (Resource -> Dictionary) ---

func _item_to_dict(item: ResourceItemData) -> Dictionary:
	if not item:
		return {}
	return {
		"id": item.id,
		"name": item.name,
		"description": item.description,
		"category": item.category,
		"type": item.type,
		"rarity": item.rarity,
		"weight": item.weight,
		"stack_size": item.stack_size,
		"sources": item.sources.duplicate(),
		"used_for": item.used_for.duplicate()
	}


func _recipe_to_dict(recipe: RecipeData) -> Dictionary:
	if not recipe:
		return {}
	return {
		"id": recipe.id,
		"name": recipe.name,
		"description": recipe.description,
		"category": recipe.category,
		"recipe_category": recipe.recipe_category,
		"station": recipe.station,
		"craft_time": recipe.craft_time,
		"unlock": recipe.unlock,
		"profession_bonus": recipe.profession_bonus,
		"inputs": recipe.inputs.duplicate(true),
		"output": recipe.output.duplicate(true)
	}


func _profession_to_dict(profession: ProfessionData) -> Dictionary:
	if not profession:
		return {}
	return {
		"id": profession.id,
		"name": profession.name,
		"description": profession.description,
		"primary_car": profession.primary_car,
		"field_role": profession.field_role,
		"priority": profession.priority,
		"secondary_cars": profession.secondary_cars.duplicate(),
		"synergies": profession.synergies.duplicate(),
		"passive_bonuses": profession.passive_bonuses.duplicate(),
		"active_abilities": profession.active_abilities.duplicate(true)
	}


func _train_car_to_dict(train_car: TrainCarData) -> Dictionary:
	if not train_car:
		return {}
	return {
		"id": train_car.id,
		"name": train_car.name,
		"description": train_car.description,
		"type": train_car.type,
		"category": train_car.category,
		"acquisition": train_car.acquisition,
		"crew_station": train_car.crew_station,
		"upgrade_tree": train_car.upgrade_tree,
		"damage_effect": train_car.damage_effect,
		"subsystems": train_car.subsystems.duplicate(),
		"dependencies": train_car.dependencies.duplicate()
	}


# --- Factory Methods (Dictionary -> Resource) ---
# These delegate to static factory methods on the data classes.

func _create_item_from_dict(data: Dictionary) -> ResourceItemData:
	return ResourceItemData.from_dict(data)


func _create_recipe_from_dict(data: Dictionary) -> RecipeData:
	return RecipeData.from_dict(data)


func _create_profession_from_dict(data: Dictionary) -> ProfessionData:
	return ProfessionData.from_dict(data)


func _create_train_car_from_dict(data: Dictionary) -> TrainCarData:
	return TrainCarData.from_dict(data)
