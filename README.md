# Swift Menu Bar

A native macOS menu bar replacement built with Swift and SwiftUI. Designed for [yabai](https://github.com/koekeishiya/yabai) window management.

## Features

- **Yabai spaces** — clickable space buttons with window counts and focus highlighting
- **Google Sheet widget** — displays a published CSV cell value (optional)
- **Battery** — live percentage via IOKit
- **Date & time** — click to open Calendar
- **Native menu bar reveal** — move the cursor to the top edge to access the system menu bar

## Requirements

- macOS 14+
- [yabai](https://github.com/koekeishiya/yabai) installed and running
- Swift 5.9+ (Xcode Command Line Tools)

## Setup

```bash
git clone https://github.com/jsrath/swift-menu-bar.git
cd swift-menu-bar
cp config.example.json ~/Library/Application\ Support/SwiftMenuBar/config.json
```

Edit `~/Library/Application Support/SwiftMenuBar/config.json`:

| Key | Description |
|-----|-------------|
| `yabaiPath` | Path to the yabai binary (default: `/opt/homebrew/bin/yabai`) |
| `sheetURL` | Published Google Sheet CSV URL (optional) |
| `sheetRefreshInterval` | Sheet refresh interval in seconds (default: `600`) |
| `fontName` | Font family name (default: `Roboto`) |
| `fontSize` | Font size in points (default: `12`) |
| `barHeight` | Bar height in points — must match yabai `external_bar` (default: `29`) |

### yabai configuration

Add to your `~/.config/yabai/yabairc`:

```bash
yabai -m config external_bar all:29:0
yabai -m config mouse_follows_focus off
```

Adjust `29` to match `barHeight` in your config.

## Build & Run

```bash
./run.sh
```

This builds `SwiftMenuBar.app`, ensures config exists, and launches the app.

## Launch at Login

```bash
./install-launch-agent.sh
```

The install script generates a LaunchAgent with your local project path and waits for yabai before starting.

## Architecture

```
Sources/SwiftMenuBar/
├── App/            Application entry point and lifecycle
├── Configuration/  JSON config loading
├── Models/         Yabai and battery data types
├── Services/       yabai client, sheet fetch, battery, process runner
├── State/          Observable bar store
├── Theme/          Colors and typography
├── UI/             SwiftUI bar views
└── Window/         Panel, reveal controller, click handling
```

## License

MIT
