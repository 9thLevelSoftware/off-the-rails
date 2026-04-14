# Project State

## Current Position
- **Phase**: 0 of 7 (not started)
- **Status**: V2 Initialized — ready for `/legion:plan 1`
- **Last Activity**: V2 project initialization (2026-04-14)

## Progress
```
[                    ] 0% — 0/17 plans complete
```

## V1 Status
- **Shipped**: 2026-04-14
- **Repository**: https://github.com/9thLevelSoftware/off-the-rails
- **Archive**: `.planning/archive/v1/`

## Recent Decisions

| Decision | Value |
|----------|-------|
| Execution Mode | Guided |
| Planning Depth | Deep Analysis |
| Cost Profile | Premium |
| V2 Scope | Isometric foundation + mod architecture |
| Perspective | Isometric (Project Zomboid style) |
| Art Style | Pixel art, PZ-tier detail (48-64px) |
| Mod Support | Full — content, cars, expeditions, total conversion |

## V2 Architecture Decisions

| Decision | Choice |
|----------|--------|
| Rendering | 2D Isometric (TileMap, Y-sorting) |
| Tile Size | 64x32 (2:1 isometric ratio) |
| Character Sprites | 48-64px tall, 4/8 directions |
| Mod Loading | user://mods/ with mod.json manifests |
| Data Architecture | Data-driven, all content in files |
| V1 Port | GameState, crafting domain, signals |

## Next Action

Run `/legion:plan 1` to begin Phase 1: Isometric Foundation
