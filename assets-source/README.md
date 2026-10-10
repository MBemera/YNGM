# YNGM graphics source

`graphics-v2.blend` contains the editable source for seven weapons, equipment for all nine enemy roles and eight scenery pieces. Each asset has its own collection. Weapon mechanisms have a `fire` NLA track; the existing Godot character rigs supply the enemy animations.

Export a selected collection as glTF Binary (`.glb`) to the corresponding path under `game/assets/models/v2/`. Export active vertex colours and NLA-track animations. Keep textures, transparency and additional lights out of this kit. All assets share one opaque vertex-colour material at runtime.

The Blender source stays outside `game/` so game imports and CI do not require Blender. `graphics-v2-budget.json` records triangle counts; the graphics test enforces maximums of 800 triangles per weapon/scenery asset and 500 per enemy equipment set.

Local generator: `C:\Scripts\build-yngm-graphics.py`, documented in `C:\Scripts\README.md`. Running it regenerates this source and the GLBs. Hand edits should be made to a saved copy of the source before running the generator again.

Original designs and source are MIT licensed under the repository's [LICENSE](../LICENSE). The existing Kenney and RobotExpressive characters retain their separate CC0 licences.
