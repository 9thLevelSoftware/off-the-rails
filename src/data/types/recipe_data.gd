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


## Create a RecipeData instance from a dictionary.
## Centralized factory method used by ContentRegistry and ModAPI.
static func from_dict(data: Dictionary) -> RecipeData:
	var id_val: String = data.get("id", "")
	if id_val.is_empty():
		return null

	var recipe := RecipeData.new()
	recipe.id = id_val
	recipe.name = data.get("name", id_val)
	recipe.description = data.get("description", "")
	recipe.category = data.get("category", "consumable")
	recipe.recipe_category = data.get("recipe_category", "")
	recipe.station = data.get("station", "workshop")
	recipe.craft_time = data.get("craft_time", 60)
	recipe.unlock = data.get("unlock", "default")
	recipe.profession_bonus = data.get("profession_bonus", "")

	var inputs_data = data.get("inputs", {})
	if inputs_data is Dictionary:
		recipe.inputs = inputs_data.duplicate()
	elif inputs_data is Array:
		recipe.inputs = {}
		for input_entry in inputs_data:
			if input_entry is Dictionary:
				var item_id: String = input_entry.get("item_id", "")
				var quantity: int = input_entry.get("quantity", 1)
				if not item_id.is_empty():
					recipe.inputs[item_id] = quantity

	var output_data = data.get("output", {})
	if output_data is Dictionary:
		if output_data.has("item_id"):
			var item_id: String = output_data.get("item_id", "")
			var quantity: int = output_data.get("quantity", 1)
			recipe.output = {item_id: quantity}
		else:
			recipe.output = output_data.duplicate()

	return recipe


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


## Check if this recipe has a profession bonus
func has_profession_bonus() -> bool:
	return profession_bonus != "" and profession_bonus != null


## Get total input cost (sum of all input quantities)
func get_total_input_cost() -> int:
	var total: int = 0
	for resource_id in inputs:
		total += inputs[resource_id]
	return total


## Get total output quantity (sum of all output quantities)
func get_total_output_quantity() -> int:
	var total: int = 0
	for item_id in output:
		total += output[item_id]
	return total
