# Phase 1: Isometric Foundation — Context

**Phase**: 1 of 7
**Goal**: Establish isometric rendering infrastructure in Godot 4.6
**Status**: Planned
**Architecture**: Clean Architecture (selected via competing proposals)

## Requirements

| ID | Description | Priority |
|----|-------------|----------|
| R1 | Isometric tilemap rendering with Y-sorting | Must |
| R2 | Isometric camera system (follow player, zoom) | Must |

## Existing Assets

### V1 Codebase (Reference Only)
- `src/player/camera_controller.gd` — 3D follow camera pattern (adapt for 2D)
- `src/autoloads/game_state.gd` — V1 state management (Phase 6 port)
- Full V1 implementation in `src/` — 54 GDScript files, 21 scenes

### MCP Tooling
- `tools/godot-mcp/` — TypeScript MCP server (165 tools)
- `addons/gdai-mcp-plugin-godot/` — Binary GDExtension plugin

### Design Documentation
- `.planning/specs/01-isometric-foundation-spec.md` — Full specification

## Architecture Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Architecture Style | Clean Architecture | Separation of concerns, testable components |
| Directory Location | `src/isometric/` | Parallel to V1 code, clean separation |
| Layer Structure | domain/infrastructure/adapters/scenes | Domain logic decoupled from Godot nodes |
| Tile Size | 64x32 (2:1 ratio) | Standard isometric, matches PROJECT.md |

## Target Directory Structure

```
src/isometric/
├── domain/
│   ├── camera_config.gd
│   ├── viewport_calculator.gd
│   └── tilemap_layout_calculator.gd
├── infrastructure/
│   ├── tileset_loader.gd
│   └── tilemap_repository.gd
├── adapters/
│   ├── camera_2d_controller.gd
│   ├── tilemap_adapter.gd
│   └── isometric_canvas.gd
├── scenes/
│   └── isometric_level.tscn
└── test/
    └── test_isometric_level.tscn
assets/tilesets/
└── iso_floor.tres
```

## Plan Structure

| Plan | Wave | Name | Depends On |
|------|------|------|------------|
| 01-01 | 1 | Domain Layer | — |
| 01-02 | 1 | Assets & Infrastructure | — |
| 01-03 | 2 | Adapters | 01-01, 01-02 |
| 01-04 | 3 | Scenes & Integration | 01-03 |

## MCP Development Notes

Agents implementing this phase should use MCP tools where appropriate:
- `mcp__godot-mcp__create_directory` — Create src/isometric/ subdirectories
- `mcp__godot-mcp__create_script` — Create GDScript files
- `mcp__godot-mcp__create_scene` — Create .tscn scene files
- `mcp__godot-mcp__create_resource` — Create tileset .tres files

Verification should use:
- `mcp__godot-mcp__list_project_files` — Verify file creation
- `mcp__godot-mcp__read_file` — Verify script content
- `mcp__godot-mcp__read_scene` — Verify scene structure

## Success Criteria

- [ ] Domain layer classes created with correct interfaces
- [ ] Placeholder tileset renders in isometric (64x32)
- [ ] Camera follows target with smooth lerp
- [ ] Camera zooms via mouse wheel (0.5x - 2.0x)
- [ ] Y-sorting works correctly (depth ordering)
- [ ] Test scene verifies all requirements
