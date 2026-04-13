## GameState Autoload
## Central state management for campaign progression and session lifecycle.
## Emits signals for session and location changes that other systems can subscribe to.
extends Node

# --- Signals ---
## Emitted when a game session starts
signal session_started
## Emitted when a game session ends
signal session_ended
## Emitted when the player changes location
signal location_changed(new_location: String)

# --- Properties ---
## Current campaign phase (0 = not started, 1+ = phase number)
var campaign_phase: int = 0
## Current location identifier (e.g., "train_car_1", "expedition_forest")
var current_location: String = ""
## Whether a game session is currently active
var session_active: bool = false

# --- Methods ---

## Starts a new game session.
## Emits session_started signal.
func start_session() -> void:
	if session_active:
		push_warning("GameState: start_session() called while session already active")
		return
	session_active = true
	session_started.emit()


## Ends the current game session.
## Emits session_ended signal.
func end_session() -> void:
	if not session_active:
		push_warning("GameState: end_session() called while no session active")
		return
	session_active = false
	session_ended.emit()


## Changes the current location and emits location_changed signal.
## @param new_location: The location identifier to change to.
func change_location(new_location: String) -> void:
	if new_location == current_location:
		return
	current_location = new_location
	location_changed.emit(new_location)
