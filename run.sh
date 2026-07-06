#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"

"$ROOT/scripts/setup-config.sh"
"$ROOT/build.sh"
pkill -f "SwiftMenuBar" 2>/dev/null || true
open "$ROOT/SwiftMenuBar.app"
