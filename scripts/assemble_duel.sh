#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
python3 "$ROOT/scripts/assemble_duel.py"
ffprobe -hide_banner "$ROOT/output/duel.mp4"
