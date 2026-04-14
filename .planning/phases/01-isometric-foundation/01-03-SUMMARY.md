# Plan 01-03: Adapters — Summary

**Status**: Complete
**Agent**: engineering-godot-developer
**Executed**: 2026-04-14

## Files Created

| File | Class | Extends | Purpose |
|------|-------|---------|---------|
| `src/isometric/adapters/camera_2d_controller.gd` | IsoCameraController | Camera2D | Follow target + zoom with smooth lerp |
| `src/isometric/adapters/tilemap_adapter.gd` | IsoTilemapAdapter | Node2D | Wraps TileMap with domain logic |
| `src/isometric/adapters/isometric_canvas.gd` | IsoCanvas | CanvasLayer | Manages rendering layers with Y-sort |

## Verification

- LSP diagnostics: All 3 files pass with 0 errors
- All adapters extend appropriate Godot nodes
- Domain classes referenced via preload constants

## Domain Integration

| Adapter | Domain Dependencies |
|---------|---------------------|
| IsoCameraController | IsoCameraConfig |
| IsoTilemapAdapter | IsoViewportCalculator, IsoTilemapLayoutCalculator, IsoTilesetLoader |
| IsoCanvas | IsoViewportCalculator |

## Implementation Notes

1. Camera uses `_physics_process` for smooth follow (frame-rate independent)
2. Camera uses `_input` for zoom wheel handling with pause check
3. TileMap adapter expects a child node named "TileMap"
4. Canvas manages 3 layers: WorldLayer (z=0), EntityLayer (z=1), UILayer (top)
5. Both WorldLayer and EntityLayer have Y-sort enabled for depth ordering

## Success Criteria

- [x] `camera_2d_controller.gd` extends Camera2D with follow + zoom
- [x] Camera uses IsoCameraConfig from domain
- [x] `tilemap_adapter.gd` extends Node2D with tilemap management
- [x] TileMap has Y-sort enabled
- [x] `isometric_canvas.gd` manages rendering layers
- [x] All adapters properly reference domain classes

## Next

Plan 01-04 (Scenes & Integration) can now compose these adapters.
