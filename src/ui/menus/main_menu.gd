class_name MainMenu
extends CanvasLayer
## Main menu displayed when game launches.
## Provides Start and Exit options. Start transitions to profession selection.

signal start_pressed
signal exit_pressed

@onready var start_button: Button = $CenterContainer/VBoxContainer/StartButton
@onready var exit_button: Button = $CenterContainer/VBoxContainer/ExitButton


func _ready() -> void:
	layer = 100  # Top layer, above all gameplay and other menus

	start_button.pressed.connect(_on_start_pressed)
	exit_button.pressed.connect(_on_exit_pressed)

	# Grab focus on start button for keyboard/gamepad navigation
	start_button.grab_focus()

	print("[MainMenu] Ready")


func _on_start_pressed() -> void:
	start_pressed.emit()


func _on_exit_pressed() -> void:
	exit_pressed.emit()


## Shows the main menu
func show_menu() -> void:
	visible = true
	start_button.grab_focus()


## Hides the main menu
func hide_menu() -> void:
	visible = false
