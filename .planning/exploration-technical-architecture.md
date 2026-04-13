# Technical Architecture Exploration

**Date**: 2026-04-12  
**Mode**: Crystallize  
**Status**: Complete — Ready for implementation planning

## Summary

Technical architecture decisions for **Off The Rails**, a 2-8 player co-op PvE expedition game in Godot 4.6. These decisions establish the foundational structure before implementation begins.

---

## Decisions Made

### 1. Multiplayer Authority Model: Listen Server

**Choice**: Host-as-player with single authority  
**Rationale**: 
- Simple for MVP, no infrastructure cost
- Train's centralized state (engine powers everything, shared inventory) naturally fits single authority
- Can architect for host migration later if needed
- Godot's ENet multiplayer supports this well

**Future consideration**: Design network code to allow migration to dedicated server if competitive integrity becomes important.

### 2. Primary Language: Hybrid (GDScript + C#)

**Choice**: GDScript for gameplay/UI, C# for performance-critical systems  
**Rationale**:
- GDScript: Rapid iteration, better MCP tool integration, most community examples
- C#: Strong typing for networking stack, state sync, pathfinding algorithms
- Clear boundary: Don't mix languages within a single system

**Boundaries**:
- GDScript: UI, game logic, expeditions, train interactions, player controls
- C#: Networking/RPC layer, state synchronization, escalation calculations, AI pathfinding

### 3. Scene Organization: Additive Scenes

**Choice**: Train and Expedition scenes coexist, loaded additively  
**Rationale**:
- Enables split-team play (some defend train, others scavenge)
- Real-time train state visible to expedition team
- Supports "extraction tension" — train scene active during fight-to-the-train
- Matches design doc's scaling considerations (team splitting at higher player counts)

**Structure**:
```
Main (persistent)
├── Autoloads (GameState, NetworkManager, AudioManager)
├── TrainScene (always loaded, may be hidden)
├── ExpeditionScene (loaded when in field)
└── UI (persistent overlay)
```

### 4. Data Pipeline: Build-time YAML → .tres

**Choice**: Convert YAML design files to Godot Resources at build time  
**Rationale**:
- Fast runtime loading (no parsing overhead)
- Full editor integration and previews
- Type safety via custom Resource classes
- Maintains human-readable YAML as source of truth for design iteration

**Pipeline**:
```
docs/design/data/*.yaml → build script → res://data/*.tres
```

**Source files** (authoritative):
- train-cars.yaml
- professions.yaml
- resources.yaml
- upgrades.yaml
- locations.yaml
- recipes.yaml

### 5. MCP Development Workflow: Full MCP-driven

**Choice**: AI-assisted development using godot-mcp (149 tools) + GDAI  
**Rationale**:
- Rapid scene scaffolding and iteration
- Runtime testing and inspection
- Automated validation against design docs
- Human review and polish on AI-generated output

**Workflow**:
1. Claude reads design docs (YAML + markdown)
2. MCP tools create scenes, nodes, scripts
3. Human reviews in Godot editor
4. Iterate via MCP for adjustments
5. Manual polish for visual/UX refinement

---

## Knowns

- Godot 4.6 with Jolt Physics and Forward Plus renderer
- Greenfield codebase — no legacy constraints
- Rich design documentation already exists
- Two MCP servers operational (GDAI + godot-mcp)
- MVP scope: 2-8 players, 6-8 professions, 5 location archetypes

## Unknowns (to resolve during implementation)

| Unknown | Resolution Path |
|---------|-----------------|
| ENet vs WebRTC for networking | Prototype both, test NAT traversal |
| YAML→.tres build tooling | Implement as GDScript or Python build step |
| Train car attachment system | Design scene inheritance vs composition |
| Escalation sync precision | Test with simulated latency |
| Scene memory footprint | Profile with both scenes loaded |

---

## Architectural Sketch

```
off-the-rails/
├── project.godot
├── .planning/                    # Legion planning state
├── docs/design/                  # Design documentation (source of truth)
│   └── data/*.yaml              # Design data files
├── addons/
│   └── gdai-mcp-plugin-godot/   # AI development tools
├── tools/
│   └── godot-mcp/               # MCP server (149 tools)
├── src/                         # Game source code
│   ├── autoloads/               # Persistent managers
│   │   ├── game_state.gd        # Campaign/session state
│   │   ├── network_manager.cs   # C# networking stack
│   │   └── audio_manager.gd     # Sound management
│   ├── train/                   # Train hub systems
│   │   ├── train.tscn           # Main train scene
│   │   ├── cars/                # Individual car scenes
│   │   └── systems/             # Train subsystems (power, repair)
│   ├── expedition/              # Field gameplay
│   │   ├── expedition.tscn      # Expedition scene root
│   │   ├── locations/           # Location archetypes
│   │   └── entities/            # Enemies, items, hazards
│   ├── player/                  # Player character
│   ├── ui/                      # UI scenes and scripts
│   └── data/                    # Generated .tres resources
├── assets/                      # Art, audio, models
└── build/                       # Build scripts and output
```

---

## Next Action

Run `/legion:start` to begin implementation planning with these architecture decisions as foundation.
