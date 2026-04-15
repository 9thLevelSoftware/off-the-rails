## GameState Autoload
## Central state management for campaign progression and session lifecycle.
## Emits signals for session and location changes that other systems can subscribe to.
##
## PROFESSION SELECTION (V1):
## Currently defaults to Engineer profession on session start. A profession selection
## UI will be added in Phase 7 integration. For testing other professions, call:
##   GameState.select_profession(load("res://src/data/professions/medic.tres"))
## before starting the session.
extends Node

# --- Constants ---
const DEFAULT_PROFESSION_PATH := "res://src/data/professions/engineer.tres"

# --- Scene paths (V2 isometric) ---
# These paths were updated from V1 3D scenes to V2 isometric scenes.
# Workshop serves as the initial train car in V2 scope.
const TRAIN_SCENE := "res://src/train/cars/workshop/scenes/workshop.tscn"
const EXPEDITION_SCENE := "res://src/isometric/scenes/isometric_level.tscn"
const PLAYER_SCENE := "res://src/isometric/player/player.tscn"

# --- Signals ---
## Emitted when a game session starts
signal session_started
## Emitted when a game session ends
signal session_ended
## Emitted when the player changes location
signal location_changed(new_location: String)
## Emitted when a scene transition begins
signal scene_transition_started(from_scene: GameScene, to_scene: GameScene)
## Emitted when a scene transition completes
signal scene_transition_completed(new_scene: GameScene)
## Emitted when the player is spawned in a scene
signal player_spawned(player: CharacterBody2D)
## Emitted when a profession is selected
signal profession_selected(profession: ProfessionData)
## Emitted when inventory quantity changes for an item
signal inventory_changed(item_id: String, old_quantity: int, new_quantity: int)

# --- Inventory state ---
var inventory: Dictionary = {}  # {item_id: quantity}

# --- Scene state ---
enum GameScene { TRAIN, EXPEDITION }
var current_scene: GameScene = GameScene.TRAIN
var player_instance: CharacterBody2D = null

# --- Scene references ---
var train_scene_root: Node = null
var expedition_scene_root: Node = null

# --- Profession state ---
var player_profession: ProfessionData = null

# --- Properties ---
## Current campaign phase (0 = not started, 1+ = phase number)
var campaign_phase: int = 0
## Current location identifier (e.g., "train_car_1", "expedition_forest")
var current_location: String = ""
## Whether a game session is currently active
var session_active: bool = false

# --- Content Registry ---
var _content_registry: ContentRegistry = null


## Initialize the content registry. Call once at game startup.
func init_content_registry() -> bool:
	if _content_registry != null:
		return true
	_content_registry = ContentRegistry.new()
	return _content_registry.load_base_content()


## Get the content registry. Initializes lazily if not yet loaded.
## Uses ModLoader's registry when available (single source of truth for all content including mods).
func get_content_registry() -> ContentRegistry:
	# Use ModLoader's registry (single source of truth for all content including mods)
	# Access via get_node since ModLoader has no class_name (to avoid autoload shadowing)
	var mod_loader := get_node_or_null("/root/ModLoader")
	if mod_loader and mod_loader.is_ready():
		return mod_loader.get_content_registry()
	# Fallback for tests or if ModLoader not ready
	if _content_registry == null:
		if not init_content_registry():
			push_warning("GameState: ContentRegistry failed to load base content")
	return _content_registry


## Get an item definition by ID.
func get_item_data(item_id: String) -> ResourceItemData:
	return get_content_registry().get_item(item_id)


## Get a recipe definition by ID.
func get_recipe_data(recipe_id: String) -> RecipeData:
	return get_content_registry().get_recipe(recipe_id)


## Check if an item ID is valid (exists in registry).
func is_valid_item(item_id: String) -> bool:
	return get_content_registry().items.has_item(item_id)


# --- Methods ---

## Starts a new game session.
## Emits session_started signal.
func start_session() -> void:
	if session_active:
		push_warning("GameState: start_session() called while session already active")
		return

	# Default to Engineer profession for V1 testing if none selected
	if player_profession == null:
		var default_prof := load(DEFAULT_PROFESSION_PATH) as ProfessionData
		if default_prof:
			select_profession(default_prof)
			print("[GameState] Defaulted to Engineer profession for V1 testing")
		else:
			push_error("GameState: Failed to load default profession from %s" % DEFAULT_PROFESSION_PATH)

	session_active = true
	session_started.emit()


## Ends the current game session.
## Emits session_ended signal.
func end_session() -> void:
	if not session_active:
		push_warning("GameState: end_session() called while no session active")
		return
	session_active = false
	session_ended.emit()


## Changes the current location and emits location_changed signal.
## @param new_location: The location identifier to change to.
func change_location(new_location: String) -> void:
	if new_location == current_location:
		return
	current_location = new_location
	location_changed.emit(new_location)


## Selects a profession for the player.
## If player is already spawned, applies immediately. Otherwise, deferred until spawn.
func select_profession(profession: ProfessionData) -> void:
	player_profession = profession
	profession_selected.emit(profession)

	if player_instance and player_instance.has_method("set_profession"):
		player_instance.set_profession(profession)
		print("[GameState] Profession applied: %s" % profession.name)
	else:
		print("[GameState] Profession selected: %s (will apply on spawn)" % profession.name)


# --- Scene Transition Methods ---

## Transitions to the train scene.
func transition_to_train() -> void:
	_transition_to_scene(GameScene.TRAIN)


## Transitions to the expedition scene.
func transition_to_expedition() -> void:
	_transition_to_scene(GameScene.EXPEDITION)


## Internal method to handle scene transitions.
func _transition_to_scene(target: GameScene) -> void:
	if current_scene == target:
		return

	var from_scene := current_scene
	scene_transition_started.emit(from_scene, target)

	# Hide/disable current scene
	match current_scene:
		GameScene.TRAIN:
			if train_scene_root:
				train_scene_root.visible = false
				train_scene_root.process_mode = Node.PROCESS_MODE_DISABLED
		GameScene.EXPEDITION:
			if expedition_scene_root:
				expedition_scene_root.visible = false
				expedition_scene_root.process_mode = Node.PROCESS_MODE_DISABLED

	current_scene = target

	# Show/enable target scene and spawn player
	match target:
		GameScene.TRAIN:
			if train_scene_root:
				train_scene_root.visible = true
				train_scene_root.process_mode = Node.PROCESS_MODE_INHERIT
				_spawn_player_at_scene(train_scene_root)
		GameScene.EXPEDITION:
			if expedition_scene_root:
				expedition_scene_root.visible = true
				expedition_scene_root.process_mode = Node.PROCESS_MODE_INHERIT
				_spawn_player_at_scene(expedition_scene_root)

	scene_transition_completed.emit(target)


## Spawns or moves the player to the spawn point in the given scene.
func _spawn_player_at_scene(scene_root: Node) -> void:
	if not player_instance:
		var player_packed := load(PLAYER_SCENE) as PackedScene
		if player_packed == null:
			push_error("GameState: Failed to load player scene from %s" % PLAYER_SCENE)
			return
		player_instance = player_packed.instantiate()

	# Reparent player to scene if needed
	if player_instance.get_parent() != scene_root:
		if player_instance.get_parent():
			player_instance.get_parent().remove_child(player_instance)
		scene_root.add_child(player_instance)

	# V2: Uses Node2D spawn points with simple position assignment.
	# V1 used Node3D with Transform3D.
	var spawn_point := scene_root.get_node_or_null("PlayerSpawn") as Node2D
	if spawn_point:
		player_instance.position = spawn_point.position

	player_spawned.emit(player_instance)

	# Apply deferred profession after spawn
	if player_profession and player_instance.has_method("set_profession"):
		player_instance.set_profession(player_profession)
		print("[GameState] Deferred profession applied: %s" % player_profession.name)


## Registers a scene root for scene transition management.
## Call this from each scene's _ready() method.
## If session is active and this is the current scene type, spawns player.
func register_scene(scene_type: GameScene, scene_root: Node) -> void:
	match scene_type:
		GameScene.TRAIN:
			train_scene_root = scene_root
		GameScene.EXPEDITION:
			expedition_scene_root = scene_root

	# If session is active and this scene matches current scene, spawn player
	# This handles initial load when transition_to_scene is skipped
	# Use call_deferred to ensure scene is fully in tree before accessing global transforms
	if session_active and scene_type == current_scene:
		call_deferred("_spawn_player_at_scene", scene_root)
		call_deferred("emit_signal", "scene_transition_completed", current_scene)


# --- Inventory Methods ---

## Add quantity to inventory for an item.
## Returns the new quantity.
func add_to_inventory(item_id: String, quantity: int) -> int:
	var old_qty: int = inventory.get(item_id, 0)
	var new_qty: int = old_qty + quantity
	inventory[item_id] = new_qty
	inventory_changed.emit(item_id, old_qty, new_qty)
	return new_qty


## Remove quantity from inventory for an item.
## Returns true if removal was successful (had enough), false otherwise.
func remove_from_inventory(item_id: String, quantity: int) -> bool:
	var current: int = inventory.get(item_id, 0)
	if current < quantity:
		return false
	var new_qty: int = current - quantity
	if new_qty == 0:
		inventory.erase(item_id)
	else:
		inventory[item_id] = new_qty
	inventory_changed.emit(item_id, current, new_qty)
	return true


## Get current quantity of an item in inventory.
func get_inventory_quantity(item_id: String) -> int:
	return inventory.get(item_id, 0)


## Check if inventory has at least the specified quantity of an item.
func has_inventory_quantity(item_id: String, quantity: int) -> bool:
	return inventory.get(item_id, 0) >= quantity


## Check if inventory has all specified items in required quantities.
## items_dict: {item_id: quantity_needed}
func has_all_inventory(items_dict: Dictionary) -> bool:
	for item_id in items_dict:
		var needed: int = items_dict[item_id]
		if inventory.get(item_id, 0) < needed:
			return false
	return true


## Consume multiple items from inventory atomically.
## Returns true if all items were consumed, false if any were missing (no partial consumption).
func consume_inventory(items_dict: Dictionary) -> bool:
	# First check if we have everything
	if not has_all_inventory(items_dict):
		return false
	# Then consume all
	for item_id in items_dict:
		var quantity: int = items_dict[item_id]
		var old_qty: int = inventory.get(item_id, 0)
		var new_qty: int = old_qty - quantity
		if new_qty == 0:
			inventory.erase(item_id)
		else:
			inventory[item_id] = new_qty
		inventory_changed.emit(item_id, old_qty, new_qty)
	return true


## Add multiple items to inventory.
func add_all_inventory(items_dict: Dictionary) -> void:
	for item_id in items_dict:
		var quantity: int = items_dict[item_id]
		add_to_inventory(item_id, quantity)


## Debug method to set inventory directly (for testing).
func debug_set_inventory(new_inventory: Dictionary) -> void:
	var old_inventory := inventory.duplicate()
	inventory = new_inventory.duplicate()
	# Emit changes for removed items
	for item_id in old_inventory:
		if item_id not in inventory:
			inventory_changed.emit(item_id, old_inventory[item_id], 0)
	# Emit changes for added/modified items
	for item_id in inventory:
		var old_qty: int = old_inventory.get(item_id, 0)
		var new_qty: int = inventory[item_id]
		if old_qty != new_qty:
			inventory_changed.emit(item_id, old_qty, new_qty)
