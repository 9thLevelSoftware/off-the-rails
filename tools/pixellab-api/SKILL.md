---
name: pixellab-api
description: Generate pixel art game assets using the PixelLab v2 API — characters, animations, tilesets, isometric tiles, map objects, UI elements, and more. Use this skill whenever the user wants to create, generate, or produce pixel art sprites, game tiles, character sheets, animations, tilesets, map objects, or UI elements. Also use when the user mentions PixelLab, pixel art generation, sprite creation, or needs game-ready 2D assets. Trigger this skill even for vague requests like "make me a character" or "I need tiles for my map" when the context involves pixel art or game development.
---

# PixelLab v2 API — Pixel Art Asset Generation

## Overview

PixelLab is an AI pixel art generation API. This skill covers the **v2 API** which includes Pro endpoints, background job processing, character management, and specialized game asset generators (tilesets, isometric tiles, map objects, UI elements).

The official Python SDK (`pip install pixellab`) only covers v1 and is missing most v2 endpoints. Use the bundled wrapper script at `scripts/pixellab.py` instead.

## Setup

1. Read `scripts/pixellab.py` into your working directory
2. The API key and base URL are preconfigured in the script
3. Install dependencies: `pip install requests Pillow --break-system-packages`

```python
import sys
sys.path.insert(0, "/path/to/skill/scripts")
from pixellab import PixelLab
pl = PixelLab()
```

## Core Concepts

### Sync vs Async Endpoints

**Sync endpoints** return image data directly in the response. Fast, single-generation calls:
- `generate_image_pixflux` — General images up to 400x400
- `generate_image_bitforge` — Small sprites up to 200x200
- `animate_with_text_v3` — Animation from first frame + action

**Async endpoints** return a `background_job_id`. You must poll for completion:
- `generate_image_pro` — Pro image generation
- `create_character_4dir` / `create_character_8dir` — Multi-direction characters
- `animate_character` — Character animations
- `create_tileset` — Wang tilesets
- `create_isometric_tile` — Isometric tiles
- `create_tiles_pro` — Advanced tile generation
- `create_map_object` — Map objects (transparent bg)
- `generate_ui` — UI elements
- `generate_8_rotations` — 8-rotation views
- All `_v2` edit/animate endpoints

**Polling pattern for async jobs:**
```python
result = pl.create_character_4dir("knight with plate armor", width=48, height=48)
job_id = result.get("background_job_id")
completed = pl.poll_job(job_id, interval=3, max_wait=180)
```

Or use the convenience method:
```python
result = pl.create_character_4dir("knight in armor", width=48, height=48)
saved_files = pl.wait_and_save(result, "knight")
```

### Image Format

All images use base64-encoded data. The wrapper handles encoding/decoding. When you need to pass an existing image to an endpoint (e.g., for editing or animation), read it and base64-encode:

```python
import base64
with open("sprite.png", "rb") as f:
    b64 = base64.b64encode(f.read()).decode()
```

## Endpoint Selection Guide

Pick the right endpoint based on what you're creating:

### Characters (multi-direction sprites)
| Need | Endpoint | Notes |
|------|----------|-------|
| Character facing 4 directions (S/W/E/N) | `create_character_4dir` | Async. Best starting point. |
| Character facing 8 directions | `create_character_8dir` | Async. `mode="standard"` or `"pro"`. |
| Animate existing character | `animate_character` | Async. Pass `character_id`. Use `template_animation_id` for preset anims or `action_description` for custom. |
| List/get/export characters | `list_characters`, `get_character`, `export_character_zip` | Management endpoints. |

**Template animation IDs** (partial list): `backflip`, `breathing-idle`, `cross-punch`, `crouched-walking`, `crouching`, `drinking`, `falling-back-death`, `fight-stance-idle-8-frames`, `fireball`, `flying-kick`, `idle`, `jump`, `melee-attack`, `pick-up`, `run`, `walk`

**Character creation parameters:**
- `template_id`: `"mannequin"` (humanoid, default), `"bear"`, `"cat"`, `"dog"`, `"horse"`, `"lion"` (quadrupeds)
- `outline`: `"thin"`, `"medium"`, `"thick"`, `"none"`
- `shading`: `"soft"`, `"hard"`, `"flat"`, `"none"`
- `detail`: `"low"`, `"medium"`, `"high"`
- `view`: `"side"`, `"low top-down"`, `"high top-down"`

### Single Images / Sprites
| Need | Endpoint | Notes |
|------|----------|-------|
| General pixel art (med-large) | `generate_image_pixflux` | Sync. Up to 400x400. Good all-rounder. |
| Small sprites (items, icons) | `generate_image_bitforge` | Sync. Up to 200x200. Style transfer support. |
| High-quality pro generation | `generate_image_pro` | Async. Up to 792x688. Reference/style images. |

### Tiles & Tilesets
| Need | Endpoint | Notes |
|------|----------|-------|
| Top-down Wang tileset (2 terrains) | `create_tileset` | Async. 16 or 32px tiles. Lower + upper terrain with transitions. |
| Sidescroller platform tileset | `create_tileset_sidescroller` | Async. Platform tiles with optional decoration layer. |
| Isometric tiles | `create_isometric_tile` | Async. Shapes: `"thin tile"`, `"thick tile"`, `"block"`. |
| Advanced multi-tile generation | `create_tiles_pro` | Async. Supports hex, isometric, square, octagon. Number descriptions for variations. |

**Tileset tips:**
- `transition_size`: `0.0` (sharp), `0.25`, `0.5`, `1.0` (gradual blend)
- `view` for top-down: `"low top-down"` or `"high top-down"`
- For isometric games, use `create_tiles_pro` with `tile_type="isometric"` and `tile_view="low top-down"`
- `create_tiles_pro` auto-detects tile count from numbered descriptions — do NOT pass `n_tiles` as a parameter (API rejects it)

### Map Objects (environment props)
| Need | Endpoint | Notes |
|------|----------|-------|
| Single object, transparent bg | `create_map_object` | **Async** (returns job_id). Views: `"low top-down"`, `"high top-down"`, `"side"`. |
| Object with 4 rotations | `create_object_4dir` | Async. 4 cardinal direction views. |

**Map object enum values differ from character endpoints:**
- `outline`: `"single color outline"`, `"selective outline"`, `"lineless"` (NOT thin/medium/thick)
- `shading`: `"flat shading"`, `"basic shading"`, `"medium shading"`, `"detailed shading"` (NOT soft/hard/flat)
- `detail`: `"low detail"`, `"medium detail"`, `"high detail"` (NOT just low/medium/high)

### Animation
| Need | Endpoint | Notes |
|------|----------|-------|
| Animate from first frame | `animate_with_text_v3` | Sync. Provide first frame + action text. 4-16 frames. |
| Animate existing character | `animate_character` | Async. Template or custom. |
| Edit animation frames | `edit_animation_v2` (use `_post`) | Async. Text-based edit on 2-16 frames. |
| Interpolate between keyframes | `interpolation_v2` (use `_post`) | Async. Tweening between two images. |

### UI Elements
| Need | Endpoint | Notes |
|------|----------|-------|
| Game UI (buttons, bars, frames) | `generate_ui` | Async. Optional `color_palette` string. |

### Editing & Operations
| Need | Endpoint | Notes |
|------|----------|-------|
| Edit existing image with text | `edit_image` | Async. Describe the change. |
| Remove background | `remove_background` | Sync. Simple or complex mode. |
| Convert photo to pixel art | `image_to_pixelart` | Sync. Specify input and output sizes. |
| Rotate character/object | `generate_8_rotations` | Async. From reference image. |

## Prompt Engineering for PixelLab

Good descriptions are critical. The API responds best to:

**Characters:** Focus on key visual features, not backstory. "armored knight with blue cape and iron helmet, side view" beats "Sir Galahad the brave who fought many dragons".

**Tiles:** Describe the material/terrain, not the location. "dark stone brick floor with moss in cracks" beats "dungeon floor".

**Objects:** Be specific about the object and its visual style. "rusty metal barrel with hazard symbol, slight dents" beats "barrel".

**Style parameters matter:**
- `outline="thin"` + `shading="soft"` + `detail="high"` -> Clean, detailed sprites (good for PZ-style)
- `outline="none"` + `shading="flat"` + `detail="low"` -> Minimalist/retro look
- `view` should match your game perspective consistently

## Response Handling

Async job responses look like:
```json
{
  "background_job_id": "uuid-here",
  "character_id": "uuid-here",
  "status": "processing"
}
```

When polled via `GET /background-jobs/{job_id}`, completed jobs return:
```json
{
  "id": "job-uuid",
  "status": "completed",
  "last_response": { ... }
}
```

**Image formats in responses:**
- **Map objects**: `last_response.image` = base64 PNG string
- **Characters (4dir/8dir)**: `last_response.images` = dict keyed by direction (`south`, `west`, `north`, `east`), each with `type: "rgba_bytes"`, `width`, `height`, `base64`
- **Tiles**: `last_response.images` = array of objects, each with `type: "rgba_bytes"`, `width`, `height`, `base64`
- **Character canvas size**: ~40% larger than the requested `image_size` (e.g., requesting 48x48 yields 68x68 canvas)

**`rgba_bytes` format** means the base64 data is raw RGBA pixel data, NOT a PNG. The wrapper converts this to PNG using PIL. If handling manually:
```python
from PIL import Image
import base64
raw = base64.b64decode(b64_string)
img = Image.frombytes("RGBA", (width, height), raw)
img.save("output.png")
```

## Budget Awareness

Check with `pl.balance()`. Different endpoints cost different amounts:
- Standard character (4dir): ~4 generations
- Pro character (8dir pro mode): ~20-40 generations
- Single image: ~1 generation
- Tileset: ~16-23 generations (depends on transition_size)
- Animation: varies by frame count and directions

Use `seed` parameter for reproducible results when iterating on prompts.

## Common Workflows

### New character for a game
```python
result = pl.create_character_4dir(
    "survivor in torn jumpsuit with tool belt, post-apocalyptic",
    width=48, height=48,
    outline="thin", shading="soft", detail="high",
    view="low top-down"
)
char_id = result.get("character_id")
job_id = result.get("background_job_id")
completed = pl.poll_job(job_id)

anim_result = pl.animate_character(
    char_id, template_animation_id="walk", mode="template"
)
pl.poll_job(anim_result.get("background_job_id"))

zip_data = pl.export_character_zip(char_id)
```

### Isometric tileset for a game map
```python
result = pl.create_tiles_pro(
    description="1). weathered metal floor plate 2). rusted grated floor 3). mossy stone tile",
    tile_type="isometric",
    tile_size=32,
    tile_view="low top-down"
)
job_id = result.get("background_job_id")
completed = pl.poll_job(job_id)
saved = pl._save_result_images(completed, "floor_tiles")
```

## Reference

For the complete API endpoint documentation with all parameters, read `references/endpoints.md`.
