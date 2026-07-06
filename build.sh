#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
APP="$ROOT/SwiftMenuBar.app"
BINARY_NAME="SwiftMenuBar"

cd "$ROOT"
swift build -c release

mkdir -p "$APP/Contents/MacOS"
mkdir -p "$APP/Contents/Resources"

cp "$ROOT/.build/release/$BINARY_NAME" "$APP/Contents/MacOS/$BINARY_NAME"
cp "$ROOT/Info.plist" "$APP/Contents/Info.plist"
cp "$ROOT/config.example.json" "$APP/Contents/Resources/config.example.json"

chmod +x "$APP/Contents/MacOS/$BINARY_NAME"

echo "Built $APP"
