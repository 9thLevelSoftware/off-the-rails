class_name InteractionStateMachine
extends RefCounted

## State machine tracking the interaction lifecycle.
## Manages transitions between IDLE, IN_RANGE, INTERACTING, and COOLDOWN states.
## No Node dependencies - pure logic suitable for infrastructure layer.

## Interaction states
enum State {
	IDLE,         ## No interactable in range
	IN_RANGE,     ## Interactable detected within range, ready to interact
	INTERACTING,  ## Currently interacting with an interactable
	COOLDOWN      ## Post-interaction cooldown period
}

## Emitted when state changes
signal state_changed(old_state: State, new_state: State)

## Emitted when player enters range of an interactable
signal entered_range(interactable_id: String)

## Emitted when player exits range of all interactables
signal exited_range()

## Emitted when interaction begins
signal interaction_started(interactable_id: String)

## Emitted when interaction ends
signal interaction_ended(interactable_id: String)

## Current state (readonly externally, use getter)
var _current_state: State = State.IDLE

## ID of interactable currently in range or being interacted with
var _current_target: String = ""

## Remaining cooldown time in seconds
var _cooldown_remaining: float = 0.0

## Duration of cooldown after interaction ends
var _cooldown_duration: float = 0.5


## Get the current state.
var current_state: State:
	get:
		return _current_state


## Get the current target interactable ID.
var current_target: String:
	get:
		return _current_target


## Update the state machine based on player position and available interactables.
## Call this every frame from a Node's _process or _physics_process.
func update(player_pos: Vector2, detector: IsometricProximityDetector) -> void:
	# Skip updates while interacting or in cooldown
	if _current_state == State.INTERACTING or _current_state == State.COOLDOWN:
		return

	# Find nearest interactable in range
	var nearest := detector.find_nearest_in_range(player_pos)

	match _current_state:
		State.IDLE:
			if nearest != "":
				_transition_to(State.IN_RANGE)
				_current_target = nearest
				entered_range.emit(nearest)

		State.IN_RANGE:
			if nearest == "":
				# No longer in range of anything
				_current_target = ""
				_transition_to(State.IDLE)
				exited_range.emit()
			elif nearest != _current_target:
				# Switched to a different interactable
				var old_target := _current_target
				_current_target = nearest
				exited_range.emit()
				entered_range.emit(nearest)


## Tick the state machine for time-based transitions.
## Call this every frame with delta time.
func tick(delta: float) -> void:
	if _current_state == State.COOLDOWN:
		_cooldown_remaining -= delta
		if _cooldown_remaining <= 0.0:
			_cooldown_remaining = 0.0
			_transition_to(State.IDLE)


## Attempt to start an interaction with the current target.
## Returns true if interaction started successfully.
func try_interact() -> bool:
	if _current_state != State.IN_RANGE:
		return false

	if _current_target == "":
		return false

	_transition_to(State.INTERACTING)
	interaction_started.emit(_current_target)
	return true


## End the current interaction and start cooldown.
func end_interaction() -> void:
	if _current_state != State.INTERACTING:
		return

	var ended_target := _current_target
	_current_target = ""
	_cooldown_remaining = _cooldown_duration
	_transition_to(State.COOLDOWN)
	interaction_ended.emit(ended_target)


## Set the cooldown duration for post-interaction cooldown.
func set_cooldown_duration(duration: float) -> void:
	_cooldown_duration = maxf(0.0, duration)


## Get the remaining cooldown time.
func get_cooldown_remaining() -> float:
	return _cooldown_remaining


## Check if currently in a state that allows interaction.
func can_interact() -> bool:
	return _current_state == State.IN_RANGE and _current_target != ""


## Check if currently interacting.
func is_interacting() -> bool:
	return _current_state == State.INTERACTING


## Check if in cooldown.
func is_in_cooldown() -> bool:
	return _current_state == State.COOLDOWN


## Force reset to IDLE state. Use sparingly - mainly for testing or error recovery.
func reset() -> void:
	var old_state := _current_state
	_current_state = State.IDLE
	_current_target = ""
	_cooldown_remaining = 0.0
	if old_state != State.IDLE:
		state_changed.emit(old_state, State.IDLE)


## Internal state transition with signal emission.
func _transition_to(new_state: State) -> void:
	if _current_state == new_state:
		return

	var old_state := _current_state
	_current_state = new_state
	state_changed.emit(old_state, new_state)


## Get state as string for debugging.
func get_state_name() -> String:
	match _current_state:
		State.IDLE:
			return "IDLE"
		State.IN_RANGE:
			return "IN_RANGE"
		State.INTERACTING:
			return "INTERACTING"
		State.COOLDOWN:
			return "COOLDOWN"
	return "UNKNOWN"
