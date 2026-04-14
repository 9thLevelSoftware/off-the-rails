class_name HealthBarUI
extends Control

## Health bar UI element for displaying player health.
## For V1: static display at 100% as placeholder for future combat system.
## Exposes API for future integration: set_health(), take_damage()

# --- Visual constants ---
const COLOR_HEALTHY := Color(0.2, 0.8, 0.2)      # Green
const COLOR_WOUNDED := Color(0.9, 0.9, 0.2)     # Yellow
const COLOR_CRITICAL := Color(0.9, 0.2, 0.2)    # Red

# --- Threshold percentages ---
const THRESHOLD_WOUNDED := 50.0   # Below 50% = yellow
const THRESHOLD_CRITICAL := 25.0  # Below 25% = red

# --- Node references ---
@onready var progress_bar: ProgressBar = $VBoxContainer/ProgressBar
@onready var health_label: Label = $VBoxContainer/HealthLabel

# --- State ---
var _current_health: float = 100.0
var _max_health: float = 100.0


func _ready() -> void:
	# Initialize at full health for V1
	set_health(100.0, 100.0)


## Sets the current and maximum health values.
## @param current: Current health value
## @param max_health: Maximum health value
func set_health(current: float, max_health: float) -> void:
	_current_health = clampf(current, 0.0, max_health)
	_max_health = max_health
	_update_display()


## Applies damage to current health.
## @param amount: Amount of damage to apply
func take_damage(amount: float) -> void:
	_current_health = maxf(0.0, _current_health - amount)
	_update_display()


## Heals current health by the specified amount.
## @param amount: Amount to heal
func heal(amount: float) -> void:
	_current_health = minf(_max_health, _current_health + amount)
	_update_display()


## Returns the current health percentage (0-100).
func get_health_percentage() -> float:
	if _max_health <= 0.0:
		return 0.0
	return (_current_health / _max_health) * 100.0


## Returns true if health is at zero.
func is_dead() -> bool:
	return _current_health <= 0.0


## Updates the visual display.
func _update_display() -> void:
	var percentage := get_health_percentage()

	# Update progress bar
	if progress_bar:
		progress_bar.max_value = _max_health
		progress_bar.value = _current_health

	# Update label
	if health_label:
		health_label.text = "%d / %d" % [int(_current_health), int(_max_health)]

	# Update color based on health percentage
	var color := _get_health_color(percentage)
	_apply_color(color)


## Returns the appropriate color for the current health percentage.
func _get_health_color(percentage: float) -> Color:
	if percentage <= THRESHOLD_CRITICAL:
		return COLOR_CRITICAL
	elif percentage <= THRESHOLD_WOUNDED:
		return COLOR_WOUNDED
	else:
		return COLOR_HEALTHY


## Applies color to progress bar and label.
func _apply_color(color: Color) -> void:
	if progress_bar:
		var fill_style := StyleBoxFlat.new()
		fill_style.bg_color = color
		fill_style.corner_radius_top_left = 4
		fill_style.corner_radius_top_right = 4
		fill_style.corner_radius_bottom_left = 4
		fill_style.corner_radius_bottom_right = 4
		progress_bar.add_theme_stylebox_override("fill", fill_style)

	if health_label:
		health_label.add_theme_color_override("font_color", color)
