#!/usr/bin/env bash
# Idempotent Cloud Agent bootstrap for the Giorgis games repo.
# Sets up both projects:
#   * ashen-rite  -> Godot 4.7 arcade fighter (needs the Godot editor/runtime)
#   * scripts/    -> duel-video assembler (needs Python + Pillow; ffmpeg ships in the base image)
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GODOT_VERSION="4.7.2-stable"
GODOT_BIN="/usr/local/bin/godot"

echo "==> Installing system packages (python venv support)"
# ffmpeg, Mesa/llvmpipe OpenGL and the DejaVu fonts already ship in the base image;
# only the Python venv module is missing there.
sudo apt-get update -qq
sudo apt-get install -y -qq python3-venv unzip curl

echo "==> Ensuring Godot ${GODOT_VERSION} is installed"
if ! command -v godot >/dev/null 2>&1 || ! godot --version 2>/dev/null | grep -q "^4\.7"; then
  tmp="$(mktemp -d)"
  url="https://github.com/godotengine/godot-builds/releases/download/${GODOT_VERSION}/Godot_v${GODOT_VERSION}_linux.x86_64.zip"
  echo "    downloading ${url}"
  curl -fsSL -o "${tmp}/godot.zip" "${url}"
  unzip -o -q "${tmp}/godot.zip" -d "${tmp}"
  sudo mv "${tmp}/Godot_v${GODOT_VERSION}_linux.x86_64" "${GODOT_BIN}"
  sudo chmod +x "${GODOT_BIN}"
  rm -rf "${tmp}"
fi
godot --version

echo "==> Creating Python virtualenv and installing requirements"
cd "${REPO_ROOT}"
python3 -m venv .venv
./.venv/bin/pip install --quiet --upgrade pip
./.venv/bin/pip install --quiet -r requirements.txt

echo "==> Importing Godot assets so the project is ready to run"
godot --headless --path ashen-rite --import >/dev/null 2>&1 || true

echo "==> Setup complete."
echo "    Run the game :  godot --path ashen-rite"
echo "    Build video  :  ./.venv/bin/python scripts/assemble_duel.py"
