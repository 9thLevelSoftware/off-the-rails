class_name EscalationManager
extends Node

## Manages escalation level during expeditions.
## Tracks threat level as a percentage (0-100) and emits signals when crossing thresholds.

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

## Emitted when escalation level changes
signal escalation_changed(old_level: float, new_level: float)

## Emitted when crossing into a new threshold tier
signal threshold_crossed(old_threshold: EscalationThreshold, new_threshold: EscalationThreshold)

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
	pass


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
