# Phase 7: Integration — Context

## Phase Goal

Wire all systems into a playable prototype. Connect the isometric foundation (Phases 1-4), mod architecture (Phase 5), and V1 logic port (Phase 6) into a functional gameplay loop where players can walk around the Workshop, interact with the workbench to open crafting, and see mod content loaded.

## Requirements Covered

| ID | Description | Status |
|----|-------------|--------|
| All V2 | All V2 requirements verified together | Pending |

## Success Criteria

- [ ] Player can walk around Workshop car
- [ ] Player can interact with workbench (opens crafting)
- [ ] Crafting queue functional
- [ ] At least one mod loads and adds content
- [ ] No critical bugs in prototype loop
- [ ] Foundation ready for content expansion (V2.1)

## Existing Assets

### Isometric Foundation (Phases 1-4)
- `src/isometric/adapters/player_controller.gd` — CharacterBody2D player with isometric movement
- `src/isometric/adapters/camera_2d_controller.gd` — Camera following player
- `src/train/cars/workshop/scenes/workshop.tscn` — Isometric workshop scene with tilemap
- `src/interaction/adapters/isometric_interaction_controller.gd` — Proximity-based interaction
- `src/train/cars/workshop/adapters/equipment_interactable.gd` — Workbench interaction component

### Mod Architecture (Phase 5)
- `src/data/content_registry.gd` — Single source of truth for game content
- `src/mod_system/mod_loader.gd` — Discovers and loads mods from user://mods/
- `src/mods/example_item_mod/` — Example mod with items, recipes, and init script
- `data/base_items.json`, `data/base_recipes.json` — Base game content

### V1 Logic Port (Phase 6)
- `src/autoloads/game_state.gd` — Session management, inventory, scene transitions (adapted for 2D)
- `src/crafting/domain/` — CraftJob, CraftQueue, RecipeValidator (perspective-agnostic)
- `src/crafting/adapters/workshop_adapter.gd` — Crafting queue management with workbench wiring
- `src/crafting/infrastructure/crafting_event_bus.gd` — Signal routing including `crafting_ui_requested`
- `src/crafting/ui/crafting_ui.gd` — Crafting UI with `open(adapter)` method

### Main Scene
- `src/main.tscn` — Main scene with SceneContainer, UILayer, HUD
- `src/main.gd` — Menu flow, scene loading (currently references 3D train scene)

## Key Integration Gaps

1. **Scene Path Mismatch**: `main.gd` loads `src/train/train.tscn` (3D) but should load `src/train/cars/workshop/scenes/workshop.tscn` (2D isometric)

2. **Missing GameState Registration**: Workshop scene doesn't call `GameState.register_scene()`, so player won't spawn

3. **Missing PlayerSpawn Marker**: Workshop scene needs a Node2D named "PlayerSpawn" for player position

4. **CraftingUI Not Connected**: `CraftingEventBus.crafting_ui_requested` signal exists but nothing subscribes to show the UI

5. **WorkshopAdapter Not Wired**: `connect_to_workbench()` method exists but isn't called with the workbench reference

6. **Example Mod Location**: Example mod is in `src/mods/` but ModLoader reads from `user://mods/`

## Key Design Decisions

| Decision | Rationale |
|----------|-----------|
| Update main.gd paths | Minimal change, preserves existing menu flow |
| Workshop self-registers with GameState | Follows Phase 6 pattern, no changes to GameState needed |
| HUD manages CraftingUI connection | HUD is persistent, can observe CraftingEventBus |
| Copy example mod for testing | Preserves original, tests real mod loading path |

## Plan Structure

| Plan | Wave | Focus |
|------|------|-------|
| 07-01 | 1 | Scene Wiring & Main Loop |
| 07-02 | 2 | Crafting UI & Mod Integration |

## Dependencies

- Phase 4 (Interaction System) — Provides EquipmentInteractable for workbench
- Phase 5 (Mod Architecture) — Provides ModLoader and ContentRegistry
- Phase 6 (V1 Logic Port) — Provides GameState, CraftingEventBus, WorkshopAdapter

## Constraints

- No changes to crafting domain logic — only wiring
- Preserve existing menu flow (Main Menu → Profession Select → Gameplay)
- ModLoader reads from user://mods/, not res://
- All changes must be testable by running the game
