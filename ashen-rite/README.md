# Giorgis Fighting

Original arcade 2D fighting game for **Godot 4.7**.

Open the `ashen-rite` folder in Godot 4.7 and press **Play**. Nothing else to configure.

## Play

1. Install [Godot 4.7](https://godotengine.org/download).
2. Import `ashen-rite/project.godot`.
3. Press Play. Main scene is already set.

Lead fighter: **Chris Xrisakis**.

## Controls (Player 1)

| Key | Action |
| --- | --- |
| A / D | Move |
| W | Jump |
| S | Crouch |
| J | Light attack |
| K | Heavy attack |
| L | Special (50 meter) |
| U | Block |
| I | Grab (beats block) |
| O | Ultimate (full meter) |
| Esc / P | Pause |

Player 2 (optional human): arrows + Z/X/C/V/B/N or numpad 1–6.

Change bindings in `scripts/input/control_map.gd` (keyboard + gamepad hooks).

## Add a character

1. Copy `data/characters/chris_xrisakis.json` to a new file, e.g. `data/characters/my_fighter.json`.
2. Change `id`, `name`, stats, colors, `special_id` (`bolt`, `wave`, `dash`, `slam`, `blast`).
3. Optional: drop a PNG at `data/characters/refs/my_fighter.png` and set `reference_image`.
4. Restart the game. The roster loads every JSON in that folder.

Or write a description (see `data/descriptions/example.txt`), put a photo at `data/characters/refs/custom.png`, and press **F** on the character select screen to forge the Custom Rite slot. No online AI is used.

## Combat notes

- Best of 3 (first to 2 rounds).
- Special meter fills from hitting and getting hit. Ultimate fills more slowly.
- Combos: Light → Light → Heavy → Special. Combo counter appears at 2+ hits.
- CPU difficulties: Easy / Normal / Hard / Expert in Options.

## Arenas

Moonlit Temple, Neon Rift Street, The Under-Rite, Crimson Keep. Random by default; pick one in Options.
