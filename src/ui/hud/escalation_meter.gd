class_name EscalationMeterUI
extends Control

## Visual escalation meter that displays current threat level during expeditions.
## Color gradient: green (0-25%) -> yellow (25-50%) -> orange (50-75%) -> red (75-100%)
## Connects to EscalationManager via group lookup.

# --- Color constants for threshold tiers ---
const COLOR_NORMAL := Color(0.2, 0.8, 0.2)      # Green
const COLOR_ELEVATED := Color(0.9, 0.9, 0.2)   # Yellow
const COLOR_HIGH := Color(0.9, 0.5, 0.1)       # Orange
const COLOR_CRITICAL := Color(0.9, 0.2, 0.2)   # Red
const COLOR_OVERRUN := Color(0.6, 0.0, 0.0)    # Dark red

# --- Node references ---
@onready var progress_bar: ProgressBar = $VBoxContainer/ProgressBar
@onready var percentage_label: Label = $VBoxContainer/PercentageLabel
@onready var threshold_label: Label = $VBoxContainer/HeaderContainer/ThresholdLabel

# --- State ---
var _connected_manager: EscalationManager = null


func _ready() -> void:
	# Initialize display at 0%
	_update_display(0.0, EscalationManager.EscalationThreshold.NORMAL)


func _exit_tree() -> void:
	_disconnect_manager()


## Connects to an EscalationManager and subscribes to its signals.
func connect_to_manager(manager: EscalationManager) -> void:
	if _connected_manager == manager:
		return

	_disconnect_manager()
	_connected_manager = manager

	manager.escalation_changed.connect(_on_escalation_changed)
	manager.threshold_crossed.connect(_on_threshold_crossed)

	# Initialize with current values
	_update_display(manager.escalation_level, manager.current_threshold)
	print("[EscalationMeter] Connected to EscalationManager")


## Disconnects from the current EscalationManager.
func _disconnect_manager() -> void:
	if _connected_manager == null:
		return

	if _connected_manager.escalation_changed.is_connected(_on_escalation_changed):
		_connected_manager.escalation_changed.disconnect(_on_escalation_changed)
	if _connected_manager.threshold_crossed.is_connected(_on_threshold_crossed):
		_connected_manager.threshold_crossed.disconnect(_on_threshold_crossed)

	_connected_manager = null


## Called when escalation level changes.
func _on_escalation_changed(_old_level: float, new_level: float) -> void:
	var threshold := EscalationManager.EscalationThreshold.NORMAL
	if _connected_manager:
		threshold = _connected_manager.current_threshold
	_update_display(new_level, threshold)


## Called when threshold tier changes.
func _on_threshold_crossed(_old_threshold: EscalationManager.EscalationThreshold, new_threshold: EscalationManager.EscalationThreshold) -> void:
	var level: float = 0.0
	if _connected_manager:
		level = _connected_manager.escalation_level
	_update_display(level, new_threshold)


## Updates the visual display with current escalation state.
func _update_display(level: float, threshold: EscalationManager.EscalationThreshold) -> void:
	# Update progress bar value
	if progress_bar:
		progress_bar.value = level

	# Update percentage label
	if percentage_label:
		percentage_label.text = "%d%%" % int(level)

	# Update threshold label
	if threshold_label:
		threshold_label.text = EscalationManager.get_threshold_name_for(threshold)

	# Update color based on threshold
	var color := _get_threshold_color(threshold)
	_apply_color(color)


## Returns the color for a given threshold tier.
func _get_threshold_color(threshold: EscalationManager.EscalationThreshold) -> Color:
	match threshold:
		EscalationManager.EscalationThreshold.NORMAL:
			return COLOR_NORMAL
		EscalationManager.EscalationThreshold.ELEVATED:
			return COLOR_ELEVATED
		EscalationManager.EscalationThreshold.HIGH:
			return COLOR_HIGH
		EscalationManager.EscalationThreshold.CRITICAL:
			return COLOR_CRITICAL
		EscalationManager.EscalationThreshold.OVERRUN:
			return COLOR_OVERRUN
		_:
			return COLOR_NORMAL


## Applies color to progress bar and labels.
func _apply_color(color: Color) -> void:
	if progress_bar:
		# Create a stylebox for the fill color
		var fill_style := StyleBoxFlat.new()
		fill_style.bg_color = color
		fill_style.corner_radius_top_left = 4
		fill_style.corner_radius_top_right = 4
		fill_style.corner_radius_bottom_left = 4
		fill_style.corner_radius_bottom_right = 4
		progress_bar.add_theme_stylebox_override("fill", fill_style)

	if percentage_label:
		percentage_label.add_theme_color_override("font_color", color)

	if threshold_label:
		threshold_label.add_theme_color_override("font_color", color)
