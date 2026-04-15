# Phase 6: V1 Logic Port — Context

## Phase Goal

Port proven V1 architecture patterns to work with the V2 isometric foundation. The V1 code (GameState, crafting domain, signal architecture) already exists in the codebase but references 3D types and scenes. This phase adapts it for isometric (2D) and wires it with the V2 mod architecture from Phase 5.

## Requirements Covered

| ID | Description | Status |
|----|-------------|--------|
| R11 | Port GameState autoload (adapt for isometric) | Pending |
| R12 | Port crafting domain logic (perspective-agnostic) | Already present — verify integration |
| R13 | Port data pipeline (YAML → .tres) | Superseded by JSON → ContentRegistry (Phase 5) |
| R14 | Port signal architecture patterns | Already present — wire to isometric systems |

## Key Discovery: V1 Code Already in V2 Codebase

During planning analysis, we discovered:

1. **Crafting domain** (`src/crafting/domain/`) — Pure RefCounted objects (CraftJob, CraftQueue, RecipeValidator) with no Node dependencies. Already perspective-agnostic.

2. **GameState** (`src/autoloads/game_state.gd`) — Fully implemented with inventory, session management, scene transitions, signals. BUT references `CharacterBody3D` and 3D scene paths.

3. **Data pipeline** — Phase 5 implemented `ContentRegistry` + `DataLoader` using JSON, replacing the original YAML → .tres concept. Already functional.

4. **Signal architecture** — `CraftingEventBus` singleton exists. GameState emits signals for session/location/inventory changes.

## What This Phase Actually Does

**Adaptation, not porting.** The code exists; it needs to work with V2 systems:

1. **Adapt GameState** — Change `CharacterBody3D` → `CharacterBody2D`, update scene paths for isometric
2. **Wire ContentRegistry** — Connect GameState inventory to Phase 5 registries for item validation
3. **Verify crafting flow** — Ensure crafting domain works through isometric interaction system
4. **Test integration** — Validate signals propagate correctly across all connected systems

## Existing Assets

### V2 Isometric Foundation (Phases 1-4)
- `src/isometric/adapters/player_controller.gd` — CharacterBody2D player
- `src/isometric/scenes/isometric_level.gd` — Level management
- `src/interaction/adapters/isometric_interaction_controller.gd` — Interaction system
- `src/train/cars/workshop/adapters/equipment_interactable.gd` — Workbench interaction

### V2 Mod Architecture (Phase 5)
- `src/data/content_registry.gd` — Single source of truth for all game content
- `src/data/data_loader.gd` — JSON file loading
- `src/data/registries/` — ItemRegistry, RecipeRegistry, ProfessionRegistry, TrainCarRegistry
- `src/mod_system/mod_loader.gd` — Mod discovery and loading

### V1 Logic (to adapt)
- `src/autoloads/game_state.gd` — Session, inventory, scene transitions (3D references)
- `src/crafting/domain/` — CraftJob, CraftQueue, RecipeValidator (already agnostic)
- `src/crafting/infrastructure/crafting_event_bus.gd` — Signal routing

## Key Design Decisions

| Decision | Rationale |
|----------|-----------|
| Keep existing GameState structure | Architecture is sound; only types need updating |
| Use ContentRegistry as item source | Consistent with Phase 5 mod architecture |
| Preserve signal patterns | V1 signals worked well; just wire to new systems |
| Test through interaction system | Verifies complete integration chain |

## Plan Structure

| Plan | Wave | Focus |
|------|------|-------|
| 06-01 | 1 | Adapt GameState for Isometric |
| 06-02 | 2 | Wire V1 Logic with V2 Systems |
| 06-03 | 3 | Integration Testing & Signal Verification |

## Dependencies

- Phase 4 (Interaction System) — Provides equipment_interactable for crafting entry point
- Phase 5 (Mod Architecture) — Provides ContentRegistry for item/recipe data

## Constraints

- GameState must remain an autoload (singleton pattern)
- Inventory API must preserve backward compatibility (existing crafting code uses it)
- No changes to crafting domain logic — only infrastructure/adapter wiring
- All changes must be testable via Godot scene execution
