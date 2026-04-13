# Phase 2 Context: Player & Movement

## Phase Goal

Create a playable character with smooth movement and camera controls that can navigate between Train and Expedition scenes.

## Requirements

| ID | Description |
|----|-------------|
| R1 | Single-player gameplay (networking deferred to V2) |

## Success Criteria

- [ ] Player character moves with WASD + mouse
- [ ] Camera follows player appropriately
- [ ] Player can transition between Train and Expedition scenes
- [ ] Basic collision and physics work with Jolt

## Existing Assets

From Phase 1:
- `src/` directory structure with 6 subdirectories
- `src/autoloads/game_state.gd` — GameState autoload with signals and methods
- Main scene with additive loading pattern
- 205 .tres resources generated from YAML data pipeline

From CODEBASE.md:
- Godot 4.6 with Jolt Physics engine
- Forward Plus renderer
- Hybrid language approach (GDScript for gameplay, C# for networking later)

## Key Design Decisions

- **Architecture approach**: Pragmatic — player as CharacterBody3D with camera as child node, GameState handles scene transitions
- **Camera style**: Third-person follow camera (adjustable later for different perspectives)
- **Input handling**: Godot's built-in Input singleton with actions configured in project settings
- **Scene persistence**: Player position/state preserved in GameState during transitions

## Plan Structure

| Plan | Wave | Name | Agent(s) |
|------|------|------|----------|
| 02-01 | 1 | Player Character & Movement | engineering-senior-developer |
| 02-02 | 2 | Scene Integration & Transitions | engineering-senior-developer, testing-qa-verification-specialist |

## Constraints

- No multiplayer/RPC code in V1
- Use GDScript (not C#) for all gameplay code
- Leverage Jolt Physics (not default Godot physics)
- MCP-driven development using gdai-mcp tools

## Open Questions (from Design Docs)

Relevant to this phase:
- How does death work? (Defer — implement basic respawn for now)
- Solo play story? (Not addressed in V1 scope)

---
*Generated: 2026-04-13*
