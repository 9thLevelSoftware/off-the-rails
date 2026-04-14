# Phase 7: Integration — Context

## Phase Goal

Connect all implemented systems into a playable loop with basic UI. Players should be able to start a game, select a profession, explore the train, embark on expeditions, craft items, use abilities, and experience the complete gameplay cycle.

## Requirements

All V1 requirements validated through integration:
- **R1**: Single-player gameplay
- **R2**: Train hub with 2-3 functional cars
- **R3**: Expedition system with escalation and extraction
- **R4**: 2-3 professions with abilities and bonuses
- **R5**: Basic crafting at workshop station

## Success Criteria

1. Complete loop: Train → Expedition → Extract → Train
2. Profession abilities work during expedition
3. Crafted items usable during expedition
4. Basic HUD (health, escalation, inventory)
5. Main menu and pause
6. No critical bugs in core loop

## Existing Assets

### From Phase 2 (Player & Movement)
- `src/player/player.gd` — CharacterBody3D with profession support
- `src/player/player.tscn` — Player scene with CameraMount
- `src/player/camera_controller.gd` — Mouse look camera

### From Phase 3 (Train Core)
- `src/train/train.gd` — Train scene with Engine + Workshop
- `src/train/train.tscn` — Additive train scene
- `src/train/train_manager.gd` — Train state management
- `src/train/interaction/interaction_controller.gd` — Interaction system
- `src/train/cars/engine.gd`, `workshop.gd` — Car implementations

### From Phase 4 (Expedition Core)
- `src/expedition/expedition.gd` — Expedition scene with exit trigger
- `src/expedition/expedition.tscn` — Additive expedition scene
- `src/expedition/escalation/escalation_manager.gd` — Escalation with 5 thresholds
- `src/expedition/enemies/enemy_spawner.gd` — Threshold-based spawner
- `src/expedition/loot/loot_container.gd` — Interactable loot

### From Phase 5 (Professions)
- `src/professions/ability_manager.gd` — Ability activation with cooldowns
- `src/professions/ability_effects.gd` — Effect handlers (stubbed for future)
- `src/professions/passive_bonus_manager.gd` — Passive bonus application
- `src/data/professions/engineer.tres`, `medic.tres` — Profession data

### From Phase 6 (Crafting)
- `src/crafting/domain/` — CraftJob, CraftQueue, RecipeValidator
- `src/crafting/infrastructure/` — JobScheduler, EventBus, repositories
- `src/crafting/adapters/` — WorkshopAdapter, ExpeditionPauseHandler
- `src/crafting/ui/` — RecipeSelectionPanel, QueueDisplay, CraftingUI

### Core Autoload
- `src/autoloads/game_state.gd` — Scene transitions, inventory (8 methods), profession selection

## Architecture Notes

**Additive Scene Model**: Train and Expedition scenes coexist. GameState manages visibility and process_mode:
- Train visible → Expedition hidden (and disabled)
- Expedition visible → Train hidden (but crafting continues if pause handler allows)

**Signal-Based Communication**: All systems use signals for loose coupling:
- `GameState.scene_transition_started` / `completed`
- `GameState.inventory_changed`
- `GameState.profession_selected`
- `CraftingEventBus.job_completed`
- `EscalationManager.threshold_reached`

**UI Architecture**: Phase 7 introduces:
- Persistent CanvasLayer for HUD (above game scenes)
- Menu scenes (main menu, pause) that block game processing
- Modal dialogs for profession selection, crafting UI

## Plan Structure

| Plan | Wave | Name | Depends On |
|------|------|------|------------|
| 07-01 | 1 | System Wiring & Signal Connections | — |
| 07-02 | 2 | HUD & Status Display | 07-01 |
| 07-03 | 3 | Menus, Pause & Loop Verification | 07-01, 07-02 |

## Key Integration Points

### 1. Crafting ↔ GameState
- CraftingEventBus.job_completed → GameState.add_to_inventory
- CraftingEventBus.job_started → GameState.consume_inventory (already wired in Phase 6)
- Verify: crafted item appears in inventory after queue completion

### 2. Expedition ↔ Crafting
- ExpeditionPauseHandler listens to GameState.scene_transition_started
- Pause crafting queue when entering expedition
- Resume when returning to train
- Verify: queue position preserved across transitions

### 3. Profession ↔ Expedition
- AbilityManager attached to Player, processes in expedition
- PassiveBonusManager affects crafting speed (already wired)
- Verify: Engineer abilities work during expedition (Quick Repair, Jury Rig)

### 4. Loot ↔ Inventory
- LootContainer.collected → GameState.add_to_inventory
- Verify: picked-up items appear in inventory

### 5. HUD ↔ All Systems
- Listen to EscalationManager.escalation_changed for meter
- Listen to GameState.inventory_changed for resource display
- Listen to Player health changes (placeholder for combat)

## V1 Scope Boundaries

**In Scope:**
- Complete playable loop
- Basic HUD (escalation, inventory counts)
- Simple main menu (start, exit)
- Profession selection (2 choices)
- Pause menu (resume, quit)
- No critical bugs in core loop

**Out of Scope (V2+):**
- Health/combat system (placeholder only)
- Settings menu (audio, graphics)
- Save/load system
- Multiplayer
- Full 8 professions
- Campaign progression

## Risk Areas

| Risk | Mitigation |
|------|------------|
| Signal ordering issues | Test specific signal sequences in verification |
| UI layering conflicts | Use dedicated CanvasLayer with explicit z-index |
| Pause affecting wrong nodes | Use process_mode carefully, test crafting continues |
| Scene transition race conditions | Add state guards, test rapid transitions |
| Inventory sync drift | Add debug assertion for inventory consistency |

## Codebase Conventions

- GDScript for all gameplay and UI code
- Signals for cross-system communication
- CanvasLayer for persistent UI elements
- Control nodes for UI (not Sprite2D)
- Input actions via project InputMap (not hardcoded)
- Two-phase init for complex dependencies

---
*Generated: 2026-04-14*
