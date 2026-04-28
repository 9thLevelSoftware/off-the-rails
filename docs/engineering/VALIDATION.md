# Validation

Run commands from the repository root unless noted.

## Canonical Commands

```bash
python tools/validate.py --standards
python tools/validate.py --godot
python tools/validate.py --mcp
python tools/validate.py --all
```

## What Each Check Covers

- `--standards` validates repo knowledge indexes, agent entrypoints, generated artifact rules, Godot project settings, Node runtime metadata, and basic architecture boundaries.
- `--godot` runs Godot headlessly with `tools/godot/check_project.gd` and fails on project errors.
- `--mcp` runs `npm ci --ignore-scripts`, `npm audit --audit-level=moderate`, `npm test`, and `npm run build` in `tools/godot-mcp`.
- `--all` runs standards, Godot, then MCP checks.

## Local Godot Resolution

`tools/validate.py --godot` resolves the first non-Mono Godot 4.6.2 executable in this order:

1. `GODOT_PATH` environment variable.
2. `.mcp.json` `godot-mcp.env.GODOT_PATH`.
3. `godot` on `PATH`.

CI sets `GODOT_PATH` to an official non-Mono Godot 4.6.2 stable Linux binary. The validator fails on Godot errors except for the known GDAI cleanup line `Capture not registered: 'gdaimcp'.`, which is emitted after the project check has already completed.

## CI

Root GitHub Actions workflows live under `.github/workflows/` and call the same validation entrypoint as local agents.
