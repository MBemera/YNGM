# Legal notices

This file records what the game is made of, who made each part, and the licence each part is under.
It is a provenance record, not legal advice.

## This project's licence

The original work in this repository is released under the [MIT licence](LICENSE), Copyright (c) 2026 Matthew Bright.
That covers the game code, level design, story text, generated sound effects, the YNGM logo, the cover art, the
packaging scripts and the documentation.

Two exceptions:

- Third-party assets and the engine keep their own licences (listed below).
- The `joe_*.wav` voice clips are **not** under MIT. See [Voice clips](#voice-clips).

## Shipped in the game and installers

| Component | Used for | Licence | Notice |
|---|---|---|---|
| [Godot Engine](https://godotengine.org/) 4.7.2 | Engine runtime inside every build | MIT (Expat) | [GODOT-LICENSE.txt](game/licenses/GODOT-LICENSE.txt), [GODOT-COPYRIGHT.txt](game/licenses/GODOT-COPYRIGHT.txt) |
| Godot's bundled libraries and fonts (FreeType, HarfBuzz, ICU, mbedTLS, Open Sans and others) | Text, rendering, platform support | Various permissive licences | [GODOT-THIRD-PARTY.txt](game/licenses/GODOT-THIRD-PARTY.txt) |
| [Kenney](https://kenney.nl/assets) City Kit Commercial, City Kit Roads, Car Kit, Blaster Kit, Mini Characters, Furniture Kit, Space Station Kit | Buildings, roads, cars, people, blasters, props | CC0 1.0 | [Kenney-*.txt](game/licenses/) |
| RobotExpressive by Tomás Laulhé ([Quaternius](https://quaternius.com/)), modifications by Don McCurdy | Security bots and the exosuit boss | CC0 1.0 | [RobotExpressive.md](game/licenses/RobotExpressive.md) |
| [Helicopter](https://poly.pizza/m/EQJ2MECUbx) by kazuma (Poly Pizza) | Rescue helicopter | CC0 1.0 | [Helicopter.txt](game/licenses/Helicopter.txt) |
| [Poly Haven](https://polyhaven.com/license) textures (14) and the `the_sky_is_on_fire` HDRI | Surfaces and sky | CC0 1.0 | [PolyHaven.txt](game/licenses/PolyHaven.txt) |
| Voice clips generated with Piper voices `kristin`, `norman`, `john` and `joe` | All spoken lines | See [Voice clips](#voice-clips) | [voice-*.MODEL_CARD.txt](game/licenses/) |
| [NSIS](https://nsis.sourceforge.io/) 3.13 | Windows installer and uninstaller | zlib/libpng | [NSIS-COPYING.txt](game/licenses/NSIS-COPYING.txt) |
| Original project content (code, story, sound effects from `tools/generate_sfx.py`, logo, cover art) | Everything else | MIT | [LICENSE](LICENSE) |

Every package carries these texts in its `licenses/` folder plus `CREDITS-AND-LICENSES.txt`.
[asset-manifest.json](game/licenses/asset-manifest.json) lists every media file with its SHA-256, creator and licence.
The full CC0 legal text is in [CC0-1.0.txt](game/licenses/CC0-1.0.txt).

## Voice clips

All spoken lines were synthesised offline with [Piper](https://github.com/OHF-Voice/piper1-gpl). No real person's
voice was recorded or cloned for this game.

- **`kristin`, `norman`, `john`** (81 clips): voice models by Bryce Beattie, trained
  on public-domain [LibriVox](https://librivox.org/) recordings. `kristin` and `norman` were trained from scratch;
  `john` was fine-tuned from `kristin`. These clips are under MIT with the rest of the project.
- **`joe`** (31 clips, prefix `joe_`: Preston Exitwell, the exosuit boss and the helicopter leader): the `joe`
  dataset is CC0, but the model was fine-tuned from Piper's `lessac` voice. That voice was trained on the
  [Blizzard Challenge 2013 Lessac data](https://www.cstr.ed.ac.uk/projects/blizzard/2013/lessac_blizzard2013/license.html),
  whose licence permits research use only and excludes commercial use. The licence does not say how it applies to
  models fine-tuned from that data or to their output. Because of that:
  - the `joe_*.wav` clips are excluded from the MIT licence and are distributed only as part of this free,
    non-commercial game;
  - do not reuse them commercially;
  - before any commercial release, regenerate those lines with a voice that has a clean lineage
    (change the voice in `game/data/story/cast.json`, `game/scripts/enemy_types.gd` and `game/scripts/helicopter.gd`,
    then run `tools/generate_voice.py`).

## Build and development tools (not shipped)

| Tool | Used for | Licence |
|---|---|---|
| Piper TTS 1.8.0 (piper1-gpl, includes espeak-ng) | Generating the voice clips | GPL-3.0-or-later |
| ONNX Runtime 1.30.0 | Running the Piper voice models | MIT |
| Godot 4.7.2 editor and export templates | Editing, testing, exporting | MIT |
| Python 3.12 | Packaging and asset scripts | PSF License |
| Pillow 12.3.0 | Installer artwork and icons | MIT-CMU |
| pytest 9.1.1 | Packaging tests | MIT |
| FFmpeg | Recording gameplay video during development | LGPL/GPL (depends on build) |
| Claude Code (Anthropic) and Codex (OpenAI) | AI coding assistants (see below) | Provider terms of service |

None of these programs are included in the game or installers. Piper's GPL applies to Piper itself. Under the
[GPL FAQ](https://www.gnu.org/licenses/gpl-faq.html#GPLOutput), a program's output is generally not covered by
the program's licence, so the generated WAV files are not GPL.

## AI assistance

The code, levels, dialogue, tests, packaging and documentation were written with AI coding assistants (Anthropic's
Claude Code and OpenAI's Codex), directed and reviewed by the author. The YNGM logo was made with Codex's built-in
image generation from the prompt in [installer/logo-prompt.txt](installer/logo-prompt.txt), with no reference images.
The cover art was supplied by the author. Both providers' terms assign any rights they hold in outputs to the user.
How far copyright protects AI-generated material varies by country.

## Fiction and trademarks

This is satire. Every character, company, product, startup, investor and AI model in the game is fictional. Any
resemblance to real people or businesses is coincidental. On 2026-10-03 the names were checked against web
searches, and any that matched a real business, product, trademark or well-known person were replaced. Real places
(San Francisco, Sand Hill Road, the 101, Pier 70) appear only as settings. No company or person depicted, named or
parodied has any affiliation with the game, or endorses or sponsors it.

Tool and asset names in this file (Godot, Kenney, Poly Haven, Poly Pizza, Quaternius, NSIS, Piper, Claude, Codex,
GitHub and others) are trademarks of their owners and appear only to credit them. The foam blaster is a generic
toy design and does not represent any brand.

## Privacy

The game has no accounts, telemetry, ads, purchases or network access. It saves level progress and settings only
in a local file on your computer.

## Warranty and signing

Provided as is, without warranty (see [LICENSE](LICENSE)). The Windows installer is not code-signed. The macOS app
is ad-hoc signed and not notarised. Each release lists SHA-256 hashes so you can check the downloads.
