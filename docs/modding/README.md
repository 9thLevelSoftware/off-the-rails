# Modding Documentation

Modding docs describe the supported extension surface for content packs and scripts.

## Start Here

- [Getting Started](getting-started.md)
- [Mod API Reference](mod-api-reference.md)

## Current Mod Architecture

- Mods are discovered from `user://mods/`.
- Each mod uses a `mod.json` manifest.
- Content data extends or overrides base registries through the mod loader.
- Scripts interact through `ModAPI` and `EventHooks`.
