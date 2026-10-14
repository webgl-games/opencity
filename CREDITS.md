# Credits and asset licences

OpenCity's code (GDScript, scenes and shaders) is MIT licensed, see `LICENSE`.
Every third-party asset in this repository is listed below with its source and
licence. If you add an asset, add it here too, and only add assets whose licence
allows redistribution (CC0, CC-BY or an MIT-compatible licence).

| File | What it is | Author / source | Licence |
|---|---|---|---|
| `assets/characters/UAL1_Standard.glb` | Rigged mannequin with 43 animations (Universal Animation Library), used for the on-foot player | [Quaternius](https://quaternius.com) | [CC0 1.0](https://creativecommons.org/publicdomain/zero/1.0/) (licence text: `assets/characters/LICENSE-Quaternius-UAL.txt`) |

## Made for this project (MIT, same as the code)

- **City, roads, buildings, cars, truck, helicopter, lamp posts, pedestrians:**
  built procedurally from Godot primitives in `scripts/` and `scenes/`.
- **Building facades and road markings:** drawn by the shaders in `shaders/`,
  no textures.
- **`screenshots/`:** captures of the game itself, taken with the F12 /
  `--shot` helper in `scripts/dev_capture.gd`.

## Not in this repository

- **Fonts:** the HUD uses Godot's built-in default font, which ships with the
  engine.
- **Audio:** there is no audio yet.
