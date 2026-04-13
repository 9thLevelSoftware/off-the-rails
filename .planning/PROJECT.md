# Off The Rails

## What This Is

A 2-8 player co-op PvE expedition game built in Godot 4.6 where survivors restore a derelict train into a mobile home and battle platform, crossing the overgrown ruins of a rail-built colony world to scavenge, upgrade, and eventually escape the planet.

**Pacing reference**: "Barotrauma meets Project Zomboid on rails."

## Core Value

The train is not just transport — it's your workshop, infirmary, armory, and fortress. You push deeper into a dead colony's rail network, stopping to scavenge what you need, fighting what you disturb, and returning to your moving home before things get worse. Every expedition has stakes, every upgrade feels earned, and the train's visible state is your campaign progress bar.

## Who It's For

- Co-op gamers who enjoy survival management games (Project Zomboid, Barotrauma)
- Players who value team coordination and role specialization
- Fans of tense extraction gameplay with meaningful resource management
- Groups of 2-8 friends looking for a campaign-style experience

## Requirements

### Validated
(None yet — ship to validate)

### Active (V1 Scope)

**Core Loop:**
- R1: Single-player gameplay (networking deferred to V2)
- R2: Train hub with 2-3 functional cars (Engine, Workshop, +1)
- R3: Expedition system with escalation meter and extraction mechanics
- R4: 2-3 professions with distinct abilities and train station roles
- R5: Basic crafting at workshop station

**Technical Foundation:**
- R6: Directory structure matching architectural sketch
- R7: YAML → .tres build pipeline for design data
- R8: Core autoloads (GameState)
- R9: Additive scene architecture (Train + Expedition coexist)
- R10: MCP-driven development workflow

### Out of Scope (V1)

- Multiplayer networking and RPC layer
- All 10 train cars (start with 2-3)
- All 8 professions (start with 2-3)
- Campaign progression, route map, milestones
- Endgame and escape sequence
- Full art assets and polish
- Audio system

## Constraints

- **Solo developer** — one person implementing all code
- **No paid assets** — free/open assets only
- **MCP-driven** — leverage godot-mcp + GDAI for rapid iteration
- **Hybrid language** — GDScript for gameplay/UI, C# for networking (later)

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Single-player first | Validate core loop before networking complexity | No RPC code in V1 |
| Listen Server architecture | Simple MVP, train's centralized state fits single authority | Architect for later |
| Hybrid GDScript + C# | GDScript for iteration speed, C# for networking performance | Clear boundaries per system |
| Additive scenes | Enable split-team play, real-time train state during expeditions | Train + Expedition coexist |
| Build-time YAML → .tres | Fast runtime, editor integration, human-readable source | Build script required |
| Full MCP-driven | Rapid scaffolding, AI review/iterate cycle | Human polish pass |
| Guided execution | Solo dev wants learning and control | Agent proposes, user approves |
| Deep analysis planning | Comprehensive specs before implementation | More planning upfront |
| Premium agent usage | Maximize parallelism for speed | Spawn specialists freely |

## Architecture Influences

See `.planning/exploration-technical-architecture.md` for full architecture decisions.

**Key patterns:**
```
Main (persistent)
├── Autoloads (GameState)
├── TrainScene (always loaded)
├── ExpeditionScene (loaded when in field)
└── UI (persistent overlay)
```

**Data flow:**
```
docs/design/data/*.yaml → build script → res://data/*.tres → runtime
```

**Source layout:**
```
src/
├── autoloads/         # GameState, later NetworkManager
├── train/             # Train hub scenes and scripts
├── expedition/        # Field gameplay
├── player/            # Player character
├── ui/                # UI scenes
└── data/              # Generated .tres resources
```

---
*Last updated: 2026-04-12 after initialization*
