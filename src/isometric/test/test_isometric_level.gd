# Test scene for verifying isometric foundation
# R1: TileMapLayer + Y-sort verification
# R2: Camera follow + zoom verification

class_name TestIsoLevel
extends Node2D

@onready var iso_level: IsoLevel = $IsoLevel
@onready var test_entity: CharacterBody2D = $TestEntity

const MOVE_SPEED: float = 200.0


func _ready() -> void:
	call_deferred("_initialize_test")


func _initialize_test() -> void:
	if not iso_level:
		push_error("TestIsoLevel: IsoLevel child not found")
		return
	if not test_entity:
		push_error("TestIsoLevel: TestEntity child not found")
		return

	# Wait for tilemap adapter to be ready
	var tilemap_adapter := iso_level.get_tilemap()
	if tilemap_adapter and not tilemap_adapter.is_ready():
		push_warning("TileMapLayer adapter not yet initialized, waiting...")
		await get_tree().process_frame

	# Connect camera to test entity
	iso_level.set_camera_target(test_entity)

	# Position test entity at origin
	test_entity.global_position = Vector2.ZERO

	print("Isometric Foundation Test")
	print("========================")
	print("WASD: Move test entity")
	print("Mouse wheel: Zoom in/out")
	print("Watch Y-sorting as entity moves")


# NOTE: delta is passed but unused — CharacterBody2D.move_and_slide() handles
# frame-rate independence internally
func _physics_process(_delta: float) -> void:
	_handle_movement()


func _handle_movement() -> void:
	var input_dir := Vector2.ZERO

	if Input.is_action_pressed("move_forward"):
		input_dir.y -= 1
	if Input.is_action_pressed("move_backward"):
		input_dir.y += 1
	if Input.is_action_pressed("move_left"):
		input_dir.x -= 1
	if Input.is_action_pressed("move_right"):
		input_dir.x += 1

	if input_dir != Vector2.ZERO:
		input_dir = input_dir.normalized()
		var screen_dir := Vector2(input_dir.x, input_dir.y)
		test_entity.velocity = screen_dir * MOVE_SPEED
		test_entity.move_and_slide()
