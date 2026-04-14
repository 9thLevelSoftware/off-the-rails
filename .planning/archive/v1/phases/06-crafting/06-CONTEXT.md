# Phase 6: Crafting — Context

## Phase Goal

Implement a functional workshop with queue-based crafting system following Clean Architecture principles. The crafting system should support real-time progression, resource consumption, and prepare for future station expansion (Armory, Infirmary, Lab).

## Requirements

- **R5**: Basic crafting at workshop station

## Success Criteria

1. Workshop station interaction
2. Recipe selection UI
3. Queue system with time progression
4. 5-10 basic recipes functional
5. Resource consumption and output
6. Crafting continues during expedition (train-side)

## Architecture Decision

**Selected**: Clean Architecture (from 3 proposals)

**Rationale**: Separates domain logic from infrastructure, enables testable core, and prepares for multi-station support in future phases.

**Structure**:
```
src/crafting/
├── domain/
│   ├── craft_queue.gd          # Queue entity: slots, progress tracking
│   ├── craft_job.gd            # Job value object: recipe, resources, progress
│   ├── recipe_validator.gd     # Use case: can_craft_recipe?, validate_inputs
│   └── job_scheduler.gd        # Use case: enqueue, dequeue, tick progression
├── infrastructure/
│   ├── inventory_repository.gd # Interface for querying player inventory
│   ├── recipe_repository.gd    # Interface for loading/finding recipes
│   └── crafting_event_bus.gd   # Signals: queued, completed, failed, paused
├── adapters/
│   ├── workshop_adapter.gd     # Connects WorkshopCar to crafting system
│   └── expedition_pause_handler.gd # Pause queue on expedition start
└── ui/
    ├── recipe_list_panel.gd    # Recipe selection UI
    └── queue_display.gd        # Current job and queue status
```

## Existing Assets

### From Phase 3 (Train Core)
- `src/train/cars/workshop.gd` — WorkshopCar with Fabricator subsystem
- `src/train/subsystems/fabricator.gd` — Power-dependent crafting subsystem
- `src/train/interaction/interactable.gd` — Base interaction class
- `src/train/interaction/interaction_controller.gd` — Player interaction handling

### From Phase 5 (Professions)
- `src/professions/ability_manager.gd` — Pattern for manager classes
- `src/professions/passive_bonus_manager.gd` — Pattern for bonus application
- Profession data includes crafting speed bonuses

### Design Documents
- `docs/design/systems/crafting.md` — Full crafting system design
- `docs/design/data/recipes.yaml` — 57 recipes (22 default unlocks)
- `docs/design/data/resources.yaml` — 31 resource types

### Build Pipeline
- `tools/build_data.py` — YAML → .tres converter (extend for recipes)

## Plan Structure

| Plan | Wave | Name | Depends On |
|------|------|------|------------|
| 06-01 | 1 | Domain & Data Foundation | — |
| 06-02 | 2 | Infrastructure & Scheduling | 06-01 |
| 06-03 | 3 | Adapters, Integration & UI | 06-01, 06-02 |

## Key Constraints

1. **V1 Scope**: Workshop station only (other stations deferred)
2. **Queue Slots**: T1 station = 1 slot (tier system deferred)
3. **No Persistence**: Queue state not saved (Phase 7 integration)
4. **Profession Bonuses**: -25% craft time for relevant professions
5. **Pause During Expeditions**: Queue pauses when Fabricator offline

## Open Questions (Deferred)

- Quality system implementation (Poor → Superior)
- Failed craft mechanics
- Bulk crafting discounts
- Recipe discovery system
