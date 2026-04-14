# Mod API Reference

This document provides a complete reference for the Off The Rails modding API.

## Overview

The mod system provides three main interfaces for mod authors:

1. **mod.json** - Manifest file declaring mod metadata and content
2. **ModAPI** - Typed API for registering content from scripts
3. **EventHooks** - Signal bus for reacting to game events

## mod.json Schema

Every mod must have a `mod.json` file in its root directory.

### Required Fields

| Field | Type | Description |
|-------|------|-------------|
| `id` | String | Unique identifier. Must start with a lowercase letter and contain only lowercase letters, numbers, and underscores. Pattern: `^[a-z][a-z0-9_]*$` |
| `version` | String | Semantic version. Pattern: `X.Y.Z` (e.g., `1.0.0`, `2.1.3`) |
| `name` | String | Human-readable display name |

### Optional Fields

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `description` | String | `""` | Mod description shown in mod manager |
| `author` | String | `""` | Author name or team |
| `dependencies` | Array[String] | `[]` | List of required mod IDs that must load first |
| `content_files` | Array[String] | `[]` | Relative paths to JSON data files to load |
| `scripts` | Array[String] | `[]` | Relative paths to GDScript files to execute |

### Example mod.json

```json
{
  "id": "my_awesome_mod",
  "version": "1.0.0",
  "name": "My Awesome Mod",
  "description": "Adds awesome new content to the game.",
  "author": "Your Name",
  "dependencies": [],
  "content_files": [
    "data/items.json",
    "data/recipes.json"
  ],
  "scripts": [
    "scripts/on_init.gd"
  ]
}
```

### Path Security

- Paths must be relative (no leading `/` or `\`)
- Path traversal (`..`) is not allowed
- Script files must have `.gd` extension

---

## ModAPI

The `ModAPI` class provides methods for registering and querying game content from mod scripts.

### Accessing ModAPI

ModAPI is passed to your script's `_mod_init` function:

```gdscript
extends RefCounted

func _mod_init(api: ModAPI) -> void:
    # Use api here
    pass
```

### Content Registration Methods

All registration methods automatically prefix IDs with your mod's ID to prevent collisions. For example, if your mod ID is `my_mod` and you register an item with ID `sword`, the final ID will be `my_mod:sword`.

#### register_item

```gdscript
func register_item(item_data: Dictionary) -> bool
```

Register a new item. Returns `true` on success, `false` on validation failure.

**Required Fields:**

| Field | Type | Description |
|-------|------|-------------|
| `id` | String | Item identifier (will be prefixed with mod ID) |

**Optional Fields:**

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `name` | String | Same as `id` | Display name |
| `description` | String | `""` | Item description |
| `category` | String | `"common"` | Category: `common`, `structured`, `milestone`, `crafted` |
| `type` | String | `"material"` | Type: `material`, `component`, `consumable`, `key_item`, `data`, `ammo`, `equipment`, `tool` |
| `rarity` | String | `"common"` | Rarity: `common`, `uncommon`, `rare`, `very_rare`, `unique` |
| `weight` | float | `1.0` | Weight per unit |
| `stack_size` | int | `10` | Maximum stack size |
| `sources` | Array | `[]` | Where the item can be found |
| `used_for` | Array | `[]` | What the item is used for |

**Example:**

```gdscript
func _mod_init(api: ModAPI) -> void:
    var my_item := {
        "id": "energy_cell",
        "name": "Energy Cell",
        "description": "A compact power source.",
        "category": "common",
        "type": "component",
        "stack_size": 20
    }
    api.register_item(my_item)
```

#### register_recipe

```gdscript
func register_recipe(recipe_data: Dictionary) -> bool
```

Register a new crafting recipe. Returns `true` on success.

**Required Fields:**

| Field | Type | Description |
|-------|------|-------------|
| `id` | String | Recipe identifier (will be prefixed with mod ID) |

**Optional Fields:**

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `name` | String | Same as `id` | Display name |
| `description` | String | `""` | Recipe description |
| `category` | String | `"consumable"` | Category: `consumable`, `ammo`, `medical`, `repair`, `tool`, `equipment`, `train_part`, `specialty`, `conversion` |
| `station` | String | `"workshop"` | Crafting station: `field`, `workshop`, `armory`, `infirmary`, `refinery`, `greenhouse`, `lab` |
| `inputs` | Array or Dict | `{}` | Input requirements (see below) |
| `output` | Dict | `{}` | Output item and quantity |
| `craft_time` | int | `60` | Base crafting time in seconds |
| `unlock` | String | `"default"` | Unlock requirement: `default`, `schematic_common`, `schematic_advanced`, `upgrade_t2`, `upgrade_t3`, `upgrade_t4`, `research` |
| `profession_bonus` | String | `""` | Profession that gets -25% craft time |

**Input Formats:**

Array format (recommended):
```json
"inputs": [
  {"item_id": "scrap_metal", "quantity": 5},
  {"item_id": "wire", "quantity": 2}
]
```

Dictionary format:
```json
"inputs": {"scrap_metal": 5, "wire": 2}
```

**Example:**

```gdscript
func _mod_init(api: ModAPI) -> void:
    var my_recipe := {
        "id": "custom_tool",
        "name": "Custom Tool",
        "station": "workshop",
        "inputs": [
            {"item_id": "scrap_metal", "quantity": 3},
            {"item_id": "my_mod:energy_cell", "quantity": 1}
        ],
        "output": {"item_id": "my_mod:custom_tool", "quantity": 1},
        "craft_time": 30
    }
    api.register_recipe(my_recipe)
```

#### register_profession

```gdscript
func register_profession(profession_data: Dictionary) -> bool
```

Register a new profession. Returns `true` on success.

**Required Fields:**

| Field | Type | Description |
|-------|------|-------------|
| `id` | String | Profession identifier |

**Optional Fields:**

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `name` | String | Same as `id` | Display name |
| `description` | String | `""` | Profession description |
| `primary_car` | String | `""` | Primary train car |
| `field_role` | String | `""` | Role during expeditions |
| `priority` | int | `3` | AI priority (1-5) |
| `secondary_cars` | Array | `[]` | Secondary train cars |
| `synergies` | Array | `[]` | Synergy professions |
| `passive_bonuses` | Array | `[]` | Passive bonus descriptions |
| `active_abilities` | Array | `[]` | Active ability definitions |

#### register_train_car

```gdscript
func register_train_car(car_data: Dictionary) -> bool
```

Register a new train car type. Returns `true` on success.

**Required Fields:**

| Field | Type | Description |
|-------|------|-------------|
| `id` | String | Train car identifier |

**Optional Fields:**

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `name` | String | Same as `id` | Display name |
| `description` | String | `""` | Train car description |
| `type` | String | `"car"` | Car type |
| `category` | String | `"utility"` | Car category |
| `acquisition` | String | `"starting"` | How to acquire |
| `crew_station` | bool | `false` | Has crew station |
| `upgrade_tree` | String | `""` | Upgrade tree reference |
| `damage_effect` | String | `""` | Effect when damaged |
| `subsystems` | Array | `[]` | Subsystem names |
| `dependencies` | Array | `[]` | Required dependencies |

### Query Methods

All query methods return copies (Dictionaries), not references to internal data.

| Method | Returns | Description |
|--------|---------|-------------|
| `get_item(id: String)` | Dictionary | Get item data by ID (empty if not found) |
| `get_all_item_ids()` | Array[String] | Get all registered item IDs |
| `item_exists(id: String)` | bool | Check if item exists |
| `get_recipe(id: String)` | Dictionary | Get recipe data by ID |
| `get_all_recipe_ids()` | Array[String] | Get all registered recipe IDs |
| `recipe_exists(id: String)` | bool | Check if recipe exists |
| `get_profession(id: String)` | Dictionary | Get profession data by ID |
| `get_all_profession_ids()` | Array[String] | Get all registered profession IDs |
| `profession_exists(id: String)` | bool | Check if profession exists |
| `get_train_car(id: String)` | Dictionary | Get train car data by ID |
| `get_all_train_car_ids()` | Array[String] | Get all registered train car IDs |
| `train_car_exists(id: String)` | bool | Check if train car exists |
| `get_content_summary()` | Dictionary | Get summary of all registered content |
| `get_current_mod()` | String | Get the current mod ID context |

**Example:**

```gdscript
func _mod_init(api: ModAPI) -> void:
    # Check if a base game item exists
    if api.item_exists("scrap_metal"):
        var scrap := api.get_item("scrap_metal")
        print("Scrap metal weight: %s" % scrap.get("weight", 1.0))
    
    # Get all items
    var all_items := api.get_all_item_ids()
    print("Total items: %d" % all_items.size())
```

### Signals

| Signal | Parameters | Description |
|--------|------------|-------------|
| `content_registered` | `mod_id: String, content_type: String, content_id: String` | Emitted when content is registered |
| `script_executed` | `mod_id: String, script_path: String` | Emitted when a mod script runs |

---

## EventHooks

The `EventHooks` autoload provides signals that mods can connect to for reacting to game events.

### Accessing EventHooks

EventHooks is a global autoload accessible from any script:

```gdscript
func _mod_init(api: ModAPI) -> void:
    EventHooks.game_ready.connect(_on_game_ready)
    EventHooks.craft_completed.connect(_on_craft_completed)

func _on_game_ready() -> void:
    print("Game is ready!")

func _on_craft_completed(recipe_id: String, station_id: String, item_id: String) -> void:
    print("Crafted: %s" % item_id)
```

### Lifecycle Events

| Signal | Parameters | Description |
|--------|------------|-------------|
| `game_ready` | None | Game is fully initialized |
| `game_paused` | None | Game is paused |
| `game_resumed` | None | Game resumed from pause |
| `game_exiting` | None | Game is about to exit |

### Content Events

| Signal | Parameters | Description |
|--------|------------|-------------|
| `item_registered` | `item_id: String, mod_id: String` | New item registered |
| `recipe_registered` | `recipe_id: String, mod_id: String` | New recipe registered |
| `content_loaded` | `content_type: String, count: int` | Batch content finished loading |

### Train Events

| Signal | Parameters | Description |
|--------|------------|-------------|
| `train_car_entered` | `car_id: String, player_id: int` | Player entered train car |
| `train_car_exited` | `car_id: String, player_id: int` | Player exited train car |
| `subsystem_state_changed` | `car_id: String, subsystem: String, new_state: int` | Subsystem state changed |

### Expedition Events

| Signal | Parameters | Description |
|--------|------------|-------------|
| `expedition_started` | `location_id: String` | Expedition started |
| `expedition_ended` | `location_id: String, success: bool` | Expedition ended |
| `escalation_changed` | `old_level: int, new_level: int` | Escalation level changed |

### Crafting Events

| Signal | Parameters | Description |
|--------|------------|-------------|
| `craft_started` | `recipe_id: String, station_id: String` | Crafting began |
| `craft_completed` | `recipe_id: String, station_id: String, item_id: String` | Crafting completed |
| `craft_failed` | `recipe_id: String, reason: String` | Crafting failed |

### Player Events

| Signal | Parameters | Description |
|--------|------------|-------------|
| `player_joined` | `player_id: int, profession: String` | Player joined game |
| `player_left` | `player_id: int` | Player left game |
| `player_inventory_changed` | `player_id: int, item_id: String, delta: int` | Inventory changed |

### Mod Lifecycle Events

| Signal | Parameters | Description |
|--------|------------|-------------|
| `mod_loading` | `mod_id: String` | Mod is being loaded |
| `mod_loaded` | `mod_id: String` | Mod finished loading |
| `mod_unloaded` | `mod_id: String` | Mod was unloaded |

---

## Data File Formats

Content can be defined in JSON files listed in `content_files`.

### items.json

```json
{
  "items": [
    {
      "id": "my_item",
      "name": "My Item",
      "description": "A custom item.",
      "category": "common",
      "type": "material",
      "rarity": "common",
      "weight": 1.0,
      "stack_size": 10,
      "sources": ["expedition", "crafting"],
      "used_for": ["crafting", "upgrades"]
    }
  ]
}
```

### recipes.json

```json
{
  "recipes": [
    {
      "id": "my_recipe",
      "name": "My Recipe",
      "description": "Crafts a custom item.",
      "category": "consumable",
      "station": "workshop",
      "inputs": [
        {"item_id": "scrap_metal", "quantity": 5},
        {"item_id": "wire", "quantity": 2}
      ],
      "output": {"item_id": "my_item", "quantity": 1},
      "craft_time": 60,
      "unlock": "default",
      "profession_bonus": "engineer"
    }
  ]
}
```

---

## Best Practices

### ID Prefixing

- All IDs are automatically prefixed with your mod ID (e.g., `my_mod:my_item`)
- When referencing your own mod's items in recipes, use the prefixed form
- Base game items do not have a prefix (e.g., `scrap_metal`)

### Error Handling

- Always check return values from registration methods
- Use `push_warning()` or `print()` for debugging
- The mod system gracefully handles errors and won't crash on malformed content

```gdscript
func _mod_init(api: ModAPI) -> void:
    if not api.register_item(my_item):
        push_warning("[MyMod] Failed to register item")
```

### Signal Cleanup

- Connections made in `_mod_init` persist for the game session
- If you need cleanup, connect to `EventHooks.game_exiting`

```gdscript
var _api: ModAPI

func _mod_init(api: ModAPI) -> void:
    _api = api
    EventHooks.game_exiting.connect(_on_game_exit)

func _on_game_exit() -> void:
    print("[MyMod] Cleaning up...")
```

### Dependencies

- List required mods in `dependencies` to ensure load order
- Missing dependencies will prevent your mod from loading
- Circular dependencies are detected and reported as errors

### Testing

1. Copy your mod to `user://mods/`
2. Launch the game and check console output
3. Look for `[ModLoader]` messages confirming load
4. Use the debug console to verify content registration

---

## Error Types

The mod system reports these error types:

| Error Type | Description |
|------------|-------------|
| `MANIFEST_NOT_FOUND` | No mod.json in directory |
| `MANIFEST_PARSE_FAILED` | Invalid JSON syntax |
| `MANIFEST_INVALID` | Schema validation failed |
| `DEPENDENCY_MISSING` | Required mod not found |
| `CONTENT_LOAD_FAILED` | Content file not found or invalid |
| `SCRIPT_LOAD_FAILED` | Script file not found |
| `SCRIPT_INVALID` | Script is not valid GDScript |
| `SCRIPT_EXECUTION_ERROR` | Script threw an error |

Errors are logged to the console with `[ModLoader]` prefix and stored in the ModErrorHandler for programmatic access.
