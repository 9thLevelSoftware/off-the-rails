## Main Scene Controller
## Manages additive scene loading for Train and Expedition scenes.
## Uses SceneContainer node for dynamically loaded child scenes.
extends Node

# --- Constants ---
const TRAIN_SCENE_PATH: String = "res://src/train/train.tscn"
const EXPEDITION_SCENE_PATH: String = "res://src/expedition/expedition.tscn"

# --- Node References ---
@onready var scene_container: Node = $SceneContainer
@onready var ui_layer: CanvasLayer = $UILayer

# --- State ---
var _train_instance: Node = null
var _expedition_instance: Node = null

# --- Lifecycle ---

func _ready() -> void:
	print("Main: Scene initialized")


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
