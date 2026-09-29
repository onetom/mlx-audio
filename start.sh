#!/usr/bin/env bash
# Start the mlx-audio OpenAI-compatible API server.
# Usage: ./start.sh [port]   (default: 8880)
set -euo pipefail

cd "$(dirname "$0")"

PORT="${1:-8880}"

uv sync --extra server
# misaki is a venv-only install; uv sync prunes it, so reinstall every time.
# en-core-web-sm is NOT a misaki dependency: misaki downloads it lazily on
# first G2P use (misaki/en.py). Install it here so no request ever downloads.
uv pip install 'misaki[en]' \
  'en-core-web-sm @ https://github.com/explosion/spacy-models/releases/download/en_core_web_sm-3.8.0/en_core_web_sm-3.8.0-py3-none-any.whl'

# Pre-fetch Kokoro weights + all voice packs so the first request does no downloads.
# Voices are served from prince-canuma/Kokoro-82M (see KokoroPipeline), the rest
# from mlx-community/Kokoro-82M-bf16 (the "kokoro" model alias in server.py).
uv run hf download mlx-community/Kokoro-82M-bf16
uv run hf download prince-canuma/Kokoro-82M --include "voices/*"

# Everything Kokoro needs is cached by now; forbid runtime network access so
# load_model's snapshot_download etag checks can't stall requests.
# Remove this line if you want to serve other, not-yet-cached models.
export HF_HUB_OFFLINE=1

# Warm the Kokoro model (weights + G2P + MLX compile) before serving so the
# first extension request is fast.
exec uv run mlx_audio.server --host 0.0.0.0 --port "$PORT" --warmup-model kokoro
