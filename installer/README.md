# Windows packaging

Player installer: `../dist/YNGM-1.0.0-Windows-x64-Setup.exe`.
Windows 10/11 x64, OpenGL 3.3, keyboard and mouse. Offline and self-contained.
Per-user installation; Start-menu game/credits/uninstall shortcuts; optional desktop shortcut.
The logo is embedded in the game, installer, uninstaller and shortcuts.

## Rebuild

From the project root run `python tools/packaging/build-yngm.py`.
Project helpers and usage are in `../tools/packaging/README.md`.
Installer source: `yngm.nsi`. Export settings: `../game/export_presets.cfg`.
Build output: `../build/windows/`. Final installer metadata: `../dist/build-result.json`.
Logs: `import.log`, `export.log`, `licence-extraction.log`, `compile.log`.
No signing certificate is configured; the installer and game are unsigned.

## Pinned build tools

- Godot 4.7.2 official engine/export templates, MIT engine plus bundled component licences.
  https://github.com/godotengine/godot-builds/releases/tag/4.7.2-stable
  Template archive SHA256: f298490b8d44d934be425a5a65a51bf15f422428b229a06a6e11d9ffea248011.
- NSIS 3.13 portable, maintained by multiple contributors, zlib/libpng core licence.
  https://sourceforge.net/projects/nsis/files/NSIS%203/3.13/
  Uses solid zlib compression. Original COPYING is distributed.
- Existing Python/Pillow and Windows resource APIs convert/embed the project icon.
  The archived rcedit tool is not used.

## Licence coverage

`CREDITS-AND-LICENSES.txt` and `licenses/` ship beside the game and inside its PCK.
Includes exact Godot 4.7.2 engine/library/font notices, corresponding upstream source
URLs, full CC0 legal text, original Kenney/RobotExpressive/helicopter/Poly Haven
notices, four voice model cards, and original NSIS COPYING.
`licenses/asset-manifest.json` lists every source media asset (674 as of 2026-10-03) with SHA256 hashes.
No Piper executable, voice models, Python or development tools are distributed.
These third-party notices do not grant a new licence for the original game code/content.

## Verification

A staged install uses `/S /TESTMODE /D=<absolute-project-build-folder>`.
`/TESTMODE` skips registry and Start-menu/desktop writes. `/D` must be last.
The test installation is retained; running its uninstaller would delete files and
requires user approval. The normal uninstaller deletes only enumerated package files,
checks an installation marker, and removes only empty directories.
Final staged install matched all 26 package file hashes. The exported game pack passed
56 gameplay checks. The installed executable completed startup and automatic shutdown
with no errors. Native game/setup/uninstaller icons were extracted and inspected.
Windows locked during the visible launch check; the desktop screenshot is not evidence
of the menu. Test teardown reports resource warnings; installed-runtime smoke does not.

## Artwork

`../game/assets/branding/yngm-logo.png`, `yngm.ico`; built-in imagegen.
Exact generation prompt: `logo-prompt.txt`.
