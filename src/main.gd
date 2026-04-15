## Main Scene Controller
## Manages additive scene loading for Train and Expedition scenes.
## Uses SceneContainer node for dynamically loaded child scenes.
## Also manages game state transitions: Main Menu -> Profession Select -> Gameplay
extends Node

# --- Constants ---
const TRAIN_SCENE_PATH: String = "res://src/train/cars/workshop/scenes/workshop.tscn"
const EXPEDITION_SCENE_PATH: String = "res://src/expedition/expedition.tscn"
const MAIN_MENU_SCENE_PATH: String = "res://src/ui/menus/main_menu.tscn"
const PROFESSION_SELECT_SCENE_PATH: String = "res://src/ui/menus/profession_select.tscn"
const PAUSE_MENU_SCENE_PATH: String = "res://src/ui/menus/pause_menu.tscn"

# --- Game States ---
enum GameMode { MAIN_MENU, PROFESSION_SELECT, PLAYING }

# --- Node References ---
@onready var scene_container: Node = $SceneContainer
@onready var ui_layer: CanvasLayer = $UILayer
@onready var hud: CanvasLayer = $HUD
@onready var _crafting_ui: CraftingUI = $UILayer/CraftingUI

# --- State ---
var _train_instance: Node = null
var _expedition_instance: Node = null
var _main_menu: CanvasLayer = null
var _profession_select: CanvasLayer = null
var _pause_menu: CanvasLayer = null
var _current_mode: GameMode = GameMode.MAIN_MENU

# --- Lifecycle ---

func _ready() -> void:
	# Scene loading architecture:
	# - Main handles initial scene loading on startup (load_train/load_expedition)
	# - Each scene registers itself with GameState in its _ready() via register_scene()
	# - After initial load, GameState handles all transitions via transition_to_train/expedition()
	# - GameState manages player spawning, scene visibility, and process modes
	print("Main: Scene initialized")

	# Connect to GameState signals
	GameState.session_started.connect(_on_session_started)
	GameState.session_ended.connect(_on_session_ended)

	# Connect crafting UI signal
	CraftingEventBus.get_instance().crafting_ui_requested.connect(_on_crafting_ui_requested)

	# Load menu scenes
	_load_menus()

	# Start in main menu mode
	_enter_main_menu()


# --- Public Methods ---

## Loads the Train scene into the SceneContainer.
## Does nothing if Train is already loaded.
func load_train() -> void:
	if _train_instance != null:
		push_warning("Main: load_train() called but Train is already loaded")
		return
	
	var train_scene: PackedScene = load(TRAIN_SCENE_PATH)
	if train_scene == null:
		push_error("Main: Failed to load Train scene from " + TRAIN_SCENE_PATH)
		return
	
	_train_instance = train_scene.instantiate()
	scene_container.add_child(_train_instance)
	print("Main: Train scene loaded")


## Loads the Expedition scene into the SceneContainer.
## Does nothing if Expedition is already loaded.
func load_expedition() -> void:
	if _expedition_instance != null:
		push_warning("Main: load_expedition() called but Expedition is already loaded")
		return
	
	var expedition_scene: PackedScene = load(EXPEDITION_SCENE_PATH)
	if expedition_scene == null:
		push_error("Main: Failed to load Expedition scene from " + EXPEDITION_SCENE_PATH)
		return
	
	_expedition_instance = expedition_scene.instantiate()
	scene_container.add_child(_expedition_instance)
	print("Main: Expedition scene loaded")


## Unloads the Expedition scene from the SceneContainer.
## Does nothing if Expedition is not loaded.
func unload_expedition() -> void:
	if _expedition_instance == null:
		push_warning("Main: unload_expedition() called but Expedition is not loaded")
		return
	
	_expedition_instance.queue_free()
	_expedition_instance = null
	print("Main: Expedition scene unloaded")


## Unloads the Train scene from the SceneContainer.
## Does nothing if Train is not loaded.
func unload_train() -> void:
	if _train_instance == null:
		push_warning("Main: unload_train() called but Train is not loaded")
		return
	
	_train_instance.queue_free()
	_train_instance = null
	print("Main: Train scene unloaded")


## Returns true if the Train scene is currently loaded.
func is_train_loaded() -> bool:
	return _train_instance != null


## Returns true if the Expedition scene is currently loaded.
func is_expedition_loaded() -> bool:
	return _expedition_instance != null


# --- Menu Management ---

## Loads all menu scenes
func _load_menus() -> void:
	# Load Main Menu
	var main_menu_scene: PackedScene = load(MAIN_MENU_SCENE_PATH)
	if main_menu_scene:
		_main_menu = main_menu_scene.instantiate()
		add_child(_main_menu)
		_main_menu.start_pressed.connect(_on_main_menu_start)
		_main_menu.exit_pressed.connect(_on_main_menu_exit)
		print("Main: Main menu loaded")
	else:
		push_error("Main: Failed to load main menu from " + MAIN_MENU_SCENE_PATH)

	# Load Profession Select
	var profession_scene: PackedScene = load(PROFESSION_SELECT_SCENE_PATH)
	if profession_scene:
		_profession_select = profession_scene.instantiate()
		add_child(_profession_select)
		_profession_select.profession_selected.connect(_on_profession_selected)
		_profession_select.back_pressed.connect(_on_profession_back)
		_profession_select.visible = false
		print("Main: Profession select loaded")
	else:
		push_error("Main: Failed to load profession select from " + PROFESSION_SELECT_SCENE_PATH)

	# Load Pause Menu
	var pause_scene: PackedScene = load(PAUSE_MENU_SCENE_PATH)
	if pause_scene:
		_pause_menu = pause_scene.instantiate()
		add_child(_pause_menu)
		_pause_menu.quit_to_menu_pressed.connect(_on_pause_quit_to_menu)
		print("Main: Pause menu loaded")
	else:
		push_error("Main: Failed to load pause menu from " + PAUSE_MENU_SCENE_PATH)


## Enters main menu mode
func _enter_main_menu() -> void:
	_current_mode = GameMode.MAIN_MENU

	# Ensure mouse is visible for menu interaction
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	# Show main menu, hide others
	if _main_menu:
		_main_menu.show_menu()
	if _profession_select:
		_profession_select.hide_menu()

	# Hide HUD during menus
	if hud:
		hud.visible = false

	# Unload gameplay scenes if loaded
	if _train_instance:
		unload_train()
	if _expedition_instance:
		unload_expedition()

	print("Main: Entered MAIN_MENU mode")


## Enters profession select mode
func _enter_profession_select() -> void:
	_current_mode = GameMode.PROFESSION_SELECT

	if _main_menu:
		_main_menu.hide_menu()
	if _profession_select:
		_profession_select.show_menu()

	print("Main: Entered PROFESSION_SELECT mode")


## Enters gameplay mode
func _enter_playing() -> void:
	_current_mode = GameMode.PLAYING

	# Hide menus
	if _main_menu:
		_main_menu.hide_menu()
	if _profession_select:
		_profession_select.hide_menu()

	# Show HUD
	if hud:
		hud.visible = true

	# Load train scene
	load_train()

	print("Main: Entered PLAYING mode")


# --- Menu Signal Handlers ---

func _on_main_menu_start() -> void:
	_enter_profession_select()


func _on_main_menu_exit() -> void:
	print("Main: Exiting game")
	get_tree().quit()


func _on_profession_selected(profession: ProfessionData) -> void:
	print("Main: Profession selected: %s" % profession.name)
	GameState.select_profession(profession)
	GameState.start_session()
	# Note: _enter_playing() is called via _on_session_started


func _on_profession_back() -> void:
	_enter_main_menu()


func _on_pause_quit_to_menu() -> void:
	GameState.end_session()
	# Note: _enter_main_menu() is called via _on_session_ended


# --- GameState Signal Handlers ---

func _on_session_started() -> void:
	print("Main: Session started")
	_enter_playing()


func _on_session_ended() -> void:
	print("Main: Session ended")
	# Force unpause if paused
	if _pause_menu and _pause_menu.is_paused():
		_pause_menu.force_unpause()

	# Clear player profession for next session
	GameState.player_profession = null
	GameState.inventory.clear()

	_enter_main_menu()


# --- Crafting UI Handler ---

func _on_crafting_ui_requested(requester) -> void:
	if requester is WorkshopAdapter and _crafting_ui:
		_crafting_ui.open(requester)
	elif not _crafting_ui:
		push_warning("Main: CraftingUI not available")
