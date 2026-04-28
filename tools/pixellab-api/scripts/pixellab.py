"""
PixelLab API v2 — Python wrapper for Off The Rails asset generation.

Usage:
    from pixellab import PixelLab
    pl = PixelLab()
    
    # Generate a single image
    result = pl.generate_image("wooden barrel, top-down view", width=64, height=64)
    
    # Create a character with 4 directions
    job = pl.create_character_4dir("knight with plate armor", width=48, height=48)
    
    # Poll async jobs
    status = pl.poll_job(job["background_job_id"])
"""

import requests
import base64
import time
import json
import os
from pathlib import Path
from io import BytesIO

API_BASE = "https://api.pixellab.ai/v2"
API_KEY = "2f70a6be-6c63-4599-a0e6-666359a3ce81"

class PixelLab:
    def __init__(self, api_key=API_KEY, base_url=API_BASE):
        self.base_url = base_url
        self.headers = {
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json"
        }
        self.output_dir = Path("./pixellab_output")
        self.output_dir.mkdir(exist_ok=True)

    def _post(self, endpoint, payload, stream=False):
        url = f"{self.base_url}/{endpoint}"
        resp = requests.post(url, headers=self.headers, json=payload, timeout=120)
        if resp.status_code in (200, 202):
            content_type = resp.headers.get("content-type", "")
            if "image/" in content_type:
                return {"type": "image", "data": resp.content, "format": content_type.split("/")[-1]}
            return resp.json()
        else:
            return {"error": resp.status_code, "detail": resp.text}

    def _get(self, endpoint):
        url = f"{self.base_url}/{endpoint}"
        resp = requests.get(url, headers=self.headers, timeout=60)
        if resp.status_code == 200:
            content_type = resp.headers.get("content-type", "")
            if "image/" in content_type:
                return {"type": "image", "data": resp.content}
            return resp.json()
        elif resp.status_code == 423:
            return {"status": "processing"}
        else:
            return {"error": resp.status_code, "detail": resp.text}

    def _save_png(self, data, name):
        """Save raw bytes or base64 string as PNG."""
        path = self.output_dir / f"{name}.png"
        if isinstance(data, bytes):
            path.write_bytes(data)
        elif isinstance(data, str):
            path.write_bytes(base64.b64decode(data))
        return str(path)

    def _rgba_bytes_to_png(self, b64_data, width, height, name):
        """Convert rgba_bytes (raw RGBA pixel data, base64-encoded) to PNG file."""
        from PIL import Image
        raw = base64.b64decode(b64_data)
        img = Image.frombytes("RGBA", (width, height), raw)
        path = self.output_dir / f"{name}.png"
        img.save(str(path), "PNG")
        return str(path)

    def _save_image_obj(self, img_obj, name):
        """Save an image object from the API — handles both PNG base64 and rgba_bytes."""
        if isinstance(img_obj, str):
            return self._save_png(img_obj, name)
        if isinstance(img_obj, dict):
            b64 = img_obj.get("base64")
            if not b64:
                return None
            if img_obj.get("type") == "rgba_bytes":
                w = img_obj.get("width")
                h = img_obj.get("height")
                if w and h:
                    return self._rgba_bytes_to_png(b64, w, h, name)
            return self._save_png(b64, name)
        return None

    def _save_result_images(self, result, prefix):
        """Extract and save images from various API response formats."""
        saved = []
        if isinstance(result, dict) and result.get("type") == "image":
            path = self._save_png(result["data"], prefix)
            saved.append(path)
            return saved

        data = result.get("last_response", result.get("data", result))

        if isinstance(data, dict) and "image" in data and isinstance(data["image"], str):
            path = self._save_png(data["image"], prefix)
            saved.append(path)
        elif isinstance(data, dict) and "image" in data and isinstance(data["image"], dict):
            path = self._save_image_obj(data["image"], prefix)
            if path:
                saved.append(path)

        directions = ["south", "south_west", "west", "north_west", "north", "north_east", "east", "south_east"]
        if isinstance(data, dict) and "images" in data and isinstance(data["images"], dict):
            for d in directions:
                if d in data["images"]:
                    path = self._save_image_obj(data["images"][d], f"{prefix}_{d}")
                    if path:
                        saved.append(path)

        if isinstance(data, dict) and "images" in data and isinstance(data["images"], list):
            for i, img in enumerate(data["images"]):
                path = self._save_image_obj(img, f"{prefix}_{i}")
                if path:
                    saved.append(path)

        if isinstance(data, dict) and "frames" in data and isinstance(data["frames"], list):
            for i, frame in enumerate(data["frames"]):
                if isinstance(frame, dict) and "image" in frame:
                    path = self._save_image_obj(frame["image"], f"{prefix}_frame{i}")
                    if path:
                        saved.append(path)
                elif isinstance(frame, dict) and "base64" in frame:
                    path = self._save_image_obj(frame, f"{prefix}_frame{i}")
                    if path:
                        saved.append(path)

        if not saved and isinstance(data, dict):
            for d in directions:
                if d in data and isinstance(data[d], dict) and "base64" in data[d]:
                    path = self._save_image_obj(data[d], f"{prefix}_{d}")
                    if path:
                        saved.append(path)

        return saved

    # -- Balance --
    def balance(self):
        return self._get("balance")

    # -- Image Generation --
    def generate_image_pro(self, description, width=64, height=64, seed=None, no_background=False, **kwargs):
        payload = {"description": description, "image_size": {"width": width, "height": height}, "no_background": no_background}
        if seed is not None: payload["seed"] = seed
        payload.update(kwargs)
        return self._post("generate-image-v2", payload)

    def generate_image_pixflux(self, description, width=64, height=64, no_background=False,
                                outline=None, shading=None, detail=None, view=None, direction=None, seed=None, **kwargs):
        payload = {"description": description, "image_size": {"width": width, "height": height}, "no_background": no_background}
        for k, v in [("outline", outline), ("shading", shading), ("detail", detail), ("view", view), ("direction", direction), ("seed", seed)]:
            if v is not None: payload[k] = v
        payload.update(kwargs)
        return self._post("create-image-pixflux", payload)

    def generate_image_bitforge(self, description, width=64, height=64, no_background=False,
                                 outline=None, shading=None, detail=None, view=None, direction=None, seed=None, **kwargs):
        payload = {"description": description, "image_size": {"width": width, "height": height}, "no_background": no_background}
        for k, v in [("outline", outline), ("shading", shading), ("detail", detail), ("view", view), ("direction", direction), ("seed", seed)]:
            if v is not None: payload[k] = v
        payload.update(kwargs)
        return self._post("create-image-bitforge", payload)

    # -- UI --
    def generate_ui(self, description, width=256, height=256, seed=None, no_background=False, color_palette=None, **kwargs):
        payload = {"description": description, "image_size": {"width": width, "height": height}, "no_background": no_background}
        if seed is not None: payload["seed"] = seed
        if color_palette: payload["color_palette"] = color_palette
        payload.update(kwargs)
        return self._post("generate-ui-v2", payload)

    # -- Characters --
    def create_character_4dir(self, description, width=48, height=48, seed=None,
                               outline=None, shading=None, detail=None, view=None, template_id=None, **kwargs):
        payload = {"description": description, "image_size": {"width": width, "height": height}}
        for k, v in [("outline", outline), ("shading", shading), ("detail", detail), ("view", view), ("template_id", template_id), ("seed", seed)]:
            if v is not None: payload[k] = v
        payload.update(kwargs)
        return self._post("create-character-with-4-directions", payload)

    def create_character_8dir(self, description, width=48, height=48, mode="standard",
                               seed=None, outline=None, shading=None, detail=None, view=None, template_id=None, **kwargs):
        payload = {"description": description, "image_size": {"width": width, "height": height}, "mode": mode}
        for k, v in [("outline", outline), ("shading", shading), ("detail", detail), ("view", view), ("template_id", template_id), ("seed", seed)]:
            if v is not None: payload[k] = v
        payload.update(kwargs)
        return self._post("create-character-with-8-directions", payload)

    def animate_character(self, character_id, action_description=None, template_animation_id=None,
                          mode=None, directions=None, frame_count=None, seed=None, **kwargs):
        payload = {"character_id": character_id}
        for k, v in [("action_description", action_description), ("template_animation_id", template_animation_id),
                      ("mode", mode), ("directions", directions), ("frame_count", frame_count), ("seed", seed)]:
            if v is not None: payload[k] = v
        payload.update(kwargs)
        return self._post("animate-character", payload)

    def list_characters(self, limit=100, offset=0):
        return self._get(f"characters?limit={limit}&offset={offset}")

    def get_character(self, character_id):
        return self._get(f"characters/{character_id}")

    def export_character_zip(self, character_id):
        return self._get(f"characters/{character_id}/zip")

    # -- Tilesets --
    def create_tileset(self, lower_desc, upper_desc, tile_width=32, tile_height=32,
                       transition_desc="", view=None, seed=None, **kwargs):
        payload = {"lower_description": lower_desc, "upper_description": upper_desc,
                   "transition_description": transition_desc, "tile_size": {"width": tile_width, "height": tile_height}}
        if view: payload["view"] = view
        if seed is not None: payload["seed"] = seed
        payload.update(kwargs)
        return self._post("tilesets", payload)

    def create_tileset_sidescroller(self, lower_desc, tile_width=32, tile_height=32, transition_desc="", seed=None, **kwargs):
        payload = {"lower_description": lower_desc, "transition_description": transition_desc,
                   "tile_size": {"width": tile_width, "height": tile_height}}
        if seed is not None: payload["seed"] = seed
        payload.update(kwargs)
        return self._post("tilesets-sidescroller", payload)

    def get_tileset(self, tileset_id):
        return self._get(f"tilesets/{tileset_id}")

    def create_isometric_tile(self, description, width=32, height=32, seed=None,
                               tile_shape="thin tile", **kwargs):
        """Create isometric tile.

        Args:
            tile_shape: 'thin tile' (flat) | 'thick tile' | 'block'
            width/height: max 64px (API limit)

        Note: Web UI has thickness/view_angle sliders but API doesn't expose them.
        Use 'thin tile' for flat floor tiles.
        """
        # API enforces max 64x64
        width = min(width, 64)
        height = min(height, 64)
        payload = {
            "description": description,
            "image_size": {"width": width, "height": height},
            "isometric_tile_shape": tile_shape
        }
        if seed is not None: payload["seed"] = seed
        payload.update(kwargs)
        return self._post("create-isometric-tile", payload)

    def get_isometric_tile(self, tile_id):
        return self._get(f"isometric-tiles/{tile_id}")

    def create_tiles_pro(self, description, tile_type="isometric", tile_size=32, tile_view="low top-down", seed=None, **kwargs):
        """Number each tile variation in the description: '1). grass 2). stone 3). lava'. API auto-detects count."""
        payload = {"description": description, "tile_type": tile_type, "tile_size": tile_size, "tile_view": tile_view}
        if seed is not None: payload["seed"] = seed
        payload.update(kwargs)
        return self._post("create-tiles-pro", payload)

    def get_tiles_pro(self, tile_id):
        return self._get(f"tiles-pro/{tile_id}")

    # -- Map Objects --
    def create_map_object(self, description, width=64, height=64, view="high top-down",
                           outline=None, shading=None, detail=None, seed=None, **kwargs):
        payload = {"description": description, "image_size": {"width": width, "height": height}, "view": view}
        for k, v in [("outline", outline), ("shading", shading), ("detail", detail), ("seed", seed)]:
            if v is not None: payload[k] = v
        payload.update(kwargs)
        return self._post("map-objects", payload)

    def create_object_4dir(self, description, width=64, height=64, seed=None, **kwargs):
        payload = {"description": description, "image_size": {"width": width, "height": height}}
        if seed is not None: payload["seed"] = seed
        payload.update(kwargs)
        return self._post("create-object-with-4-directions", payload)

    # -- Animation --
    def animate_with_text_v3(self, first_frame_b64, action, frame_count=8, seed=None, no_background=False, **kwargs):
        payload = {"first_frame": {"type": "base64", "base64": first_frame_b64, "format": "png"},
                   "action": action, "frame_count": frame_count, "no_background": no_background}
        if seed is not None: payload["seed"] = seed
        payload.update(kwargs)
        return self._post("animate-with-text-v3", payload)

    # -- Editing --
    def edit_image(self, image_b64, description, width, height, seed=None, no_background=False, **kwargs):
        payload = {"image": {"type": "base64", "base64": image_b64, "format": "png"},
                   "image_size": {"width": width, "height": height}, "description": description,
                   "width": width, "height": height, "no_background": no_background}
        if seed is not None: payload["seed"] = seed
        payload.update(kwargs)
        return self._post("edit-image", payload)

    # -- Image Operations --
    def remove_background(self, image_b64, width, height, **kwargs):
        payload = {"image": {"type": "base64", "base64": image_b64, "format": "png"}, "image_size": {"width": width, "height": height}}
        payload.update(kwargs)
        return self._post("remove-background", payload)

    def image_to_pixelart(self, image_b64, in_w, in_h, out_w, out_h, seed=None):
        payload = {"image": {"type": "base64", "base64": image_b64, "format": "png"},
                   "image_size": {"width": in_w, "height": in_h}, "output_size": {"width": out_w, "height": out_h}}
        if seed is not None: payload["seed"] = seed
        return self._post("image-to-pixelart", payload)

    # -- Rotation --
    def generate_8_rotations(self, ref_image_b64, width, height, description=None,
                              view="low top-down", seed=None, no_background=False, **kwargs):
        payload = {"reference_image": {"type": "base64", "base64": ref_image_b64, "format": "png"},
                   "image_size": {"width": width, "height": height}, "view": view, "no_background": no_background}
        if description: payload["description"] = description
        if seed is not None: payload["seed"] = seed
        payload.update(kwargs)
        return self._post("generate-8-rotations-v2", payload)

    # -- Background Jobs --
    def get_job(self, job_id):
        return self._get(f"background-jobs/{job_id}")

    def poll_job(self, job_id, interval=3, max_wait=180):
        elapsed = 0
        while elapsed < max_wait:
            result = self.get_job(job_id)
            if "error" in result: return result
            status = result.get("status", result.get("data", {}).get("status", "unknown"))
            if status in ("completed", "complete", "done"): return result
            if status in ("failed", "error"): return result
            time.sleep(interval)
            elapsed += interval
        return {"error": "timeout", "elapsed": elapsed}

    def wait_and_save(self, job_response, prefix, interval=3, max_wait=180):
        job_id = job_response.get("background_job_id") or job_response.get("data", {}).get("background_job_id")
        if not job_id:
            return self._save_result_images(job_response, prefix)
        result = self.poll_job(job_id, interval, max_wait)
        if "error" in result and result["error"] not in ("timeout",):
            return result
        return self._save_result_images(result, prefix)


# -- Quick-use functions --
_default = None
def _pl():
    global _default
    if _default is None:
        _default = PixelLab()
    return _default

def balance(): return _pl().balance()
def generate(desc, w=64, h=64, **kw): return _pl().generate_image_pixflux(desc, w, h, **kw)
def character_4dir(desc, w=48, h=48, **kw): return _pl().create_character_4dir(desc, w, h, **kw)
def character_8dir(desc, w=48, h=48, **kw): return _pl().create_character_8dir(desc, w, h, **kw)
def tileset(lower, upper, tw=32, th=32, **kw): return _pl().create_tileset(lower, upper, tw, th, **kw)
def iso_tile(desc, w=32, h=32, **kw): return _pl().create_isometric_tile(desc, w, h, **kw)
def map_object(desc, w=64, h=64, **kw): return _pl().create_map_object(desc, w, h, **kw)
def job_status(job_id): return _pl().get_job(job_id)
def poll(job_id, **kw): return _pl().poll_job(job_id, **kw)

if __name__ == "__main__":
    print("Checking PixelLab balance...")
    print(json.dumps(balance(), indent=2))
