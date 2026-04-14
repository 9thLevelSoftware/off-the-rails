class_name EscalationManager
extends Node

## Manages escalation level during expeditions.
## Tracks threat level as a percentage (0-100) and emits signals when crossing thresholds.
## Supports time-based escalation, action triggers, and pause/resume functionality.

## Escalation thresholds representing threat levels during an expedition.
## NORMAL: 0-25%, ELEVATED: 26-50%, HIGH: 51-75%, CRITICAL: 76-99%, OVERRUN: 100%
enum EscalationThreshold {
	NORMAL,     ## 0-25%: Routine exploration, minimal threat
	ELEVATED,   ## 26-50%: Increased activity, caution advised
	HIGH,       ## 51-75%: Significant danger, defensive measures needed
	CRITICAL,   ## 76-99%: Extreme threat, extraction recommended
	OVERRUN     ## 100%: Position compromised, immediate evacuation required
}

## Threshold boundary constants (exclusive upper bounds for each tier below)
const THRESHOLD_ELEVATED := 25.0
const THRESHOLD_HIGH := 50.0
const THRESHOLD_CRITICAL := 75.0
const THRESHOLD_OVERRUN := 100.0

## Escalation trigger constants for common actions
const TRIGGER_COMBAT_LIGHT := 5.0   ## Light combat encounter
const TRIGGER_COMBAT_HEAVY := 15.0  ## Heavy combat or boss encounter
const TRIGGER_ALARM := 25.0         ## Triggered alarm or loud event
const TRIGGER_SEALED_AREA := 7.0    ## Entering a sealed/restricted area

## Time-based escalation rate (escalation points per minute)
@export var time_escalation_rate: float = 2.0
## Whether time-based escalation is enabled
@export var time_escalation_enabled: bool = true

## Emitted when escalation level changes
signal escalation_changed(old_level: float, new_level: float)

## Emitted when crossing into a new threshold tier
signal threshold_crossed(old_threshold: EscalationThreshold, new_threshold: EscalationThreshold)

## Accumulated time for time-based escalation (in seconds)
var _escalation_timer: float = 0.0
## Whether escalation is currently paused
var _is_paused: bool = false

## Read-only accessor for pause state
var is_paused: bool:
	get:
		return _is_paused

## Current escalation level (0.0 to 100.0)
var escalation_level: float = 0.0:
	set(value):
		var clamped_value := clampf(value, 0.0, 100.0)
		if escalation_level == clamped_value:
			return
		var old_level := escalation_level
		var old_threshold := current_threshold
		escalation_level = clamped_value
		var new_threshold := get_threshold_for_level(escalation_level)

		escalation_changed.emit(old_level, escalation_level)

		if old_threshold != new_threshold:
			threshold_crossed.emit(old_threshold, new_threshold)

## Current threshold computed from escalation_level
var current_threshold: EscalationThreshold:
	get:
		return get_threshold_for_level(escalation_level)


func _ready() -> void:
	add_to_group("escalation_manager")
	# Disable processing until expedition starts
	set_process(false)


func _process(delta: float) -> void:
	if not time_escalation_enabled or _is_paused:
		return

	# Accumulate time and apply escalation
	_escalation_timer += delta

	# Convert rate from per-minute to per-second and apply
	var rate_per_second := time_escalation_rate / 60.0
	var escalation_amount := rate_per_second * delta

	if escalation_amount > 0.0:
		escalation_level += escalation_amount


## Determines the threshold tier for a given escalation level.
## Boundaries: NORMAL [0-25], ELEVATED (25-50], HIGH (50-75], CRITICAL (75-100), OVERRUN [100]
func get_threshold_for_level(level: float) -> EscalationThreshold:
	if level >= THRESHOLD_OVERRUN:
		return EscalationThreshold.OVERRUN
	elif level > THRESHOLD_CRITICAL:
		return EscalationThreshold.CRITICAL
	elif level > THRESHOLD_HIGH:
		return EscalationThreshold.HIGH
	elif level > THRESHOLD_ELEVATED:
		return EscalationThreshold.ELEVATED
	else:
		return EscalationThreshold.NORMAL


## Resets escalation to zero (beginning of expedition).
func reset_escalation() -> void:
	escalation_level = 0.0
	_escalation_timer = 0.0


## Adds escalation from an action or event.
## @param amount: Escalation points to add (will be clamped to 100 max total)
## @param reason: Optional description for debug output
func add_escalation(amount: float, reason: String = "") -> void:
	if amount <= 0.0:
		return

	var old_level := escalation_level
	escalation_level += amount  # Setter handles clamping

	var reason_text := " (%s)" % reason if reason != "" else ""
	print("Escalation +%.1f%s: %.1f%%" % [amount, reason_text, escalation_level])


## Triggers combat escalation.
## @param heavy: If true, uses TRIGGER_COMBAT_HEAVY, otherwise TRIGGER_COMBAT_LIGHT
func trigger_combat(heavy: bool = false) -> void:
	var amount := TRIGGER_COMBAT_HEAVY if heavy else TRIGGER_COMBAT_LIGHT
	var reason := "heavy combat" if heavy else "light combat"
	add_escalation(amount, reason)


## Triggers alarm escalation.
func trigger_alarm() -> void:
	add_escalation(TRIGGER_ALARM, "alarm triggered")


## Triggers sealed area escalation.
func trigger_sealed_area() -> void:
	add_escalation(TRIGGER_SEALED_AREA, "entered sealed area")


## Returns true if escalation has reached the OVERRUN threshold (100%).
func is_overrun() -> bool:
	return current_threshold == EscalationThreshold.OVERRUN


## Returns human-readable name for the current threshold.
func get_threshold_name() -> String:
	return get_threshold_name_for(current_threshold)


## Returns human-readable name for a specific threshold.
static func get_threshold_name_for(threshold: EscalationThreshold) -> String:
	match threshold:
		EscalationThreshold.NORMAL:
			return "Normal"
		EscalationThreshold.ELEVATED:
			return "Elevated"
		EscalationThreshold.HIGH:
			return "High"
		EscalationThreshold.CRITICAL:
			return "Critical"
		EscalationThreshold.OVERRUN:
			return "Overrun"
		_:
			return "Unknown"


## Pauses time-based escalation. Action triggers still work.
func pause_escalation() -> void:
	_is_paused = true


## Resumes time-based escalation after a pause.
func resume_escalation() -> void:
	_is_paused = false


## Starts the expedition, enabling escalation systems.
## Resets escalation to zero and enables time-based escalation.
func start_expedition() -> void:
	reset_escalation()
	_is_paused = false
	time_escalation_enabled = true
	set_process(true)
	print("Expedition started - escalation tracking enabled")


## Ends the expedition, disabling escalation systems.
## Stops time-based escalation and processing.
func end_expedition() -> void:
	time_escalation_enabled = false
	set_process(false)
	print("Expedition ended - final escalation: %.1f%% (%s)" % [escalation_level, get_threshold_name()])
