class_name RecipeData
extends Resource
## Data resource for crafting recipes.
## Generated from recipes.yaml by yaml_to_tres.py

# Core properties
@export var id: String = ""
@export var name: String = ""
@export var description: String = ""

# Classification
@export_enum("consumable", "ammo", "medical", "repair", "tool", "equipment", "train_part", "specialty", "conversion") var category: String = "consumable"
@export var recipe_category: String = ""  # Original YAML category key

# Crafting requirements
@export_enum("field", "workshop", "armory", "infirmary", "refinery", "greenhouse", "lab") var station: String = "workshop"

# Input resources - dictionary of {resource_id: quantity}
@export var inputs: Dictionary = {}

# Output items - dictionary of {item_id: quantity}
@export var output: Dictionary = {}

# Timing
@export var craft_time: int = 60  # Base time in seconds

# Unlock requirements
@export_enum("default", "schematic_common", "schematic_advanced", "upgrade_t2", "upgrade_t3", "upgrade_t4", "research") var unlock: String = "default"

# Profession that gets -25% craft time
@export var profession_bonus: String = ""


func _to_string() -> String:
	return "[RecipeData:%s]" % id


## Check if this recipe is available by default
func is_default_unlocked() -> bool:
	return unlock == "default"


## Check if this recipe requires a schematic
func requires_schematic() -> bool:
	return unlock in ["schematic_common", "schematic_advanced"]


## Check if this recipe requires an upgrade
func requires_upgrade() -> bool:
	return unlock in ["upgrade_t2", "upgrade_t3", "upgrade_t4"]


## Get the input cost for a specific resource
func get_input_cost(resource_id: String) -> int:
	return inputs.get(resource_id, 0)


## Check if this recipe requires a specific resource
func requires_resource(resource_id: String) -> bool:
	return resource_id in inputs


## Get the output quantity for a specific item
func get_output_quantity(item_id: String) -> int:
	return output.get(item_id, 0)


## Get the primary output item ID (first key in output)
func get_primary_output_id() -> String:
	if output.is_empty():
		return ""
	return output.keys()[0]


## Get craft time with profession bonus applied
func get_craft_time_for_profession(profession_id: String) -> int:
	if profession_id == profession_bonus and profession_bonus != "":
		return int(craft_time * 0.75)  # 25% reduction
	return craft_time


## Check if inputs can be satisfied by available resources
func can_craft_with(available_resources: Dictionary) -> bool:
	for resource_id in inputs:
		var needed: int = inputs[resource_id]
		var have: int = available_resources.get(resource_id, 0)
		if have < needed:
			return false
	return true
