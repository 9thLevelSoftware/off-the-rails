# Technical Debt

Track known cleanup work here so it is visible to future agents.

## Active

- Build a real Godot scene test harness that can run gameplay test scenes and convert logged failures into non-zero exit codes.
- Add deeper GDScript dependency checks once module boundaries are stable enough to enforce without noisy false positives.
- Review generated asset tooling output and decide which logs should remain tracked under `tools/pixellab-api/scripts/`.
- Decide whether `McpInteractionServer` should be installed as a project autoload for runtime MCP tools.
- Convert stale `.planning/` summaries that still contain useful current decisions into `docs/engineering/` or `docs/design/`.

## Closed

- Removed stale duplicate agent guidance by delegating `CLAUDE.md` to `AGENTS.md`.
- Removed unused `.NET` project settings while the repository has no C# sources.
- Added root validation and CI entrypoints.
