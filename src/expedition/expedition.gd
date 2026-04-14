## Expedition Scene
## The procedurally generated expedition environment for combat and exploration.
extends Node3D

@onready var exit_trigger: Area3D = $ExitTrigger

## Reference to the escalation manager. Set in editor or auto-discovered from children.
@export var escalation_manager: EscalationManager

## Reference to enemy spawner for reset on re-entry.
var _enemy_spawner: EnemySpawner = null


func _ready() -> void:
	add_to_group("expedition")
	_discover_escalation_manager()
	_discover_enemy_spawner()
	if GameState:
		GameState.register_scene(GameState.GameScene.EXPEDITION, self)
		# Connect to scene transition to handle escalation lifecycle
		GameState.scene_transition_completed.connect(_on_scene_transition_completed)
	if exit_trigger:
		# Configure collision - only detect layer 1 (player/physics bodies)
		exit_trigger.set_collision_layer_value(1, false)  # Area doesn't need to be on layer 1
		exit_trigger.set_collision_mask_value(1, true)    # Detect layer 1 bodies
		exit_trigger.body_entered.connect(_on_exit_trigger_body_entered)
	else:
		push_error("Expedition: ExitTrigger not found - players will be trapped in expedition")
	print("Expedition: Scene initialized")


func _on_exit_trigger_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		_end_expedition()
		GameState.transition_to_train()


## Called when scene transition completes.
func _on_scene_transition_completed(new_scene: GameState.GameScene) -> void:
	if new_scene == GameState.GameScene.EXPEDITION:
		_start_expedition()


## Starts expedition systems when entering the expedition scene.
func _start_expedition() -> void:
	if escalation_manager:
		escalation_manager.start_expedition()
	if _enemy_spawner:
		_enemy_spawner.reset()
	print("Expedition: Started")


## Ends expedition systems when leaving the expedition scene.
func _end_expedition() -> void:
	if escalation_manager:
		escalation_manager.end_expedition()
	print("Expedition: Ended")


## Disconnects signals when the expedition scene is removed from the tree.
func _exit_tree() -> void:
	if GameState and GameState.scene_transition_completed.is_connected(_on_scene_transition_completed):
		GameState.scene_transition_completed.disconnect(_on_scene_transition_completed)


## Auto-discovers EscalationManager if not explicitly set via @export.
func _discover_escalation_manager() -> void:
	if escalation_manager:
		return
	for child in get_children():
		if child is EscalationManager:
			escalation_manager = child
			break
	if not escalation_manager:
		push_warning("Expedition: No EscalationManager found as child node")


## Auto-discovers EnemySpawner from children.
func _discover_enemy_spawner() -> void:
	for child in get_children():
		if child is EnemySpawner:
			_enemy_spawner = child
			break
