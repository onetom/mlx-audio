#!/usr/bin/env bash
# Start the mlx-audio OpenAI-compatible API server.
# Usage: ./start.sh [port]   (default: 8880)
set -euo pipefail

cd "$(dirname "$0")"

PORT="${1:-8880}"

uv sync --extra server
# misaki is a venv-only install; uv sync prunes it, so reinstall every time.
uv pip install 'misaki[en]'

exec uv run mlx_audio.server --host 0.0.0.0 --port "$PORT"
