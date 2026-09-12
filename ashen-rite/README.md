# Giorgis Fighting

Original arcade 2D fighting game for **Godot 4.7**. Visual north star: compact chibi fighters on a bright outdoor field (Tiny Fight-style), not oversized model sprites or neon arenas.

Open the `ashen-rite` folder in Godot 4.7 and press **Play**. Nothing else to configure.

The extra download size is a soundtrack the game actually uses: one unique song per menu, mode, stage, and fighter. Gallery Radio plays the same catalog. There is no dummy padding.

## Play

1. Install [Godot 4.7](https://godotengine.org/download).
2. Import `ashen-rite/project.godot`.
3. Press Play. Main scene is already set.

Lead fighter: **Chris Xrisakis**. Default opponent: **Giorgis**. Default arena: **Green Hill Field**.

First Godot open may scan the music folder. Tracks load from disk at runtime, one song at a time.

## Modes

| Menu | What it is |
| --- | --- |
| PLAY | Quick versus, Chris vs Giorgis on the current stage |
| ARCADE | First-to-1 ladder through the roster. Last bout plays the final theme |
| SURVIVAL | Endless first-to-1 waves. CPU gets meaner each wave |
| TIME ATTACK | 60 seconds. Score is damage, hits, and max combo |
| TRAINING | Infinite timer, dummy cycle, advantage display |
| GALLERY | Radio of every mode, stage, and fighter theme. A/D pick a song, Enter plays it |

Wait on the title splash for the attract demo.

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
| Forward + U | Parry (tap at impact) |
| Run + J / K | Dash attack |
| L + U while hit | Burst (50 meter, escape a combo) |
| I | Grab (beats block) |
| O | Ultimate (full meter) |
| Getup + back | Roll |
| Esc / P | Pause |

Player 2 (optional human): arrows + Z/X/C/V/B/N or numpad 1–6.

Change bindings in `scripts/input/control_map.gd` (keyboard + gamepad hooks).

## Roster

**Chris Xrisakis**, **Giorgis**, and **Mako**. Default match is Chris vs Giorgis.

Mako is a shirtless close-range brawler (Body Check / Dempsey Roll). Each of the three has a unique super: Chris sends original open-wheel cars (Grid Strike), Giorgis drinks Straight Vodka for heal + ATK, Mako weaves the Dempsey Roll. Each has a theme in the gallery.

## Add a character

1. Copy `data/characters/chris_xrisakis.json` to a new file, e.g. `data/characters/my_fighter.json`.
2. Change `id`, `name`, stats, colors, `special_id` (`bolt`, `wave`, `dash`, `slam`, `blast`).
3. Optional: drop a PNG at `data/characters/refs/my_fighter.png` and set `reference_image`.
4. Restart the game. The roster loads every JSON in that folder.

Or write a description (see `data/descriptions/example.txt`), put a photo at `data/characters/refs/custom.png`, and press **F** on the character select screen to forge the Custom Rite slot. No online AI is used.

## Combat notes

- Versus is best of 3. **Arcade** / **Survival** / **Time Attack** are first-to-1.
- Special meter (pink METER) fills from hitting and getting hit. Full meter = **EX special**. Super (bottom) fills more slowly.
- Combos: Light → Light → Heavy → Special → Super. HUD shows hits, damage, scaling, and a rank.
- Jump-cancel lights/heavies on hit. Super-cancel specials on hit.
- Each fighter's special and super actually play differently (teleport, quake, freeze, multi-fireballs).
- **Rage** below 22% HP: extra damage and a red glow. **Guard** fills when you block; a full bar is a guard break.
- Training: infinite timer, meter refill, R reset, F dummy cycle (CPU / block / stand / crouch / jump / mash), on-screen advantage.
- Throw tech (press Throw as they grab). Air tech near the end of air hitstun.
- Just Guard (block at the last moment). Pushblock (Special during blockstun, 25 meter).
- Getup attack is a reversal. Super and dash attacks have armor. Clash if both hitboxes meet.
- CPU difficulties: Easy / Normal / Hard / Expert in Options. Hitboxes toggle is there too.

## Arenas

Green Hill Field (default), Moonlit Temple, Neon Rift Street, The Under-Rite, Crimson Keep, Tidal Dock, Snow Ridge, Desert Gate, Clocktower, Bamboo Yard, Storm Bridge, Sunset Pier, Void Garden.

Character select → stage select (A/D, Enter), or T on the roster / Options.

Each stage has its own song. Character select plays that fighter's theme.

## Soundtrack

28 unique songs in `assets/audio/music/` (one per menu, mode, stage, and fighter). Rebuild with:

`python3 tools/bake_soundtrack.py`

Gallery Radio plays every track. Fights pick survival / time attack / arcade / final / stage themes from the same catalog.

## Download

https://github.com/SirGiorgis/games/archive/refs/heads/cursor/ashen-rite-fighter-acf2.zip
