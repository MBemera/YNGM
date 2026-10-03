"""Build YNGM's Windows installer plus Linux and macOS packages, with the licence bundle."""
import argparse
import hashlib
import json
import logging
import shutil
import subprocess
from pathlib import Path
from yngm_windows_resources import embed_windows_resources
from yngm_unix_packages import ASSISTANT_HELP, build_linux_package, build_macos_package

PROJECT = Path(__file__).resolve().parents[2]
VERSION = "1.0.0"
TITLE = "Escape from the Permanent Underclass"
KENNEY = {"blasters": "blaster-kit", "cars": "car-kit", "characters": "mini-characters",
          "city": "city-kit-commercial", "furniture": "furniture-kit",
          "roads": "city-kit-roads", "station": "space-station-kit"}

CREDITS = """ESCAPE FROM THE PERMANENT UNDERCLASS / YNGM
Version 1.0.0

THIRD-PARTY CREDITS AND LICENCES
These notices cover the named third-party components. They do not change
ownership or licensing of the original game code, dialogue, sound effects or artwork.

ENGINE
Godot Engine 4.7.2: MIT / Expat licence.
Copyright 2014-present Godot Engine contributors.
Copyright 2007-2014 Juan Linietsky, Ariel Manzur.
https://godotengine.org/license/
Full engine and third-party notices, including embedded fonts, are in licenses/.
Corresponding engine and embedded-library source:
https://github.com/godotengine/godot/tree/4.7.2-stable
https://github.com/godotengine/godot/archive/refs/tags/4.7.2-stable.tar.gz

MODELS - CREATIVE COMMONS ZERO 1.0
Kenney: City Kit Commercial, City Kit Roads, Car Kit, Blaster Kit,
Mini Characters, Furniture Kit and Space Station Kit.
https://kenney.nl/assets
Original pack licence notices: licenses/Kenney-*.txt.

RobotExpressive: Tomas Laulhe / Quaternius; modifications by Don McCurdy
(facial expression morph targets, FBX2GLTF conversion, material adjustments).
https://www.quaternius.com/
https://github.com/KhronosGroup/glTF-Sample-Models/tree/main/2.0/RobotExpressive
Original model notice: licenses/RobotExpressive.md.

Helicopter by kazuma, downloaded from Poly Pizza, CC0 1.0.
https://poly.pizza/m/EQJ2MECUbx
Original model notice: licenses/Helicopter.txt.

TEXTURES AND SKY - CREATIVE COMMONS ZERO 1.0
Poly Haven: marble_01, concrete_wall_008, metal_plate,
concrete_floor_worn_001, concrete_floor_02, asphalt_02, dirty_carpet,
corrugated_iron, metal_grate_rusty, large_red_bricks, laminate_floor_02,
hangar_concrete_floor, floor_tiles_06, blue_metal_plate and the_sky_is_on_fire.
https://polyhaven.com/license
Individual source URLs: licenses/PolyHaven.txt.
Full CC0 legal text: licenses/CC0-1.0.txt.

VOICES
Prepared using Piper TTS with these voice datasets:
Joe: CC0 dataset from the Open Home Foundation voice datasets.
https://github.com/OHF-Voice/voice-datasets
John, Kristin and Norman: public-domain LibriVox recordings, voice models
prepared by Bryce Beattie. https://brycebeattie.com/files/tts/
https://huggingface.co/rhasspy/piper-voices
Original model cards: licenses/voice-*.txt.
The distribution contains generated WAV recordings; no Piper executable,
voice model, Python environment or development tool is included.

SOUND EFFECTS AND LOGO
Sound effects created for this game by tools/generate_sfx.py.
YNGM logo created for this project; no external image reference assets used.

INSTALLER
NSIS 3.13, copyright 1999-2026 Contributors, zlib/libpng licence.
The installer uses the zlib compression module.
https://nsis.sourceforge.io/
Full unmodified NSIS licence notice: licenses/NSIS-COPYING.txt.
Source: https://sourceforge.net/projects/nsis/files/NSIS%203/3.13/nsis-3.13-src.tar.bz2

Asset-by-asset provenance and hashes: licenses/asset-manifest.json.
"""

PLAYER_README = """ESCAPE FROM THE PERMANENT UNDERCLASS / YNGM 1.0.0

Run YNGM.exe, or use the installed Start-menu shortcut.
Windows 10/11 x64; keyboard and mouse; OpenGL 3.3 compatible graphics.
The installer contains the game and engine. No Godot install, Python,
account, internet connection or API key is required to play.

WASD move; mouse look; Shift sprint; Space jump; left mouse button fire.
1-7 or the mouse wheel switch weapons: foam dart blaster, confetti cannon,
slop grenade, NDA stapler (stuns), hype railgun (pierces), valuation bubble
(area pop) and disruptor (chain arcs). New weapons unlock as the story goes.
Green BRIDGE ROUND crates restore health. R restarts; Esc releases the mouse;
Enter skips story scenes; M returns to the menu after a level.

Eleven voiced story levels, from South of Market to the OMEGA launch pad.
Choose Easy, Normal, Hard or Nightmare from the main menu; progress and
difficulty are saved, and LEVEL SELECT replays any level you have reached.
GRAPHICS (Auto/Low/Medium/High) trades detail for frame rate; SHOW FPS shows
the frame counter. Frame rate is uncapped apart from vsync (monitor refresh).

Credits and full third-party licence texts are included in licenses/.
Use the Start-menu Credits and licences shortcut to open the credits.
Uninstall through Windows Installed apps or Uninstall.exe in the game folder.
The uninstaller removes only the files and shortcuts installed by this package.
Linux and macOS packages are built alongside this installer; each has its own README.
"""

def run_command(arguments: list[str], directory: Path, log_path: Path) -> None:
    logging.info("Run %s", Path(arguments[0]).name)
    with log_path.open("wb") as log:
        subprocess.run(arguments, cwd=directory, stdout=log, stderr=subprocess.STDOUT,
                       creationflags=subprocess.CREATE_NO_WINDOW, check=True)

def write_text(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8")

def collect_engine_notices(project: Path, licenses: Path) -> None:
    engine = project / "tools/godot/Godot_v4.7.2-stable_win64_console.exe"
    output = project / "installer/engine-licences.json"
    run_command([str(engine), "--headless", "--path", str(project / "game"), "--script",
                 str(Path(__file__).with_name("yngm-engine-licences.gd")), "--", str(output)],
                project, project / "installer/licence-extraction.log")
    notices = json.loads(output.read_text(encoding="utf-8"))
    if notices["version"]["string"] != "4.7.2-stable (official)":
        if not notices["version"]["string"].startswith("4.7.2"):
            raise RuntimeError("Unexpected Godot licence-source version")
    write_text(licenses / "GODOT-LICENSE.txt", notices["engine_license"])
    lines = []
    for component in notices["third_party_copyrights"]:
        lines.append(component["name"])
        for part in component["parts"]:
            lines.extend(part["copyright"])
            lines.extend(["Files: " + ", ".join(part["files"]), "Licence: " + part["license"], ""])
    for identifier, text in notices["third_party_licenses"].items():
        lines.extend(["=" * 72, identifier, "=" * 72, text, ""])
    write_text(licenses / "GODOT-THIRD-PARTY.txt", "\n".join(lines))
    shutil.copy2(project / "installer/GODOT_COPYRIGHT.txt", licenses / "GODOT-COPYRIGHT.txt")

def collect_asset_notices(project: Path, licenses: Path) -> None:
    assets = project / "game/assets"
    for folder in KENNEY:
        shutil.copy2(assets / f"models/{folder}/License.txt", licenses / f"Kenney-{folder}.txt")
    copies = {"models/robot/LICENSE_README.md": "RobotExpressive.md",
              "models/helicopter/LICENSE.txt": "Helicopter.txt", "POLYHAVEN_LICENSE.txt": "PolyHaven.txt"}
    for source, destination in copies.items():
        shutil.copy2(assets / source, licenses / destination)
    for voice in (project / "tools/tts/voices").glob("*.MODEL_CARD.txt"):
        shutil.copy2(voice, licenses / f"voice-{voice.name}")
    shutil.copy2(project / "installer/CC0-1.0.txt", licenses / "CC0-1.0.txt")
    shutil.copy2(project / "tools/nsis/nsis-3.13/COPYING", licenses / "NSIS-COPYING.txt")

def describe_asset(path: Path) -> dict:
    parts = path.parts
    if parts[0] == "models" and parts[1] in KENNEY:
        return {"creator": "Kenney", "license": "CC0-1.0", "source": "https://kenney.nl/assets/" + KENNEY[parts[1]]}
    if parts[:2] == ("models", "robot"):
        return {"creator": "Tomas Laulhe / Quaternius; modifications by Don McCurdy", "license": "CC0-1.0"}
    if parts[:2] == ("models", "helicopter"):
        return {"creator": "kazuma", "license": "CC0-1.0", "source": "https://poly.pizza/m/EQJ2MECUbx"}
    if parts[0] in ("textures", "sky"):
        identifier = parts[1] if parts[0] == "textures" else "the_sky_is_on_fire"
        return {"creator": "Poly Haven", "license": "CC0-1.0", "source": "https://polyhaven.com/a/" + identifier}
    if parts[:2] == ("audio", "voice"):
        voice = "joe" if path.name.startswith("intro_") else path.name.split("_", 1)[0]
        if voice not in ("joe", "john", "kristin", "norman"):
            raise ValueError(f"Unknown voice: {path}")
        return {"creator": "Piper voice: " + voice, "license": "CC0 voice dataset" if voice == "joe" else "Public-domain voice dataset",
                "notice": f"voice-en_US-{voice}-medium.MODEL_CARD.txt"}
    if parts[:2] == ("audio", "sfx") or parts[0] == "branding":
        return {"creator": "Original project content", "license": "Project content; no third-party asset licence"}
    raise ValueError(f"Missing asset provenance: {path}")

def write_asset_manifest(project: Path, licenses: Path) -> None:
    assets, entries = project / "game/assets", []
    media_types = {".glb", ".jpg", ".png", ".hdr", ".wav", ".ico"}
    for path in sorted(assets.rglob("*")):
        if not path.is_file() or path.suffix.lower() in (".import", ".txt", ".md"):
            continue
        if path.suffix.lower() not in media_types:
            raise ValueError(f"Unreviewed asset type: {path}")
        relative = path.relative_to(assets)
        entries.append({"path": str(relative).replace("\\", "/"), "sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
                        **describe_asset(relative)})
    write_text(licenses / "asset-manifest.json", json.dumps({"assets": entries}, indent=2, ensure_ascii=False))
    logging.info("Licence manifest covers %s media files", len(entries))

def prepare_package_notices(project: Path, package: Path) -> None:
    licenses = project / "game/licenses"
    licenses.mkdir(exist_ok=True)
    collect_engine_notices(project, licenses)
    collect_asset_notices(project, licenses)
    write_asset_manifest(project, licenses)
    write_text(licenses / "CREDITS-AND-LICENSES.txt", CREDITS)
    write_text(package / "CREDITS-AND-LICENSES.txt", CREDITS)
    write_text(package / "README.txt", PLAYER_README + "\n" + ASSISTANT_HELP.format(readme="README.txt"))
    shutil.copytree(licenses, package / "licenses", dirs_exist_ok=True)
    shutil.copy2(project / "game/assets/branding/yngm.ico", package / "yngm.ico")

def export_game(project: Path, package: Path) -> None:
    engine = project / "tools/godot/Godot_v4.7.2-stable_win64_console.exe"
    run_command([str(engine), "--headless", "--path", str(project / "game"), "--import"],
                project / "game", project / "installer/import.log")
    run_command([str(engine), "--headless", "--path", str(project / "game"), "--export-release",
                 "Windows Desktop", str(package / "YNGM.exe")], project / "game", project / "installer/export.log")
    embed_windows_resources(package / "YNGM.exe", package / "yngm.ico", VERSION, TITLE)
    if not (package / "YNGM.pck").is_file():
        raise RuntimeError("Release export did not produce its game pack")

def write_uninstall_files(project: Path, package: Path) -> None:
    files = sorted((path.relative_to(package) for path in package.rglob("*") if path.is_file()), reverse=True)
    directories = sorted((path.relative_to(package) for path in package.rglob("*") if path.is_dir()),
                         key=lambda path: len(path.parts), reverse=True)
    lines = [f'  Delete "$INSTDIR\\{path}"' for path in files]
    lines.extend(f'  RMDir "$INSTDIR\\{path}"' for path in directories)
    write_text(project / "installer/uninstall-files.nsh", "\n".join(lines) + "\n")

def compile_installer(project: Path, package: Path) -> Path:
    compiler = project / "tools/nsis/nsis-3.13/makensis.exe"
    output = project / f"dist/YNGM-{VERSION}-Windows-x64-Setup.exe"
    output.parent.mkdir(exist_ok=True)
    write_uninstall_files(project, package)
    run_command([str(compiler), "/V3", f"/DPROJECT_ROOT={project}", f"/DPACKAGE_ROOT={package}",
                 f"/DOUTPUT_FILE={output}", str(project / "installer/yngm.nsi")],
                project / "installer", project / "installer/compile.log")
    return output

def export_unix_games(project: Path) -> tuple[Path, Path]:
    engine = project / "tools/godot/Godot_v4.7.2-stable_win64_console.exe"
    linux_build, macos_build = project / "build/linux", project / "build/macos"
    linux_build.mkdir(parents=True, exist_ok=True)
    macos_build.mkdir(parents=True, exist_ok=True)
    run_command([str(engine), "--headless", "--path", str(project / "game"), "--export-release", "Linux",
                 str(linux_build / "YNGM.x86_64")], project / "game", project / "installer/export-linux.log")
    run_command([str(engine), "--headless", "--path", str(project / "game"), "--export-release", "macOS",
                 str(macos_build / "YNGM-macOS.zip")], project / "game", project / "installer/export-macos.log")
    if not (linux_build / "YNGM.pck").is_file() or not (macos_build / "YNGM-macOS.zip").is_file():
        raise RuntimeError("Linux or macOS export did not produce its output")
    return linux_build, macos_build / "YNGM-macOS.zip"

def build_unix_packages(project: Path) -> list[Path]:
    linux_build, macos_zip = export_unix_games(project)
    linux = build_linux_package(project, VERSION, linux_build, project / f"dist/YNGM-{VERSION}-Linux-x86_64.tar.gz")
    macos = build_macos_package(project, VERSION, macos_zip, project / f"dist/YNGM-{VERSION}-macOS-universal.zip")
    return [linux, macos]

def describe_artifact(path: Path, platform: str, signing: str) -> dict:
    return {"platform": platform, "file": str(path), "size_mb": round(path.stat().st_size / 1e6, 2),
            "sha256": hashlib.sha256(path.read_bytes()).hexdigest(), "signing": signing}

def save_build_result(project: Path, installer: Path, linux: Path, macos: Path) -> None:
    result = {"version": VERSION, "artifacts": [
        describe_artifact(installer, "Windows x64", "unsigned"),
        describe_artifact(linux, "Linux x86_64", "not applicable"),
        describe_artifact(macos, "macOS universal (Apple Silicon + Intel)", "ad-hoc signed, not notarised")]}
    write_text(project / "dist/build-result.json", json.dumps(result, indent=2))
    print(json.dumps(result, indent=2))

def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--project", type=Path, default=PROJECT)
    arguments = parser.parse_args()
    project, package = arguments.project, arguments.project / "build/windows"
    package.mkdir(parents=True, exist_ok=True)
    prepare_package_notices(project, package)
    export_game(project, package)
    installer = compile_installer(project, package)
    linux, macos = build_unix_packages(project)
    save_build_result(project, installer, linux, macos)

if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO, format="%(levelname)s: %(message)s")
    try:
        main()
    except Exception:
        logging.exception("Packaging failed; see installer/*.log")
        raise SystemExit(1)