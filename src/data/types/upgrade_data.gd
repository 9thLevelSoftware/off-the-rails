class_name UpgradeData
extends Resource
## Data resource for train car upgrades.
## Generated from upgrades.yaml by yaml_to_tres.py

# Core properties
@export var id: String = ""
@export var name: String = ""
@export var description: String = ""

# Classification
@export var car: String = ""  # Which car this upgrade belongs to
@export_enum("core", "side") var path: String = "core"
@export var tier: int = 1  # 1-4 for core, unlock_tier for side

# Unlock tier (for side branches)
@export var unlock_tier: int = 0

# Effects - list of gameplay effects
@export var effects: Array[String] = []

# Resource costs - dictionary of {resource_id: quantity}
@export var costs: Dictionary = {}

# Prerequisites - list of upgrade IDs required
@export var requires: Array[String] = []

# Profession that gets a bonus when building this
@export var profession_bonus: String = ""


func _to_string() -> String:
	return "[UpgradeData:%s]" % id


## Check if this is a core (required) upgrade
func is_core() -> bool:
	return path == "core"


## Check if this is a side (optional) upgrade
func is_side() -> bool:
	return path == "side"


## Get the effective tier (tier for core, unlock_tier for side)
func get_effective_tier() -> int:
	if is_side() and unlock_tier > 0:
		return unlock_tier
	return tier


## Check if prerequisites are met given a list of completed upgrades
func prerequisites_met(completed_upgrades: Array[String]) -> bool:
	for req in requires:
		if req not in completed_upgrades:
			return false
	return true


## Get the cost for a specific resource
func get_cost(resource_id: String) -> int:
	return costs.get(resource_id, 0)


## Check if this upgrade requires a specific resource
func requires_resource(resource_id: String) -> bool:
	return resource_id in costs


## Get total resource cost count
func get_total_cost_items() -> int:
	var total := 0
	for cost in costs.values():
		total += cost
	return total
