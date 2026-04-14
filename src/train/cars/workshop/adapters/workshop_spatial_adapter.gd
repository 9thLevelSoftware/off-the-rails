class_name WorkshopSpatialAdapter
extends Node2D

## Adapter that bridges FloorLayout domain objects to Godot scene nodes.
## Renders EquipmentEntity instances as Sprite2D + StaticBody2D nodes.
## Creates EquipmentInteractable children for interaction system integration.
## Follows Clean Architecture: domain layer has no knowledge of this adapter.

const EquipmentEntityClass = preload("res://src/train/cars/workshop/domain/equipment_entity.gd")
const FloorLayoutClass = preload("res://src/train/cars/workshop/domain/floor_layout.gd")

## Emitted when an equipment node has been created and added to the scene
signal equipment_rendered(equipment_id: String)

## Reference to the FloorLayout domain object
var _floor_layout: FloorLayout = null

## Maps equipment_id -> Node2D for quick lookup
var _equipment_nodes: Dictionary = {}

## Maps equipment_id -> EquipmentInteractable for cleanup
var _equipment_interactables: Dictionary = {}

## Container for all equipment nodes (enables Y-sorting)
@onready var _equipment_container: Node2D = $EquipmentContainer

## Get placeholder color for equipment type
static func _get_placeholder_color(equipment_type: int) -> Color:
	match equipment_type:
		EquipmentEntity.EquipmentType.WORKBENCH:
			return Color(0.55, 0.35, 0.15)  # Brown
		EquipmentEntity.EquipmentType.LOCKER:
			return Color(0.4, 0.45, 0.5)    # Gray-blue
		EquipmentEntity.EquipmentType.CRATE:
			return Color(0.6, 0.5, 0.3)     # Tan
		EquipmentEntity.EquipmentType.SHELVING:
			return Color(0.5, 0.5, 0.5)     # Gray
		_:
			return Color(0.5, 0.5, 0.5)     # Default gray


func _ready() -> void:
	if not _equipment_container:
		push_error("WorkshopSpatialAdapter: EquipmentContainer child not found")


## Set up the adapter with a FloorLayout and render all equipment.
## Clears any existing equipment nodes first.
func setup(layout: FloorLayout) -> void:
	if layout == null:
		push_error("WorkshopSpatialAdapter: Cannot setup with null FloorLayout")
		return

	_floor_layout = layout
	_clear_equipment()
	_render_equipment()


## Clear all existing equipment nodes and interactables
func _clear_equipment() -> void:
	for equipment_id in _equipment_nodes.keys():
		var node: Node2D = _equipment_nodes[equipment_id]
		if is_instance_valid(node):
			node.queue_free()
	_equipment_nodes.clear()
	_equipment_interactables.clear()


## Render all equipment from the FloorLayout as scene nodes
func _render_equipment() -> void:
	if _floor_layout == null:
		return

	if _equipment_container == null:
		push_error("WorkshopSpatialAdapter: EquipmentContainer is null")
		return

	for equipment in _floor_layout.get_all_equipment():
		var node := _create_equipment_node(equipment)
		if node:
			_equipment_container.add_child(node)
			_equipment_nodes[equipment.equipment_id] = node

			# Create and attach EquipmentInteractable as child
			var interactable := _create_equipment_interactable(equipment, node)
			if interactable:
				_equipment_interactables[equipment.equipment_id] = interactable

			equipment_rendered.emit(equipment.equipment_id)


## Create a Node2D representing an equipment entity.
## Includes Sprite2D for visuals and StaticBody2D for collision.
func _create_equipment_node(equipment: EquipmentEntity) -> Node2D:
	if equipment == null:
		return null

	# Root node for this equipment
	var root := Node2D.new()
	root.name = equipment.equipment_id
	root.position = _tile_to_world(equipment.tile_position)

	# Create sprite
	var sprite := Sprite2D.new()
	sprite.name = "Sprite"

	# Try to load sprite from path, fall back to placeholder
	if equipment.sprite_path and ResourceLoader.exists(equipment.sprite_path):
		sprite.texture = load(equipment.sprite_path)
	else:
		sprite.texture = _create_placeholder_texture(equipment.equipment_type, equipment.collision_rect.size)

	root.add_child(sprite)

	# Create collision body
	var static_body := StaticBody2D.new()
	static_body.name = "StaticBody"

	var collision_shape := CollisionShape2D.new()
	collision_shape.name = "CollisionShape"

	var rect_shape := RectangleShape2D.new()
	rect_shape.size = equipment.collision_rect.size
	collision_shape.shape = rect_shape

	static_body.add_child(collision_shape)
	root.add_child(static_body)

	return root


## Convert tile coordinates to isometric world (screen) coordinates.
## Uses standard isometric projection: 2:1 ratio with 64x32 tiles.
func _tile_to_world(tile_pos: Vector2i) -> Vector2:
	return EquipmentEntity.tile_to_world(tile_pos)


## Create a placeholder texture for equipment that has no sprite.
## Returns an ImageTexture with a colored rectangle.
func _create_placeholder_texture(equipment_type: int, size: Vector2 = Vector2(64, 32)) -> ImageTexture:
	var color: Color = _get_placeholder_color(equipment_type)

	# Ensure minimum size
	var width := maxi(int(size.x), 16)
	var height := maxi(int(size.y), 16)

	# Create image with solid color and border
	var image := Image.create(width, height, false, Image.FORMAT_RGBA8)
	image.fill(color)

	# Add darker border for visibility
	var border_color := color.darkened(0.3)
	for x in range(width):
		image.set_pixel(x, 0, border_color)
		image.set_pixel(x, height - 1, border_color)
	for y in range(height):
		image.set_pixel(0, y, border_color)
		image.set_pixel(width - 1, y, border_color)

	return ImageTexture.create_from_image(image)


## Create an EquipmentInteractable for the given equipment and add as child.
func _create_equipment_interactable(equipment: EquipmentEntity, parent_node: Node2D) -> EquipmentInteractable:
	if equipment == null or parent_node == null:
		return null

	var interactable := EquipmentInteractable.new()
	interactable.name = "Interactable"
	parent_node.add_child(interactable)

	# Setup after adding to tree (required for deferred registration)
	interactable.setup(equipment)

	return interactable


## Get equipment node by ID
func get_equipment_node(equipment_id: String) -> Node2D:
	return _equipment_nodes.get(equipment_id, null)


## Get all equipment node IDs
func get_equipment_ids() -> Array:
	return _equipment_nodes.keys()


## Check if an equipment node exists
func has_equipment_node(equipment_id: String) -> bool:
	return _equipment_nodes.has(equipment_id)
