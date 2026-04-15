"""
Batch 1 continuation — picks up from wall tiles onward.
Survivor (done), floor tiles (done). Starting: walls, equipment, UI.
"""
import sys, json, shutil, time
from pathlib import Path
from datetime import datetime, timezone
from PIL import Image, ImageDraw

def flush(*args, **kwargs):
    print(*args, **kwargs)
    sys.stdout.flush()

# -- Paths --
SCRIPTS_DIR = Path(__file__).parent
sys.path.insert(0, str(SCRIPTS_DIR))
from pixellab import PixelLab

OUT_BASE = Path(r"C:\Users\dasbl\Documents\off-the-rails\assets\generated")
LOG_PATH  = OUT_BASE / "generation_log.json"

DIRS = {
    "survivor_idle":  OUT_BASE / "characters" / "survivor" / "idle",
    "survivor_walk":  OUT_BASE / "characters" / "survivor" / "walk",
    "workshop_floor": OUT_BASE / "train" / "workshop" / "floor",
    "workshop_walls": OUT_BASE / "train" / "workshop" / "walls",
    "workshop_equip": OUT_BASE / "train" / "workshop" / "equipment",
    "hud":            OUT_BASE / "ui" / "hud",
}
for d in DIRS.values():
    d.mkdir(parents=True, exist_ok=True)

pl = PixelLab()
log_entries = []

def ts():
    return datetime.now(timezone.utc).isoformat()

def validate_png(path):
    p = Path(path)
    if not p.exists():        return False, "missing"
    if p.stat().st_size < 200:
        return False, f"tiny ({p.stat().st_size}B)"
    try:
        img = Image.open(p).convert("RGBA")
        if img.getbbox() is None:
            return False, "blank"
        return True, f"{img.width}x{img.height}"
    except Exception as e:
        return False, f"PIL:{e}"

def run_job(job_resp, out_dir, prefix):
    """Poll async job, save to out_dir, return list of saved paths."""
    pl.output_dir = Path(out_dir)
    pl.output_dir.mkdir(parents=True, exist_ok=True)
    try:
        saved = pl.wait_and_save(job_resp, prefix, interval=5, max_wait=300)
        return saved if isinstance(saved, list) else []
    except Exception as e:
        flush(f"    ERROR in wait_and_save: {e}")
        return []

def record(asset_id, cat, endpoint, prompt, seed, job_id, char_id, files, dims, ok, notes="", gens=1):
    status = "[OK]" if ok else "[FAIL]"
    flush(f"  {status} {asset_id}: files={len(files)} dims={dims}")
    entry = {"asset_id": asset_id, "category": cat, "endpoint": endpoint,
             "prompt": prompt, "seed": seed, "job_id": job_id,
             "character_id": char_id, "files_generated": files,
             "dimensions": dims, "validation": "pass" if ok else "fail",
             "notes": notes, "generations_used": gens, "timestamp": ts()}
    log_entries.append(entry)

def check_bal():
    try:
        b = pl.balance()
        g = b.get("subscription", {}).get("generations", "?")
        flush(f"  [BAL] {g} generations remaining")
    except Exception as e:
        flush(f"  [BAL] error: {e}")


# ── Already done — log them so totals are correct ─────────────────────────────
flush("=== Registering completed assets ===")
survivor_files = [f.name for f in DIRS["survivor_idle"].glob("survivor_*.png")]
record("survivor_4dir", "characters", "create-character-with-4-directions",
       "survivor in worn tan jumpsuit...", 42001,
       "5d260438-02c9-401d-ad74-5fa84c514c0e",
       "c7b6883c-427f-4dd2-99dd-42fb7370f360",
       survivor_files, "48x48", bool(survivor_files), "prior run", gens=0)

floor_files = [f.name for f in DIRS["workshop_floor"].glob("*.png")]
record("workshop_floor_tiles", "train_tiles", "create-tiles-pro",
       "4-variant workshop floor", 42010, "", None,
       floor_files, "64x64", bool(floor_files), "prior run", gens=0)

check_bal()

# ── 1.3  Workshop Wall Tiles ──────────────────────────────────────────────────
flush("\n=== 1.3 Workshop Wall Tiles ===")
WALL_PROMPT = (
    "1). pegboard workshop wall with hanging tool outlines "
    "2). metal panel wall with rivets and cable conduit "
    "3). reinforced workshop wall with ventilation grate"
)
try:
    resp = pl.create_tiles_pro(description=WALL_PROMPT, tile_type="isometric",
                               tile_size=64, tile_view="low top-down", seed=42020)
    flush(f"  job_id={resp.get('background_job_id','?')}")
    saved = run_job(resp, DIRS["workshop_walls"], "workshop_wall")
    vok = all(validate_png(f)[0] for f in saved) if saved else False
    record("workshop_wall_tiles", "train_tiles", "create-tiles-pro",
           WALL_PROMPT, 42020, resp.get("background_job_id",""), None,
           [Path(f).name for f in saved], "64x64", vok and bool(saved), gens=3)
except Exception as e:
    flush(f"  ERROR: {e}")

check_bal()


# ── 1.4  Workshop Equipment ───────────────────────────────────────────────────
flush("\n=== 1.4 Workshop Equipment ===")
EQUIPMENT = [
    ("workbench",    96, 96,
     "heavy industrial workbench with mounted vise and scattered tools, welding marks, isometric pixel art, post-apocalyptic"),
    ("tool_rack",    64, 64,
     "wall-mounted tool rack with wrenches hammers and pliers, pegboard backing, isometric pixel art"),
    ("parts_bin",    64, 64,
     "metal parts bin filled with scrap metal pieces and salvaged gears, industrial, isometric pixel art"),
    ("anvil",        64, 64,
     "small anvil on wooden stump with hammer, blacksmith-industrial hybrid, isometric pixel art"),
    ("salvage_pile", 64, 64,
     "pile of salvaged machine parts and scrap, messy but organized, post-apocalyptic, isometric pixel art"),
]
for i, (name, w, h, prompt) in enumerate(EQUIPMENT):
    flush(f"  Generating {name} ({w}x{h})...")
    seed = 42030 + i * 10
    try:
        resp = pl.create_map_object(description=prompt, width=w, height=h,
                                    view="high top-down",
                                    outline="selective outline",
                                    shading="detailed shading",
                                    detail="high detail", seed=seed)
        flush(f"    job_id={resp.get('background_job_id','?')}")
        saved = run_job(resp, DIRS["workshop_equip"], name)
        vok = all(validate_png(f)[0] for f in saved) if saved else False
        record(f"workshop_{name}", "train_equipment", "map-objects",
               prompt, seed, resp.get("background_job_id",""), None,
               [Path(f).name for f in saved], f"{w}x{h}", vok and bool(saved))
    except Exception as e:
        flush(f"    ERROR: {e}")

check_bal()


# ── 1.5  HUD UI ───────────────────────────────────────────────────────────────
flush("\n=== 1.5 HUD UI Elements ===")
UI_ITEMS = [
    ("health_bar",      128, 24,
     "pixel art game health bar, red fill with dark metal frame, post-apocalyptic style", 42050),
    ("interact_prompt",  64, 32,
     "pixel art interaction prompt button showing 'E' key, industrial metal frame", 42051),
]
for name, w, h, prompt, seed in UI_ITEMS:
    flush(f"  Generating {name}...")
    try:
        resp = pl.generate_ui(description=prompt, width=w, height=h, seed=seed)
        flush(f"    job_id={resp.get('background_job_id','?')}")
        saved = run_job(resp, DIRS["hud"], name)
        vok = all(validate_png(f)[0] for f in saved) if saved else False
        record(f"ui_{name}", "ui_hud", "generate-ui-v2",
               prompt, seed, resp.get("background_job_id",""), None,
               [Path(f).name for f in saved], f"{w}x{h}", vok and bool(saved))
    except Exception as e:
        flush(f"    ERROR: {e}")

check_bal()

# ── Write log ─────────────────────────────────────────────────────────────────
flush("\n=== Writing generation_log.json ===")
existing = []
if LOG_PATH.exists():
    try:
        existing = json.loads(LOG_PATH.read_text(encoding="utf-8"))
    except Exception:
        existing = []
existing.extend(log_entries)
LOG_PATH.write_text(json.dumps(existing, indent=2), encoding="utf-8")
flush(f"  {len(log_entries)} new entries written ({len(existing)} total)")


# ── Batch preview composite ───────────────────────────────────────────────────
flush("\n=== Building Batch 1 Preview Composite ===")
SCALE, PAD, COLS = 4, 6, 8

all_pngs = []
for d in DIRS.values():
    all_pngs.extend(sorted(d.glob("*.png")))
flush(f"  {len(all_pngs)} PNGs found")

images = []
for p in all_pngs:
    try:
        img = Image.open(p).convert("RGBA")
        scaled = img.resize((img.width * SCALE, img.height * SCALE), Image.NEAREST)
        images.append((scaled, p.stem[:18]))
    except Exception as ex:
        flush(f"  skip {p.name}: {ex}")

if images:
    cell_w = max(im.width for im, _ in images) + PAD * 2
    cell_h = max(im.height for im, _ in images) + PAD * 2 + 14
    rows = (len(images) + COLS - 1) // COLS
    canvas = Image.new("RGBA", (cell_w * COLS, cell_h * rows), (30, 30, 30, 255))
    draw = ImageDraw.Draw(canvas)
    for idx, (img, label) in enumerate(images):
        col, row = idx % COLS, idx // COLS
        x = col * cell_w + PAD + (cell_w - PAD * 2 - img.width) // 2
        y = row * cell_h + PAD
        canvas.paste(img, (x, y), img)
        draw.text((col * cell_w + PAD, row * cell_h + cell_h - 14),
                  label, fill=(200, 200, 200, 255))
    preview_path = OUT_BASE / "batch1_preview.png"
    canvas.save(str(preview_path))
    flush(f"  Preview: {preview_path}")
else:
    flush("  No images — preview skipped")

# ── Summary ───────────────────────────────────────────────────────────────────
flush("\n" + "=" * 55)
flush("BATCH 1 COMPLETE")
passed = sum(1 for e in log_entries if e["validation"] == "pass")
flush(f"  Assets logged : {len(log_entries)}")
flush(f"  Passed        : {passed}")
flush(f"  Failed        : {len(log_entries) - passed}")
total_gens = sum(e["generations_used"] for e in log_entries)
flush(f"  Gens this run : {total_gens}")
flush("=" * 55)
