class_name ProfessionUtils
extends RefCounted

## Utility functions for profession data parsing.


## Parse cooldown string "120s" to float seconds 120.0
static func parse_cooldown(cooldown_str: String) -> float:
	if cooldown_str.is_empty():
		return 0.0
	var numeric_part := cooldown_str.trim_suffix("s").strip_edges()
	if numeric_part.is_valid_float():
		return numeric_part.to_float()
	push_warning("ProfessionUtils: Invalid cooldown format '%s'" % cooldown_str)
	return 0.0


## Parse percentage from string like "25%" to float 0.25
static func parse_percentage(text: String) -> float:
	var regex := RegEx.new()
	regex.compile("(\\d+)%")
	var result := regex.search(text)
	if result:
		return result.get_string(1).to_float() / 100.0
	return 0.0


## Check if bonus is a "faster" type (multiply rate)
static func is_speed_bonus(text: String) -> bool:
	return "faster" in text.to_lower()


## Check if bonus is a "reduced" type (multiply cost)
static func is_reduction_bonus(text: String) -> bool:
	return "reduced" in text.to_lower()
