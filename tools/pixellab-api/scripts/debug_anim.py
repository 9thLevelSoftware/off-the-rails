"""Debug animate_character response format."""
import sys, json
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent))
from pixellab import PixelLab

pl = PixelLab()
CHARACTER_ID = "c7b6883c-427f-4dd2-99dd-42fb7370f360"

print("=== Submitting idle animation job ===")
resp = pl.animate_character(character_id=CHARACTER_ID, template_animation_id="idle", seed=99)
print(f"Initial response keys: {list(resp.keys()) if isinstance(resp, dict) else resp}")
print(json.dumps(resp, indent=2))

job_id = resp.get("background_job_id")
if not job_id:
    print("No job_id — sync response?"); sys.exit()

print(f"\n=== Polling job {job_id} ===")
result = pl.poll_job(job_id, interval=5, max_wait=180)
print(f"Result status: {result.get('status')}")
print(f"Result keys: {list(result.keys())}")
if "last_response" in result:
    lr = result["last_response"]
    print(f"last_response type: {type(lr)}")
    if isinstance(lr, dict):
        print(f"last_response keys: {list(lr.keys())}")
        for k, v in lr.items():
            vtype = type(v).__name__
            if isinstance(v, list):
                print(f"  {k}: list[{len(v)}]")
                if v:
                    print(f"    [0] keys: {list(v[0].keys()) if isinstance(v[0], dict) else type(v[0])}")
            elif isinstance(v, dict):
                print(f"  {k}: dict keys={list(v.keys())}")
            else:
                print(f"  {k}: {vtype} = {str(v)[:80]}")
