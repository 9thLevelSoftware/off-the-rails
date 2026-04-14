## Expedition Scene
## The procedurally generated expedition environment for combat and exploration.
extends Node3D

@onready var exit_trigger: Area3D = $ExitTrigger

## Reference to the escalation manager. Set in editor or auto-discovered from children.
@export var escalation_manager: EscalationManager


func _ready() -> void:
	add_to_group("expedition")
	_discover_escalation_manager()
	if GameState:
		GameState.register_scene(GameState.GameScene.EXPEDITION, self)
	if exit_trigger:
		# Configure collision - only detect layer 1 (player/physics bodies)
		exit_trigger.set_collision_layer_value(1, false)  # Area doesn't need to be on layer 1
		exit_trigger.set_collision_mask_value(1, true)    # Detect layer 1 bodies
		exit_trigger.body_entered.connect(_on_exit_trigger_body_entered)
	print("Expedition: Scene initialized")


func _on_exit_trigger_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		GameState.transition_to_train()


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
