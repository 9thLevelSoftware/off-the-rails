class_name ResourceItemData
extends Resource
## Data resource for in-game resources/items.
## Generated from resources.yaml by yaml_to_tres.py

# Core properties
@export var id: String = ""
@export var name: String = ""
@export var description: String = ""

# Classification
@export_enum("common", "structured", "milestone", "crafted") var category: String = "common"
@export_enum("material", "component", "consumable", "key_item", "data", "ammo", "equipment", "tool") var type: String = "material"
@export_enum("common", "uncommon", "rare", "very_rare", "unique") var rarity: String = "common"

# Physical properties
@export var weight: float = 1.0
@export var stack_size: int = 10

# Acquisition and usage
@export var sources: Array[String] = []
@export var used_for: Array[String] = []


func _to_string() -> String:
	return "[ResourceItemData:%s]" % id


## Create a ResourceItemData instance from a dictionary.
## Centralized factory method used by ContentRegistry and ModAPI.
static func from_dict(data: Dictionary) -> ResourceItemData:
	var id_val: String = data.get("id", "")
	if id_val.is_empty():
		return null

	var item := ResourceItemData.new()
	item.id = id_val
	item.name = data.get("name", id_val)
	item.description = data.get("description", "")
	item.category = data.get("category", "common")
	item.type = data.get("type", "material")
	item.rarity = data.get("rarity", "common")
	item.weight = data.get("weight", 1.0)
	item.stack_size = data.get("stack_size", 10)

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


## Check if this resource can be found at a location type
func found_at(location_type: String) -> bool:
	return location_type in sources


## Check if this resource is used for a specific purpose
func is_used_for(purpose: String) -> bool:
	return purpose in used_for


## Get the total weight for a given quantity
func get_weight_for_quantity(quantity: int) -> float:
	return weight * quantity


## Get how many stacks are needed for a quantity
func get_stacks_needed(quantity: int) -> int:
	return ceili(float(quantity) / float(stack_size))


## Check if this is a progression-gating resource
func is_milestone() -> bool:
	return category == "milestone"


## Check if this is a basic common resource
func is_common() -> bool:
	return category == "common"


## Check if this is a crafted item
func is_crafted() -> bool:
	return category == "crafted"


## Check if this is ammunition
func is_ammo() -> bool:
	return type == "ammo"


## Check if this is equipment (wearable)
func is_equipment() -> bool:
	return type == "equipment"


## Check if this is a tool
func is_tool() -> bool:
	return type == "tool"
