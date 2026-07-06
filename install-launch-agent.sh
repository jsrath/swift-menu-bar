#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
PLIST_DST="$HOME/Library/LaunchAgents/dev.swift-menu-bar.plist"

chmod +x "$ROOT/scripts/launch-at-login.sh"
"$ROOT/scripts/setup-config.sh"

cat > "$PLIST_DST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>dev.swift-menu-bar</string>
    <key>ProgramArguments</key>
    <array>
        <string>$ROOT/scripts/launch-at-login.sh</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
</dict>
</plist>
EOF

launchctl bootout "gui/$(id -u)/dev.swift-menu-bar" 2>/dev/null || true
launchctl bootstrap "gui/$(id -u)" "$PLIST_DST"
launchctl enable "gui/$(id -u)/dev.swift-menu-bar"

echo "Installed launch agent: $PLIST_DST"
echo "Swift Menu Bar will start automatically at login."
