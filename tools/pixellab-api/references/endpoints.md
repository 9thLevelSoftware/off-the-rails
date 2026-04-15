# PixelLab v2 API — Endpoint Reference

Base URL: `https://api.pixellab.ai/v2`
Auth: `Authorization: Bearer <token>`

## Table of Contents
1. [Account](#account)
2. [Image Generation](#image-generation)
3. [Characters](#characters)
4. [Animation](#animation)
5. [Tilesets](#tilesets)
6. [Map Objects](#map-objects)
7. [UI Generation](#ui-generation)
8. [Editing](#editing)
9. [Image Operations](#image-operations)
10. [Rotation](#rotation)
11. [Background Jobs](#background-jobs)

---

## Account

### GET /balance
Returns credits (USD) and subscription generations remaining.

---

## Image Generation

### POST /generate-image-v2 (Pro) — ASYNC
Generate pixel art from text.
- `description` (str, required, max 2000)
- `image_size` (required): `width` (16-792), `height` (16-688)
- `seed` (int|null), `no_background` (bool)
- `reference_images` (array, up to 4) — optional subject guidance
- `style_image` (object|null) — pixel size/style reference
- `style_options`: `color_palette`, `outline`, `detail`, `shading` (all bool, default true)

### POST /create-image-pixflux — SYNC
General pixel art generation. Good all-rounder.
- `description` (str, required)
- `image_size`: `width` (16-400), `height` (16-400)
- `text_guidance_scale` (1.0-20.0, default 8)
- `outline`, `shading`, `detail`, `view`, `direction` (all optional strings)
- `isometric` (bool), `no_background` (bool)
- `init_image` (base64 object|null), `init_image_strength` (1-999, default 300)
- `color_image` (base64 object|null) — force color palette
- `seed` (int|null)

### POST /create-image-bitforge — SYNC
Small-medium sprites, supports style transfer.
- `description` (str, required)
- `image_size`: `width` (16-200), `height` (16-200)
- `text_guidance_scale` (1.0-20.0, default 8.0)
- `style_strength` (0-100, default 0), `style_image` (base64|null)
- `outline`, `shading`, `detail`, `view`, `direction` (optional)
- `isometric` (bool), `oblique_projection` (bool), `no_background` (bool)
- `coverage_percentage` (number|null)
- `inpainting_image`, `mask_image` (base64|null)
- `skeleton_keypoints` (array|null), `skeleton_guidance_scale` (0-5, default 1)
- `seed` (int|null)

### POST /generate-with-style-v2 (Pro) — ASYNC
Match the style of reference images.
- `style_images` (array of base64 objects, 1-4, required)
- `description` (str, required, max 2000)
- `image_size`: `width` (16-512), `height` (16-512)
- `style_description` (str|null)
- `seed`, `no_background`

---

## Characters

### POST /create-character-with-4-directions — ASYNC
- `description` (str, required, max 2000)
- `image_size`: `width` (16-128), `height` (16-128) — character size, canvas ~40% larger
- `outline` (`thin`|`medium`|`thick`|`none`), `shading` (`soft`|`hard`|`flat`|`none`), `detail` (`low`|`medium`|`high`)
- `view` (`side`|`low top-down`|`high top-down`|`perspective`)
- `template_id` (`mannequin` default, or `bear`|`cat`|`dog`|`horse`|`lion`)
- `isometric` (bool), `color_image`, `force_colors` (bool), `seed` (int|null)
Returns: `background_job_id`, `character_id`

### POST /create-character-with-8-directions — ASYNC
Same as 4-dir plus: `mode` (`standard`|`pro`)

### POST /animate-character — ASYNC
- `character_id` (str, required)
- `action_description` (str|null) — required for custom mode
- `mode` (`template`|`v3`|`pro`), `template_animation_id` (str|null)
- Available templates: `backflip`, `breathing-idle`, `cross-punch`, `crouched-walking`, `crouching`, `drinking`, `falling-back-death`, `fight-stance-idle-8-frames`, `fireball`, `flying-kick`, `idle`, `jump`, `melee-attack`, `pick-up`, `run`, `walk`
- `frame_count` (4-16, even, v3 mode only)
- `directions` (array|null), `seed`

### GET /characters — List (limit, offset)
### GET /characters/{id} — Details
### DELETE /characters/{id}
### GET /characters/{id}/zip — Export ZIP

---

## Animation

### POST /animate-with-text-v3 — SYNC
- `first_frame` (base64, required), `last_frame` (base64|null)
- `action` (str, required, max 500), `frame_count` (4-16, default 8, even)
- `seed`, `no_background`

### POST /animate-with-text-v2 (Pro) — ASYNC
- `reference_image` (base64, required), `reference_image_size` (32-256)
- `action` (str, required), `image_size` (32-256)
- `view`, `direction`, `seed`, `no_background`

### POST /animate-with-skeleton — SYNC
- `reference_image` (required), `skeleton_keypoints` (array)
- `image_size` (16-256), `guidance_scale` (1-20, default 4)

### POST /edit-animation-v2 (Pro) — ASYNC
- `description` (required), `frames` (2-16), `image_size` (16-256)

### POST /interpolation-v2 (Pro) — ASYNC
- `start_image`, `end_image` (base64+size), `action` (required), `image_size` (16-128)

### POST /transfer-outfit-v2 (Pro) — ASYNC
- `reference_image` (base64+size), `frames` (2-16), `image_size` (32-256)

### POST /estimate-skeleton — SYNC
- `image` (base64, required) — returns keypoints

---

## Tilesets

### POST /tilesets — ASYNC (Wang tileset)
- `lower_description`, `upper_description` (required)
- `tile_size`: 16 or 32, `transition_size` (0.0|0.25|0.5|1.0)
- `view` (`low top-down`|`high top-down`)
- `tile_strength`, `tileset_adherence_freedom`, `tileset_adherence`
- Reference images: `lower_reference_image`, `upper_reference_image`, `transition_reference_image`

### POST /tilesets-sidescroller — ASYNC
- `lower_description` (required), `transition_description`
- Same style/adherence params

### POST /create-isometric-tile — ASYNC
- `description`, `image_size` (16-64), `isometric_tile_shape` (`thin tile`|`thick tile`|`block`)

### POST /create-tiles-pro — ASYNC
- `description` — number variations: "1). grass 2). stone"
- `tile_type` (`hex`|`hex_pointy`|`isometric`|`octagon`|`square_topdown`)
- `tile_size` (16-256), `tile_view`, `style_images`, `seed`
- NOTE: `n_tiles` param is documented but REJECTED by API — count auto-detected from description

### GET /tilesets/{id}, /isometric-tiles/{id}, /tiles-pro/{id}

---

## Map Objects

### POST /map-objects — ASYNC
- `description`, `image_size` (32-400), `view` (`low top-down`|`high top-down`|`side`)
- **Different enums than characters:**
  - `outline`: `single color outline`|`selective outline`|`lineless`
  - `shading`: `flat shading`|`basic shading`|`medium shading`|`detailed shading`
  - `detail`: `low detail`|`medium detail`|`high detail`
- `inpainting` (mask|oval|rectangle), `background_image`, `seed`

### POST /create-object-with-4-directions — ASYNC
- `description`, `image_size` (32-256), style params, `seed`

### GET /objects, /objects/{id}, DELETE /objects/{id}

---

## UI Generation

### POST /generate-ui-v2 (Pro) — ASYNC
- `description`, `image_size` (16-792 x 16-688), `color_palette` (str), `concept_image`, `seed`

---

## Editing

### POST /edit-images-v2 (Pro) — ASYNC
- `method` (`edit_with_text`|`edit_with_reference`), `edit_images` (1-16), `image_size` (32-512)

### POST /edit-image — ASYNC
- `image` (base64), `description`, `image_size` (16-400), `seed`

### POST /inpaint-v3 (Pro) — ASYNC
- `description`, `inpainting_image`, `mask_image` (white=paint), `crop_to_mask`

### POST /inpaint — SYNC
- `description`, `image_size` (16-200), `inpainting_image`, `mask_image`

---

## Image Operations

### POST /remove-background — SYNC
- `image`, `image_size` (1-400), `background_removal_task`

### POST /image-to-pixelart — SYNC
- `image`, `image_size` (16-1280), `output_size` (16-320)

### POST /resize — SYNC
- `reference_image`, `reference_image_size` (16-200), `target_size` (16-200)

---

## Rotation

### POST /generate-8-rotations-v2 (Pro) — ASYNC
- `method`, `reference_image`, `image_size` (32-168), `view`, `seed`

### POST /rotate — SYNC
- `from_image`, `image_size` (16-200), view/direction change params

---

## Background Jobs

### GET /background-jobs/{job_id}
- `status`: `processing`, `completed`, `failed`
- Completed data in `last_response` field
- 404 if not found, 423 if still processing (for direct resource endpoints)
