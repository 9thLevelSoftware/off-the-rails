# Phase 2: Player & Movement — Context

**Phase**: 2 of 7
**Goal**: Isometric character with natural-feeling movement
**Status**: Planned
**Architecture**: Clean Architecture (continued from Phase 1)

## Requirements

| ID | Description | Priority |
|----|-------------|----------|
| R3 | Isometric player movement (4/8-direction, input conversion) | Must |

## Existing Assets (from Phase 1)

### Isometric Foundation
- `src/isometric/domain/` — Camera config, viewport calculator, tilemap layout
- `src/isometric/adapters/` — Camera2D controller, tilemap adapter, isometric canvas
- `src/isometric/scenes/isometric_level.tscn` — Main level scene with Y-sorted layers
- `src/isometric/test/test_isometric_level.gd` — Test movement (screen-space, NOT isometric)

### Key Integration Points
- `IsoLevel.get_entity_layer()` — Returns Y-sorted entity layer for player
- `IsoLevel.set_camera_target(node)` — Camera follow system
- `EntityLayer` — Y-sort enabled Node2D for depth ordering

### V1 Reference
- `src/player/player.gd` — 3D player with profession system (pattern reference)

## Architecture Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Directory | `src/isometric/player/` | Consistent with Phase 1 structure |
| Layer Extension | Add domain/adapters for player | Maintain Clean Architecture |
| Input Conversion | 2:1 isometric matrix | Standard isometric, matches 64x32 tiles |
| Animation | 4-direction first, 8-direction optional | MVP scope, expandable |
| Sprite Size | 48-64px tall | Per PROJECT.md "PZ-tier detail" |

## Isometric Input Conversion

Standard 2:1 isometric conversion (tile aspect 64x32):

```
WASD Input → Isometric Screen Direction:
W (up)    → (-1, -0.5) normalized → north-west
S (down)  → ( 1,  0.5) normalized → south-east
A (left)  → (-1,  0.5) normalized → south-west
D (right) → ( 1, -0.5) normalized → north-east
```

Conversion matrix:
```
screen.x = (world.x - world.y) * (tile_width / 2)
screen.y = (world.x + world.y) * (tile_height / 2)
```

For input (world to screen direction):
```
screen_dir = Vector2(
    (input.x - input.y),
    (input.x + input.y) * 0.5
).normalized()
```

## Target Directory Structure

```
src/isometric/
├── domain/
│   ├── ... (existing)
│   ├── isometric_direction.gd    # Direction enum + helpers
│   ├── input_converter.gd        # WASD → isometric conversion
│   └── movement_config.gd        # Speed, acceleration settings
├── adapters/
│   ├── ... (existing)
│   └── player_controller.gd      # CharacterBody2D movement adapter
├── player/
│   ├── player.tscn               # Player scene
│   └── animation_controller.gd   # AnimatedSprite2D direction handler
└── scenes/
    └── ... (existing)
assets/
└── player/
    └── placeholder_player.png    # 4-direction placeholder sprite
```

## Plan Structure

| Plan | Wave | Name | Depends On |
|------|------|------|------------|
| 02-01 | 1 | Domain & Input Conversion | — |
| 02-02 | 2 | Player Character | 02-01 |

## Success Criteria

- [ ] CharacterBody2D with isometric movement
- [ ] WASD converts to isometric directions correctly
- [ ] 4-direction sprite animation (idle + walk)
- [ ] Y-sort positions player correctly relative to objects
- [ ] Movement feels responsive and natural (no input lag, smooth acceleration)
