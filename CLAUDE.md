# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

OffTheRails is a Godot 4.6 game project with integrated MCP (Model Context Protocol) tooling for AI-assisted development. The project combines two MCP systems:

1. **GDAI MCP Plugin** (`addons/gdai-mcp-plugin-godot/`) - Binary GDExtension plugin from gdaimcp.com
2. **Godot MCP Server** (`tools/godot-mcp/`) - TypeScript MCP server with 149+ tools for full Godot control

## Commands

### Godot MCP Server (tools/godot-mcp/)

```bash
# Build the MCP server
cd tools/godot-mcp && npm install && npm run build

# Run tests (390 tests via Vitest)
cd tools/godot-mcp && npm test

# Watch mode for tests
cd tools/godot-mcp && npm run test:watch

# Inspect MCP server with MCP Inspector
cd tools/godot-mcp && npm run inspector

# Build with watch mode during development
cd tools/godot-mcp && npm run watch
```

### Godot Project

The project uses Godot 4.6 with Forward Plus renderer and Jolt Physics engine.

## Architecture

### MCP Server Communication

The godot-mcp server uses two communication channels:

1. **Headless CLI** - For scene/resource operations without running game. Runs Godot with `--headless --script godot_operations.gd <operation> <json_params>`.

2. **TCP Socket (port 9090)** - For runtime interaction with running game. The `mcp_interaction_server.gd` autoload listens for JSON commands from the TypeScript MCP server.

### Source Layout (tools/godot-mcp/)

| Path | Purpose |
|------|---------|
| `src/index.ts` | MCP server entry point, all 149 tool definitions and handlers |
| `src/utils.ts` | Pure utility functions: parameter mapping, validation, type conversion |
| `build/scripts/godot_operations.gd` | Headless GDScript runner for file-based operations |
| `build/scripts/mcp_interaction_server.gd` | TCP autoload for runtime game control |
| `tests/` | Vitest test suite: utils (31), tool-definitions (157), handlers (202) |

### Autoloads

The project has `GDAIMCPRuntime` autoloaded from the GDAI plugin. For godot-mcp runtime tools, `McpInteractionServer` must be added as an autoload.

### Type Conversion

The MCP server handles automatic conversion between JSON and Godot types: Vector2/3, Color, Quaternion, Basis, Transform2D/3D, AABB, Rect2, and all PackedArray types. Property type detection uses node's `get_property_list()`.

## GDAI Plugin Structure

The GDAI plugin (`addons/gdai-mcp-plugin-godot/`) is a commercial binary GDExtension:
- `gdai_mcp_plugin.gd` - Editor plugin that validates OS/architecture and loads native library
- `gdai_mcp_runtime.gd` - Autoload that instantiates `GDAIRuntimeServer` at runtime
- `bin/` - Platform-specific binaries (windows/, linux/, macos/)
- `gdai_mcp_server.py` - Python MCP server script

## MCP Client Configuration

Project-level config is in `.mcp.json`. For other MCP clients, add to your config:
```json
{
  "mcpServers": {
    "godot-mcp": {
      "command": "node",
      "args": ["C:\\Users\\dasbl\\Documents\\off-the-rails\\tools\\godot-mcp\\build\\index.js"],
      "env": {
        "GODOT_PATH": "C:\\Users\\dasbl\\Documents\\Godot\\Godot_v4.6.2-stable_mono_win64.exe",
        "DEBUG": "true"
      }
    },
    "gdai-mcp": {
      "command": "uv",
      "args": ["run", "C:\\Users\\dasbl\\Documents\\off-the-rails\\addons\\gdai-mcp-plugin-godot\\gdai_mcp_server.py"],
      "env": {
        "GDAI_MCP_SERVER_PORT": "3571"
      }
    }
  }
}
```

## Godot Project Settings

- Engine: Godot 4.6
- Renderer: Forward Plus
- Physics: Jolt Physics
- .NET assembly name: OffTheRails
