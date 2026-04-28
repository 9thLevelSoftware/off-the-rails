extends Camera3D
## True-dimetric (2:1 isometric) camera with optional follow target.
##
## Attach this script to a Camera3D node. Set `target` in the inspector to a
## Node3D (typically the player). Leave `target` null for a free/static camera.
##
## The dimetric angle (atan(1/√2) ≈ 35.264°) makes 1×1×1 meter boxes appear as
## 2:1 diamonds on screen — the classic "isometric" look used by PZ, RimWorld,
## Roguelikes. Pair this with `projection = PROJECTION_ORTHOGONAL` (set below
## in _ready()) and adjust `size` for zoom.
##
## Controls at runtime (for debugging): mouse wheel zooms in/out.

## Node the camera should follow. If null, the camera stays put.
@export var target: Node3D

## Horizontal offset from the target (world-space meters).
@export var follow_offset: Vector3 = Vector3.ZERO

## How snappy the follow is. Higher = stiffer, lower = lazier/lag.
@export_range(1.0, 30.0) var follow_smoothing: float = 10.0

## Orthographic size in world-space units. ~10-12 works well for interior rooms.
@export_range(1.0, 50.0) var zoom_size: float = 12.0

## Zoom min/max for mouse-wheel zoom.
@export var zoom_min: float = 4.0
@export var zoom_max: float = 30.0

const DIMETRIC_PITCH_DEG: float = -35.264
const DIMETRIC_YAW_DEG: float = 45.0


func _ready() -> void:
	projection = PROJECTION_ORTHOGONAL
	size = zoom_size
	rotation_degrees = Vector3(DIMETRIC_PITCH_DEG, DIMETRIC_YAW_DEG, 0.0)


func _process(delta: float) -> void:
	if target == null:
		return
	# Smoothly interpolate camera position toward the target + offset.
	var desired: Vector3 = target.global_position + follow_offset
	global_position = global_position.lerp(desired, clamp(follow_smoothing * delta, 0.0, 1.0))


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_size = clamp(zoom_size - 1.0, zoom_min, zoom_max)
			size = zoom_size
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_size = clamp(zoom_size + 1.0, zoom_min, zoom_max)
			size = zoom_size
