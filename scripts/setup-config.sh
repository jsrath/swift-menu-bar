#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CONFIG_DIR="$HOME/Library/Application Support/SwiftMenuBar"
CONFIG_FILE="$CONFIG_DIR/config.json"

mkdir -p "$CONFIG_DIR"

if [[ ! -f "$CONFIG_FILE" ]]; then
  cp "$ROOT/config.example.json" "$CONFIG_FILE"
  echo "Created $CONFIG_FILE — edit it to customize settings."
fi
