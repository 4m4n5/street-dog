#!/usr/bin/env bash
# Portable Godot Catalyst MCP launcher for this repo.
# Use with: codex mcp add godot -- "$(pwd)/scripts/mcp/godot-catalyst.sh"

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
GODOT_BIN="${GODOT_PATH:-/Applications/Godot.app/Contents/MacOS/Godot}"

export GODOT_PROJECT_PATH="$ROOT"
export GODOT_PATH="$GODOT_BIN"
export GODOT_TOOL_MODE="${GODOT_TOOL_MODE:-full}"

NODE_BIN="${NODE_PATH:-/opt/homebrew/bin/node}"
NPX_BIN="$(dirname "$NODE_BIN")/npx"

exec "$NPX_BIN" -y godot-catalyst "$@"
