class_name EnemyPlaceholder
extends CharacterBody3D

## Placeholder enemy for Phase 4 integration testing.
## Visual representation: red capsule mesh.
## Behavior: static placeholder - no AI or movement implemented yet.

## Whether this enemy is currently active (for future AI system).
var is_active: bool = true

## Reference to spawn point this enemy originated from (for debugging).
var spawn_point: Marker3D = null


func _ready() -> void:
	add_to_group("enemies")
	print("EnemyPlaceholder: Spawned at %s" % global_position)


## Called when enemy is defeated (stub for future implementation).
func defeat() -> void:
	print("EnemyPlaceholder: Defeated at %s" % global_position)
	queue_free()


## Returns enemy info for debugging.
func get_debug_info() -> Dictionary:
	var spawn_name: String = spawn_point.name if spawn_point else "unknown"
	return {
		"position": global_position,
		"is_active": is_active,
		"spawn_point": spawn_name
	}
