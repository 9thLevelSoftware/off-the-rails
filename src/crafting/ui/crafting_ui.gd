class_name CraftingUI
extends CanvasLayer

## Main crafting UI container.
## Combines RecipeSelectionPanel and QueueDisplay.
## Manages UI visibility and signal routing.

## Emitted when the UI is closed
signal ui_closed()

## UI References
@onready var dim_background: ColorRect = $DimBackground
@onready var recipe_panel: RecipeSelectionPanel = $CenterContainer/MainPanel/HSplit/RecipeSelectionPanel
@onready var queue_display: QueueDisplay = $CenterContainer/MainPanel/HSplit/QueueDisplay

## Workshop adapter reference (set by parent)
var _adapter: WorkshopAdapter = null


func _ready() -> void:
	# Connect recipe panel signals
	recipe_panel.craft_requested.connect(_on_craft_requested)
	recipe_panel.panel_closed.connect(_on_panel_closed)

	# Connect queue display signals
	queue_display.cancel_requested.connect(_on_cancel_requested)

	# Connect dim background click to close
	dim_background.gui_input.connect(_on_background_input)

	# Hide by default
	visible = false


## Open the crafting UI with the given adapter.
func open(adapter: WorkshopAdapter) -> void:
	_adapter = adapter

	# Load recipes into panel
	var recipes := adapter.get_available_recipes()
	recipe_panel.set_recipes(recipes)

	# Sync queue display with current queue state
	queue_display.sync_with_queue(adapter.get_queue())

	# Show UI
	visible = true

	# Pause game input (optional - depends on game design)
	# get_tree().paused = true


## Close the crafting UI.
func close() -> void:
	visible = false
	_adapter = null
	ui_closed.emit()

	# Resume game input
	# get_tree().paused = false


## Handle craft request from recipe panel.
func _on_craft_requested(recipe: RecipeData) -> void:
	if _adapter == null:
		push_warning("CraftingUI: No adapter set")
		return

	var result := _adapter.enqueue_recipe(recipe)

	if result.success:
		print("[CraftingUI] Enqueued recipe: %s" % recipe.name)
		# Refresh panels to show updated state
		recipe_panel.refresh()
	else:
		print("[CraftingUI] Failed to enqueue recipe: %s" % result.error)
		# Could show error dialog here


## Handle cancel request from queue display.
func _on_cancel_requested(job_id: int) -> void:
	if _adapter == null:
		return

	var result := _adapter.cancel_job(job_id)

	if result.success:
		print("[CraftingUI] Cancelled job: %d" % job_id)
		# Refresh recipe panel (resources refunded)
		recipe_panel.refresh()
	else:
		print("[CraftingUI] Failed to cancel job: %s" % result.error)


## Handle panel close signal.
func _on_panel_closed() -> void:
	close()


## Handle background click to close.
func _on_background_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			close()


## Handle escape key to close.
func _input(event: InputEvent) -> void:
	if not visible:
		return

	if event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()
