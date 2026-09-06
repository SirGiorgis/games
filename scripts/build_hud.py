#!/usr/bin/env python3
"""Render transparent HUD overlays for each duel beat."""

from __future__ import annotations

import json
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "scripts" / "duel_script.json"
OUT = ROOT / "output" / "hud"
FONT_CANDIDATES = [
    "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
    "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
    "/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf",
]


def font(size: int) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    for path in FONT_CANDIDATES:
        if Path(path).exists():
            return ImageFont.truetype(path, size)
    return ImageFont.load_default()


def rounded_rect(draw: ImageDraw.ImageDraw, xy, fill, radius=12, outline=None, width=2):
    draw.rounded_rectangle(xy, radius=radius, fill=fill, outline=outline, width=width)


def lp_block(draw, x, y, label, lp, color, align="left"):
    bar_w, bar_h = 520, 28
    max_lp = 8000
    frac = max(0.0, min(1.0, lp / max_lp))
    filled = int(bar_w * frac)
    if align == "right":
        box = (x - 40 - bar_w, y, x - 20, y + 110)
        bx = x - 30 - bar_w
    else:
        box = (x + 20, y, x + 60 + bar_w, y + 110)
        bx = x + 40
    rounded_rect(draw, box, fill=(8, 12, 28, 200), radius=16, outline=color, width=3)
    title_f = font(22)
    lp_f = font(40)
    tx = bx if align == "left" else bx
    draw.text((tx, y + 8), label, font=title_f, fill=color)
    lp_text = f"{lp:,}"
    if align == "right":
        tw = draw.textlength(lp_text, font=lp_f)
        draw.text((bx + bar_w - tw, y + 4), lp_text, font=lp_f, fill=(255, 255, 255, 255))
    else:
        draw.text((tx + 160, y + 2), lp_text, font=lp_f, fill=(255, 255, 255, 255))
    bar_y = y + 58
    draw.rounded_rectangle((bx, bar_y, bx + bar_w, bar_y + bar_h), radius=8, fill=(30, 30, 40, 220))
    if filled > 4:
        draw.rounded_rectangle((bx, bar_y, bx + filled, bar_y + bar_h), radius=8, fill=color)


def render_beat(beat: dict, w: int, h: int) -> Image.Image:
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    blue = (80, 170, 255, 255)
    red = (255, 80, 70, 255)

    lp_block(d, 0, 24, "BLUE", beat["lp_blue"], blue, "left")
    lp_block(d, w, 24, "RED", beat["lp_red"], red, "right")

    turn = beat.get("turn") or ""
    if turn:
        tf = font(28)
        tw = d.textlength(turn, font=tf)
        cx = (w - tw) / 2
        rounded_rect(
            d,
            (cx - 28, 28, cx + tw + 28, 78),
            fill=(10, 10, 18, 210),
            radius=20,
            outline=(255, 220, 90, 255),
            width=2,
        )
        d.text((cx, 36), turn, font=tf, fill=(255, 230, 140, 255))

    title = beat.get("title") or ""
    if title:
        hf = font(64)
        tw = d.textlength(title, font=hf)
        d.text(((w - tw) / 2 + 3, 163), title, font=hf, fill=(0, 0, 0, 180))
        d.text(((w - tw) / 2, 160), title, font=hf, fill=(255, 255, 255, 255))

    subtitle = beat.get("subtitle") or ""
    if subtitle:
        sf = font(34)
        tw = d.textlength(subtitle, font=sf)
        rounded_rect(
            d,
            ((w - tw) / 2 - 24, 250, (w + tw) / 2 + 24, 310),
            fill=(0, 0, 0, 150),
            radius=12,
        )
        d.text(((w - tw) / 2, 258), subtitle, font=sf, fill=(230, 240, 255, 255))

    card = beat.get("card") or ""
    atk = beat.get("atk") or ""
    if card or atk:
        bar_text = card if not atk else f"{card}    {atk}"
        cf = font(32)
        tw = d.textlength(bar_text, font=cf)
        y0 = h - 140
        rounded_rect(
            d,
            ((w - tw) / 2 - 36, y0, (w + tw) / 2 + 36, y0 + 70),
            fill=(12, 16, 40, 220),
            radius=10,
            outline=(180, 200, 255, 220),
            width=2,
        )
        d.text(((w - tw) / 2, y0 + 16), bar_text, font=cf, fill=(255, 255, 255, 255))

    dmg = beat.get("damage")
    if dmg is not None:
        side = beat.get("damage_side") or "blue"
        df = font(96)
        text = f"{dmg}"
        tw = d.textlength(text, font=df)
        x = 220 if side == "blue" else w - 220 - tw
        y = 360
        color = (255, 70, 70, 255)
        d.text((x + 4, y + 4), text, font=df, fill=(0, 0, 0, 200))
        d.text((x, y), text, font=df, fill=color)

    return img


def main() -> None:
    data = json.loads(SCRIPT.read_text())
    OUT.mkdir(parents=True, exist_ok=True)
    w, h = data["width"], data["height"]
    for beat in data["beats"]:
        img = render_beat(beat, w, h)
        dest = OUT / f"{beat['id']}.png"
        img.save(dest)
        print(f"wrote {dest}")


if __name__ == "__main__":
    main()
