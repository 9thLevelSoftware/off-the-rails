# Adapter: Camera2D with follow and zoom behavior
# Consumes IsoCameraConfig from domain layer

class_name IsoCameraController
extends Camera2D

# Configuration (injected or default)
var config: IsoCameraConfig

# Target to follow
@export var follow_target: Node2D

# Current zoom level (interpolated)
var _current_zoom: float = 1.0
var _target_zoom: float = 1.0


func _ready() -> void:
	if not config:
		config = IsoCameraConfig.create_default()
	_current_zoom = 1.0
	_target_zoom = 1.0
	zoom = Vector2.ONE


func _physics_process(delta: float) -> void:
	_update_follow(delta)
	_update_zoom(delta)


func _input(event: InputEvent) -> void:
	if get_tree().paused:
		return
	if event is InputEventMouseButton:
		_handle_zoom_input(event)


# Follow target with lerp smoothing
func _update_follow(delta: float) -> void:
	if follow_target:
		var target_pos := follow_target.global_position + config.follow_offset
		global_position = global_position.lerp(target_pos, config.follow_speed * delta)


# Smoothly interpolate zoom
func _update_zoom(delta: float) -> void:
	if not is_equal_approx(_current_zoom, _target_zoom):
		_current_zoom = lerpf(_current_zoom, _target_zoom, config.zoom_speed * delta)
		zoom = Vector2(_current_zoom, _current_zoom)


# Handle mouse wheel zoom
func _handle_zoom_input(event: InputEventMouseButton) -> void:
	if event.button_index == MOUSE_BUTTON_WHEEL_UP:
		_target_zoom = clampf(_target_zoom + config.zoom_step, config.zoom_min, config.zoom_max)
	elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		_target_zoom = clampf(_target_zoom - config.zoom_step, config.zoom_min, config.zoom_max)


# Set zoom level directly (for saved state restoration)
func set_zoom_level(level: float) -> void:
	_target_zoom = clampf(level, config.zoom_min, config.zoom_max)
	_current_zoom = _target_zoom
	zoom = Vector2(_current_zoom, _current_zoom)


# Get current zoom level
func get_zoom_level() -> float:
	return _current_zoom
