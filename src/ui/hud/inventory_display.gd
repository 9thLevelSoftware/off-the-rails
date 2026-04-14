class_name InventoryDisplayUI
extends Control

## Displays key resource counts in the HUD.
## Shows tracked resources as a horizontal row at the bottom of the screen.
## Connects to GameState.inventory_changed for real-time updates.

# --- Tracked resources for V1 ---
const TRACKED_RESOURCES: Array[String] = [
	"scrap_metal",
	"wire",
	"electronic_components",
	"repair_kit"
]

# --- Resource display colors (placeholder icons) ---
const RESOURCE_COLORS: Dictionary = {
	"scrap_metal": Color(0.6, 0.6, 0.6),           # Gray
	"wire": Color(0.8, 0.5, 0.2),                  # Copper/orange
	"electronic_components": Color(0.2, 0.6, 0.9), # Blue
	"repair_kit": Color(0.2, 0.8, 0.4)             # Green
}

# --- Node references ---
@onready var resource_container: HBoxContainer = $PanelContainer/HBoxContainer

# --- State ---
var _resource_labels: Dictionary = {}  # {item_id: Label}


func _ready() -> void:
	_create_resource_displays()


## Creates visual displays for each tracked resource.
func _create_resource_displays() -> void:
	for item_id in TRACKED_RESOURCES:
		var item_container := _create_resource_item(item_id)
		resource_container.add_child(item_container)


## Creates a single resource item display.
func _create_resource_item(item_id: String) -> Control:
	var container := HBoxContainer.new()
	container.add_theme_constant_override("separation", 4)

	# Placeholder colored rectangle as icon
	var icon := ColorRect.new()
	icon.custom_minimum_size = Vector2(20, 20)
	icon.color = RESOURCE_COLORS.get(item_id, Color.WHITE)
	container.add_child(icon)

	# Resource count label
	var label := Label.new()
	label.text = "0"
	label.add_theme_font_size_override("font_size", 16)
	container.add_child(label)

	# Store reference for updates
	_resource_labels[item_id] = label

	# Add separator between items
	var separator := Control.new()
	separator.custom_minimum_size = Vector2(16, 0)
	container.add_child(separator)

	return container


## Initializes display with current inventory state.
func initialize(inventory: Dictionary) -> void:
	for item_id in TRACKED_RESOURCES:
		var quantity: int = inventory.get(item_id, 0)
		update_item(item_id, quantity)


## Updates the display for a specific item.
func update_item(item_id: String, quantity: int) -> void:
	if item_id not in TRACKED_RESOURCES:
		return

	var label: Label = _resource_labels.get(item_id)
	if label:
		label.text = str(quantity)
