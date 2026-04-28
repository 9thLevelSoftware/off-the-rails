# Engineering Standards

These standards adapt the Harness engineering model to this Godot repository: make the repo legible to agents, enforce what matters mechanically, and keep cleanup continuous.

## Repository Knowledge

- `AGENTS.md` stays short and points to `docs/`.
- Current docs live under `docs/`; `.planning/archive/` is historical.
- Complex work gets an execution plan in `docs/engineering/exec-plans/active/`.
- Completed execution plans move to `docs/engineering/exec-plans/completed/`.
- Stale facts in agent entrypoints are treated as validation failures.

## Mechanical Invariants

- `python tools/validate.py --standards` must pass before merging standards, docs, or tooling changes.
- Generated artifacts are not committed: `__pycache__`, `*.pyc`, `node_modules`, `.godot`, and `tools/godot-mcp/build`.
- `project.godot` must remain Godot 4.6, Forward Plus, Jolt Physics, and free of unused `.NET` settings while no C# files exist.
- `CLAUDE.md` delegates to `AGENTS.md` instead of duplicating instructions.
- `tools/godot-mcp/package.json` and lockfile keep Node 24.x as the repository tooling runtime.

## Coding Expectations

- Prefer existing module patterns over new abstractions.
- Keep domain code independent from Godot scene/UI concerns where the current structure supports it.
- Add tests or validation when changing behavior.
- Do not revert unrelated dirty worktree changes.
- If validation exposes a pre-existing issue, call it out and either fix it in scope or record it in `docs/engineering/TECH_DEBT.md`.

## CI Philosophy

CI mirrors local validation instead of inventing a separate gate. Jobs should be small, explicit, time-boxed, and read-only unless a workflow is specifically intended to publish artifacts.
