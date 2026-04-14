class_name PauseMenu
extends CanvasLayer
## Pause menu displayed during gameplay.
## Uses ui_pause input action (Escape key) to toggle.
## Must have process_mode = PROCESS_MODE_ALWAYS to work when game is paused.

signal resume_pressed
signal quit_to_menu_pressed

@onready var resume_button: Button = $CenterContainer/PanelContainer/VBoxContainer/ResumeButton
@onready var quit_button: Button = $CenterContainer/PanelContainer/VBoxContainer/QuitButton

var _is_paused := false


func _ready() -> void:
	layer = 50  # Above HUD (10), below main menu (100)

	# CRITICAL: Must process when paused to respond to unpause input
	process_mode = Node.PROCESS_MODE_ALWAYS

	resume_button.pressed.connect(_on_resume_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

	# Start hidden
	visible = false

	print("[PauseMenu] Ready - process_mode: ALWAYS")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_pause"):
		toggle_pause()
		get_viewport().set_input_as_handled()


func toggle_pause() -> void:
	if _is_paused:
		_unpause()
	else:
		_pause()


func _pause() -> void:
	if not GameState.session_active:
		return  # Don't pause if no active session (e.g., in main menu)

	_is_paused = true
	get_tree().paused = true
	visible = true
	# Show mouse cursor for menu interaction
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	resume_button.grab_focus()
	print("[PauseMenu] Game paused")


func _unpause() -> void:
	_is_paused = false
	get_tree().paused = false
	visible = false
	# Re-capture mouse for FPS controls
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	print("[PauseMenu] Game resumed")


func _on_resume_pressed() -> void:
	_unpause()
	resume_pressed.emit()


func _on_quit_pressed() -> void:
	_unpause()  # Unpause before emitting so game can clean up
	quit_to_menu_pressed.emit()


## Force unpause (used when session ends)
func force_unpause() -> void:
	if _is_paused:
		_unpause()


## Check if currently paused
func is_paused() -> bool:
	return _is_paused
