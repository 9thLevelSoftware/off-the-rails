# Off The Rails — Asset Generation via PixelLab API

## Your Role

You are generating pixel art game assets for "Off The Rails", an isometric co-op PvE survival game built in Godot 4.6. You will systematically work through an asset production list, calling the PixelLab v2 API to generate each asset, validating the output, and organizing the results.

## Project Context

- **Art Style:** PZ-tier isometric pixel art (Project Zomboid reference). Detailed, not retro 8-bit.
- **Perspective:** Isometric, 2:1 ratio, "low top-down" view. Use this consistently across ALL assets.
- **Characters:** 48px target size (canvas will be ~68px due to PixelLab's ~40% padding).
- **Tiles:** 64px for isometric floor tiles via `create_tiles_pro`. 32px is too small — always use 64.
- **Map Objects:** 64x64 minimum, 96x96 for larger equipment. Transparent backgrounds.
- **Item Icons:** 32x32 via `generate_image_bitforge`.
- **Setting:** Post-apocalyptic colony world. Overgrown ruins, salvaged tech, industrial decay. NOT fantasy/medieval.

## API Setup


**Base URL:** `https://api.pixellab.ai/v2`
**API Key:** `2f70a6be-6c63-4599-a0e6-666359a3ce81`
**Auth Header:** `Authorization: Bearer {API_KEY}`
**Budget:** 5,000 subscription generations. Check balance with `GET /balance` periodically.

Install dependencies: `pip install requests Pillow`

The wrapper script is at: `C:\Users\dasbl\Documents\off-the-rails\tools\pixellab-api\scripts\pixellab.py`
Copy it to your working directory and import it:

```python
from pixellab import PixelLab
pl = PixelLab()
```

The wrapper's `output_dir` defaults to `./pixellab_output` — change it if needed:
```python
pl.output_dir = Path("/path/to/your/output")
```

## Critical API Behavior (Learned from Testing)

1. **Almost everything is async.** Most endpoints return `{"background_job_id": "uuid", "status": "processing"}`. You must poll `GET /background-jobs/{job_id}` until `status == "completed"`.

2. **Results are in `last_response`, NOT `data`.** When a job completes:
   ```json
   {"id": "...", "status": "completed", "last_response": { ...actual images here... }}
   ```

3. **Images use `rgba_bytes` format** — raw RGBA pixel data (base64 encoded), NOT base64 PNG. Convert with:
   ```python
   from PIL import Image
   import base64
   raw = base64.b64decode(b64_string)
   img = Image.frombytes("RGBA", (width, height), raw)
   img.save("output.png")
   ```
   The wrapper's `_save_result_images(result, prefix)` handles this automatically.

4. **Map objects use DIFFERENT enum values than characters:**
   - Characters: `outline="thin"`, `shading="soft"`, `detail="high"`
   - Map objects: `outline="selective outline"`, `shading="detailed shading"`, `detail="high detail"`

5. **`create_tiles_pro` rejects the `n_tiles` parameter.** The API auto-detects tile count from numbered descriptions like `"1). grass 2). stone 3). lava"`. Do NOT pass `n_tiles`.

6. **Character canvas is ~40% larger than requested.** Requesting 48x48 yields ~68x68 canvas.

7. **Character rotations come as direction-keyed dicts:**
   ```json
   {"last_response": {"images": {"south": {...}, "west": {...}, "north": {...}, "east": {...}}}}
   ```

8. **Tile results come as arrays:**
   ```json
   {"last_response": {"images": [{...}, {...}, ...]}}
   ```

## Endpoint Selection Quick Reference

| Asset Type | Endpoint | Key Params |
|-----------|----------|-----------|
| Character (4-dir) | `POST /create-character-with-4-directions` | `description`, `image_size`, `outline`, `shading`, `detail`, `view`, `template_id` |
| Character animation | `POST /animate-character` | `character_id`, `template_animation_id` OR `action_description`, `mode` |
| Isometric tiles | `POST /create-tiles-pro` | `description` (numbered), `tile_type="isometric"`, `tile_size=64`, `tile_view="low top-down"` |
| Map/environment object | `POST /map-objects` | `description`, `image_size`, `view="high top-down"`, uses different enums (see #4) |
| Item icon (small) | `POST /create-image-bitforge` | `description`, `image_size={w:32,h:32}`, `no_background=true` |
| UI element | `POST /generate-ui-v2` | `description`, `image_size`, `color_palette` |
| General image | `POST /create-image-pixflux` | `description`, `image_size`, good for larger one-off images |
| Object with 4 rotations | `POST /create-object-with-4-directions` | `description`, `image_size` |

## Workflow Per Asset

For each asset in the production list:

### Step 1: Generate
- Pick the correct endpoint for the asset type
- Write a descriptive, visual prompt. Focus on materials, colors, and form — not backstory
- Include style params: `outline`, `shading`, `detail`, `view` consistently
- Use a `seed` value so you can reproduce good results (record it)
- Fire the API call

### Step 2: Poll & Save
- If async, poll `GET /background-jobs/{job_id}` every 5 seconds until `status == "completed"`
- Use the wrapper's `_save_result_images(result, prefix)` to extract and save PNGs
- If sync (pixflux/bitforge), save the returned image directly

### Step 3: Validate
Open each saved PNG with PIL and verify:
- **Dimensions are correct** (expected size ± the 40% canvas padding for characters)
- **Mode is RGBA** (transparency preserved)
- **Not blank** — check that the image has non-transparent pixels (`img.getbbox() is not None`)
- **Reasonable file size** — a 64x64 PNG should be >500 bytes
- **Consistent perspective** — all isometric assets should match "low top-down"
- For characters: confirm all 4 (or 8) direction images were generated
- For tiles: confirm expected tile count (usually 16 for isometric sets)

### Step 4: Log
After each asset, append to a generation log (JSON or CSV):
```json
{
  "asset_id": "workshop_floor_tiles",
  "category": "train_tiles",
  "endpoint": "create-tiles-pro",
  "prompt": "the description used",
  "seed": 12345,
  "job_id": "uuid",
  "character_id": "uuid or null",
  "files_generated": ["tile_0.png", "tile_1.png", ...],
  "dimensions": "64x64",
  "validation": "pass",
  "notes": "",
  "generations_used": 1,
  "timestamp": "2026-04-14T..."
}
```

### Step 5: Organize Output
Save assets to this structure under the project directory:
```
C:\Users\dasbl\Documents\off-the-rails\assets\generated\
├── characters\
│   ├── survivor\
│   │   ├── south.png, west.png, north.png, east.png
│   │   └── walk\  (animation frames)
│   ├── engineer\
│   ├── medic\
│   └── ...
├── enemies\
│   ├── swarmer\
│   ├── ambusher\
│   └── ...
├── train\
│   ├── workshop\
│   │   ├── floor\  (tile PNGs)
│   │   ├── walls\
│   │   └── equipment\  (workbench.png, tool_rack.png, ...)
│   ├── engine\
│   └── ...
├── expeditions\
│   ├── small_town\
│   │   ├── terrain\
│   │   └── props\
│   └── ...
├── icons\
│   ├── resources\
│   ├── consumables\
│   ├── ammo\
│   ├── medical\
│   ├── tools\
│   ├── equipment\
│   └── abilities\
├── ui\
│   ├── hud\
│   ├── inventory\
│   ├── crafting\
│   └── menus\
└── generation_log.json
```

## Style Consistency Rules

Apply these parameters consistently across ALL assets in a category:

**Characters (players + enemies):**
```python
outline="thin", shading="soft", detail="high", view="low top-down", template_id="mannequin"
```

**Isometric Tiles (train + expedition):**
```python
tile_type="isometric", tile_size=64, tile_view="low top-down"
```

**Map Objects (equipment + props):**
```python
view="high top-down", outline="selective outline", shading="detailed shading", detail="high detail"
# Use 64x64 for small objects, 96x96 for large equipment
```

**Item Icons:**
```python
# via generate_image_bitforge
width=32, height=32, no_background=True, outline="thin", detail="high"
```

**Prompt Style Guide:**
- Describe MATERIALS and VISUAL FEATURES, not backstory or function
- Always include the setting context: "post-apocalyptic", "colony world", "industrial salvage"
- For consistency, reference "pixel art" in prompts
- Good: "rusty metal workbench with vise grip and scattered tools, industrial, post-apocalyptic, isometric pixel art"
- Bad: "a workbench where the machinist crafts items for the crew"

## Error Handling

- If an API call returns 422: read the error detail — it usually tells you exactly which enum values are valid
- If an API call returns 429: wait 30 seconds and retry
- If an API call returns 402: stop and report — you're out of generations
- If a job stays in "processing" for over 3 minutes: log it and move on, retry later
- If validation fails (blank image, wrong size): retry with a different seed, adjust prompt if needed
- Keep a separate `failed_assets.json` for anything that needs re-generation

## Budget Management

You have 5,000 generations. Approximate costs:
- Character 4-dir: ~4 gen
- Character 8-dir standard: ~8 gen
- Character 8-dir pro: ~20-40 gen (avoid unless needed)
- Animation (template): ~1 gen per direction
- Tiles pro: ~1 gen per tile (16 tiles = ~16 gen)
- Map object: ~1 gen
- Bitforge image: ~1 gen
- UI element: ~1 gen

**Check balance every 20 assets** with `GET /balance`. Stop and report if below 500 remaining.

## Asset Production Queue (Priority Order)

Work through this list top to bottom. Each item is one generation task. Check off as completed.

### BATCH 1: MVP Core (Phase 3 — Workshop Car Prototype)
These are needed immediately for the current development phase.

**1.1 Player Character — Generic Survivor**
- [ ] `create_character_4dir`: "survivor in worn tan jumpsuit with tool belt, utility goggles on forehead, work boots, post-apocalyptic colony world, isometric pixel art" (48x48)
- [ ] `animate_character` (template: `idle`): idle animation, all 4 directions
- [ ] `animate_character` (template: `walk`): walk cycle, all 4 directions

**1.2 Workshop Car Floor Tiles**
- [ ] `create_tiles_pro`: "1). dark metal grate floor with tool marks and oil stains 2). riveted steel plate floor, industrial workshop 3). worn anti-slip metal plate floor 4). workshop drainage grate floor" (isometric, 64px)

**1.3 Workshop Car Wall Tiles**
- [ ] `create_tiles_pro`: "1). pegboard workshop wall with hanging tool outlines 2). metal panel wall with rivets and cable conduit 3). reinforced workshop wall with ventilation grate" (isometric, 64px)

**1.4 Workshop Car Equipment**
- [ ] `map_object`: "heavy industrial workbench with mounted vise and scattered tools, welding marks, isometric pixel art, post-apocalyptic" (96x96)
- [ ] `map_object`: "wall-mounted tool rack with wrenches hammers and pliers, pegboard backing, isometric pixel art" (64x64)
- [ ] `map_object`: "metal parts bin filled with scrap metal pieces and salvaged gears, industrial, isometric pixel art" (64x64)
- [ ] `map_object`: "small anvil on wooden stump with hammer, blacksmith-industrial hybrid, isometric pixel art" (64x64)
- [ ] `map_object`: "pile of salvaged machine parts and scrap, messy but organized, post-apocalyptic, isometric pixel art" (64x64)

**1.5 Basic HUD/Interaction UI**
- [ ] `generate_ui`: "pixel art game health bar, red fill with dark metal frame, post-apocalyptic style" (128x24)
- [ ] `generate_ui`: "pixel art interaction prompt button showing 'E' key, industrial metal frame" (64x32)


### BATCH 2: Starting Train Cars (Engine, Cargo, Bunks)

**2.1 Engine Car Floor Tiles**
- [ ] `create_tiles_pro`: "1). heavy riveted steel plate floor with oil stains, engine room 2). reinforced metal floor with welded seams, industrial 3). heat-resistant engine room plating, dark metal with scorch marks" (isometric, 64px)

**2.2 Engine Car Equipment**
- [ ] `map_object`: "large train engine block, pistons and pipes, steampunk-industrial, isometric pixel art, post-apocalyptic" (128x96)
- [ ] `map_object`: "power distribution panel with switches, gauges, and blinking indicators, industrial, isometric pixel art" (64x64)
- [ ] `map_object`: "cylindrical fuel tank with gauge and valve wheel, industrial metal, isometric pixel art" (64x64)
- [ ] `map_object`: "coal and fuel storage bin, open top with dark contents, metal frame, isometric pixel art" (64x64)
- [ ] `map_object`: "pipe junction with valves and pressure gauges, brass and steel, isometric pixel art" (64x64)

**2.3 Cargo Car Floor Tiles**
- [ ] `create_tiles_pro`: "1). wooden plank floor with metal runner strips, cargo hold 2). worn wooden crate floor, freight car 3). metal-reinforced wooden floor with loading marks" (isometric, 64px)

**2.4 Cargo Car Equipment**
- [ ] `map_object`: "wooden storage crate, reinforced corners, stenciled labels, isometric pixel art" (48x48)
- [ ] `map_object`: "tall metal storage shelf rack with miscellaneous supplies, industrial, isometric pixel art" (64x96)
- [ ] `map_object`: "wooden supply pallet stacked with boxes, isometric pixel art" (64x48)
- [ ] `map_object`: "metal sorting table with compartments, industrial, isometric pixel art" (64x64)
- [ ] `map_object`: "sealed hazmat container, yellow and black warning stripes, isometric pixel art" (48x48)

**2.5 Bunks Car Floor + Equipment**
- [ ] `create_tiles_pro`: "1). worn carpet over metal floor, residential 2). threadbare rug mat, faded pattern 3). bare metal floor with scattered personal items" (isometric, 64px)
- [ ] `map_object`: "two-tier metal bunk bed with thin mattresses and blankets, post-apocalyptic, isometric pixel art" (64x96)
- [ ] `map_object`: "metal footlocker, dented, with padlock, military surplus style, isometric pixel art" (48x32)
- [ ] `map_object`: "small folding table with chair, personal items, mug, isometric pixel art" (48x48)
- [ ] `map_object`: "makeshift morale station with radio, playing cards, books, isometric pixel art" (64x48)


### BATCH 3: MVP Enemies (4 base types)

**3.1 Swarmer**
- [ ] `create_character_4dir`: "small alien insectoid creature, chitinous shell, glowing eyes, fast and aggressive, dark carapace with bioluminescent spots, post-apocalyptic colony world, isometric pixel art" (32x32, template_id="cat" or "dog")
- [ ] `animate_character` (template: `walk`): move cycle
- [ ] `animate_character` (action: "lunging bite attack"): attack anim

**3.2 Ambusher/Stalker**
- [ ] `create_character_4dir`: "lurking alien predator, lean and angular, camouflage-pattern skin, long claws, hunched posture, stalking prey, dark mottled coloring, isometric pixel art" (48x48)
- [ ] `animate_character` (template: `walk`): move cycle
- [ ] `animate_character` (action: "leaping claw slash attack"): attack anim

**3.3 Blocker**
- [ ] `create_character_4dir`: "large heavily armored alien creature, thick chitinous plates, massive forearms, tank-like build, slow and imposing, dark shell with glowing seams, isometric pixel art" (64x64)
- [ ] `animate_character` (template: `walk`): move cycle
- [ ] `animate_character` (action: "heavy ground slam attack"): attack anim

**3.4 Ranged**
- [ ] `create_character_4dir`: "alien creature with bio-luminescent sacs on back, spits projectiles, medium build, elevated head crest, toxic coloring, isometric pixel art" (48x48)
- [ ] `animate_character` (template: `walk`): move cycle
- [ ] `animate_character` (action: "spitting ranged projectile attack"): attack anim

### BATCH 4: Common Item Icons (most-used resources)

All via `generate_image_bitforge` at 32x32, `no_background=True`:

- [ ] "pile of rusty scrap metal pieces, industrial salvage, pixel art icon"
- [ ] "tangled electrical wiring and cables, copper wire, pixel art icon"
- [ ] "glass bottles of industrial chemicals, hazard labels, pixel art icon"
- [ ] "metal jerrycan of crude fuel oil, dirty, pixel art icon"
- [ ] "folded fabric and rubber seal gaskets, pixel art icon"
- [ ] "first aid supplies, bandages and pill bottle, pixel art icon"
- [ ] "canned food rations, military surplus, pixel art icon"
- [ ] "clear water bottle, purified, pixel art icon"
- [ ] "broken circuit boards and electronic chips, pixel art icon"
- [ ] "glass shards and ceramic tiles, fragile materials, pixel art icon"
- [ ] "precision machine gears and bearings, pixel art icon"
- [ ] "electrical relay switches, pixel art icon"
- [ ] "glowing power core energy cell, pixel art icon"
- [ ] "shiny refined metal alloy ingot, pixel art icon"
- [ ] "optical lens and sensor components, pixel art icon"


### BATCH 5: First Expedition Environments (Small Town + Rail Station)

**5.1 Small Town Terrain**
- [ ] `create_tileset`: lower="cracked asphalt road, broken pavement, post-apocalyptic", upper="overgrown grass and weeds reclaiming road", transition="dirt and rubble edge" (32x32, view="low top-down", transition_size=0.5)
- [ ] `create_tiles_pro`: "1). cracked sidewalk with grass growing through 2). overgrown garden path 3). broken concrete foundation 4). dirt path with scattered debris" (isometric, 64px)

**5.2 Small Town Props**
- [ ] `map_object`: "rusted abandoned sedan car, flat tires, broken windows, overgrown, isometric pixel art" (96x64)
- [ ] `map_object`: "old wooden mailbox, tilting, post-apocalyptic suburban, isometric pixel art" (32x48)
- [ ] `map_object`: "broken street lamp, bent pole, shattered light, isometric pixel art" (32x64)
- [ ] `map_object`: "wooden park bench, weathered, moss growing, isometric pixel art" (64x32)
- [ ] `map_object`: "looted shop counter, open register, scattered items, isometric pixel art" (64x48)
- [ ] `map_object`: "fallen bookshelf, books scattered, isometric pixel art" (64x48)

**5.3 Rail Station Terrain**
- [ ] `create_tileset`: lower="concrete rail platform, weathered", upper="rail tracks on gravel bed", transition="platform edge with yellow safety line" (32x32, view="low top-down", transition_size=0.5)
- [ ] `create_tiles_pro`: "1). concrete platform surface with cracks 2). gravel rail bed with wooden ties 3). metal grate walkway between tracks 4). loading dock concrete" (isometric, 64px)

**5.4 Rail Station Props**
- [ ] `map_object`: "rail track segment with wooden ties, isometric pixel art" (96x32)
- [ ] `map_object`: "train platform bench, metal frame, worn wooden slats, isometric pixel art" (64x32)
- [ ] `map_object`: "ticket booth kiosk, glass broken, isometric pixel art" (48x64)
- [ ] `map_object`: "rail signal box, metal cabinet with levers, isometric pixel art" (48x48)
- [ ] `map_object`: "abandoned luggage cart with suitcases, isometric pixel art" (64x48)
- [ ] `map_object`: "arrivals departures display board, cracked screen, isometric pixel art" (48x64)

**5.5 Universal Expedition Props**
- [ ] `map_object`: "small wooden crate, nailed shut, isometric pixel art" (32x32)
- [ ] `map_object`: "metal supply crate, dented, stenciled markings, isometric pixel art" (48x32)
- [ ] `map_object`: "rusty metal barrel, dented, isometric pixel art" (32x48)
- [ ] `map_object`: "chemical barrel with yellow hazard symbol, isometric pixel art" (32x48)
- [ ] `map_object`: "open doorframe in crumbling wall, isometric pixel art" (48x64)
- [ ] `map_object`: "locked reinforced door, keypad lock, isometric pixel art" (48x64)
- [ ] `map_object`: "small rubble pile, broken concrete and rebar, isometric pixel art" (48x32)
- [ ] `map_object`: "large rubble pile blocking path, collapsed wall, isometric pixel art" (96x64)
- [ ] `map_object`: "scattered debris, broken glass and metal scraps, isometric pixel art" (64x32)
- [ ] `map_object`: "tangled wiring and cables hanging from ceiling, isometric pixel art" (48x48)
- [ ] `map_object`: "overgrown vegetation clump, vines and weeds, post-apocalyptic, isometric pixel art" (48x48)
- [ ] `map_object`: "broken overhead light fixture, dangling, isometric pixel art" (32x48)


### BATCH 6: Remaining Train Cars (Infirmary, Armory, Signal, Refinery, Greenhouse, Lab)

For each car, generate:
- 3-4 floor tile variants via `create_tiles_pro` (isometric, 64px)
- 5 equipment objects via `map_object` (64x64 to 96x96)

Use the floor descriptions and equipment lists from the asset production list at:
`C:\Users\dasbl\Documents\off-the-rails\docs\design\asset-production-list.md`

### BATCH 7: Profession Character Variants

8 profession characters via `create_character_4dir` (48x48):
- Engineer, Medic, Scavenger, Security, Signal Tech, Machinist, Botanist, Researcher
- Each needs unique visual identity (see color/outfit guide in asset list)
- Animate each: idle + walk minimum

### BATCH 8: Remaining Expedition Environments

7 more locations: Freight Yard, Industrial Facility, Research Sector, Agricultural Dome, Tunnel/Maintenance, Crash Site, Survivor Enclave.
Per location:
- 1 Wang tileset (terrain transitions) via `create_tileset`
- 3-4 floor tile variants via `create_tiles_pro`
- 6-8 unique props via `map_object`

### BATCH 9: Remaining Item Icons

~66 remaining icons via `generate_image_bitforge` (32x32, no_background):
- Structured resources (11), Milestone items (10), Crafted consumables (8), Ammo (7), Medical (7), Repair kits (5), Tools (5), Equipment (7), Specialty (6)

### BATCH 10: UI Elements + Ability Icons

- HUD elements via `generate_ui`
- Inventory/crafting/menu UI via `generate_ui`
- 24 ability icons via `generate_image_bitforge` (32x32)
- 8 status effect icons via `generate_image_bitforge` (24x24)
- Route map node icons via `generate_image_bitforge` (32x32)


## Execution Instructions

1. **Start with Batch 1.** Complete it fully before moving to Batch 2. Each batch is a coherent set that can be validated together.

2. **Generate → Poll → Save → Validate → Log** for every asset. No skipping validation.

3. **Create a preview composite** at the end of each batch — a single PNG showing all generated assets from that batch scaled up 3-4x with nearest-neighbor interpolation for easy visual review. Save as `batch_N_preview.png`.

4. **After each batch, report:**
   - How many assets generated successfully
   - How many failed validation (and why)
   - Current generation balance remaining
   - The preview composite path
   - Any assets that need re-generation

5. **If a prompt produces poor results**, try these adjustments in order:
   - Different seed (try 3 seeds before changing prompt)
   - Add more visual detail to the prompt
   - Adjust size (larger often = better quality)
   - Try a different endpoint (pixflux vs bitforge vs pro)

6. **Maintain style consistency.** If early assets establish a visual style that works, feed them as `style_image` or `color_image` references to later generations to keep the palette and detail level consistent.

7. **The full asset production list** with detailed descriptions for every item is at:
   `C:\Users\dasbl\Documents\off-the-rails\docs\design\asset-production-list.md`
   Refer to it for the complete breakdown of what's needed per category.

8. **The PixelLab API reference** (full endpoint docs) is at:
   `C:\Users\dasbl\Documents\off-the-rails\tools\pixellab-api\references\endpoints.md`

9. **The Python wrapper** is at:
   `C:\Users\dasbl\Documents\off-the-rails\tools\pixellab-api\scripts\pixellab.py`

Begin with Batch 1. Report back after each batch with results and the preview composite.
