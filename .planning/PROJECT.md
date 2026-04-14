# Off The Rails V2

## What This Is

A 2-8 player co-op PvE expedition game rebuilt in **isometric pixel art** using Godot 4.6. Players restore a derelict train into a mobile fortress, crossing the overgrown ruins of a rail-built colony world to scavenge, craft, upgrade, and escape.

**V2 Focus**: Isometric foundation and mod-friendly architecture. Content restoration and multiplayer come later.

**Pacing reference**: "Project Zomboid meets FTL on rails."

## Core Value

The train is your workshop, infirmary, armory, and fortress — now visualized as an **isometric cross-section** where you see the entire layout, your crew's positions, and systems at a glance. The shift from 3D FPS to isometric enables:

- Better co-op coordination (see where everyone is)
- Spatial equipment layouts (not single-dimension corridors)
- Achievable solo-dev art pipeline (pixel art vs 3D models)
- Mod-friendly architecture from the ground up

## Who It's For

- Co-op survival gamers (Project Zomboid, Barotrauma, FTL fans)
- Modding communities (total conversion support planned)
- Players who value team coordination and role specialization
- Solo dev building for eventual 2-8 player multiplayer

## Requirements

### Validated
(From V1 — architecture patterns that worked)
- Signal-driven state management
- Clean Architecture for complex domains (crafting)
- YAML → .tres data pipeline
- Additive scene architecture

### Active (V2 Scope)

**Isometric Foundation:**
- R1: Isometric tilemap rendering with Y-sorting
- R2: Isometric camera system (follow player, zoom)
- R3: Isometric player movement (4/8-direction, input conversion)
- R4: One train car (Workshop) with spatial floor layout
- R5: Isometric interaction system (approach + interact)

**Mod Architecture:**
- R6: Data-driven content architecture (all game content in data files)
- R7: Mod discovery and loading system
- R8: Mod validation and error handling
- R9: Scripting API foundation (expose core systems)
- R10: Example mod demonstrating extensibility

**V1 Logic Port:**
- R11: Port GameState autoload (adapt for isometric)
- R12: Port crafting domain logic (perspective-agnostic)
- R13: Port data pipeline (YAML → .tres)
- R14: Port signal architecture patterns

### Out of Scope (V2)

- Content parity with V1 (2 cars, 2 professions, 55 recipes) — V2.1
- Multiplayer networking — V3
- Full pixel art assets (placeholder-first)
- Audio system
- Campaign, route map, progression
- Steam Workshop integration
- All 10 train cars / 8 professions

## Constraints

- **Solo developer** — achievable scope, pixel art pipeline
- **Godot 4.6** — leverage isometric TileMap, Y-sorting
- **Pixel art at PZ-tier detail** — 48-64px characters, not 8-bit retro
- **Mod-first architecture** — total conversion support from day one
- **V1 architecture carries forward** — don't reinvent working patterns

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Isometric perspective | Train needs spatial depth; co-op needs visibility | Project Zomboid style, not Barotrauma side-view |
| Pixel art (PZ-tier) | Achievable solo, can still do horror/atmosphere | 48-64px characters, detailed environments |
| Mod-first architecture | Community extends the game; total conversion viable | Data-driven everything, scripting API |
| Foundation before content | Get isometric + modding right first | Content restoration is V2.1 |
| Port V1 logic | Architecture was sound, just presentation was wrong | GameState, crafting domain, signals transfer |
| Guided execution | Solo dev wants learning and control | Agent proposes, user approves |
| Deep analysis planning | Comprehensive specs before implementation | More planning upfront |
| Premium agent usage | Maximize parallelism for speed | Spawn specialists freely |

## Architecture Influences

**From V1 (proven patterns):**
```
Main (persistent)
├── Autoloads (GameState — adapted for isometric)
├── TrainScene (isometric tilemap)
├── ExpeditionScene (isometric exploration)
└── UI (persistent overlay)
```

**New for V2:**
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

**Isometric rendering:**
```
TileMap (isometric mode, 64x32 tiles)
├── Y-sort enabled for depth ordering
├── Collision shapes for walls/objects
└── Navigation regions for pathfinding

Character (CharacterBody2D)
├── AnimatedSprite2D (4/8 direction frames)
├── Isometric input conversion
└── Y-sort based on position.y
```

---
*Last updated: 2026-04-14 — V2 initialization*
