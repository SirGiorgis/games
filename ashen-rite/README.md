# Giorgis Fighting

Original arcade 2D fighting game for **Godot 4.7**. Visual north star: compact chibi fighters on a bright outdoor field (Tiny Fight-style), not oversized model sprites or neon arenas.

Open the `ashen-rite` folder in Godot 4.7 and press **Play**. Nothing else to configure.

## Play

1. Install [Godot 4.7](https://godotengine.org/download).
2. Import `ashen-rite/project.godot`.
3. Press Play. Main scene is already set.

Lead fighter: **Chris Xrisakis**. Default opponent: **Giorgis**. Default arena: **Green Hill Field**.

## Controls (Player 1)

| Key | Action |
| --- | --- |
| A / D | Move |
| W | Jump |
| S | Crouch |
| J | Light attack |
| K | Heavy attack |
| L | Special (50 meter; EX when the pink meter is full) |
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

- Best of 3 (first to 2 rounds). Final Round when both are one win away.
- Special meter (pink METER) fills from hitting and getting hit. Full meter = **EX special**. Super (bottom) fills more slowly.
- Combos: Light → Light → Heavy → Special → Super. Combo counter shows hits, damage, and scaling.
- Jump-cancel lights/heavies on hit. Super-cancel specials on hit.
- Each fighter's special and super actually play differently (teleport, quake, freeze, multi-fireballs).
- Training mode: infinite timer, meter refill, dummy stand/block in Options.
- Attract demo starts if you wait on the title splash.
- Throw tech (press Throw as they grab). Air tech near the end of air hitstun.
- Just Guard (block at the last moment). Pushblock (Special during blockstun, 25 meter).
- Getup attack is a reversal. Super has armor against strikes. Clash if both hitboxes meet.
- CPU difficulties: Easy / Normal / Hard / Expert in Options. Hitboxes toggle is there too.

## Arenas

Green Hill Field (default), Moonlit Temple, Neon Rift Street, The Under-Rite, Crimson Keep. Character select → stage select, or set one in Options / T on the roster.

## Download

https://github.com/SirGiorgis/games/archive/refs/heads/cursor/ashen-rite-fighter-acf2.zip
