#!/usr/bin/env python3
"""Bake a unique uncompressed 48kHz stereo soundtrack for Giorgis Fighting.

Each track is a real song (drums, bass, chords, lead) with its own seed, key,
and tempo — not silence, noise, or copied loops. One track per menu, mode,
stage, and fighter. The gallery and in-match music player load these files.
"""
from __future__ import annotations

import json
import math
import os
import sys
import struct
import wave
from concurrent.futures import ProcessPoolExecutor, as_completed
from pathlib import Path

import numpy as np

RATE = 48000
SECONDS = 72.0
OUT = Path(__file__).resolve().parents[1] / "assets" / "audio" / "music"

TRACKS = [
    ("menu", "CABINET LIGHTS", 108, 0, 3),
    ("arcade", "LADDER DRUMS", 132, 7, 5),
    ("survival", "WAVE MACHINE", 140, 2, 9),
    ("timeattack", "CLOCK FUSE", 168, 9, 11),
    ("results", "HOUSE CALL CREST", 96, 5, 4),
    ("defeat", "LIGHTS DOWN", 78, 4, 8),
    ("tutorial", "FIRST STEPS", 100, 0, 2),
    ("gallery", "VINYL ROOM", 92, 7, 1),
    ("attract", "ATTRACT DEMO", 118, 9, 6),
    ("pause", "HOLD MUSIC", 84, 2, 0),
    ("final", "FINAL ROUND", 154, 3, 10),
    ("credits", "AFTER THE RITE", 88, 5, 3),
    ("stage:grass_field", "GREEN HILL FIELD", 126, 0, 4),
    ("stage:moonlit_temple", "MOONLIT TEMPLE", 112, 9, 7),
    ("stage:neon_street", "NEON RIFT STREET", 148, 3, 11),
    ("stage:the_pit", "THE UNDER-RITE", 136, 2, 8),
    ("stage:crimson_keep", "CRIMSON KEEP", 122, 7, 5),
    ("stage:tidal_dock", "TIDAL DOCK", 118, 5, 2),
    ("stage:snow_ridge", "SNOW RIDGE", 104, 4, 9),
    ("stage:desert_gate", "DESERT GATE", 128, 8, 6),
    ("stage:clocktower", "CLOCKTOWER", 144, 1, 10),
    ("stage:bamboo_yard", "BAMBOO YARD", 120, 10, 3),
    ("stage:storm_bridge", "STORM BRIDGE", 152, 6, 8),
    ("stage:sunset_pier", "SUNSET PIER", 110, 3, 1),
    ("stage:void_garden", "VOID GARDEN", 100, 11, 7),
    ("theme:chris_xrisakis", "THREAD THE LANE", 142, 0, 4),
    ("theme:hoodrich_stacks", "SAY THE NAME", 138, 7, 5),
    ("theme:mako", "STILL STANDING", 128, 2, 9),
    ("theme:fogas", "STILL SMILING", 96, 5, 3),
    ("theme:giannis", "SHOW OUT", 132, 11, 6),
    ("theme:vag", "COTTON RUN", 118, 4, 2),
]


def midi(n: float) -> float:
    return 440.0 * (2.0 ** ((n - 69.0) / 12.0))


def env_exp(n: int, rate: int, tau: float) -> np.ndarray:
    t = np.arange(n, dtype=np.float32) / rate
    return np.exp(-t / max(tau, 1e-4)).astype(np.float32)


def write_wav(path: Path, stereo: np.ndarray) -> None:
    pcm = np.clip(stereo, -1.0, 1.0)
    pcm = (pcm * 32767.0).astype(np.int16)
    path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(path), "w") as w:
        w.setnchannels(2)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(pcm.tobytes())


def render_one(item: tuple) -> tuple[str, str, str, int]:
    key, title, bpm, root_off, color = item
    seed = abs(hash((key, title, bpm, root_off, color))) % (2**31)
    rng = np.random.default_rng(seed)
    n = int(SECONDS * RATE)
    beat = 60.0 / float(bpm)
    eighth = beat * 0.5
    t = np.arange(n, dtype=np.float64) / RATE
    root = 45 + root_off  # MIDI
    minor = color % 2 == 1
    scale = np.array([0, 2, 3, 5, 7, 8, 10] if minor else [0, 2, 4, 5, 7, 9, 11])
    bass_deg = np.array([0, 0, 4, 2, 0, 5, 4, 3, 0, 0, 5, 2, 0, 4, 5, 7])
    lead_deg = np.array([7, 8, 9, 7, 5, 4, 5, 7, 9, 11, 9, 7, 5, 4, 2, 0])
    # rotate patterns by color so songs differ
    bass_deg = np.roll(bass_deg, color)
    lead_deg = np.roll(lead_deg, color * 2 + root_off)

    step = np.floor(t / eighth).astype(np.int64)
    bass_note = root + scale[bass_deg[step % len(bass_deg)] % len(scale)]
    # drop an octave every other bar on some tracks
    if color % 3 == 0:
        bass_note = np.where((step // 8) % 4 == 3, bass_note - 12, bass_note)
    bass_f = midi(bass_note.astype(np.float64))
    # integrate phase so frequency changes don't click
    bass_phase = np.cumsum(bass_f / RATE) * 2.0 * math.pi
    bass = 0.16 * np.sin(bass_phase)
    bass += 0.07 * np.sin(2.0 * bass_phase)
    # pluck envelope per eighth
    pos = np.mod(t, eighth)
    bass *= (0.35 + 0.65 * np.exp(-pos * 7.5))

    # chord pad: root, third, fifth
    third = 3 if minor else 4
    pad = np.zeros(n, dtype=np.float64)
    for off, amp in ((0, 0.045), (third, 0.035), (7, 0.03), (12, 0.02)):
        f = midi(root + off)
        pad += amp * np.sin(2.0 * math.pi * f * t)
    pad *= 0.55 + 0.45 * np.sin(2.0 * math.pi * t / 8.0)

    lead_note = root + 12 + scale[lead_deg[step % len(lead_deg)] % len(scale)]
    if color % 4 == 0:
        lead_note += 12
    lead_f = midi(lead_note.astype(np.float64))
    lead_phase = np.cumsum(lead_f / RATE) * 2.0 * math.pi
    # square-ish lead via tanh(sin)
    lead = 0.07 * np.tanh(2.8 * np.sin(lead_phase))
    lead += 0.025 * np.sin(2.0 * lead_phase + 0.4)
    lead *= 0.4 + 0.6 * np.exp(-pos * 5.0)
    # rest every 4th bar
    lead *= ((step // 8) % 4 != 3).astype(np.float64)

    # drums
    kick = np.zeros(n, dtype=np.float64)
    snare = np.zeros(n, dtype=np.float64)
    hat = np.zeros(n, dtype=np.float64)
    beat_idx = np.floor(t / beat).astype(np.int64)
    kt = np.mod(t, beat)
    kick_mask = (beat_idx % 2 == 0) | ((color % 5 == 0) & (beat_idx % 4 == 3))
    kick_f = 78.0 - kt * 70.0
    kick = np.sin(2.0 * math.pi * np.clip(kick_f, 30.0, 120.0) * kt) * np.exp(-kt * 14.0)
    kick *= kick_mask.astype(np.float64) * 0.28
    noise = rng.standard_normal(n) * 0.22
    snare = noise * np.exp(-kt * 16.0)
    snare += 0.05 * np.sin(2.0 * math.pi * 180.0 * kt) * np.exp(-kt * 14.0)
    snare *= ((beat_idx % 2 == 1).astype(np.float64)) * 0.22
    hat_pos = np.mod(t, eighth)
    hat = (rng.standard_normal(n) * 0.09) * np.exp(-hat_pos * 48.0)
    hat *= ((step % 2 == 1).astype(np.float64))

    # fill noise sweep unique per track
    sweep_f = 220.0 + color * 40.0
    sweep = 0.02 * np.sin(2.0 * math.pi * sweep_f * t + np.sin(t * (1.2 + color * 0.15)))
    mix = bass + pad + lead + kick + snare + hat + sweep

    # soft clip + fade
    mix = np.tanh(mix * 1.15)
    fade = int(0.04 * RATE)
    mix[:fade] *= np.linspace(0, 1, fade)
    mix[-fade:] *= np.linspace(1, 0, fade)

    # stereo: delay + pan LFO
    delay = int((0.012 + (color % 5) * 0.002) * RATE)
    right = np.zeros_like(mix)
    right[delay:] = mix[:-delay] * 0.86
    right[:delay] = mix[:delay] * 0.4
    lfo = 0.12 * np.sin(2.0 * math.pi * (0.07 + color * 0.01) * t)
    left = mix * (1.0 - lfo)
    right = right * (1.0 + lfo)
    stereo = np.stack([left, right], axis=1).astype(np.float32)
    peak = float(np.max(np.abs(stereo))) or 1.0
    stereo *= 0.89 / peak

    fname = key.replace(":", "_").replace("/", "_") + ".wav"
    write_wav(OUT / fname, stereo)
    return key, fname, title, int(SECONDS)


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    wanted = [a for a in sys.argv[1:] if not a.startswith("-")]
    items = TRACKS
    if wanted:
        items = [t for t in TRACKS if t[0] in wanted]
        if not items:
            raise SystemExit("no matching tracks: %s" % ", ".join(wanted))
    catalog = {"map": {}, "tracks": []}
    cat_path = OUT / "catalog.json"
    if wanted and cat_path.exists():
        catalog = json.loads(cat_path.read_text())
        catalog.setdefault("map", {})
        catalog.setdefault("tracks", [])
    workers = min(8, os.cpu_count() or 4)
    done = 0
    with ProcessPoolExecutor(max_workers=workers) as pool:
        futs = {pool.submit(render_one, item): item[0] for item in items}
        for fut in as_completed(futs):
            key, fname, title, sec = fut.result()
            catalog["map"][key] = fname
            catalog["tracks"] = [t for t in catalog["tracks"] if t.get("id") != key]
            catalog["tracks"].append({"id": key, "file": fname, "title": title, "seconds": sec})
            done += 1
            print(f"[{done}/{len(items)}] {key} -> {fname}", flush=True)
    catalog["tracks"].sort(key=lambda x: x["id"])
    cat_path.write_text(json.dumps(catalog, indent=2) + "\n")
    total = sum((OUT / t["file"]).stat().st_size for t in catalog["tracks"] if (OUT / t["file"]).exists())
    print(f"catalog {len(catalog['tracks'])} tracks, {total / (1024**3):.3f} GiB")


if __name__ == "__main__":
    main()
