# Legal notices

This file records what the game is made of, who made each part, and the licence each part is under.
It is a provenance record, not legal advice.

## This project's licence

The original work in this repository is released under the [MIT licence](LICENSE), Copyright (c) 2026 Matthew Bright.
That covers the game code, level design, story text, voice clips, generated sound effects, the YNGM logo, the cover
art, the packaging scripts and the documentation. Third-party assets and the engine keep their own licences (listed
below), all of them free and open-source licences: CC0, MIT, zlib, and the permissive licences of Godot's bundled
libraries and fonts.

## Shipped in the game and installers

| Component | Used for | Licence | Notice |
|---|---|---|---|
| [Godot Engine](https://godotengine.org/) 4.7.2 | Engine runtime inside every build | MIT (Expat) | [GODOT-LICENSE.txt](game/licenses/GODOT-LICENSE.txt), [GODOT-COPYRIGHT.txt](game/licenses/GODOT-COPYRIGHT.txt) |
| Godot's bundled libraries and fonts (FreeType, HarfBuzz, ICU, mbedTLS, libjpeg-turbo, Open Sans and others) | Text, rendering, platform support | MIT/Expat, BSD, Apache-2.0, Zlib, OFL-1.1, FTL, IJG, Unicode, BSL-1.0, MPL-2.0 (CA certificate list) and CC-BY-4.0 (Godot logo) | [GODOT-THIRD-PARTY.txt](game/licenses/GODOT-THIRD-PARTY.txt) |
| [Kenney](https://kenney.nl/assets) City Kit Commercial, City Kit Roads, Car Kit, Blaster Kit, Mini Characters, Furniture Kit, Space Station Kit | Buildings, roads, cars, people, blasters, props | CC0 1.0 | [Kenney-*.txt](game/licenses/) |
| RobotExpressive by Tomás Laulhé ([Quaternius](https://quaternius.com/)), modifications by Don McCurdy | Security bots and the exosuit boss | CC0 1.0 | [RobotExpressive.md](game/licenses/RobotExpressive.md) |
| [Helicopter](https://poly.pizza/m/EQJ2MECUbx) by kazuma (Poly Pizza) | Rescue helicopter | CC0 1.0 | [Helicopter.txt](game/licenses/Helicopter.txt) |
| [Poly Haven](https://polyhaven.com/license) textures (14) and the `the_sky_is_on_fire` HDRI | Surfaces and sky | CC0 1.0 | [PolyHaven.txt](game/licenses/PolyHaven.txt) |
| Voice clips generated with the public-domain Piper voices `kristin`, `norman` and `john` | All spoken lines | MIT (see [Voice clips](#voice-clips)) | [voice-*.MODEL_CARD.txt](game/licenses/) |
| [NSIS](https://nsis.sourceforge.io/) 3.13 (zlib compressor, AdvSplash, System and nsDialogs plug-ins) | Windows installer and uninstaller | zlib/libpng | [NSIS-COPYING.txt](game/licenses/NSIS-COPYING.txt) |
| Original project content (code, story, voice clips, sound effects from `tools/generate_sfx.py`, logo, cover art) | Everything else | MIT | [LICENSE](LICENSE) |
| Original v.2 models (`assets/models/v2/`) and Blender source (`assets-source/`) | Weapons, enemy equipment, scenery and objective props | MIT | [LICENSE](LICENSE) |

Every package carries these texts in its `licenses/` folder plus `CREDITS-AND-LICENSES.txt`.
Portions of this software are copyright © The FreeType Project (www.freetype.org). All rights reserved.
This software is based in part on the work of the Independent JPEG Group.
[asset-manifest.json](game/licenses/asset-manifest.json) lists every media file with its SHA-256, creator and licence.
The full CC0 legal text is in [CC0-1.0.txt](game/licenses/CC0-1.0.txt).

## Voice clips

All 96 spoken clips were synthesised offline with [Piper](https://github.com/OHF-Voice/piper1-gpl). No real person's
voice was recorded or cloned for this game.

The three voices, `kristin`, `norman` and `john`, are models by Bryce Beattie trained on public-domain
[LibriVox](https://librivox.org/) recordings. `kristin` and `norman` were trained from scratch; `john` was fine-tuned
from `kristin`. Nothing in their lineage carries a non-commercial or research-only licence, so the clips are under
MIT with the rest of the project. `game/tests/test_level.gd` fails if a clip from any other voice is added.

Version 1.0.0 also contained 31 clips from Piper's `joe` voice. That voice was fine-tuned from Piper's `lessac`
voice, whose [Blizzard Challenge 2013 training data](https://www.cstr.ed.ac.uk/projects/blizzard/2013/lessac_blizzard2013/license.html)
is licensed for research use only. Version 1.0.1 removed those clips and regenerated the lines (Preston Exitwell,
the exosuit boss and the helicopter leader) with `norman`.

## Release licence review (2026-10-03, version 1.0.1)

Every component that ships in the game or installers was checked against its source before release:

- **Engine:** Godot is MIT. Its bundled libraries were read from the engine binary itself
  (`tools/packaging/yngm-engine-licences.gd`), and all of them are permissive. The licences with an obligation
  are met as follows:
  - FreeType (FTL) and libjpeg-turbo (IJG) require a credit in the documentation; it is above and in the credits.
  - The MPL-2.0 file is Mozilla's CA certificate list, available unmodified in the linked Godot 4.7.2 source.
  - The CC-BY-4.0 item is the Godot logo, credited in the notices.
  - Every full licence text ships in `licenses/`.
- **Assets:** CC0 was confirmed on each source page: Kenney's pack licence files, RobotExpressive's licence,
  [kazuma's Helicopter on Poly Pizza](https://poly.pizza/m/EQJ2MECUbx) and the [Poly Haven licence](https://polyhaven.com/license).
  CC0 needs no attribution; credits are given anyway.
- **Voices:** Bryce Beattie released `kristin`, `norman` and `john` into the public domain ("Feel free to use these
  for any legal and ethical purpose", [brycebeattie.com/files/tts](https://brycebeattie.com/files/tts/)). They were
  trained only on public-domain LibriVox recordings. The [piper-voices](https://huggingface.co/rhasspy/piper-voices)
  repository is MIT.
- **Installer:** NSIS and its plug-ins are zlib/libpng. Only the zlib compressor is used (not bzip2 or LZMA).
- **Original content:** the code, story, logo and sound effects are by the author with AI assistance. Anthropic's and
  OpenAI's terms assign output rights to the user. The sound effects are synthesised in code
  (`tools/generate_sfx.py`, standard library only, no samples). The cover art was supplied by the author, who is
  responsible for holding the rights to it.
- **Build tools** (Piper GPL-3.0, espeak-ng, Python, Pillow, pytest, FFmpeg) are not distributed, so they place no
  conditions on the release.

Nothing in the release is under a non-commercial, research-only or share-alike licence.

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

## Fundraising

The README links to the author's [fundraising page for the National Breast Cancer Foundation](https://fundraise.nbcf.org.au/fundraisers/matthewbright/you-are-gunna-make-it). Donations are
made on NBCF's own fundraising site and go directly to NBCF, which issues receipts. The author never receives or
holds the money. Donations are voluntary and unconditional: the game is free either way and nothing is unlocked by
donating. The author is a Proud Community Supporter of the National Breast Cancer Foundation. The game is not run,
produced or endorsed by NBCF, and NBCF's logo is not used.

## Privacy

The game has no accounts, telemetry, ads, purchases or network access. It saves level progress and settings only
in a local file on your computer.

## Warranty and signing

Provided as is, without warranty (see [LICENSE](LICENSE)). The Windows installer is not code-signed. The macOS app
is ad-hoc signed and not notarised. Each release lists SHA-256 hashes so you can check the downloads.
