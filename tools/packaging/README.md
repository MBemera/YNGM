# Packaging helpers

From the project root: `python tools/packaging/build-yngm.py` (Windows).

- `build-yngm.py`: exports the game for Windows, Linux and macOS, assembles the licence bundle and compiles the installer.
- `yngm_installer_artwork.py`: cuts the installer splash, wizard and progress-page bitmaps from the cover art.
- `yngm_unix_packages.py`: builds the Linux tar.gz and macOS zip with their readmes and install helper.
- `yngm_windows_resources.py`: embeds the logo and product metadata in `YNGM.exe` through Windows APIs.
- `yngm-engine-licences.gd`: extracts the exact Godot engine, library and font notices.
- `test_yngm_installer_artwork.py`: `python -m pytest tools/packaging`.

Requirements: `python -m pip install -r tools/packaging/requirements.txt`, plus the Godot and NSIS tools described
in the [packaging guide](../../installer/README.md). No API keys are needed.
