class_name ExpeditionPauseHandler
extends RefCounted

## Handles automatic pausing/resuming of crafting during expeditions.
## Listens to GameState's scene_transition_completed signal.
## Pauses crafting when entering EXPEDITION, resumes when returning to TRAIN.

## JobScheduler instance for pause/resume control
var _scheduler: JobScheduler
var _connected: bool = false


## Constructor
## @param scheduler: JobScheduler - The scheduler to pause/resume
func _init(scheduler) -> void:
	_scheduler = scheduler


## Start listening to scene transitions.
## Call this once when the handler is set up.
func connect_signals() -> void:
	if _connected:
		return
	if not GameState.scene_transition_completed.is_connected(_on_scene_transition_completed):
		GameState.scene_transition_completed.connect(_on_scene_transition_completed)
		_connected = true


## Stop listening to scene transitions.
## Call this when the handler is no longer needed.
func disconnect_signals() -> void:
	if not _connected:
		return
	if GameState.scene_transition_completed.is_connected(_on_scene_transition_completed):
		GameState.scene_transition_completed.disconnect(_on_scene_transition_completed)
		_connected = false


## Handle scene transition.
## Pauses on EXPEDITION, resumes on TRAIN.
func _on_scene_transition_completed(new_scene: GameState.GameScene) -> void:
	match new_scene:
		GameState.GameScene.EXPEDITION:
			_scheduler.pause("expedition_active")
		GameState.GameScene.TRAIN:
			_scheduler.resume()


## Manual pause for expedition (for external control).
func pause_for_expedition() -> void:
	_scheduler.pause("expedition_active")


## Manual resume after expedition (for external control).
func resume_from_expedition() -> void:
	_scheduler.resume()


## Check if currently paused due to expedition.
func is_paused_for_expedition() -> bool:
	return _scheduler.is_paused() and _scheduler.get_pause_reason() == "expedition_active"
