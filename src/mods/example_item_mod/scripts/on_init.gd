extends RefCounted

## Example mod initialization script
##
## This script demonstrates how to:
## - Register content via the ModAPI
## - Connect to EventHooks signals
## - Log mod activity


func _mod_init(api: ModAPI) -> void:
	print("[ExampleItemMod] Initializing...")

	# Register an item via script (in addition to items.json)
	var scripted_item := {
		"id": "debug_tool",
		"name": "Debug Tool",
		"description": "A developer tool for testing. Added via script.",
		"category": "tool",
		"stack_size": 1
	}

	if api.register_item(scripted_item):
		print("[ExampleItemMod] Registered debug_tool via script")

	# Connect to game events
	EventHooks.game_ready.connect(_on_game_ready)
	EventHooks.craft_completed.connect(_on_craft_completed)

	print("[ExampleItemMod] Initialization complete!")


func _on_game_ready() -> void:
	print("[ExampleItemMod] Game is ready!")


func _on_craft_completed(recipe_id: String, station_id: String, item_id: String) -> void:
	if "example_item_mod" in recipe_id:
		print("[ExampleItemMod] Player crafted our item: %s" % item_id)
