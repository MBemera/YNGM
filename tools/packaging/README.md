# Packaging helpers

From the project root: `python tools/packaging/build-yngm.py`.

- `build-yngm.py`: exports the game, assembles licences, compiles the per-user installer.
- `yngm_windows_resources.py`: embeds the multi-resolution logo and product metadata through Windows APIs.
- `yngm-engine-licences.gd`: extracts exact Godot engine/library/font notices.

Uses existing tools in `tools/godot/` and `tools/nsis/`; no API keys or installation.
Produces `dist/YNGM-1.0.0-Windows-x64-Setup.exe`. Build outputs may be replaced.
Details and verification: [installer guide](../../installer/README.md).
