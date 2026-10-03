# Packaging

`python tools/packaging/build-yngm.py`, run from the project root on Windows, builds:

- `dist/YNGM-1.0.0-Windows-x64-Setup.exe`: a per-user NSIS installer. No admin prompt; Start-menu shortcuts
  for the game, credits and uninstaller; optional desktop shortcut.
- `dist/YNGM-1.0.0-Linux-x86_64.tar.gz`: the game, `install.sh` and `README-LINUX.txt`.
- `dist/YNGM-1.0.0-macOS-universal.zip`: an ad-hoc signed universal app (Apple Silicon and Intel) and
  `README-MACOS.txt`.

Sizes and SHA-256 hashes are written to `dist/build-result.json`. The packages themselves are published as
GitHub Release assets, not committed.

## Tools the build expects

These are git-ignored. Download them once:

| Path | What | Source |
|---|---|---|
| `tools/godot/Godot_v4.7.2-stable_win64_console.exe` | Godot 4.7.2 editor (console build) | [godot-builds 4.7.2-stable](https://github.com/godotengine/godot-builds/releases/tag/4.7.2-stable) |
| `tools/godot/templates/` | Extracted `Godot_v4.7.2-stable_export_templates.tpz` (`windows_*`, `linux_*`, `macos.zip`) | Same release; check the archive against the release's `SHA512-SUMS.txt` |
| `tools/nsis/nsis-3.13/` | NSIS 3.13 portable (`makensis.exe`, `COPYING`) | [NSIS 3.13](https://sourceforge.net/projects/nsis/files/NSIS%203/3.13/) |
| Python packages | Pillow and pytest | `python -m pip install -r tools/packaging/requirements.txt` |

`game/export_presets.cfg` points at the templates through relative paths (`../tools/godot/templates/...`).

## What the installer does

- Shows the cover art as a fading splash when it starts, and on the welcome and finish pages.
- While files copy, shows the cover art next to a **Tips and tricks** box that slides to a new tip at each install
  step, above the normal progress bar.
- Installs to `%LOCALAPPDATA%\Programs\YNGM` and writes an install marker. The uninstaller removes only the
  files it installed, and only if that marker matches.
- `/S` installs silently and skips the splash. `/TESTMODE` skips the registry and shortcut writes, for staged test
  installs: `Setup.exe /S /TESTMODE /D=C:\absolute\folder` (`/D` must come last).

The splash, wizard and progress-page bitmaps are cut from `game/assets/branding/cover-art.png` by
`tools/packaging/yngm_installer_artwork.py` into `build/installer-art/` on every build.

## Licence coverage

`CREDITS-AND-LICENSES.txt` and `licenses/` ship beside the game in every package (and inside its game pack). They
include:

- the game's MIT licence;
- the exact Godot 4.7.2 engine, library and font notices;
- the full CC0 legal text;
- the original Kenney, RobotExpressive, helicopter and Poly Haven notices;
- the four voice model cards;
- the NSIS `COPYING` file.

`licenses/asset-manifest.json` lists every media file with its SHA-256, creator and licence. No Piper executable,
voice model, Python runtime or other development tool is distributed. See [LEGAL.md](../LEGAL.md).

## Signing

The installer and game are not code-signed. The macOS app is ad-hoc signed, not notarised. Signing needs a
Windows code-signing certificate and an Apple Developer ID.

## Artwork

- Cover art: `game/assets/branding/cover-art.png`, supplied by the author.
- Logo and icon: `game/assets/branding/yngm-logo.png` and `yngm.ico`, made with Codex's built-in image
  generation. The exact prompt is in [logo-prompt.txt](logo-prompt.txt).
