class_name ResourceItemData
extends Resource
## Data resource for in-game resources/items.
## Generated from resources.yaml by yaml_to_tres.py

# Core properties
@export var id: String = ""
@export var name: String = ""
@export var description: String = ""

# Classification
@export_enum("common", "structured", "milestone") var category: String = "common"
@export_enum("material", "component", "consumable", "key_item", "data") var type: String = "material"
@export_enum("common", "uncommon", "rare", "very_rare", "unique") var rarity: String = "common"

# Physical properties
@export var weight: float = 1.0
@export var stack_size: int = 10

# Acquisition and usage
@export var sources: Array[String] = []
@export var used_for: Array[String] = []


func _to_string() -> String:
	return "[ResourceItemData:%s]" % id


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
