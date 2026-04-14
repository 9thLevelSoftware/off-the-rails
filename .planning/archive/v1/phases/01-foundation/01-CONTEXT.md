# Phase 1: Foundation — Context

**Phase**: 1 of 7
**Goal**: Establish project structure and development infrastructure
**Status**: Planned

## Requirements

| ID | Description | Priority |
|----|-------------|----------|
| R6 | Directory structure matching architectural sketch | Must |
| R7 | YAML → .tres build pipeline for design data | Must |
| R8 | Core autoloads (GameState) | Must |
| R10 | MCP-driven development workflow | Must |

## Existing Assets

### Design Documentation
- `docs/design/vision.md` — Core fantasy, design pillars
- `docs/design/gdd.md` — Master index document
- `docs/design/systems/` — Train, expeditions, professions, crafting, progression specs

### Design Data (YAML source files)
- `docs/design/data/train-cars.yaml` — 10 car definitions
- `docs/design/data/professions.yaml` — 8 profession definitions
- `docs/design/data/resources.yaml` — Resource categories
- `docs/design/data/upgrades.yaml` — Upgrade trees
- `docs/design/data/locations.yaml` — Location archetypes
- `docs/design/data/recipes.yaml` — Crafting recipes

### MCP Tooling
- `tools/godot-mcp/` — TypeScript MCP server (165 tools)
- `addons/gdai-mcp-plugin-godot/` — Binary GDExtension plugin

### Architecture Reference
- `.planning/exploration-technical-architecture.md` — Finalized architecture decisions

## Architecture Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Scene Organization | Additive scenes | Train + Expedition coexist for split-team play |
| Data Pipeline | Build-time YAML → .tres | Fast runtime, editor integration, type safety |
| Primary Language | GDScript (C# for networking later) | Rapid iteration, MCP compatibility |
| Multiplayer | Listen Server (V2) | Single-player first, architect for later |

## Target Directory Structure

```
src/
├── autoloads/
│   └── game_state.gd
├── train/
│   └── (placeholder for Phase 3)
├── expedition/
│   └── (placeholder for Phase 4)
├── player/
│   └── (placeholder for Phase 2)
├── ui/
│   └── (placeholder for Phase 7)
└── data/
    └── (generated .tres files)
```

## Plan Structure

| Plan | Wave | Name | Depends On |
|------|------|------|------------|
| 01-01 | 1 | Directory & Autoloads | — |
| 01-02 | 2 | Build Pipeline | 01-01 |
| 01-03 | 2 | Scene Architecture | 01-01 |

## MCP Development Notes

Agents implementing this phase should use MCP tools where appropriate:
- `mcp__godot-mcp__create_directory` — Create src/ subdirectories
- `mcp__godot-mcp__create_script` — Create GDScript files
- `mcp__godot-mcp__create_scene` — Create .tscn scene files
- `mcp__godot-mcp__manage_autoloads` — Register autoloads in project.godot
- `mcp__gdai-mcp__create_scene` — Alternative scene creation via GDAI

Verification should use:
- `mcp__godot-mcp__list_project_files` — Verify file creation
- `mcp__godot-mcp__read_project_settings` — Verify autoload registration
- `mcp__godot-mcp__read_scene` — Verify scene structure

## Success Criteria

- [ ] Directory structure matches architectural sketch
- [ ] YAML → .tres build script runs successfully
- [ ] GameState autoload configured and functional
- [ ] Main scene with additive scene loading works
- [ ] MCP tools can create/modify scenes
