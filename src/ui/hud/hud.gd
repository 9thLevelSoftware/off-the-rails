class_name HUD
extends CanvasLayer

## Persistent HUD overlay that displays game state to the player.
## Shows escalation meter during expeditions, inventory counts, and health bar.
## Updates reactively via signal connections to GameState and EscalationManager.

# --- Node references ---
@onready var escalation_meter: Control = $MarginContainer/VBoxContainer/TopBar/EscalationContainer/EscalationMeter
@onready var inventory_display: Control = $MarginContainer/VBoxContainer/BottomBar/InventoryDisplay
@onready var health_bar: Control = $MarginContainer/VBoxContainer/TopBar/HealthContainer/HealthBar


func _ready() -> void:
	# Set layer above gameplay (10), below menus (20)
	layer = 10

	# Connect to GameState signals
	GameState.scene_transition_completed.connect(_on_scene_transition_completed)
	GameState.inventory_changed.connect(_on_inventory_changed)

	# Initial scene state update
	_update_escalation_visibility()
	_initialize_inventory_display()
	print("[HUD] Initialized - layer %d" % layer)


func _exit_tree() -> void:
	# Disconnect signals to prevent leaks
	if GameState.scene_transition_completed.is_connected(_on_scene_transition_completed):
		GameState.scene_transition_completed.disconnect(_on_scene_transition_completed)
	if GameState.inventory_changed.is_connected(_on_inventory_changed):
		GameState.inventory_changed.disconnect(_on_inventory_changed)


## Called when the game transitions between Train and Expedition scenes.
func _on_scene_transition_completed(_new_scene: GameState.GameScene) -> void:
	_update_escalation_visibility()


## Updates escalation meter visibility based on current scene.
## Only visible during Expedition, hidden in Train.
func _update_escalation_visibility() -> void:
	if escalation_meter:
		var in_expedition := GameState.current_scene == GameState.GameScene.EXPEDITION
		escalation_meter.visible = in_expedition

		# Connect to EscalationManager when entering expedition
		if in_expedition:
			_connect_escalation_manager()


## Finds and connects to the EscalationManager in the scene tree.
func _connect_escalation_manager() -> void:
	var managers := get_tree().get_nodes_in_group("escalation_manager")
	if managers.size() > 0:
		var manager: EscalationManager = managers[0]
		if escalation_meter.has_method("connect_to_manager"):
			escalation_meter.connect_to_manager(manager)


## Called when inventory changes. Forwards to inventory display.
func _on_inventory_changed(item_id: String, _old_quantity: int, new_quantity: int) -> void:
	if inventory_display and inventory_display.has_method("update_item"):
		inventory_display.update_item(item_id, new_quantity)


## Initializes inventory display with current inventory state.
func _initialize_inventory_display() -> void:
	if inventory_display and inventory_display.has_method("initialize"):
		inventory_display.initialize(GameState.inventory)
