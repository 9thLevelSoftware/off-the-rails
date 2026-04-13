# Plan 03-02 Summary: Car Composition & Factory

## Status: Complete

## Execution Details
- **Agent**: engineering-senior-developer (via Godot Developer subagent)
- **Wave**: 2
- **Date**: 2026-04-13
- **Dependency**: 03-01 (Subsystem Architecture) - VERIFIED

## Files Created/Modified

| File | Lines | Action | Description |
|------|-------|--------|-------------|
| `src/train/interaction/interactable.gd` | 42 | Created | Interactable interface for E-key dispatch |
| `src/train/cars/train_car.gd` | 106 | Created | TrainCar base class with composition pattern |
| `src/train/cars/train_car_factory.gd` | 82 | Created | Factory for data-driven car instantiation |
| `src/train/cars/engine.gd` | 47 | Created | EngineCar script extending TrainCar |
| `src/train/cars/engine.tscn` | ~29 | Created | Engine car scene with subsystems |
| `src/train/cars/workshop.gd` | 44 | Created | WorkshopCar script extending TrainCar |
| `src/train/cars/workshop.tscn` | ~25 | Created | Workshop car scene with subsystem |
| `data/cars/engine_car.tres` | 5 | Created | Placeholder car data resource |
| `data/cars/workshop_car.tres` | 5 | Created | Placeholder car data resource |

**Total**: ~385 lines across 9 files

## Scene Structures

### engine.tscn
```
EngineCar (Node3D) [script: engine.gd]
├── PowerGrid (Node) [script: power_grid.gd]
├── Locomotion (Node) [script: locomotion.gd]
├── InteractionArea (Area3D)
│   └── CollisionShape3D (BoxShape3D, size: 4x3x8)
└── Mesh (MeshInstance3D, BoxMesh 4x3x8)
```

### workshop.tscn
```
WorkshopCar (Node3D) [script: workshop.gd]
├── Fabricator (Node) [script: fabricator.gd]
├── InteractionArea (Area3D)
│   └── CollisionShape3D (BoxShape3D, size: 4x3x6)
└── Mesh (MeshInstance3D, BoxMesh 4x3x6)
```

## Verification Results

| Command | Result |
|---------|--------|
| `test -f src/train/cars/train_car.gd` | PASS |
| `test -f src/train/cars/train_car_factory.gd` | PASS |
| `test -f src/train/cars/engine.tscn` | PASS |
| `test -f src/train/cars/workshop.tscn` | PASS |
| `test -f src/train/interaction/interactable.gd` | PASS |
| `grep -q "class_name TrainCar"` | PASS |
| `grep -q "class_name TrainCarFactory"` | PASS |
| `grep -q "Interactable"` | PASS |
| Runtime test: engine.tscn | PASS |
| Runtime test: workshop.tscn | PASS |

## Implementation Decisions

1. **Composition Pattern**: TrainCar caches child Subsystem nodes in `_ready()` via `_cache_subsystems()` for quick access.

2. **Scene Structure**: Subsystem nodes (PowerGrid, Locomotion, Fabricator) are direct children with exact names matching `@onready` references - critical for the critique fix.

3. **Factory Pattern**: TrainCarFactory uses hardcoded scene paths for V1 (2 cars). Full data-driven configuration deferred to Phase 6.

4. **Placeholder Resources**: Created minimal .tres files in `data/cars/` as placeholders for future data-driven car configuration.

5. **LSP Caching Note**: LSP reports "Could not find base class TrainCar" for new files - this is a known Godot LSP indexing delay. Runtime testing confirmed no errors.

## Issues

None blocking. LSP class_name caching resolves after editor restart.

## Architecture Summary

### TrainCar (Base)
- Composition container for Subsystem instances
- `get_subsystems()`, `get_subsystem()`, `has_capability()` queries
- Signal forwarding via `subsystem_state_changed`
- `bring_all_online()`, `take_all_offline()` batch operations

### EngineCar
- Contains PowerGrid + Locomotion subsystems
- `start_engine()` / `stop_engine()` convenience methods
- Auto-manages Locomotion state based on PowerGrid power availability

### WorkshopCar
- Contains Fabricator subsystem
- `connect_to_engine()` for power dependency injection
- `activate_workshop()` / `deactivate_workshop()` convenience methods

### TrainCarFactory
- Creates car instances by ID via scene instantiation
- Scene caching for performance
- `create_starting_cars()` for new game initialization

## Ready For

Plan 03-03: Integration & Interaction System - cars ready to be instantiated and managed by TrainManager
