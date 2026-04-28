extends Node
## EventHooks autoload — access via the autoload name, not class_name.
## (class_name removed to avoid shadowing the autoload singleton)

## Signal bus for mod scripts to listen to game events.
##
## Singleton pattern - accessed via EventHooks autoload.
## Mods connect to these signals to react to game events without
## modifying core game code.
##
## Usage in mod scripts:
##   func _mod_init(api: ModAPI) -> void:
##       EventHooks.game_ready.connect(_on_game_ready)
##       EventHooks.craft_completed.connect(_on_craft_completed)
##
## NOTE: Signals are emitted by game systems and consumed by mods.
## @warning_ignore is used because signals are intentionally not emitted
## within this class - other systems emit to this signal bus.

# --- Lifecycle Events ---

## Emitted when the game is fully initialized and ready.
@warning_ignore("unused_signal")
signal game_ready()

## Emitted when the game is paused.
@warning_ignore("unused_signal")
signal game_paused()

## Emitted when the game is resumed from pause.
@warning_ignore("unused_signal")
signal game_resumed()

## Emitted when the game is about to exit.
signal game_exiting()


# --- Content Events ---

## Emitted when a new item is registered (by base game or mod).
@warning_ignore("unused_signal")
signal item_registered(item_id: String, mod_id: String)

## Emitted when a new recipe is registered (by base game or mod).
@warning_ignore("unused_signal")
signal recipe_registered(recipe_id: String, mod_id: String)

## Emitted when a batch of content finishes loading.
@warning_ignore("unused_signal")
signal content_loaded(content_type: String, count: int)


# --- Train Events ---

## Emitted when a player enters a train car.
@warning_ignore("unused_signal")
signal train_car_entered(car_id: String, player_id: int)

## Emitted when a player exits a train car.
@warning_ignore("unused_signal")
signal train_car_exited(car_id: String, player_id: int)

## Emitted when a train car subsystem changes state.
@warning_ignore("unused_signal")
signal subsystem_state_changed(car_id: String, subsystem: String, new_state: int)


# --- Expedition Events ---

## Emitted when an expedition starts at a location.
@warning_ignore("unused_signal")
signal expedition_started(location_id: String)

## Emitted when an expedition ends.
@warning_ignore("unused_signal")
signal expedition_ended(location_id: String, success: bool)

## Emitted when escalation level changes.
@warning_ignore("unused_signal")
signal escalation_changed(old_level: int, new_level: int)


# --- Crafting Events ---

## Emitted when crafting begins for a recipe.
@warning_ignore("unused_signal")
signal craft_started(recipe_id: String, station_id: String)

## Emitted when crafting completes successfully.
@warning_ignore("unused_signal")
signal craft_completed(recipe_id: String, station_id: String, item_id: String)

## Emitted when crafting fails.
@warning_ignore("unused_signal")
signal craft_failed(recipe_id: String, reason: String)


# --- Player Events ---

## Emitted when a player joins the game.
@warning_ignore("unused_signal")
signal player_joined(player_id: int, profession: String)

## Emitted when a player leaves the game.
@warning_ignore("unused_signal")
signal player_left(player_id: int)

## Emitted when a player's inventory changes.
@warning_ignore("unused_signal")
signal player_inventory_changed(player_id: int, item_id: String, delta: int)


# --- Mod Lifecycle Events ---

## Emitted when a mod begins loading.
@warning_ignore("unused_signal")
signal mod_loading(mod_id: String)

## Emitted when a mod finishes loading successfully.
@warning_ignore("unused_signal")
signal mod_loaded(mod_id: String)

## Emitted when a mod is unloaded.
@warning_ignore("unused_signal")
signal mod_unloaded(mod_id: String)


func _ready() -> void:
	print("[EventHooks] Signal bus initialized")


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		game_exiting.emit()
