"""
Generate survivor animations — handles background_job_ids (plural) response.
animate_character returns one job_id per direction.
"""
import sys, json, time
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent))
from pixellab import PixelLab
from PIL import Image
import base64

pl = PixelLab()
CHARACTER_ID = "c7b6883c-427f-4dd2-99dd-42fb7370f360"
OUT_BASE = Path(r"C:\Users\dasbl\Documents\off-the-rails\assets\generated")

def poll_and_save(job_id, out_dir, prefix):
    """Poll a single animation job and save resulting frames."""
    Path(out_dir).mkdir(parents=True, exist_ok=True)
    result = pl.poll_job(job_id, interval=5, max_wait=300)
    if "error" in result:
        print(f"    Job {job_id[:8]} error: {result}")
        return []
    # Inspect structure
    lr = result.get("last_response", result)
    saved = []
    # Frames list
    if isinstance(lr, dict) and "frames" in lr:
        frames = lr["frames"]
        print(f"    {len(frames)} frames found")
        for i, frame in enumerate(frames):
            img_obj = frame.get("image") or frame
            path = pl._save_image_obj(img_obj, str(Path(out_dir) / f"{prefix}_frame{i:02d}"))
            if path:
                saved.append(path)
    # Fallback: raw images list
    elif isinstance(lr, dict) and "images" in lr:
        imgs = lr["images"]
        print(f"    {len(imgs)} images found")
        for i, img in enumerate(imgs if isinstance(imgs, list) else imgs.values()):
            path = pl._save_image_obj(img, str(Path(out_dir) / f"{prefix}_frame{i:02d}"))
            if path:
                saved.append(path)
    else:
        print(f"    Unrecognised structure: {list(lr.keys()) if isinstance(lr, dict) else type(lr)}")
        print(f"    Full result snippet: {json.dumps(result, indent=2)[:500]}")
    return saved

ANIMS = [
    ("breathing-idle", OUT_BASE / "characters" / "survivor" / "idle", "idle"),
    ("walk",           OUT_BASE / "characters" / "survivor" / "walk", "walk"),
]

for template, out_dir, label in ANIMS:
    print(f"\n=== {template} ===")
    resp = pl.animate_character(character_id=CHARACTER_ID, template_animation_id=template,
                                mode="template", seed=42200)
    if "error" in resp:
        print(f"  ERROR: {resp}")
        continue

    # Handle plural job IDs
    job_ids  = resp.get("background_job_ids", [])
    dirs     = resp.get("directions", [])
    print(f"  {len(job_ids)} direction jobs: {dirs}")

    for job_id, direction in zip(job_ids, dirs):
        print(f"  Polling {direction} ({job_id[:8]}...)...")
        saved = poll_and_save(job_id, out_dir, f"{label}_{direction}")
        print(f"    -> {len(saved)} files saved")

b = pl.balance()
print(f"\nBalance: {b.get('subscription',{}).get('generations','?')} remaining")
