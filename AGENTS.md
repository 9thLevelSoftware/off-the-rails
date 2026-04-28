# AGENTS.md

Short agent map for Off The Rails. Keep this file compact; repository knowledge belongs in `docs/`.

## Project

Off The Rails is a Godot 4.6.2 isometric co-op PvE game prototype with mod-first content loading and MCP tooling for agent-assisted Godot work.

## Source Of Truth

- `docs/README.md` - repository knowledge index.
- `docs/engineering/ARCHITECTURE.md` - current architecture and source layout.
- `docs/engineering/STANDARDS.md` - agent-first engineering standards and invariants.
- `docs/engineering/VALIDATION.md` - canonical local and CI validation commands.
- `docs/engineering/QUALITY.md` - current quality scorecard and known gaps.
- `docs/engineering/TECH_DEBT.md` - cleanup backlog.
- `docs/design/README.md` - design documentation index.
- `docs/modding/README.md` - modding documentation index.
- `.planning/archive/` - historical plans only; do not treat as current state.

## Canonical Commands

Run from the repository root unless noted.

```bash
python tools/validate.py --standards
python tools/validate.py --godot
python tools/validate.py --mcp
python tools/validate.py --all
```

MCP package commands, when working directly in `tools/godot-mcp/`:

```bash
npm ci --ignore-scripts
npm audit --audit-level=moderate
npm test
npm run build
npm run inspector
```

Symphony daemon commands, when working in `tools/symphony/`:

```bash
npm install && npm run build
npm test
```

## Runtime Assumptions

- Godot: 4.6.2 stable.
- Renderer: Forward Plus.
- Physics: Jolt Physics.
- Node: 24.x LTS for repository tooling.
- `tools/validate.py --godot` uses the first non-Mono Godot 4.6.2 executable found from `GODOT_PATH`, `.mcp.json`, then `godot` on `PATH`.

## Architecture Rules

- Prefer existing Godot patterns and current domain boundaries before adding abstractions.
- Keep domain logic independent of scenes, UI, adapters, and infrastructure.
- Keep generated files out of git; use validation to catch `__pycache__`, `*.pyc`, `node_modules`, `.godot`, and MCP build output.
- Put long-lived decisions in `docs/engineering/`; use `docs/engineering/exec-plans/active/` for complex multi-step work.
- Preserve user work in a dirty tree. Do not revert or clean unrelated changes without explicit instruction.
- Use Conventional Commits: `feat:`, `fix:`, `refactor:`, `test:`, `docs:`.

## Validation Expectations

- Run `python tools/validate.py --all` after code or standards changes.
- For narrow documentation-only edits, run at least `python tools/validate.py --standards`.
- Treat pre-existing validation failures as work to understand and report, not as noise to ignore.

## Linear/Symphony Workflow

- Symphony agents work from Linear tickets and should maintain one persistent `## Codex Workpad` comment per ticket.
- Status flow: `Todo` -> `In Progress` -> `Human Review` -> `Merging` -> `Done`; use `Rework` for requested changes.
- Move `Todo` tickets to `In Progress` before implementation.
- Keep the workpad checklist, acceptance criteria, validation evidence, blockers, and PR state current.
- Use the injected `linear_graphql` tool for Linear reads/writes when available.
- If external auth or secrets are missing, record the exact blocker in the workpad and stop without fabricating progress.

## GitHub/PR Expectations

- Create a branch per task from the latest remote default branch.
- Keep PRs small and tied to the Linear ticket.
- Before requesting review, run the relevant validation, push the branch, link the PR to the ticket, and confirm actionable PR feedback has been addressed or explicitly answered.

## Godot Design Constraints

- Preserve the isometric foundation: 64x32 tile assumptions, Y-sorting, and 2D isometric movement conventions.
- Keep mod-facing systems data-driven and documented in `docs/modding/` when behavior changes.
- For gameplay features, prefer deterministic domain tests where possible, then scene/runtime validation where behavior depends on Godot nodes.
