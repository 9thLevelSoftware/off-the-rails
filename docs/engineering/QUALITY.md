# Quality

## Current Scorecard

| Area | Status | Notes |
| --- | --- | --- |
| Repository knowledge | Improving | Source of truth moved to `docs/`; `.planning/` remains historical. |
| Agent entrypoint | Good | `AGENTS.md` is concise and `CLAUDE.md` delegates to it. |
| MCP TypeScript tests | Good | Vitest suite currently covers utilities, tool definitions, and handlers. |
| Godot validation | Improving | Headless script check exists; scene-level gameplay tests still need a harness. |
| CI | Improving | Root GitHub Actions run standards, MCP, and Godot validation. |
| Architecture enforcement | Basic | Standards checker enforces high-signal invariants; deeper dependency linting can be added later. |

## Quality Bar

- Every change should have a clear validation command.
- Agent-readable docs should be current enough to guide implementation without chat history.
- Mechanical checks should encode repeated review feedback.
- New standards should be enforceable before they are treated as mandatory.
