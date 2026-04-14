# Phase 3 Context: Train Core

## Phase Goal

Create a functional train hub with 2-3 interactable cars using Clean Architecture patterns: abstract subsystem base class, composition-based cars, signal-driven dependencies, and data-driven car instantiation.

## Requirements

| ID | Description |
|----|-------------|
| R2 | Train hub with 2-3 functional cars (Engine, Workshop, +1) |

## Success Criteria

- [ ] Train scene with Engine and Workshop cars
- [ ] Player can enter/exit train (already done in Phase 2)
- [ ] Basic subsystem states (Offline, Operational)
- [ ] Car-specific interactions work
- [ ] Visual representation of train state

## Existing Assets

From Phase 2:
- `src/train/train.tscn` — Train scene with PlayerSpawn, TrainCars placeholder node
- `src/train/train.gd` — Scene registration script
- `src/autoloads/game_state.gd` — Scene transition API, player spawning
- `src/player/player.tscn` — Player with WASD movement
- `src/player/player.gd` — Movement script with E-key available for interaction

From Phase 1:
- `src/` directory structure (autoloads/, train/, expedition/, player/, ui/, data/)
- 205 .tres resources from YAML data pipeline
- Main scene with additive loading pattern

From CODEBASE.md:
- Godot 4.6 with Jolt Physics engine
- Forward Plus renderer
- GDScript for all gameplay code (no C# in V1)

## Key Design Decisions

- **Architecture approach**: Clean Architecture — layered with domain/application/presentation separation
- **Subsystem pattern**: Abstract Subsystem base class with state machine, concrete implementations extend it
- **Car pattern**: Composition over inheritance — TrainCar holds subsystem instances
- **Dependency pattern**: Signal-driven — Engine broadcasts `power_available`, Workshop subscribes
- **Instantiation pattern**: Data-driven via TrainCarFactory reading .tres resources
- **Interaction pattern**: InteractionController listens to player E-key, queries Interactable interface

## Plan Structure

| Plan | Wave | Name | Agent(s) |
|------|------|------|----------|
| 03-01 | 1 | Subsystem Architecture | engineering-senior-developer |
| 03-02 | 2 | Car Composition & Factory | engineering-senior-developer |
| 03-03 | 3 | Integration & Interaction System | engineering-senior-developer, testing-qa-verification-specialist |

## Constraints

- No multiplayer/RPC code in V1
- Use GDScript (not C#) for all gameplay code
- Leverage Jolt Physics (not default Godot physics)
- MCP-driven development using gdai-mcp tools
- V1 subsystem states: Offline, Operational only (defer Damaged, Upgraded)

## Design Reference

From `docs/design/systems/train.md`:

**Train Cars (V1 Scope)**:
- Engine: Locomotion, Power Grid subsystems
- Workshop: Fabricator subsystem, requires Engine power

**Subsystem States (V1)**:
- Offline — Not powered or not installed
- Operational — Normal function

**Car Dependencies**:
- Workshop requires Engine (power)

## Open Questions (from Design Docs)

Deferred to future phases:
- Should cars be physically arrangeable or fixed order?
- Can cars be detached/lost permanently?
- What happens if Engine is destroyed?

---
*Generated: 2026-04-13*
