# Phase 5: Mod Architecture — Context

## Phase Goal

Build a data-driven content system with mod loading capability. All game content lives in data files; mods extend via a clean API. This establishes the foundation for community extensibility and total conversion support.

## Architecture Approach

**Selected: Clean Architecture** (boundary-first design)

Key principles:
- ContentRegistry as single entity boundary (all merged content)
- Typed interfaces only — no raw data access from mod scripts
- Data→Domain pipeline (YAML is infrastructure, domain never reads YAML directly)
- ModLoader as highest-level orchestrator (presenter pattern)
- Per-content-type registries for clean boundaries

Rationale: Long-term maintainability, safe mod isolation, typed APIs catch errors early, future-proof for scripting extensions.

## Requirements

| ID | Description | Covered By |
|----|-------------|------------|
| R6 | Data-driven content architecture (all game content in data files) | Plan 05-02 |
| R7 | Mod discovery and loading system | Plan 05-01 |
| R8 | Mod validation and error handling | Plan 05-01 |
| R9 | Scripting API foundation (expose core systems) | Plan 05-02, 05-03 |
| R10 | Example mod demonstrating extensibility | Plan 05-04 |

## Success Criteria

- [ ] All base game content in data files (not hardcoded)
- [ ] ModLoader autoload discovers mods in user://mods/
- [ ] mod.json manifest format defined and validated
- [ ] Content registry merges base + mod data at runtime
- [ ] Example mod adds one custom item successfully
- [ ] Mod loading errors handled gracefully (don't crash)
- [ ] Basic scripting API exposes key systems

## Plan Structure

| Plan | Wave | Name | Agent(s) | Depends On |
|------|------|------|----------|------------|
| 05-01 | 1 | Mod System Foundation | engineering-backend-architect | — |
| 05-02 | 2 | Content Registry & Data Pipeline | engineering-senior-developer | 05-01 |
| 05-03 | 3 | ModAPI & Integration | engineering-senior-developer | 05-02 |
| 05-04 | 4 | Example Mod & Documentation | product-technical-writer, testing-qa-verification-specialist | 05-03 |

## Existing Assets

### Design Documentation
- `docs/design/data/train-cars.yaml` — 10 car definitions
- `docs/design/data/professions.yaml` — 8 profession definitions
- `docs/design/data/resources.yaml` — Resource categories
- `docs/design/data/upgrades.yaml` — Upgrade trees
- `docs/design/data/locations.yaml` — Location archetypes
- `docs/design/data/recipes.yaml` — Crafting recipes

### Project Architecture (from PROJECT.md)
```
Mod System:
├── ModLoader (autoload)
│   ├── Discovers mods in user://mods/
│   ├── Validates mod.json manifests
│   └── Loads content packs and scripts
├── ModAPI (exposed interfaces)
│   ├── ContentRegistry (items, recipes, professions)
│   ├── TrainCarRegistry (custom cars)
│   └── EventHooks (gameplay events for scripts)
└── Data Architecture
    ├── Base game data in res://data/
    ├── Mods override/extend in user://mods/{mod}/data/
    └── Runtime merges base + mod data
```

## Key Design Decisions

- **Architecture approach**: Clean Architecture — boundary-first with typed registries
- **Manifest format**: mod.json (native Godot JSON, no parsing overhead)
- **Data location**: Base game in `res://data/`, mods in `user://mods/{mod_id}/data/`
- **Merge strategy**: ContentRegistry merges at startup; mod data overlays base data by ID
- **Error handling**: Graceful degradation — log bad mods, skip, continue startup
- **Scripting API**: Typed interfaces (no raw data mutation) + EventHooks signals

## Constraints

- Godot 4.6 — leverage built-in JSON parsing, autoload system
- Solo developer — prefer clear patterns over clever abstractions
- Mod-first architecture — design for total conversion support from day one
- No hot-reload in initial implementation (acceptable tradeoff)

## Prior Phase Outputs

- Phase 1-4: Isometric foundation complete (tilemap, camera, player, interaction system)
- No game content code exists yet — this phase creates the data infrastructure
