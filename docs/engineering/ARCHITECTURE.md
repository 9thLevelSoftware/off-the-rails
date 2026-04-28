# Architecture

Off The Rails is a Godot 4.6.2 project using GDScript, Forward Plus rendering, Jolt Physics, data-driven content, and integrated MCP tooling.

## Source Layout

- `src/autoloads/` - global runtime state.
- `src/data/` - content registries, data loaders, resource types, and generated `.tres` content.
- `src/isometric/` - isometric camera, canvas, movement, tilemap, and player foundation.
- `src/interaction/` - approach and prompt interaction system.
- `src/crafting/` - crafting domain, infrastructure, adapters, and UI.
- `src/train/` - train cars, workshop layout, subsystems, and train scene logic.
- `src/mod_system/`, `src/scripting/`, `src/mods/` - mod discovery, validation, API, hooks, and examples.
- `src/expedition/`, `src/professions/`, `src/ui/` - gameplay systems and interface.
- `tools/godot-mcp/` - TypeScript MCP server and tests.
- `tools/pixellab-api/` - asset generation helper tooling.

## Boundaries

- Domain code should not depend on scenes, UI, adapters, or infrastructure.
- Infrastructure may depend on domain types and autoload services.
- Adapters translate between Godot scene nodes and domain/infrastructure APIs.
- UI consumes adapters or application services; it should not own gameplay state.
- Base game content lives under `src/data/`; mods extend or override content through the mod loader.

## Godot Project Settings

- Main scene: `res://src/main.tscn`.
- Autoloads: `EventHooks`, `GDAIMCPRuntime`, `GameState`, `ModLoader`.
- Renderer feature: `4.6`, `Forward Plus`.
- Physics engine: `Jolt Physics`.
- This repository currently has no C# sources, so `.NET` project settings should stay absent unless C# is intentionally introduced.

## MCP Runtime Model

- `godot-mcp` uses headless Godot CLI operations plus runtime TCP interaction when its interaction server is installed.
- The GDAI MCP plugin is a binary GDExtension plugin and should be treated as an external integration boundary.
- MCP build output is generated and ignored at `tools/godot-mcp/build/`.
