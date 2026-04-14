# Immutable camera configuration
# Used by camera_2d_controller.gd adapter

class_name IsoCameraConfig
extends RefCounted

const Self = preload("res://src/isometric/domain/camera_config.gd")

# Follow behavior
var follow_speed: float = 5.0
var follow_offset: Vector2 = Vector2.ZERO

# Zoom constraints
var zoom_min: float = 0.5
var zoom_max: float = 2.0
var zoom_step: float = 0.1
var zoom_speed: float = 10.0

# Factory method for default config
static func create_default() -> IsoCameraConfig:
	return Self.new()

# Factory method for custom config
static func create(p_follow_speed: float, p_zoom_min: float, p_zoom_max: float) -> IsoCameraConfig:
	var config := Self.new()
	config.follow_speed = p_follow_speed
	config.zoom_min = p_zoom_min
	config.zoom_max = p_zoom_max
	return config
