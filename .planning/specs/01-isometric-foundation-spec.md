# Spec: Phase 1 — Isometric Foundation

## Overview

Establish the isometric rendering infrastructure for Off The Rails V2. This phase creates the visual foundation for all subsequent V2 development, enabling Project Zomboid-style isometric perspective with proper depth sorting. V1 code remains intact; this phase creates parallel 2D isometric systems that Phase 6 will connect to ported V1 logic.

The key outcome is a verified isometric environment: TileMap renders correctly, objects sort by depth, camera follows smoothly, and collision works in isometric space.

## Requirements

| ID | Description | Priority | Acceptance Criteria |
|----|-------------|----------|-------------------|
| R1 | Isometric tilemap rendering with Y-sorting | Must | `grep -q "tile_shape = 1" src/isometric/*.tscn` succeeds; Y-sort enabled on tilemap layers |
| R2 | Isometric camera system (follow, zoom) | Must | Camera follows test object via lerp (no teleport); mouse wheel zoom between 0.5x-2.0x; zoom level persists between frames |

## Architecture

**Selected Approach:** Clean Architecture (10 files)

V2 isometric code lives in `src/isometric/` with layered separation of concerns:

```
src/isometric/
├── domain/              # Pure business logic (no Godot nodes)
│   ├── camera_config.gd           # Immutable camera parameters
│   ├── viewport_calculator.gd     # Y-sort & projection math
│   └── tilemap_layout_calculator.gd  # Grid coordinate helpers
├── infrastructure/      # Technical services
│   ├── tileset_loader.gd          # Asset management
│   └── tilemap_repository.gd      # Scene persistence
├── adapters/           # Godot Node integration
│   ├── camera_2d_controller.gd    # Follow + zoom logic
│   ├── tilemap_adapter.gd         # Y-sort wiring
│   └── isometric_canvas.gd        # Viewport & layer management
├── scenes/             # Reusable game objects
│   └── isometric_level.tscn       # Composed from adapters
└── test/
    └── test_isometric_level.tscn  # Verification scene
assets/tilesets/
└── iso_floor.tres                 # Placeholder tileset
```

**Layer Responsibilities:**
- **Domain**: Pure GDScript classes with no Godot node dependencies. Testable without scene tree.
- **Infrastructure**: Asset loading, persistence, external service integration.
- **Adapters**: Bridge domain logic to Godot nodes (Camera2D, TileMap, CanvasLayer).
- **Scenes**: Composed scenes that wire adapters together.

TileMap uses Godot 4.6's built-in isometric mode with 64x32 tiles (2:1 ratio). Y-sorting logic lives in `viewport_calculator.gd` (domain) and is applied via `tilemap_adapter.gd`.

Camera follow/zoom parameters are defined in `camera_config.gd` (domain, immutable) and consumed by `camera_2d_controller.gd` (adapter).

### Key Decisions

| Decision | Choice | Rationale | Alternatives Considered |
|----------|--------|-----------|----------------------|
| Separate `src/isometric/` directory | New parallel directory | V1 code must stay intact for Phase 6 port; clean separation | Modify V1 scenes in place (would break V1) |
| 64x32 tile size | 2:1 isometric ratio | Project Zomboid reference; standard isometric projection | 32x16 (too small for detail), 128x64 (too large) |
| TileMap isometric mode | Godot built-in | Native engine support, handles coordinate conversion | Custom IsometricLayer script (more work, no benefit) |
| Y-sort on TileMap layer | CanvasItem y_sort_enabled | Built-in depth sorting, no custom code needed | Manual draw order (complex, error-prone) |
| Camera2D follow | Lerp interpolation | Smooth follow, V1-proven pattern | Instant follow (jarring), tween (overkill) |

## Deliverables

### Isometric TileMap Scene
- **Path:** `src/isometric/world/iso_tilemap.tscn`
- **Purpose:** Main isometric tilemap for V2 environments
- **Key Content:**
  - TileMap node with `tile_shape = TILE_SHAPE_ISOMETRIC`
  - Tile size 64x32 pixels
  - At least one TileMapLayer with Y-sort enabled
  - Placeholder floor tiles (simple colored diamonds)
  - Collision polygons matching isometric tile shape
- **Dependencies:** Requires placeholder tileset
- **Estimated Size:** ~50 lines tscn + ~20 lines gd

### Placeholder Tileset
- **Path:** `assets/tilesets/iso_floor.tres`
- **Purpose:** Minimal tileset for testing isometric rendering
- **Key Content:**
  - At least 2-3 floor tile variants (different colors)
  - Collision polygon matching 64x32 isometric diamond
  - Optional: one "object" tile for Y-sort testing
- **Dependencies:** None
- **Estimated Size:** Resource file, ~30 lines tres

### Isometric Camera Script
- **Path:** `src/isometric/camera/iso_camera.gd`
- **Purpose:** Camera2D with follow behavior and zoom
- **Key Content:**
  - Export variable for follow target (Node2D)
  - Export variables for follow speed, zoom limits
  - `_physics_process()` with lerp-based following
  - `_input()` for mouse wheel zoom
  - Clamped zoom range (e.g., 0.5x to 2.0x)
- **Dependencies:** None
- **Estimated Size:** ~40 lines

### Test Scene
- **Path:** `src/isometric/test/iso_test.tscn`
- **Purpose:** Verification scene combining all Phase 1 deliverables
- **Key Content:**
  - IsoTileMap instance
  - Simple movable CharacterBody2D (placeholder sprite)
  - IsoCamera following the CharacterBody2D
  - Basic WASD movement for testing
  - Multiple objects at different Y positions for Y-sort verification
- **Dependencies:** iso_tilemap.tscn, iso_camera.gd
- **Estimated Size:** ~80 lines tscn + ~30 lines gd

## Open Questions

| # | Question | Impact | Default if Unresolved |
|---|----------|--------|---------------------|
| 1 | Should iso_test.tscn be the new main scene, or keep V1 main? | Deferrable | Keep V1 main, run test manually |
| 2 | Exact placeholder tile colors/design? | Deferrable | Simple green/brown floor diamonds |
| 3 | Should camera zoom affect physics or just rendering? | Deferrable | Rendering only (Camera2D.zoom) |

## Complexity Assessment

**Rating:** Simple

| Metric | Value |
|--------|-------|
| Requirements | 2 |
| Deliverables | 11 (new: 11, modify: 0, config: 0) |
| Estimated waves | 1-2 |
| Estimated plans | 4 |
| Competing proposals | Optional (standard Godot patterns) |

**Rationale:** Two requirements with well-defined Godot patterns. TileMap and Camera are independent enough for parallel work, but test scene integrates both (creates soft dependency). Low architectural risk — using built-in Godot features, not custom systems.

**Recommended next step:** Proceed to decomposition. Competing proposals are optional but may surface alternative directory structures or test approaches.

## Revision History

| # | Section | Change | Reason |
|---|---------|--------|--------|
| 1 | Requirements | Added specific zoom acceptance criteria (0.5x-2.0x, persistence) | Critique: R2 acceptance was vague |

