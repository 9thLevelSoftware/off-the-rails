class_name WorkshopInteractable
extends Interactable

## Interactable component for opening the Workshop crafting UI.
## Attach as child of WorkshopCar to enable player interaction.

## Path to the crafting UI scene
const CRAFTING_UI_SCENE := "res://src/crafting/ui/crafting_ui.tscn"

## Reference to the workshop adapter
var _adapter: WorkshopAdapter = null

## Active crafting UI instance
var _crafting_ui: CraftingUI = null


func _ready() -> void:
	interaction_prompt = "Press E to use Workshop"


## Set the workshop adapter reference.
func set_adapter(adapter: WorkshopAdapter) -> void:
	_adapter = adapter


## Override interaction to open crafting UI.
func _on_interact(interactor: Node) -> void:
	if _adapter == null:
		push_warning("WorkshopInteractable: No adapter set")
		return

	if not _adapter.is_ready_for_crafting():
		print("[WorkshopInteractable] Fabricator not ready")
		# Could show "Workshop offline" message
		return

	_open_crafting_ui(interactor)


## Open the crafting UI.
func _open_crafting_ui(_interactor: Node) -> void:
	if _crafting_ui != null and is_instance_valid(_crafting_ui):
		# UI already open
		return

	var ui_scene := load(CRAFTING_UI_SCENE) as PackedScene
	if ui_scene == null:
		push_error("WorkshopInteractable: Failed to load crafting UI scene")
		return

	_crafting_ui = ui_scene.instantiate() as CraftingUI
	get_tree().root.add_child(_crafting_ui)

	_crafting_ui.ui_closed.connect(_on_ui_closed)
	_crafting_ui.open(_adapter)

	print("[WorkshopInteractable] Crafting UI opened")


## Handle UI closed signal.
func _on_ui_closed() -> void:
	if _crafting_ui and is_instance_valid(_crafting_ui):
		_crafting_ui.queue_free()
		_crafting_ui = null

	print("[WorkshopInteractable] Crafting UI closed")


func _exit_tree() -> void:
	# Clean up UI if still open
	if _crafting_ui and is_instance_valid(_crafting_ui):
		_crafting_ui.queue_free()
		_crafting_ui = null
