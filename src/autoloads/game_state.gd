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

# --- Scene paths ---
const TRAIN_SCENE := "res://src/train/train.tscn"
const EXPEDITION_SCENE := "res://src/expedition/expedition.tscn"
const PLAYER_SCENE := "res://src/player/player.tscn"

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
signal player_spawned(player: CharacterBody3D)
## Emitted when a profession is selected
signal profession_selected(profession: ProfessionData)

# --- Scene state ---
enum GameScene { TRAIN, EXPEDITION }
var current_scene: GameScene = GameScene.TRAIN
var player_instance: CharacterBody3D = null

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
		player_instance = player_packed.instantiate()

	var spawn_point := scene_root.get_node_or_null("PlayerSpawn") as Node3D
	if spawn_point:
		player_instance.global_position = spawn_point.global_position
		player_instance.global_rotation = spawn_point.global_rotation

	if player_instance.get_parent() != scene_root:
		if player_instance.get_parent():
			player_instance.get_parent().remove_child(player_instance)
		scene_root.add_child(player_instance)

	player_spawned.emit(player_instance)

	# Apply deferred profession after spawn
	if player_profession and player_instance.has_method("set_profession"):
		player_instance.set_profession(player_profession)
		print("[GameState] Deferred profession applied: %s" % player_profession.name)


## Registers a scene root for scene transition management.
## Call this from each scene's _ready() method.
func register_scene(scene_type: GameScene, scene_root: Node) -> void:
	match scene_type:
		GameScene.TRAIN:
			train_scene_root = scene_root
		GameScene.EXPEDITION:
			expedition_scene_root = scene_root
