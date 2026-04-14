# Manages direction-based sprite animation for the player
# Reads velocity to determine facing direction, plays idle/walk animations
# Maps 8 isometric directions to 4 cardinal animation directions

class_name PlayerAnimationController
extends Node

signal animation_changed(anim_name: String)

# Map 8 directions to 4 cardinal animation suffixes
# Diagonals resolve to their dominant visual axis
const _DIRECTION_TO_ANIM_SUFFIX := {
	IsometricDirection.Direction.NONE: "s",
	IsometricDirection.Direction.N: "n",
	IsometricDirection.Direction.NE: "e",
	IsometricDirection.Direction.E: "e",
	IsometricDirection.Direction.SE: "s",
	IsometricDirection.Direction.S: "s",
	IsometricDirection.Direction.SW: "w",
	IsometricDirection.Direction.W: "w",
	IsometricDirection.Direction.NW: "n",
}

var sprite: AnimatedSprite2D
var current_direction: int = IsometricDirection.Direction.S


func _ready() -> void:
	var parent := get_parent()
	if parent:
		sprite = parent.get_node_or_null("AnimatedSprite2D")
	if not sprite:
		push_warning("PlayerAnimationController: No AnimatedSprite2D sibling found")


func update_animation(velocity: Vector2, moving: bool) -> void:
	if moving:
		var direction := IsometricDirection.from_vector(velocity)
		if direction != IsometricDirection.Direction.NONE:
			current_direction = direction

	var anim_name := _get_animation_name(moving)
	_play_animation(anim_name)


func _get_animation_name(moving: bool) -> String:
	var prefix := "walk" if moving else "idle"
	var suffix: String = _DIRECTION_TO_ANIM_SUFFIX.get(current_direction, "s")
	return "%s_%s" % [prefix, suffix]


func _play_animation(anim_name: String) -> void:
	if not sprite:
		return
	if sprite.sprite_frames and sprite.sprite_frames.has_animation(anim_name):
		if sprite.animation != anim_name:
			sprite.play(anim_name)
			animation_changed.emit(anim_name)
	else:
		# Fall back to "default" animation if the specific one doesn't exist
		if sprite.sprite_frames and sprite.sprite_frames.has_animation("default"):
			if sprite.animation != "default":
				sprite.play("default")
		else:
			push_warning("Animation not found: %s" % anim_name)
