class_name EnemySpawner
extends Node3D

## Spawns enemies based on escalation threshold crossings.
## Connects to EscalationManager via deferred initialization to avoid race conditions.
## Validates spawn points and falls back to children or origin if none configured.

## The enemy scene to spawn.
@export var enemy_scene: PackedScene

## Spawn point markers. If empty, will auto-discover Marker3D children or use origin.
@export var spawn_points: Array[Marker3D] = []

## Maximum number of enemies allowed at once.
@export var max_enemies: int = 10

## Emitted when an enemy is spawned.
signal enemy_spawned(enemy: Node3D, spawn_point: Marker3D)

## Emitted when spawn fails (max reached, no scene, no points).
signal spawn_failed(reason: String)

## Tracks spawned enemies for cleanup and count limiting.
var _spawned_enemies: Array[Node3D] = []

## Tracks the last threshold we processed to prevent duplicate spawns.
var _last_processed_threshold: EscalationManager.EscalationThreshold = EscalationManager.EscalationThreshold.NORMAL

## Reference to the EscalationManager.
var _escalation_manager: EscalationManager = null

## Spawn counts per threshold crossing.
const SPAWN_COUNTS := {
	EscalationManager.EscalationThreshold.ELEVATED: 1,
	EscalationManager.EscalationThreshold.HIGH: 2,
	EscalationManager.EscalationThreshold.CRITICAL: 3,
	EscalationManager.EscalationThreshold.OVERRUN: 2
}


func _ready() -> void:
	# Use deferred calls to ensure scene tree is fully initialized
	call_deferred("_deferred_connect_signals")
	call_deferred("_validate_spawn_points")


## Deferred signal connection to EscalationManager (CRITIQUE FIX: Task 4).
func _deferred_connect_signals() -> void:
	_escalation_manager = get_tree().get_first_node_in_group("escalation_manager") as EscalationManager
	if _escalation_manager:
		_escalation_manager.threshold_crossed.connect(_on_threshold_crossed)
		# Sync initial threshold state
		_last_processed_threshold = _escalation_manager.current_threshold
		print("EnemySpawner: Connected to EscalationManager (current threshold: %s)" %
			EscalationManager.get_threshold_name_for(_last_processed_threshold))
	else:
		push_error("EnemySpawner: No EscalationManager found in 'escalation_manager' group")


## Validates and populates spawn_points array (CRITIQUE FIX: Task 3).
func _validate_spawn_points() -> void:
	# If spawn_points already populated, verify they're valid
	if not spawn_points.is_empty():
		var valid_points: Array[Marker3D] = []
		for point in spawn_points:
			if is_instance_valid(point):
				valid_points.append(point)
			else:
				push_warning("EnemySpawner: Invalid spawn point reference removed")
		spawn_points = valid_points
		if not spawn_points.is_empty():
			print("EnemySpawner: Using %d configured spawn points" % spawn_points.size())
			return

	# Fallback: auto-discover Marker3D children
	for child in get_children():
		if child is Marker3D:
			spawn_points.append(child)

	if not spawn_points.is_empty():
		print("EnemySpawner: Auto-discovered %d Marker3D children as spawn points" % spawn_points.size())
		return

	# Last resort: create a virtual spawn point at origin
	push_warning("EnemySpawner: No spawn points found - will spawn at spawner origin")


## Handles threshold crossing events.
func _on_threshold_crossed(_old_threshold: EscalationManager.EscalationThreshold,
		new_threshold: EscalationManager.EscalationThreshold) -> void:
	# Task 5: Debounce - only process if threshold actually increased beyond last processed
	if new_threshold <= _last_processed_threshold:
		return

	# Update tracking to prevent duplicate processing
	_last_processed_threshold = new_threshold

	# Get spawn count for this threshold
	if not SPAWN_COUNTS.has(new_threshold):
		return

	var spawn_count: int = SPAWN_COUNTS[new_threshold]
	print("EnemySpawner: Threshold crossed to %s - spawning %d enemies" %
		[EscalationManager.get_threshold_name_for(new_threshold), spawn_count])

	for i in range(spawn_count):
		spawn_enemy()


## Spawns a single enemy at a random spawn point.
## Returns the spawned enemy or null if spawn failed.
func spawn_enemy() -> Node3D:
	# Task 6: Respect max_enemies limit
	_cleanup_dead_enemies()
	if get_enemy_count() >= max_enemies:
		var reason := "Max enemy limit reached (%d/%d)" % [get_enemy_count(), max_enemies]
		spawn_failed.emit(reason)
		print("EnemySpawner: %s" % reason)
		return null

	# Check enemy scene is set
	if not enemy_scene:
		var reason := "No enemy_scene configured"
		spawn_failed.emit(reason)
		push_error("EnemySpawner: %s" % reason)
		return null

	# Get spawn position
	var spawn_pos: Vector3
	var spawn_marker: Marker3D = null

	if spawn_points.is_empty():
		# Fallback to spawner origin
		spawn_pos = global_position
	else:
		# Random spawn point selection
		spawn_marker = spawn_points[randi() % spawn_points.size()]
		spawn_pos = spawn_marker.global_position

	# Instantiate and position enemy
	var enemy: Node3D = enemy_scene.instantiate()
	enemy.global_position = spawn_pos

	# Set spawn point reference if enemy supports it
	if enemy.has_method("set") and "spawn_point" in enemy:
		enemy.spawn_point = spawn_marker

	# Add to scene tree (as sibling to spawner's parent for clean hierarchy)
	var parent := get_parent()
	if parent:
		parent.add_child(enemy)
	else:
		add_child(enemy)

	# Track spawned enemy
	_spawned_enemies.append(enemy)

	enemy_spawned.emit(enemy, spawn_marker)
	print("EnemySpawner: Spawned enemy at %s (count: %d/%d)" %
		[spawn_pos, get_enemy_count(), max_enemies])

	return enemy


## Returns current count of active (non-freed) enemies.
func get_enemy_count() -> int:
	_cleanup_dead_enemies()
	return _spawned_enemies.size()


## Removes freed enemies from tracking array.
func _cleanup_dead_enemies() -> void:
	_spawned_enemies = _spawned_enemies.filter(func(e): return is_instance_valid(e))


## Resets spawner state (called when expedition resets).
func reset() -> void:
	# Clean up all spawned enemies
	for enemy in _spawned_enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	_spawned_enemies.clear()
	_last_processed_threshold = EscalationManager.EscalationThreshold.NORMAL
	print("EnemySpawner: Reset - all enemies cleared")
