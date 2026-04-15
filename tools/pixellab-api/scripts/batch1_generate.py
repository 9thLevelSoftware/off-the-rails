"""
Batch 1 — Off The Rails MVP Asset Generation
Generates: Survivor character, workshop tiles/walls/equipment, basic HUD UI
"""
import sys, json, shutil, time
# Force UTF-8 output regardless of terminal encoding
if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
if hasattr(sys.stderr, "reconfigure"):
    sys.stderr.reconfigure(encoding="utf-8", errors="replace")
from pathlib import Path
from datetime import datetime, timezone
from PIL import Image, ImageDraw, ImageFont

# -- Paths --
SCRIPTS_DIR = Path(__file__).parent
sys.path.insert(0, str(SCRIPTS_DIR))
from pixellab import PixelLab

OUT_BASE = Path(r"C:\Users\dasbl\Documents\off-the-rails\assets\generated")
LOG_PATH = OUT_BASE / "generation_log.json"
FAILED_PATH = OUT_BASE / "failed_assets.json"

DIRS = {
    "survivor_idle": OUT_BASE / "characters" / "survivor" / "idle",
    "survivor_walk": OUT_BASE / "characters" / "survivor" / "walk",
    "workshop_floor": OUT_BASE / "train" / "workshop" / "floor",
    "workshop_walls": OUT_BASE / "train" / "workshop" / "walls",
    "workshop_equip": OUT_BASE / "train" / "workshop" / "equipment",
    "hud": OUT_BASE / "ui" / "hud",
}
for d in DIRS.values():
    d.mkdir(parents=True, exist_ok=True)

pl = PixelLab()
log_entries = []
failed_entries = []

# ── Helpers ───────────────────────────────────────────────────────────────────

def ts():
    return datetime.now(timezone.utc).isoformat()

def validate_png(path):
    """Returns (ok, info_string). Checks: exists, RGBA, non-blank, >500 bytes."""
    p = Path(path)
    if not p.exists():
        return False, "file missing"
    if p.stat().st_size < 500:
        return False, f"too small ({p.stat().st_size} bytes)"
    try:
        img = Image.open(p)
        if img.mode != "RGBA":
            img = img.convert("RGBA")
        if img.getbbox() is None:
            return False, "blank image"
        return True, f"{img.width}x{img.height} RGBA"
    except Exception as e:
        return False, f"PIL error: {e}"

def log_asset(asset_id, category, endpoint, prompt, seed, job_id,
              char_id, files, dims, validation, notes="", gens=1):
    entry = {
        "asset_id": asset_id, "category": category, "endpoint": endpoint,
        "prompt": prompt, "seed": seed, "job_id": job_id,
        "character_id": char_id, "files_generated": files,
        "dimensions": dims, "validation": validation, "notes": notes,
        "generations_used": gens, "timestamp": ts()
    }
    log_entries.append(entry)
    status = "[OK]" if validation == "pass" else "[FAIL]"
    print(f"  {status} {asset_id}: {validation} | files={len(files)}")
    return entry

def save_to(src_path, dest_dir, name):
    """Copy a generated PNG to the proper output directory."""
    dest = Path(dest_dir) / f"{name}.png"
    shutil.copy2(src_path, dest)
    return str(dest)

def generate_and_save(job_resp, prefix, output_dir, stem):
    """Poll async job, save images to output_dir with proper names.
    Returns list of final saved paths."""
    pl.output_dir = Path(output_dir)
    pl.output_dir.mkdir(parents=True, exist_ok=True)
    saved = pl.wait_and_save(job_resp, prefix, interval=5, max_wait=300)
    return saved if saved else []

def check_balance():
    b = pl.balance()
    gens = b.get("subscription", {}).get("generations", "?")
    print(f"\n[BALANCE] {gens} generations remaining")
    return gens


# ── 1.1  Generic Survivor — 4-dir character ───────────────────────────────────
# Already generated in prior run — reuse saved character_id and existing files.
print("\n=== 1.1 Generic Survivor (4-dir) — REUSING prior run ===")
SURVIVOR_PROMPT = (
    "survivor in worn tan jumpsuit with tool belt, utility goggles on forehead, "
    "work boots, post-apocalyptic colony world, isometric pixel art"
)
SURVIVOR_SEED = 42001
CHARACTER_ID = "c7b6883c-427f-4dd2-99dd-42fb7370f360"
JOB_ID_CHAR  = "5d260438-02c9-401d-ad74-5fa84c514c0e"

# Validate what was already saved
saved_char = list(DIRS["survivor_idle"].glob("survivor_*.png"))
val_results = []
for f in saved_char:
    ok, info = validate_png(f)
    val_results.append(f"{f.name}:{info}")
v_status = "pass" if saved_char and all("RGBA" in r for r in val_results) else "fail"
log_asset("survivor_4dir", "characters", "create-character-with-4-directions",
          SURVIVOR_PROMPT, SURVIVOR_SEED, JOB_ID_CHAR, CHARACTER_ID,
          [f.name for f in saved_char], "48x48", v_status,
          notes="reused from prior run; " + "; ".join(val_results), gens=0)


# ── 1.1b  Survivor — Idle animation ──────────────────────────────────────────
print("\n=== 1.1b Survivor Idle Animation ===")
if CHARACTER_ID:
    idle_resp = pl.animate_character(
        character_id=CHARACTER_ID,
        template_animation_id="idle",
        seed=SURVIVOR_SEED + 1
    )
    pl.output_dir = DIRS["survivor_idle"]
    saved_idle = pl.wait_and_save(idle_resp, "survivor_idle", interval=5, max_wait=300)
    idle_job = idle_resp.get("background_job_id", "")
    v_status = "pass" if saved_idle else "fail"
    log_asset("survivor_anim_idle", "characters", "animate-character",
              "idle template animation", SURVIVOR_SEED + 1, idle_job, CHARACTER_ID,
              [Path(f).name for f in saved_idle], "68x68", v_status, gens=4)
else:
    print("  SKIP: no character_id from 4-dir step")
    failed_entries.append({"asset_id": "survivor_anim_idle", "reason": "no character_id"})

# ── 1.1c  Survivor — Walk animation ──────────────────────────────────────────
print("\n=== 1.1c Survivor Walk Animation ===")
if CHARACTER_ID:
    walk_resp = pl.animate_character(
        character_id=CHARACTER_ID,
        template_animation_id="walk",
        seed=SURVIVOR_SEED + 2
    )
    pl.output_dir = DIRS["survivor_walk"]
    saved_walk = pl.wait_and_save(walk_resp, "survivor_walk", interval=5, max_wait=300)
    walk_job = walk_resp.get("background_job_id", "")
    v_status = "pass" if saved_walk else "fail"
    log_asset("survivor_anim_walk", "characters", "animate-character",
              "walk template animation", SURVIVOR_SEED + 2, walk_job, CHARACTER_ID,
              [Path(f).name for f in saved_walk], "68x68", v_status, gens=4)
else:
    print("  SKIP: no character_id from 4-dir step")
    failed_entries.append({"asset_id": "survivor_anim_walk", "reason": "no character_id"})

check_balance()


# ── 1.2  Workshop Floor Tiles ─────────────────────────────────────────────────
print("\n=== 1.2 Workshop Floor Tiles ===")
FLOOR_PROMPT = (
    "1). dark metal grate floor with tool marks and oil stains "
    "2). riveted steel plate floor, industrial workshop "
    "3). worn anti-slip metal plate floor "
    "4). workshop drainage grate floor"
)
FLOOR_SEED = 42010

floor_resp = pl.create_tiles_pro(
    description=FLOOR_PROMPT,
    tile_type="isometric", tile_size=64,
    tile_view="low top-down", seed=FLOOR_SEED
)
pl.output_dir = DIRS["workshop_floor"]
saved_floor = pl.wait_and_save(floor_resp, "workshop_floor", interval=5, max_wait=300)
floor_job = floor_resp.get("background_job_id", "")

val_ok = []
for f in saved_floor:
    ok, info = validate_png(f)
    val_ok.append(ok)
v_status = "pass" if saved_floor and all(val_ok) else "fail"
log_asset("workshop_floor_tiles", "train_tiles", "create-tiles-pro",
          FLOOR_PROMPT, FLOOR_SEED, floor_job, None,
          [Path(f).name for f in saved_floor], "64x64", v_status, gens=4)

# ── 1.3  Workshop Wall Tiles ──────────────────────────────────────────────────
print("\n=== 1.3 Workshop Wall Tiles ===")
WALL_PROMPT = (
    "1). pegboard workshop wall with hanging tool outlines "
    "2). metal panel wall with rivets and cable conduit "
    "3). reinforced workshop wall with ventilation grate"
)
WALL_SEED = 42020

wall_resp = pl.create_tiles_pro(
    description=WALL_PROMPT,
    tile_type="isometric", tile_size=64,
    tile_view="low top-down", seed=WALL_SEED
)
pl.output_dir = DIRS["workshop_walls"]
saved_walls = pl.wait_and_save(wall_resp, "workshop_wall", interval=5, max_wait=300)
wall_job = wall_resp.get("background_job_id", "")

val_ok = [validate_png(f)[0] for f in saved_walls]
v_status = "pass" if saved_walls and all(val_ok) else "fail"
log_asset("workshop_wall_tiles", "train_tiles", "create-tiles-pro",
          WALL_PROMPT, WALL_SEED, wall_job, None,
          [Path(f).name for f in saved_walls], "64x64", v_status, gens=3)

check_balance()


# ── 1.4  Workshop Equipment ───────────────────────────────────────────────────
print("\n=== 1.4 Workshop Equipment ===")

EQUIP_SEED_BASE = 42030
EQUIPMENT = [
    ("workbench",   96, 96,  "heavy industrial workbench with mounted vise and scattered tools, welding marks, isometric pixel art, post-apocalyptic"),
    ("tool_rack",   64, 64,  "wall-mounted tool rack with wrenches hammers and pliers, pegboard backing, isometric pixel art"),
    ("parts_bin",   64, 64,  "metal parts bin filled with scrap metal pieces and salvaged gears, industrial, isometric pixel art"),
    ("anvil",       64, 64,  "small anvil on wooden stump with hammer, blacksmith-industrial hybrid, isometric pixel art"),
    ("salvage_pile",64, 64,  "pile of salvaged machine parts and scrap, messy but organized, post-apocalyptic, isometric pixel art"),
]

for i, (name, w, h, prompt) in enumerate(EQUIPMENT):
    print(f"  Generating {name}...")
    seed = EQUIP_SEED_BASE + i * 10
    resp = pl.create_map_object(
        description=prompt, width=w, height=h,
        view="high top-down",
        outline="selective outline", shading="detailed shading", detail="high detail",
        seed=seed
    )
    pl.output_dir = DIRS["workshop_equip"]
    saved = pl.wait_and_save(resp, name, interval=5, max_wait=300)
    job_id = resp.get("background_job_id", "")
    val_ok = [validate_png(f)[0] for f in saved]
    v_status = "pass" if saved and all(val_ok) else "fail"
    log_asset(f"workshop_{name}", "train_equipment", "map-objects",
              prompt, seed, job_id, None,
              [Path(f).name for f in saved], f"{w}x{h}", v_status)

check_balance()


# ── 1.5  Basic HUD UI ─────────────────────────────────────────────────────────
print("\n=== 1.5 HUD UI Elements ===")

UI_ITEMS = [
    ("health_bar",      128, 24,  "pixel art game health bar, red fill with dark metal frame, post-apocalyptic style", 42050),
    ("interact_prompt", 64,  32,  "pixel art interaction prompt button showing 'E' key, industrial metal frame", 42051),
]

for name, w, h, prompt, seed in UI_ITEMS:
    print(f"  Generating {name}...")
    resp = pl.generate_ui(description=prompt, width=w, height=h, seed=seed)
    pl.output_dir = DIRS["hud"]
    saved = pl.wait_and_save(resp, name, interval=5, max_wait=300)
    job_id = resp.get("background_job_id", "")
    val_ok = [validate_png(f)[0] for f in saved]
    v_status = "pass" if saved and all(val_ok) else "fail"
    log_asset(f"ui_{name}", "ui_hud", "generate-ui-v2",
              prompt, seed, job_id, None,
              [Path(f).name for f in saved], f"{w}x{h}", v_status)

check_balance()


# ── Write Logs ────────────────────────────────────────────────────────────────
print("\n=== Writing Logs ===")

# Load existing log if any
existing = []
if LOG_PATH.exists():
    try:
        existing = json.loads(LOG_PATH.read_text())
    except Exception:
        existing = []
existing.extend(log_entries)
LOG_PATH.write_text(json.dumps(existing, indent=2))
print(f"  Log: {LOG_PATH}  ({len(log_entries)} new entries, {len(existing)} total)")

if failed_entries:
    f_existing = []
    if FAILED_PATH.exists():
        try:
            f_existing = json.loads(FAILED_PATH.read_text())
        except Exception:
            f_existing = []
    f_existing.extend(failed_entries)
    FAILED_PATH.write_text(json.dumps(f_existing, indent=2))
    print(f"  Failed: {FAILED_PATH}  ({len(failed_entries)} entries)")

# ── Batch Preview Composite ───────────────────────────────────────────────────
print("\n=== Building Batch 1 Preview Composite ===")

def collect_pngs(*dirs):
    pngs = []
    for d in dirs:
        pngs.extend(sorted(Path(d).glob("*.png")))
    return pngs

all_pngs = collect_pngs(
    DIRS["survivor_idle"], DIRS["survivor_walk"],
    DIRS["workshop_floor"], DIRS["workshop_walls"],
    DIRS["workshop_equip"], DIRS["hud"]
)
print(f"  Found {len(all_pngs)} PNGs for preview")

SCALE = 4
PAD = 6
COLS = 8

if all_pngs:
    # Determine canvas size: scale each image up 4x, arrange in a grid
    images = []
    for p in all_pngs:
        try:
            img = Image.open(p).convert("RGBA")
            scaled = img.resize((img.width * SCALE, img.height * SCALE), Image.NEAREST)
            images.append((scaled, p.stem))
        except Exception as ex:
            print(f"  Skip {p.name}: {ex}")

    if images:
        cell_w = max(im.width for im, _ in images) + PAD * 2
        cell_h = max(im.height for im, _ in images) + PAD * 2 + 14
        rows = (len(images) + COLS - 1) // COLS
        canvas = Image.new("RGBA", (cell_w * COLS, cell_h * rows), (30, 30, 30, 255))

        for idx, (img, label) in enumerate(images):
            col = idx % COLS
            row = idx // COLS
            x = col * cell_w + PAD + (cell_w - PAD*2 - img.width) // 2
            y = row * cell_h + PAD
            canvas.paste(img, (x, y), img)
            draw = ImageDraw.Draw(canvas)
            draw.text((col * cell_w + PAD, row * cell_h + cell_h - 14), label[:18],
                      fill=(200, 200, 200, 255))

        preview_path = OUT_BASE / "batch1_preview.png"
        canvas.save(str(preview_path))
        print(f"  Preview saved: {preview_path}")
    else:
        print("  No valid images to composite")
else:
    print("  No PNGs found — preview skipped")

# ── Final Summary ─────────────────────────────────────────────────────────────
print("\n" + "="*60)
print("BATCH 1 COMPLETE")
passed = sum(1 for e in log_entries if e["validation"] == "pass")
failed = len(log_entries) - passed
print(f"  Assets generated: {len(log_entries)}")
print(f"  Passed validation: {passed}")
print(f"  Failed validation: {failed}")
print(f"  Failed (skipped):  {len(failed_entries)}")
total_gens = sum(e["generations_used"] for e in log_entries)
print(f"  Generations used this batch: ~{total_gens}")
b = pl.balance()
print(f"  Remaining balance: {b.get('subscription', {}).get('generations', '?')} gen")
print("="*60)
