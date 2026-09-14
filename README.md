# Rite Brawl

Original arcade 2D fighting game for **Godot 4.7**.

## Windows: do not Import ZIP

Godot’s **Import ZIP** unpacks into `AppData\Local\Temp\godot_tmp_...`. Windows deletes that folder, then the project manager shows **Missing Project**.

1. Install [Godot 4.7](https://godotengine.org/download) (Standard, not .NET).
2. Download the zip.
3. Right-click → **Extract All** into a folder that stays, e.g. `Documents\RiteBrawl`.
4. Open the extracted `rite-brawl` folder (it contains `project.godot`).
5. In Godot: **Import** that folder, or double-click `project.godot`.
6. Press **Play**.

More detail: [rite-brawl/HOW_TO_PLAY.txt](rite-brawl/HOW_TO_PLAY.txt)

## Size

The project is a few megabytes. That is the full game. Fighters and stages are drawn in code. Hits and music are a built-in synth. The old ~400 MB soundtrack WAVs are not included.

Godot itself is a separate download.

## CrazyGames

Download the HTML5 zip (this is the file CrazyGames wants):

https://github.com/SirGiorgis/games/raw/cursor/ashen-rite-fighter-acf2/rite_brawl_crazygames_html5.zip

On the portal: **Delete all files**, then upload that zip. Do not upload `.gd` scripts or the GitHub source zip.

Store covers and hover videos (upload on the portal, separate from the game zip):

- Landscape cover: https://github.com/SirGiorgis/games/raw/cursor/ashen-rite-fighter-acf2/rite-brawl/store/cover_landscape_1920x1080.png
- Portrait cover: https://github.com/SirGiorgis/games/raw/cursor/ashen-rite-fighter-acf2/rite-brawl/store/cover_portrait_800x1200.png
- Square cover: https://github.com/SirGiorgis/games/raw/cursor/ashen-rite-fighter-acf2/rite-brawl/store/cover_square_800x800.png
- Landscape hover video: https://github.com/SirGiorgis/games/raw/cursor/ashen-rite-fighter-acf2/rite-brawl/store/hover_landscape_1920x1080.mp4
- Portrait hover video: https://github.com/SirGiorgis/games/raw/cursor/ashen-rite-fighter-acf2/rite-brawl/store/hover_portrait_1080x1620.mp4

Folder with all of them: [rite-brawl/store](rite-brawl/store).

## Zip

https://github.com/SirGiorgis/games/archive/refs/heads/cursor/ashen-rite-fighter-acf2.zip

Full notes: [rite-brawl/README.md](rite-brawl/README.md)
