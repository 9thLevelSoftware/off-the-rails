class_name RecipeValidator
extends RefCounted

## Use case for validating crafting operations.
## Checks resource availability, calculates craft times, identifies missing resources.
## Pure domain logic - no Node dependencies.


## Result of a validation check
class ValidationResult extends RefCounted:
	var success: bool = false
	var reason: String = ""
	var missing_resources: Dictionary = {}  # {resource_id: missing_quantity}

	static func ok() -> ValidationResult:
		var result := ValidationResult.new()
		result.success = true
		result.reason = "OK"
		return result

	static func fail(p_reason: String, p_missing: Dictionary = {}) -> ValidationResult:
		var result := ValidationResult.new()
		result.success = false
		result.reason = p_reason
		result.missing_resources = p_missing
		return result

	func _to_string() -> String:
		if success:
			return "[ValidationResult: OK]"
		return "[ValidationResult: FAIL - %s]" % reason


## Check if a recipe can be crafted with available resources
## Returns ValidationResult with success/failure and details
static func can_craft(recipe: RecipeData, available_resources: Dictionary) -> ValidationResult:
	if recipe == null:
		return ValidationResult.fail("No recipe specified")

	if recipe.inputs.is_empty():
		return ValidationResult.ok()  # No inputs required

	var missing: Dictionary = get_missing_resources(recipe, available_resources)

	if missing.is_empty():
		return ValidationResult.ok()

	var missing_names: Array = []
	for resource_id in missing:
		missing_names.append("%s (need %d more)" % [resource_id, missing[resource_id]])

	var reason := "Missing resources: %s" % ", ".join(missing_names)
	return ValidationResult.fail(reason, missing)


## Get dictionary of missing resources for a recipe
## Returns {resource_id: quantity_missing} for each missing resource
## Returns empty dictionary if all resources are available
static func get_missing_resources(recipe: RecipeData, available_resources: Dictionary) -> Dictionary:
	var missing: Dictionary = {}

	for resource_id in recipe.inputs:
		var needed: int = recipe.inputs[resource_id]
		var have: int = available_resources.get(resource_id, 0)

		if have < needed:
			missing[resource_id] = needed - have

	return missing


## Calculate craft time for a recipe with modifiers
## Base time - 25% if profession matches, station tier bonus applied
## Station tier bonus: T1=0%, T2=30%, T3=60%, T4=100%
static func calculate_craft_time(recipe: RecipeData, profession_id: String = "", station_tier: int = 1) -> float:
	var base_time := float(recipe.craft_time)

	# Apply profession bonus (-25%)
	if profession_id != "" and recipe.has_profession_bonus() and recipe.profession_bonus == profession_id:
		base_time *= 0.75

	# Apply station tier bonus
	var tier_multiplier := get_tier_speed_multiplier(station_tier)
	base_time /= tier_multiplier  # Faster = divide by multiplier > 1

	return base_time


## Get speed multiplier for station tier
## Higher multiplier = faster crafting
static func get_tier_speed_multiplier(station_tier: int) -> float:
	match station_tier:
		1:
			return 1.0    # T1: Base speed
		2:
			return 1.30   # T2: +30% speed
		3:
			return 1.60   # T3: +60% speed
		4:
			return 2.0    # T4: +100% speed (double)
		_:
			return 1.0


## Validate that a recipe can be crafted at a specific station
static func validate_station(recipe: RecipeData, station_type: String) -> ValidationResult:
	if recipe == null:
		return ValidationResult.fail("No recipe specified")

	if recipe.station != station_type:
		return ValidationResult.fail("Recipe requires %s station, not %s" % [recipe.station, station_type])

	return ValidationResult.ok()


## Validate recipe unlock status
## unlock_checks should contain the player's current unlock state
## e.g., {"schematics": ["schematic_common"], "upgrades": ["upgrade_t2"], "research": []}
static func validate_unlock(recipe: RecipeData, unlock_checks: Dictionary) -> ValidationResult:
	if recipe == null:
		return ValidationResult.fail("No recipe specified")

	if recipe.is_default_unlocked():
		return ValidationResult.ok()

	var unlock_type := recipe.unlock

	if unlock_type.begins_with("schematic_"):
		var schematics: Array = unlock_checks.get("schematics", [])
		if unlock_type in schematics:
			return ValidationResult.ok()
		return ValidationResult.fail("Requires %s schematic" % unlock_type)

	if unlock_type.begins_with("upgrade_"):
		var upgrades: Array = unlock_checks.get("upgrades", [])
		if unlock_type in upgrades:
			return ValidationResult.ok()
		return ValidationResult.fail("Requires station %s" % unlock_type)

	if unlock_type == "research":
		var research: Array = unlock_checks.get("research", [])
		if recipe.id in research:
			return ValidationResult.ok()
		return ValidationResult.fail("Requires research unlock")

	return ValidationResult.fail("Unknown unlock type: %s" % unlock_type)


## Full validation: station, unlock, and resources
static func validate_full(
	recipe: RecipeData,
	station_type: String,
	available_resources: Dictionary,
	unlock_checks: Dictionary,
	_profession_id: String = ""
) -> ValidationResult:
	# Check station
	var station_result := validate_station(recipe, station_type)
	if not station_result.success:
		return station_result

	# Check unlock status
	var unlock_result := validate_unlock(recipe, unlock_checks)
	if not unlock_result.success:
		return unlock_result

	# Check resources
	var resource_result := can_craft(recipe, available_resources)
	return resource_result


## Calculate how many times a recipe can be crafted with available resources
static func get_max_craft_count(recipe: RecipeData, available_resources: Dictionary) -> int:
	if recipe.inputs.is_empty():
		return 999  # Arbitrary large number for recipes with no inputs

	var max_count := 999

	for resource_id in recipe.inputs:
		var needed: int = recipe.inputs[resource_id]
		var have: int = available_resources.get(resource_id, 0)

		if needed <= 0:
			continue

		var can_make: int = int(float(have) / float(needed))
		max_count = mini(max_count, can_make)

	return max_count


## Get resources that would be consumed for a batch of crafts
static func get_batch_cost(recipe: RecipeData, count: int) -> Dictionary:
	var cost: Dictionary = {}
	for resource_id in recipe.inputs:
		cost[resource_id] = recipe.inputs[resource_id] * count
	return cost


## Get items that would be produced for a batch of crafts
static func get_batch_output(recipe: RecipeData, count: int) -> Dictionary:
	var outputs: Dictionary = {}
	for item_id in recipe.output:
		outputs[item_id] = recipe.output[item_id] * count
	return outputs
