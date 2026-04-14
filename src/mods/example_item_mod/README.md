# Example Item Mod

A demonstration mod for Off The Rails showing how to add custom items and recipes.

## Installation

1. Copy the entire `example_item_mod` folder to your mods directory:
   - **Windows**: `%APPDATA%\Godot\app_userdata\Off The Rails\mods\`
   - **Linux**: `~/.local/share/godot/app_userdata/Off The Rails/mods/`
   - **macOS**: `~/Library/Application Support/Godot/app_userdata/Off The Rails/mods/`

2. Restart the game. The mod will be automatically discovered and loaded.

## Contents

### Items Added

| ID | Name | Description |
|----|------|-------------|
| `quantum_capacitor` | Quantum Capacitor | Advanced energy storage component |
| `nano_repair_gel` | Nano Repair Gel | Self-replicating repair nanobots |
| `salvaged_ai_core` | Salvaged AI Core | Damaged AI core with useful data |
| `debug_tool` | Debug Tool | Developer testing tool (added via script) |

### Recipes Added

| ID | Name | Station | Inputs |
|----|------|---------|--------|
| `advanced_repair_kit` | Advanced Repair Kit | Workbench | 5x Scrap Metal, 1x Quantum Capacitor, 1x Nano Repair Gel |

## Structure

```
example_item_mod/
  mod.json           # Mod manifest (required)
  data/
    items.json       # Item definitions
    recipes.json     # Recipe definitions
  scripts/
    on_init.gd       # Initialization script
  README.md          # This file
```

## Using This as a Template

1. Copy this folder and rename it to your mod's ID
2. Edit `mod.json` with your mod's details
3. Replace the content in `data/` with your own items and recipes
4. Modify `scripts/on_init.gd` for custom initialization logic

## Notes

- All item IDs are automatically prefixed with your mod ID (e.g., `quantum_capacitor` becomes `example_item_mod:quantum_capacitor`)
- This prevents naming conflicts between mods
- Use the full prefixed ID when referencing items from other mods
