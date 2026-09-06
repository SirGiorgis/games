# Duel video

Fan-made cinematic from the provided still: a ~2:45 multi-turn duel, 16:9 MP4.

## Rebuild

Requires `ffmpeg` and Python 3 with Pillow (`pip install pillow`).

```bash
python3 scripts/assemble_duel.py
# or
bash scripts/assemble_duel.sh
```

Output: `output/duel.mp4`

## Contents

- `assets/frames/` — source still plus generated 16:9 keyframes
- `scripts/duel_script.json` — beat timings, LP, captions
- `scripts/build_hud.py` — LP bars, turn badge, card names, damage
- `scripts/assemble_duel.py` — Ken Burns, flash/shake, procedural audio

Signature monsters match the photo (ice dragon vs armored fire dragon). Extra cards use original names. Audio is procedural (no licensed soundtrack).
