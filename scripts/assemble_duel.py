#!/usr/bin/env python3
"""Assemble the multi-turn duel video with ffmpeg Ken Burns, HUD, and audio."""

from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "scripts" / "duel_script.json"
FRAMES = ROOT / "assets" / "frames"
HUD = ROOT / "output" / "hud"
CLIPS = ROOT / "output" / "clips"
OUT = ROOT / "output" / "duel.mp4"

FLASH = {
    "blue": "0x4488ff",
    "red": "0xff3322",
    "orange": "0xff8800",
    "white": "0xffffff",
    None: None,
}


def run(cmd: list[str]) -> None:
    print("+", " ".join(cmd[:8]), "...")
    subprocess.run(cmd, check=True)


def ken_burns_expr(zoom: str, frames: int) -> str:
    if zoom == "out":
        return (
            f"z='if(eq(on,0),1.12,max(1.12-0.0009*on,1.0))':"
            f"x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':d={frames}:s=1920x1080:fps=30"
        )
    return (
        f"z='min(1.0+0.0009*on,1.12)':"
        f"x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':d={frames}:s=1920x1080:fps=30"
    )


def make_clip(beat: dict, fps: int) -> Path:
    image = FRAMES / beat["image"]
    hud = HUD / f"{beat['id']}.png"
    dest = CLIPS / f"{beat['id']}.mp4"
    duration = float(beat["duration"])
    frames = int(round(duration * fps))
    zp = ken_burns_expr(beat.get("zoom") or "in", frames)
    shake = beat.get("shake")
    flash = FLASH.get(beat.get("flash"))

    # Scale still to cover 1920x1080 then Ken Burns from a larger canvas.
    vf_parts = [
        "[0:v]scale=2304:1296:force_original_aspect_ratio=increase,"
        "crop=2304:1296,setsar=1,"
        f"zoompan={zp},format=yuv420p[base]"
    ]
    last = "base"
    if shake:
        vf_parts.append(
            f"[{last}]crop=iw-16:ih-16:'8+8*sin(n*2.2)':'8+6*cos(n*1.7)',"
            "scale=1920:1080,setsar=1[sh]"
        )
        last = "sh"
    if flash:
        vf_parts.append(
            f"color=c={flash}:s=1920x1080:d={duration}:r={fps},format=yuva420p,"
            "colorchannelmixer=aa=0.18[fl]"
        )
        vf_parts.append(f"[{last}][fl]overlay=0:0:shortest=1[fx]")
        last = "fx"
    vf_parts.append("[1:v]format=rgba[hud]")
    vf_parts.append(f"[{last}][hud]overlay=0:0:format=auto,format=yuv420p[v]")
    filtergraph = ";".join(vf_parts)

    cmd = [
        "ffmpeg",
        "-y",
        "-loop",
        "1",
        "-i",
        str(image),
        "-i",
        str(hud),
        "-filter_complex",
        filtergraph,
        "-map",
        "[v]",
        "-t",
        f"{duration}",
        "-r",
        str(fps),
        "-c:v",
        "libx264",
        "-pix_fmt",
        "yuv420p",
        "-preset",
        "veryfast",
        "-crf",
        "20",
        str(dest),
    ]
    run(cmd)
    return dest


def make_audio(total: float, beats: list[dict], dest: Path) -> None:
    # Procedural bed + per-beat hits. No licensed music.
    parts = [
        f"sine=frequency=52:sample_rate=44100:duration={total},volume=0.12[a]",
        f"sine=frequency=78:sample_rate=44100:duration={total},volume=0.06[b]",
        f"anoisesrc=color=pink:amplitude=0.035:sample_rate=44100:duration={total}[n]",
        "[a][b][n]amix=inputs=3:duration=longest,volume=0.85[bed]",
    ]
    labels = ["[bed]"]
    t = 0.0
    hi = 0
    for beat in beats:
        sting = beat.get("flash") or beat.get("shake") or beat["id"] in ("start", "winner")
        if sting:
            delay = int(t * 1000)
            freq = 90 if beat.get("flash") == "blue" else 60
            if beat.get("id") == "start":
                freq = 220
            if beat.get("id") == "winner":
                freq = 330
            parts.append(
                f"sine=frequency={freq}:duration=0.4,volume=0.28,adelay={delay}|{delay}[h{hi}]"
            )
            labels.append(f"[h{hi}]")
            hi += 1
        t += float(beat["duration"])
    n = len(labels)
    parts.append(f"{''.join(labels)}amix=inputs={n}:duration=longest,volume=1.1[out]")
    fg = ";".join(parts)
    cmd = [
        "ffmpeg",
        "-y",
        "-filter_complex",
        fg,
        "-map",
        "[out]",
        "-t",
        f"{total}",
        str(dest),
    ]
    run(cmd)


def concat_clips(clips: list[Path], dest: Path) -> None:
    lst = CLIPS / "concat.txt"
    lst.write_text("".join(f"file '{p.resolve()}'\n" for p in clips))
    run(
        [
            "ffmpeg",
            "-y",
            "-f",
            "concat",
            "-safe",
            "0",
            "-i",
            str(lst),
            "-c",
            "copy",
            str(dest),
        ]
    )


def mux(video: Path, audio: Path, dest: Path) -> None:
    run(
        [
            "ffmpeg",
            "-y",
            "-i",
            str(video),
            "-i",
            str(audio),
            "-c:v",
            "copy",
            "-c:a",
            "aac",
            "-b:a",
            "192k",
            "-shortest",
            "-movflags",
            "+faststart",
            str(dest),
        ]
    )


def main() -> int:
    data = json.loads(SCRIPT.read_text())
    fps = int(data["fps"])
    CLIPS.mkdir(parents=True, exist_ok=True)
    HUD.mkdir(parents=True, exist_ok=True)

    print("Rendering HUD overlays...")
    run([sys.executable, str(ROOT / "scripts" / "build_hud.py")])

    clips = []
    total = 0.0
    for beat in data["beats"]:
        print(f"Clip {beat['id']} ({beat['duration']}s)")
        clips.append(make_clip(beat, fps))
        total += float(beat["duration"])

    silent = CLIPS / "_concat.mp4"
    concat_clips(clips, silent)
    audio = CLIPS / "_audio.wav"
    make_audio(total, data["beats"], audio)
    mux(silent, audio, OUT)
    print(f"Wrote {OUT} ({total:.1f}s)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
