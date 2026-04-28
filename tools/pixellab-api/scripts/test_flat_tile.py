"""Quick test: Generate one flat isometric floor tile with tile_shape='thin tile'"""
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent))
from pixellab import PixelLab

pl = PixelLab()
pl.output_dir = Path(__file__).parent / "test_output"
pl.output_dir.mkdir(exist_ok=True)

print("Testing flat isometric tile generation...")
print(f"Balance: {pl.balance()}")

# API max is 64x64 for create-isometric-tile
# Use tile_shape="thin tile" for flat floor tiles
resp = pl.create_isometric_tile(
    description="dark metal grate floor with oil stains, industrial workshop, pixel art",
    width=64, height=64,
    tile_shape="thin tile",  # Flat - no depth sides
    seed=42010
)

print(f"\nResponse: {resp}")

if "error" in resp:
    print(f"\nAPI Error: {resp}")
else:
    saved = pl.wait_and_save(resp, "test_flat_tile", interval=3, max_wait=120)
    print(f"\nSaved: {saved}")
    print(f"Check: {pl.output_dir}")
