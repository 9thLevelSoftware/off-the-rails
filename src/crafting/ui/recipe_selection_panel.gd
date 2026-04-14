class_name RecipeSelectionPanel
extends PanelContainer

## UI panel for selecting recipes to craft.
## Displays available recipes with filtering and details.
## Emits signals for recipe selection and craft requests.

## Emitted when a recipe is selected in the list
signal recipe_selected(recipe: RecipeData)

## Emitted when the craft button is pressed
signal craft_requested(recipe: RecipeData)

## Emitted when the panel should close
signal panel_closed()

## UI References
@onready var title_label: Label = $VBox/TitleLabel
@onready var category_filter: OptionButton = $VBox/FilterRow/CategoryFilter
@onready var recipe_list: ItemList = $VBox/ContentHBox/RecipeList
@onready var details_panel: PanelContainer = $VBox/ContentHBox/DetailsPanel
@onready var details_name: Label = $VBox/ContentHBox/DetailsPanel/DetailsVBox/RecipeName
@onready var details_description: RichTextLabel = $VBox/ContentHBox/DetailsPanel/DetailsVBox/Description
@onready var inputs_container: VBoxContainer = $VBox/ContentHBox/DetailsPanel/DetailsVBox/InputsContainer
@onready var outputs_container: VBoxContainer = $VBox/ContentHBox/DetailsPanel/DetailsVBox/OutputsContainer
@onready var time_label: Label = $VBox/ContentHBox/DetailsPanel/DetailsVBox/TimeLabel
@onready var craft_button: Button = $VBox/ContentHBox/DetailsPanel/DetailsVBox/CraftButton
@onready var close_button: Button = $VBox/CloseButton

## Currently displayed recipes
var _recipes: Array[RecipeData] = []

## Currently selected recipe
var _selected_recipe: RecipeData = null

## Inventory repository for resource checks
var _inventory: InventoryRepository = null

## All categories for filtering
var _categories: Array[String] = []


func _ready() -> void:
	_inventory = InventoryRepository.new()

	# Connect UI signals
	category_filter.item_selected.connect(_on_category_selected)
	recipe_list.item_selected.connect(_on_recipe_item_selected)
	craft_button.pressed.connect(_on_craft_pressed)
	close_button.pressed.connect(_on_close_pressed)

	# Initialize craft button state
	craft_button.disabled = true

	# Hide details until recipe selected
	_clear_details()


## Set the list of available recipes to display.
func set_recipes(recipes: Array[RecipeData]) -> void:
	_recipes = recipes
	_build_category_filter()
	_populate_recipe_list()


## Refresh the display with current inventory state.
func refresh() -> void:
	_populate_recipe_list()
	if _selected_recipe:
		_update_details(_selected_recipe)


## Build the category filter dropdown.
func _build_category_filter() -> void:
	_categories.clear()
	category_filter.clear()

	# Add "All" option
	category_filter.add_item("All Categories")
	_categories.append("")

	# Collect unique categories
	var seen: Array[String] = []
	for recipe in _recipes:
		if recipe.category not in seen:
			seen.append(recipe.category)

	seen.sort()

	for category in seen:
		category_filter.add_item(_format_category_name(category))
		_categories.append(category)

	category_filter.select(0)


## Populate the recipe list based on current filter.
func _populate_recipe_list() -> void:
	recipe_list.clear()

	var selected_category := _get_selected_category()

	for recipe in _recipes:
		# Filter by category
		if selected_category != "" and recipe.category != selected_category:
			continue

		# Check if craftable
		var can_craft := _can_craft_recipe(recipe)
		var item_text := recipe.name

		var idx := recipe_list.add_item(item_text)
		recipe_list.set_item_metadata(idx, recipe)

		# Dim items that cannot be crafted
		if not can_craft:
			recipe_list.set_item_custom_fg_color(idx, Color(0.5, 0.5, 0.5))


## Get the currently selected category from filter.
func _get_selected_category() -> String:
	var idx := category_filter.selected
	if idx >= 0 and idx < _categories.size():
		return _categories[idx]
	return ""


## Check if a recipe can be crafted with current resources.
func _can_craft_recipe(recipe: RecipeData) -> bool:
	var available := _inventory.get_all_resources()
	return recipe.can_craft_with(available)


## Handle category filter selection.
func _on_category_selected(_index: int) -> void:
	_populate_recipe_list()


## Handle recipe selection in list.
func _on_recipe_item_selected(index: int) -> void:
	var recipe := recipe_list.get_item_metadata(index) as RecipeData
	if recipe:
		_selected_recipe = recipe
		_update_details(recipe)
		recipe_selected.emit(recipe)


## Update the details panel for a recipe.
func _update_details(recipe: RecipeData) -> void:
	details_name.text = recipe.name
	details_description.text = recipe.description

	# Clear and populate inputs
	_clear_container(inputs_container)
	var inputs_title := Label.new()
	inputs_title.text = "Inputs:"
	inputs_title.add_theme_font_size_override("font_size", 14)
	inputs_container.add_child(inputs_title)

	var available := _inventory.get_all_resources()
	for resource_id: String in recipe.inputs:
		var needed: int = recipe.inputs[resource_id]
		var have: int = available.get(resource_id, 0)
		var label := Label.new()
		label.text = "  %s: %d/%d" % [_format_resource_name(resource_id), have, needed]
		if have < needed:
			label.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3))
		else:
			label.add_theme_color_override("font_color", Color(0.3, 0.9, 0.3))
		inputs_container.add_child(label)

	# Clear and populate outputs
	_clear_container(outputs_container)
	var outputs_title := Label.new()
	outputs_title.text = "Outputs:"
	outputs_title.add_theme_font_size_override("font_size", 14)
	outputs_container.add_child(outputs_title)

	for item_id: String in recipe.output:
		var quantity: int = recipe.output[item_id]
		var label := Label.new()
		label.text = "  %s x%d" % [_format_resource_name(item_id), quantity]
		outputs_container.add_child(label)

	# Craft time with profession bonus
	var base_time := recipe.craft_time
	var profession_id := _get_player_profession_id()
	var actual_time := recipe.get_craft_time_for_profession(profession_id)

	if actual_time < base_time:
		time_label.text = "Craft Time: %s (-%d%% profession bonus)" % [_format_time(actual_time), 25]
	else:
		time_label.text = "Craft Time: %s" % _format_time(actual_time)

	# Update craft button state
	var can_craft := _can_craft_recipe(recipe)
	craft_button.disabled = not can_craft
	if can_craft:
		craft_button.text = "Craft"
	else:
		craft_button.text = "Missing Resources"


## Clear the details panel.
func _clear_details() -> void:
	details_name.text = "Select a Recipe"
	details_description.text = ""
	_clear_container(inputs_container)
	_clear_container(outputs_container)
	time_label.text = ""
	craft_button.disabled = true
	craft_button.text = "Craft"


## Clear all children from a container.
func _clear_container(container: Container) -> void:
	for child in container.get_children():
		child.queue_free()


## Format a category name for display.
func _format_category_name(category: String) -> String:
	return category.capitalize().replace("_", " ")


## Format a resource/item ID for display.
func _format_resource_name(resource_id: String) -> String:
	return resource_id.capitalize().replace("_", " ")


## Format seconds to human-readable time.
@warning_ignore("integer_division")
func _format_time(seconds: int) -> String:
	if seconds < 60:
		return "%ds" % seconds
	var minutes := seconds / 60
	var remaining_seconds := seconds % 60
	if remaining_seconds == 0:
		return "%dm" % minutes
	return "%dm %ds" % [minutes, remaining_seconds]


## Get player profession ID.
func _get_player_profession_id() -> String:
	if GameState.player_profession:
		return GameState.player_profession.id
	return ""


## Handle craft button press.
func _on_craft_pressed() -> void:
	if _selected_recipe:
		craft_requested.emit(_selected_recipe)


## Handle close button press.
func _on_close_pressed() -> void:
	panel_closed.emit()


func _exit_tree() -> void:
	# Disconnect UI signals (good practice even for child nodes)
	if category_filter and category_filter.item_selected.is_connected(_on_category_selected):
		category_filter.item_selected.disconnect(_on_category_selected)
	if recipe_list and recipe_list.item_selected.is_connected(_on_recipe_item_selected):
		recipe_list.item_selected.disconnect(_on_recipe_item_selected)
	if craft_button and craft_button.pressed.is_connected(_on_craft_pressed):
		craft_button.pressed.disconnect(_on_craft_pressed)
	if close_button and close_button.pressed.is_connected(_on_close_pressed):
		close_button.pressed.disconnect(_on_close_pressed)
