# Adapter: Manages the isometric rendering canvas
# Coordinates viewport, layers, and depth ordering
# NOTE: Extends Node2D (not CanvasLayer) so world content scrolls with camera

class_name IsoCanvas
extends Node2D

const ViewportCalc = preload("res://src/isometric/domain/viewport_calculator.gd")

# Child nodes for organized rendering
@onready var world_layer: Node2D = $WorldLayer
@onready var entity_layer: Node2D = $EntityLayer
@onready var ui_layer: CanvasLayer = $UILayer


func _ready() -> void:
	_setup_layers()


func _setup_layers() -> void:
	# World layer for tilemap (bottom)
	if world_layer:
		world_layer.y_sort_enabled = true
		world_layer.z_index = 0

	# Entity layer for characters/objects (middle)
	if entity_layer:
		entity_layer.y_sort_enabled = true
		entity_layer.z_index = 1

	# UI layer is already a CanvasLayer (top)


# Add an entity to the appropriate layer
func add_entity(entity: Node2D) -> void:
	if entity_layer:
		entity_layer.add_child(entity)


# Remove an entity from the entity layer
func remove_entity(entity: Node2D) -> void:
	if entity.get_parent() == entity_layer:
		entity_layer.remove_child(entity)


# Add world geometry (tiles, static objects)
func add_world_object(obj: Node2D) -> void:
	if world_layer:
		world_layer.add_child(obj)


# Get the depth value for a position (for manual z-ordering if needed)
func get_depth_at(position: Vector2) -> float:
	return ViewportCalc.calculate_depth(position)


# Check if a position is visible in the current viewport
func is_position_visible(world_pos: Vector2, camera: Camera2D) -> bool:
	if not camera:
		return true
	# Guard against zero zoom (would cause division by zero)
	if camera.zoom.x == 0.0 or camera.zoom.y == 0.0:
		return true
	var viewport_rect := camera.get_viewport_rect()
	var camera_pos := camera.global_position
	var half_size := viewport_rect.size / (2.0 * camera.zoom)
	var visible_rect := Rect2(camera_pos - half_size, half_size * 2)
	return visible_rect.has_point(world_pos)
