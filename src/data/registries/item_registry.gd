class_name ItemRegistry
extends RefCounted

## Registry for Item/ResourceItem content type.
## Wraps ResourceItemData resources with ID-based lookup.
##
## The registry supports two data sources:
## 1. Godot Resource files (.tres) - for base game content
## 2. JSON dictionaries - for mod content
##
## Both are converted to ResourceItemData for uniform access.

signal item_registered(item_id: String)
signal item_overwritten(item_id: String, old_source: String, new_source: String)

var _items: Dictionary = {}  # id -> ResourceItemData
var _sources: Dictionary = {} # id -> source string (e.g., "base" or mod_id)


## Register an item from a ResourceItemData resource.
func register_item(item: ResourceItemData, source: String = "base") -> void:
	if not item or item.id.is_empty():
		push_warning("ItemRegistry: Attempted to register invalid item")
		return

	if _items.has(item.id):
		var old_source: String = _sources.get(item.id, "unknown")
		item_overwritten.emit(item.id, old_source, source)

	_items[item.id] = item
	_sources[item.id] = source
	item_registered.emit(item.id)


## Get an item by ID, returns null if not found.
func get_item(id: String) -> ResourceItemData:
	return _items.get(id)


## Get all registered items.
func get_all() -> Array[ResourceItemData]:
	var result: Array[ResourceItemData] = []
	for item in _items.values():
		result.append(item)
	return result


## Get all item IDs.
func get_all_ids() -> Array[String]:
	var result: Array[String] = []
	for id in _items.keys():
		result.append(id)
	return result


## Check if an item is registered.
func has_item(id: String) -> bool:
	return id in _items


## Get the source of an item (which mod or "base").
func get_item_source(id: String) -> String:
	return _sources.get(id, "")


## Get count of registered items.
func count() -> int:
	return _items.size()


## Get items by category.
func get_by_category(category: String) -> Array[ResourceItemData]:
	var result: Array[ResourceItemData] = []
	for item in _items.values():
		if item.category == category:
			result.append(item)
	return result


## Get items by type.
func get_by_type(type: String) -> Array[ResourceItemData]:
	var result: Array[ResourceItemData] = []
	for item in _items.values():
		if item.type == type:
			result.append(item)
	return result


## Load items from a JSON data dictionary.
## Expected format: {"items": [{id, name, ...}, ...]}
## Returns count of items loaded.
func load_from_data(data: Dictionary, source: String = "base") -> int:
	if not data.has("items"):
		return 0

	var items_array = data.get("items")
	if not items_array is Array:
		push_warning("ItemRegistry: 'items' must be an array")
		return 0

	var count := 0
	for item_data in items_array:
		if not item_data is Dictionary:
			continue
		var item := _create_from_dict(item_data)
		if item:
			register_item(item, source)
			count += 1

	return count


## Create a ResourceItemData from a dictionary.
## Handles the conversion from JSON format to Godot resource.
func _create_from_dict(data: Dictionary) -> ResourceItemData:
	var id: String = data.get("id", "")
	if id.is_empty():
		push_warning("ItemRegistry: Item missing required 'id' field")
		return null

	var item := ResourceItemData.new()
	item.id = id
	item.name = data.get("name", id)
	item.description = data.get("description", "")
	item.category = data.get("category", "common")
	item.type = data.get("type", "material")
	item.rarity = data.get("rarity", "common")
	item.weight = data.get("weight", 1.0)
	item.stack_size = data.get("stack_size", 10)

	# Handle arrays
	var sources = data.get("sources", [])
	if sources is Array:
		item.sources = []
		for s in sources:
			item.sources.append(str(s))

	var used_for = data.get("used_for", [])
	if used_for is Array:
		item.used_for = []
		for u in used_for:
			item.used_for.append(str(u))

	return item


## Clear all registered items.
func clear() -> void:
	_items.clear()
	_sources.clear()
