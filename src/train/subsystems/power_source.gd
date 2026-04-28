class_name PowerSource
extends Subsystem

## Abstract interface for power-providing subsystems.
## Extend this class to create subsystems that can provide power to others.

## Emitted when power availability changes (emitted by subclasses like PowerGrid)
@warning_ignore("unused_signal")
signal power_availability_changed(is_available: bool)


## Returns true if this subsystem is currently providing power.
## Override in subclasses to implement actual power logic.
func is_providing_power() -> bool:
	push_error("PowerSource.is_providing_power() must be overridden")
	return false
