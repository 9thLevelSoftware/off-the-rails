extends CharacterBody3D
## Player controller with WASD movement, mouse look, jump, and sprint support.

# Movement settings
@export var walk_speed: float = 5.0
@export var sprint_speed: float = 8.0
@export var jump_velocity: float = 4.5
@export var mouse_sensitivity: float = 0.002

# Camera pitch limits (in radians)
@export var min_pitch: float = -1.4  # ~-80 degrees
@export var max_pitch: float = 1.4   # ~80 degrees

# Node references
@onready var camera_mount: Node3D = $CameraMount
@onready var camera: Camera3D = $CameraMount/Camera3D
@onready var ability_manager: AbilityManager = $AbilityManager
@onready var passive_bonus_manager: PassiveBonusManager = $PassiveBonusManager

# Current profession data
var _profession: ProfessionData = null

# Gravity from project settings
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)


func _ready() -> void:
	# Explicit collision layer setup (layer 1: physics bodies)
	set_collision_layer_value(1, true)
	set_collision_mask_value(1, true)
	# Add to player group for identification
	add_to_group("player")
	# Capture the mouse cursor for FPS-style controls
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _input(event: InputEvent) -> void:
	# Handle mouse look
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		# Horizontal rotation (yaw) - rotate the entire player
		rotate_y(-event.relative.x * mouse_sensitivity)
		# Vertical rotation (pitch) - rotate only the camera mount
		camera_mount.rotate_x(-event.relative.y * mouse_sensitivity)
		camera_mount.rotation.x = clamp(camera_mount.rotation.x, min_pitch, max_pitch)

	# Note: Mouse capture is now handled by pause menu. When paused, mouse is visible.
	# When unpaused, we re-capture automatically.
	# Clicking in the game window will also re-capture the mouse.
	if event is InputEventMouseButton and event.pressed and not get_tree().paused:
		if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _physics_process(delta: float) -> void:
	# Apply gravity when not on floor
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	# Determine current speed (walking or sprinting)
	var current_speed := sprint_speed if Input.is_action_pressed("sprint") else walk_speed

	# Get input direction using Input.get_vector for smooth diagonal movement
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")

	# Transform input direction relative to player's facing direction
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	# Apply horizontal movement
	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		# Decelerate when no input
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)

	# Move the character using Jolt-compatible move_and_slide
	move_and_slide()


func set_profession(profession: ProfessionData) -> void:
	if ability_manager == null:
		push_error("Player: AbilityManager not found - cannot set profession")
		return

	if passive_bonus_manager == null:
		push_error("Player: PassiveBonusManager not found - cannot set profession")
		return

	_profession = profession
	ability_manager.set_profession(profession)
	passive_bonus_manager.set_profession(profession)

	if profession:
		print("[Player] Profession set: %s" % profession.name)


## Check if player's profession can work at a specific car.
## Uses ProfessionData.can_work_at() for the check.
func can_work_at_car(car_id: String) -> bool:
	if _profession == null:
		return false
	return _profession.can_work_at(car_id)


## Get the player's primary station (car) ID.
func get_primary_station() -> String:
	if _profession == null:
		return ""
	return _profession.primary_car


## Get the current profession data.
func get_profession() -> ProfessionData:
	return _profession
