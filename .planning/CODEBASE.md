# Codebase Analysis

**Analyzed**: 2026-04-12  
**Status**: Tooled Greenfield — infrastructure ready, game code blank

## Overview

| Metric | Value |
|--------|-------|
| Total Files | ~50 (tools + docs only) |
| Languages | TypeScript, GDScript, Python, YAML, Markdown |
| Game Source Code | 0 files |
| Design Documentation | 8 markdown + 6 YAML files |
| MCP Tooling | 2 servers (godot-mcp + GDAI) |

## Structure

```
off-the-rails/
├── project.godot              # Godot 4.6, Jolt Physics, Forward Plus
├── .planning/                 # Legion planning state
│   ├── exploration-technical-architecture.md
│   └── CODEBASE.md (this file)
├── docs/design/               # DESIGN DOCUMENTATION (source of truth)
│   ├── vision.md              # Core fantasy, pillars, scope
│   ├── gdd.md                 # Master index document
│   ├── diagrams/
│   │   └── core-loop.md       # Mermaid diagrams of gameplay loops
│   ├── systems/               # System design specs
│   │   ├── train.md           # Train cars, subsystems, progression
│   │   ├── expeditions.md     # Escalation, objectives, extraction
│   │   ├── professions.md     # 8 professions with abilities
│   │   ├── crafting.md        # Stations, recipes, queues
│   │   └── progression.md     # Campaign phases, route map
│   └── data/                  # YAML DATA (will become .tres)
│       ├── train-cars.yaml    # 10 car definitions
│       ├── professions.yaml   # 8 profession definitions
│       ├── resources.yaml     # Resource categories
│       ├── upgrades.yaml      # Upgrade trees
│       ├── locations.yaml     # Location archetypes
│       └── recipes.yaml       # Crafting recipes
├── addons/
│   └── gdai-mcp-plugin-godot/ # GDAI MCP PLUGIN (binary)
│       ├── plugin.cfg         # v0.3.2 by Delano Lourenco
│       ├── gdai_mcp_plugin.gd # Editor plugin
│       ├── gdai_mcp_runtime.gd # Runtime autoload
│       └── bin/               # Platform binaries
└── tools/
    └── godot-mcp/             # GODOT MCP SERVER (TypeScript)
        ├── package.json       # v1.0.0, 165 tools
        ├── src/
        │   ├── index.ts       # MCP server entry, tool definitions
        │   ├── utils.ts       # Utilities, type conversion
        │   └── scripts/       # GDScript runtime scripts
        │       ├── godot_operations.gd    # Headless CLI operations
        │       └── mcp_interaction_server.gd # TCP runtime control
        └── tests/             # 390 Vitest tests

```

## Design Documentation Summary

### Vision (vision.md)
- **Pitch**: Co-op PvE expedition game, survivors restore derelict train, escape planet
- **Pacing**: "Barotrauma meets Project Zomboid on rails"
- **Pillars**: Train is home, Expeditions have stakes, Roles matter, Route choice drives strategy
- **MVP Scope**: 2-8 players, 6-8 professions, 5 location archetypes, 1 enemy faction

### Train System (train.md)
- 10 car types with dependencies (Engine → Workshop → Infirmary, etc.)
- 11 subsystems with 4 states (Offline, Damaged, Operational, Upgraded)
- 5 progression states (Wreck → Limping → Functional → Fortified → Command)
- Crew scaling from 2 (skeleton) to 8 (full complement)

### Expedition System (expeditions.md)
- Escalation meter (0-100%) with 5 thresholds
- 5 escalation profiles (Slow Burn, Noise-Sensitive, Alarm-Based, etc.)
- 10 primary objective types
- Extraction methods and failed extraction handling

### Profession System (professions.md)
- 8 professions: Engineer, Medic, Scavenger, Security, Signal Tech, Machinist, Botanist, Researcher
- Each has 3 active abilities + passive bonuses
- Cross-training system for small crews
- Profession synergies defined

### Crafting System (crafting.md)
- 7 stations with 4 upgrade tiers
- Queue-based crafting with real-time progression
- 8 crafting categories
- Quality system (Poor → Standard → Quality → Superior)

### Campaign Progression (progression.md)
- 5 phases over 18-27 sessions (~30-50 hours)
- Route map with junctions, blocked routes, hazards
- Milestone gates between phases
- Specialist recruitment system

## MCP Tooling

### godot-mcp Server
- **Version**: 1.0.0
- **Tools**: 165 (CLAUDE.md says 149, package.json says 165)
- **Communication**: Dual-channel
  - Headless CLI for file operations
  - TCP socket (port 9090) for runtime control
- **Dependencies**: @modelcontextprotocol/sdk 1.26.0
- **Tests**: 390 Vitest tests (utils, tool-definitions, handlers)

### GDAI MCP Plugin
- **Version**: 0.3.2
- **Type**: Binary GDExtension (platform-specific)
- **Autoload**: GDAIMCPRuntime (configured in project.godot)
- **Server**: Python MCP server (gdai_mcp_server.py)

## Risk Areas

| Area | Risk | Mitigation |
|------|------|------------|
| No game code exists | High complexity first implementation | Start with core loop, iterate |
| Hybrid language (GDScript+C#) | Boundary confusion | Define clear ownership per system |
| Additive scenes | Memory complexity | Profile early, set budgets |
| MCP-driven development | Tool reliability | Have manual fallback workflow |
| 2-8 player scaling | Balance complexity | Test at extremes (2, 4, 8) |

## Implementation Priorities

Based on design docs and architecture decisions:

1. **Foundation** (must build first)
   - Directory structure (src/, assets/)
   - Data pipeline (YAML → .tres build script)
   - Core autoloads (GameState, NetworkManager)
   - Scene hierarchy (Main, Train, Expedition)

2. **Core Loop** (validates the game)
   - Player character with basic movement
   - One train car (Engine) with interaction
   - One expedition location
   - Basic escalation system

3. **Systems** (in dependency order)
   - Train car system (10 cars)
   - Profession system (abilities, bonuses)
   - Crafting system (stations, queues)
   - Progression system (milestones, routing)

4. **Polish** (before release)
   - Audio/VFX
   - UI/UX
   - Multiplayer stress testing
   - Campaign balance

## Open Questions (from Design Docs)

Consolidated from all system docs — resolve during implementation:

### Core
- How does difficulty scale with player count?
- What's the solo play story?
- How long is a full campaign? (Design says 30-50 hours)

### Train
- Should cars be physically arrangeable or fixed order?
- Can cars be detached/lost permanently?
- What happens if Engine is destroyed?

### Expeditions
- How does death work? Permadeath? Respawn? Rescue?
- Can you abort expedition and return later?
- Do locations reset between visits?

### Professions
- Can players change profession mid-campaign?
- Can rescued NPCs fill profession roles?
- Dual-classing possible?

### Crafting
- Should failed crafts be possible?
- Bulk crafting discount?
- Recipe discovery via experimentation?

### Progression
- How much player choice in route order?
- Can players backtrack?
- What's the failure state?
