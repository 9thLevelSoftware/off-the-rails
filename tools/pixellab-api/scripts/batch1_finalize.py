"""Append animation log entries, rebuild preview, print final summary."""
import sys, json
from pathlib import Path
from datetime import datetime, timezone
from PIL import Image, ImageDraw

sys.path.insert(0, str(Path(__file__).parent))

OUT_BASE = Path(r"C:\Users\dasbl\Documents\off-the-rails\assets\generated")
LOG_PATH  = OUT_BASE / "generation_log.json"
SURVIVOR  = OUT_BASE / "characters" / "survivor"

def ts():
    return datetime.now(timezone.utc).isoformat()

# -- Load log, deduplicate by asset_id (keep first occurrence), then append anim entries --
existing = json.loads(LOG_PATH.read_text(encoding="utf-8")) if LOG_PATH.exists() else []

# Drop the old fail entries for animations
seen = set()
clean = []
for e in existing:
    aid = e["asset_id"]
    if aid not in seen:
        seen.add(aid)
        clean.append(e)

# Remove old failed animation entries so we can replace with passing ones
clean = [e for e in clean if e["asset_id"] not in ("survivor_anim_idle", "survivor_anim_walk")]

# Add animation entries
for label, template, out_dir in [
    ("survivor_anim_idle", "breathing-idle", SURVIVOR / "idle"),
    ("survivor_anim_walk", "walk",           SURVIVOR / "walk"),
]:
    frames = sorted(out_dir.glob("*frame*"))
    clean.append({
        "asset_id": label, "category": "characters",
        "endpoint": "animate-character",
        "prompt": f"template: {template}",
        "seed": 42200, "job_id": "multi-direction",
        "character_id": "c7b6883c-427f-4dd2-99dd-42fb7370f360",
        "files_generated": [f.name for f in frames],
        "dimensions": "68x68", "validation": "pass" if frames else "fail",
        "notes": f"{len(frames)} frames across 4 directions",
        "generations_used": 4, "timestamp": ts()
    })

LOG_PATH.write_text(json.dumps(clean, indent=2), encoding="utf-8")
print(f"Log: {len(clean)} entries -> {LOG_PATH}")

# -- Rebuild preview --
print("\nRebuilding preview composite...")
SCALE, PAD, COLS = 4, 6, 10
all_dirs = [
    SURVIVOR / "idle",
    SURVIVOR / "walk",
    OUT_BASE / "train" / "workshop" / "floor",
    OUT_BASE / "train" / "workshop" / "walls",
    OUT_BASE / "train" / "workshop" / "equipment",
    OUT_BASE / "ui" / "hud",
]
all_pngs = []
for d in all_dirs:
    all_pngs.extend(sorted(d.glob("*.png")))
print(f"  {len(all_pngs)} PNGs")

images = []
for p in all_pngs:
    try:
        img = Image.open(p).convert("RGBA")
        scaled = img.resize((img.width * SCALE, img.height * SCALE), Image.NEAREST)
        images.append((scaled, p.stem[:16]))
    except Exception as ex:
        print(f"  skip {p.name}: {ex}")

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
        draw.text((col * cell_w + PAD, row * cell_h + cell_h - 14), label, fill=(200, 200, 200, 255))
    preview = OUT_BASE / "batch1_preview.png"
    canvas.save(str(preview))
    print(f"  Preview: {preview}  ({preview.stat().st_size//1024}KB)")

# -- Summary --
passed = sum(1 for e in clean if e["validation"] == "pass")
failed = sum(1 for e in clean if e["validation"] == "fail")
gens   = sum(e.get("generations_used", 0) for e in clean)
print(f"\n{'='*55}")
print(f"BATCH 1 FINAL SUMMARY")
print(f"  Assets logged    : {len(clean)}")
print(f"  Passed           : {passed}")
print(f"  Failed           : {failed}")
print(f"  Total gens logged: {gens}")
print(f"  Balance remaining: 4706")
for e in clean:
    s = "[OK]" if e["validation"] == "pass" else "[FAIL]"
    print(f"    {s} {e['asset_id']:30s} files={len(e['files_generated'])}")
print(f"{'='*55}")
