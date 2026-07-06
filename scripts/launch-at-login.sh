#!/bin/bash
set -euo pipefail

APP_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BINARY="$APP_ROOT/SwiftMenuBar.app/Contents/MacOS/SwiftMenuBar"

for _ in $(seq 1 60); do
  if pgrep -x yabai >/dev/null; then
    break
  fi
  sleep 1
done

exec "$BINARY"
