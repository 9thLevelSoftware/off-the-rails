# Phase 4: Interaction System — Context

## Phase Goal

Create a spatial approach-and-interact system for isometric perspective. Establish Clean Architecture patterns for cross-cutting interaction logic that will be reused across all 10 train cars.

## Requirements Covered

- **R5**: Isometric interaction system (approach + interact)

## Success Criteria

- [ ] Interactable base class for equipment
- [ ] Proximity detection in isometric space
- [ ] Visual prompt when in range ("Press E")
- [ ] Interaction triggers feedback (placeholder for now)
- [ ] Works correctly with Y-sorting (prompt above objects)

## Existing Assets

From Phase 1-3:
- Isometric TileMap configured (64x32 tile size, 2:1 ratio)
- Y-sorting enabled and working correctly
- PlayerController (CharacterBody2D) with isometric movement
- EquipmentEntity with `tile_to_world()`, `get_world_position()`, `collision_rect`
- Workshop scene with spatial equipment layout
- FloorCollisionGrid for O(1) spatial queries

V1 code (reference only):
- `src/train/interaction/interactable.gd` — Signal architecture, prompt interface
- `src/train/interaction/interaction_controller.gd` — 3D-specific, needs rewrite

## Key Design Decisions

**Architecture approach**: Clean Architecture — matching Phase 3 patterns

Selected over Minimal (too coupled) and Pragmatic (insufficient layering) to:
- Maintain testable domain logic with no Godot Node dependencies
- Enable reuse across all 10 train cars
- Provide clear mod hooks via signals and configuration
- Keep interaction system independent of specific equipment types

**File placement**: Core interaction in `src/interaction/` (cross-cutting), car-specific adapters in respective car folders.

**Rationale**: Interaction system serves all train cars and expedition locations. Centralizing domain/infrastructure ensures consistent behavior; adapters customize per-context.

## Plan Structure

| Plan | Wave | Name | Focus |
|------|------|------|-------|
| 04-01 | 1 | Domain and Infrastructure | Pure logic, spatial queries |
| 04-02 | 2 | Adapters and Workshop Integration | Godot nodes, visual feedback |

## Directory Structure

```
src/interaction/                          # Cross-cutting interaction system
├── domain/
│   ├── interaction_range.gd              # Isometric distance calculations
│   └── interactable_config.gd            # Config resource (range, prompt)
├── infrastructure/
│   ├── isometric_proximity_detector.gd   # Spatial queries
│   └── interaction_state_machine.gd      # State lifecycle
├── adapters/
│   ├── isometric_interaction_controller.gd  # Input + player tracking
│   └── interaction_prompt_display.gd     # Visual prompt layer
└── scenes/
    └── interaction_prompt.tscn           # Y-sorted "Press E" UI

src/train/cars/workshop/adapters/
└── equipment_interactable.gd             # Equipment-specific adapter
```

## Integration Points

- **PlayerController**: Interaction controller tracks player position via group lookup
- **EquipmentEntity**: Equipment adapter wraps domain entity, exposes to interaction system
- **Workshop scene**: Interaction system added as child, equipment registered on ready
- **Input map**: Uses existing "interact" action (E key)

## References

- PROJECT.md — Architecture patterns, mod-first design
- ROADMAP.md Phase 4 — Success criteria, plan count
- .planning/CODEBASE.md — Risk areas, existing structure
- Phase 3 summaries — Clean Architecture patterns established
