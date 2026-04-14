# Phase 3: Train Car Prototype — Context

## Phase Goal

Create one train car (Workshop) with spatial floor layout as the prototype for all 10 train cars. Establish Clean Architecture patterns separating domain logic from Godot-specific adapters.

## Requirements Covered

- **R4**: One train car (Workshop) with spatial floor layout

## Success Criteria

- [ ] Workshop car as isometric tilemap scene
- [ ] 3-4 equipment objects placed spatially (workbench, locker, crate)
- [ ] Player can walk around objects (not through)
- [ ] Clear visual distinction between floor, walls, equipment
- [ ] Car feels like a real space, not a flat corridor

## Existing Assets

From Phase 1-2:
- Isometric TileMap configured (64x32 tile size, 2:1 ratio)
- Y-sorting enabled and working correctly
- Camera follows player smoothly
- CharacterBody2D with isometric movement
- WASD converts to isometric directions correctly
- 4-direction sprite animation (idle + walk)

Design documentation:
- `docs/design/systems/train.md` — 10 car types, subsystems, progression states
- `docs/design/data/train-cars.yaml` — Car definitions including Workshop

## Key Design Decisions

**Architecture approach**: Clean Architecture — domain-driven, data-configurable system

Selected from competing proposals to establish reusable patterns for all 10 train cars:
- Domain layer (FloorLayout, EquipmentEntity) with no Godot dependencies
- Infrastructure layer (FloorLayoutLoader, FloorCollisionGrid) for data loading and spatial queries
- Adapter layer (WorkshopSpatialAdapter, WorkshopLayoutController) bridges domain to Godot nodes
- Data-driven configuration (.tres resources) enables future mod support

**Rationale**: This phase establishes the pattern for 9 more train cars. Clean Architecture ensures:
- Testable domain logic (unit tests without Godot runtime)
- Mod-friendly data layer (JSON/YAML → .tres mapping)
- Clear separation of concerns for maintainability

## Plan Structure

| Plan | Wave | Name | Focus |
|------|------|------|-------|
| 03-01 | 1 | Domain Layer and Infrastructure | Core data structures, collision grid |
| 03-02 | 2 | Adapters and Workshop Scene | Visual integration, playable scene |

## Directory Structure

```
src/train/cars/workshop/
├── domain/
│   ├── floor_layout.gd           # Data container + validation
│   └── equipment_entity.gd       # Position, collision rect, state
├── infrastructure/
│   ├── floor_layout_loader.gd    # Load .tres from data dir
│   └── floor_collision_grid.gd   # Spatial query: overlaps, adjacency
├── adapters/
│   ├── workshop_spatial_adapter.gd  # Renders domain → tilemap + sprites
│   └── workshop_layout_controller.gd # Orchestrates domain + adapter
├── data/
│   └── workshop_floor_layout.tres # Declarative equipment config
└── scenes/
    └── workshop.tscn             # Links controller + adapter
```

## References

- PROJECT.md — Architecture patterns, mod-first design
- ROADMAP.md Phase 3 — Success criteria, plan count
- docs/design/systems/train.md — Workshop car specification
- .planning/CODEBASE.md — Risk areas, MCP tooling context
