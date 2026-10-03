"""Download the CC0 Poly Haven textures and sky used by the game into game/assets.

Run: python tools/fetch_polyhaven.py
"""

import json
import urllib.request
from pathlib import Path

GAME_ASSETS = Path(__file__).resolve().parent.parent / "game" / "assets"
TEXTURE_IDS = [
    "marble_01", "concrete_wall_008", "metal_plate", "concrete_floor_worn_001", "concrete_floor_02",
    "asphalt_02", "dirty_carpet", "corrugated_iron", "metal_grate_rusty", "large_red_bricks",
    "laminate_floor_02", "hangar_concrete_floor", "floor_tiles_06", "blue_metal_plate",
]
TEXTURE_MAPS = {"Diffuse": "albedo", "nor_gl": "normal", "Rough": "roughness"}
TEXTURE_RESOLUTION = "1k"
SKY_ID = "the_sky_is_on_fire"
SKY_RESOLUTION = "2k"
USER_AGENT = "YNGM-asset-fetch/1.0"


def fetch_bytes(url: str) -> bytes:
    request = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
    with urllib.request.urlopen(request, timeout=60) as response:
        return response.read()


def fetch_file_index(asset_id: str) -> dict:
    return json.loads(fetch_bytes(f"https://api.polyhaven.com/files/{asset_id}"))


def download(url: str, destination: Path) -> None:
    if destination.exists():
        print(f"Kept existing {destination}")
        return
    destination.parent.mkdir(parents=True, exist_ok=True)
    destination.write_bytes(fetch_bytes(url))
    print(f"Wrote {destination}")


def download_texture(asset_id: str) -> None:
    files = fetch_file_index(asset_id)
    for map_name, file_stem in TEXTURE_MAPS.items():
        url = files[map_name][TEXTURE_RESOLUTION]["jpg"]["url"]
        download(url, GAME_ASSETS / "textures" / asset_id / f"{file_stem}.jpg")


def download_sky() -> None:
    files = fetch_file_index(SKY_ID)
    url = files["hdri"][SKY_RESOLUTION]["hdr"]["url"]
    download(url, GAME_ASSETS / "sky" / f"{SKY_ID}_{SKY_RESOLUTION}.hdr")


def write_licence_note() -> None:
    lines = ["Poly Haven assets (https://polyhaven.com), licence: CC0 1.0 (public domain).", ""]
    lines += [f"- texture: https://polyhaven.com/a/{asset_id}" for asset_id in TEXTURE_IDS]
    lines.append(f"- hdri: https://polyhaven.com/a/{SKY_ID}")
    (GAME_ASSETS / "POLYHAVEN_LICENSE.txt").write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> None:
    for asset_id in TEXTURE_IDS:
        download_texture(asset_id)
    download_sky()
    write_licence_note()


if __name__ == "__main__":
    main()
