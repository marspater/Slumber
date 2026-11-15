<div align="center">
  <img src="Assets/screenshot.png" alt="Slumbr sleep timer preview" width="340"/>

  # Slumbr 🌙

  **A native macOS menu bar sleep timer built with Swift 6 and SwiftUI, with Display P3 color, EDR highlights, vector artwork, and animated companions.**

  [![Swift CI](https://github.com/marspater/Slumbr/actions/workflows/swift.yml/badge.svg)](https://github.com/marspater/Slumbr/actions/workflows/swift.yml)
  [![CodeQL](https://github.com/marspater/Slumbr/actions/workflows/codeql.yml/badge.svg)](https://github.com/marspater/Slumbr/actions/workflows/codeql.yml)
  [![macOS 26+](https://img.shields.io/badge/macOS-26.0%2B-purple.svg)]()
  [![Swift 6](https://img.shields.io/badge/Swift-6-orange.svg)]()
  [![Version](https://img.shields.io/badge/version-4.0-blue.svg)](https://github.com/marspater/Slumbr/tags)
  [![License: GPL v3](https://img.shields.io/badge/license-GPL--3.0-blue.svg)](LICENSE)
</div>

## What it does

Slumbr lives in the macOS menu bar and puts the Mac to sleep after a configurable countdown. The UI is intentionally compact, native, and lightweight while still being mildly excessive about moonlight.

### Highlights

- Native Swift 6 + SwiftUI/AppKit menu bar app.
- 1–120 minute countdown with presets and keyboard control.
- Display P3 color with EDR brightness tiers and system tone mapping on displays without headroom.
- Vector moon, clouds, fox, cat, and dodo artwork with Reduce Motion support.
- Global `⌃⌥S` shortcut with conflict detection.
- Deadline-based timer logic that handles wake events without immediately putting the Mac back to sleep after a missed deadline.
- IOKit sleep request with an AppleScript fallback.
- Automated Swift CI and CodeQL security scanning.

## Requirements

- macOS 26.0 or later.
- Xcode / Apple command-line developer tools when building from source.

## Download

The current packaged build is tracked as [`Slumbr.zip`](Slumbr.zip).

1. Download and unzip `Slumbr.zip`.
2. Move `Slumbr.app` to `/Applications`.
3. Open Slumbr from Finder, Spotlight, or Launchpad.

The tracked build is not notarized, so macOS may require an explicit first-launch approval. If you prefer not to use a prebuilt artifact, build from source instead.

## Build from source

```bash
git clone https://github.com/marspater/Slumbr.git
cd Slumbr
xcodebuild test -project Slumbr.xcodeproj -scheme Slumbr -destination 'platform=macOS'
chmod +x build.sh
./build.sh --install
```

Useful build options:

- `./build.sh` builds `.build/artifacts/Slumbr.app` from `Slumbr.xcodeproj` with `xcodebuild`.
- `./build.sh --install` also installs it to `/Applications`.
- `./build.sh --package` refreshes the tracked `Slumbr.zip`.

When a Developer ID signing identity is available, the build script prefers it. Otherwise it falls back to ad-hoc signing.

## Repository layout

| Path | Purpose |
| --- | --- |
| `Slumbr.xcodeproj` | Xcode project: `Slumbr` app, `SlumbrCore` framework, `SlumbrTests` |
| `Sources/SlumbrCore` | Timer/domain logic and sleep integration |
| `Sources/Slumbr` | SwiftUI/AppKit UI, menu bar integration, art, and theme |
| `Sources/Slumbr/Theme` | Central design tokens, P3/EDR levels, component and art specs |
| `Tests/SlumbrTests` | Swift Testing suites for the timer, formatting, vector parsing, theme and artwork |
| `Assets` | Icon Composer source, screenshot, and audio assets |
| `docs/DESIGN.md` | Design system and artwork reference |
| `.github/workflows` | CI and CodeQL workflows |

## Development

Run the standard validation sequence on macOS:

```bash
xcodebuild -list -project Slumbr.xcodeproj
xcodebuild test -project Slumbr.xcodeproj -scheme Slumbr -destination 'platform=macOS'
./build.sh
```

See [`AGENTS.md`](AGENTS.md) for repository-specific engineering rules and [`docs/DESIGN.md`](docs/DESIGN.md) for the visual system.

## Changes

The latest work on `main` is documented in [`CHANGELOG.md`](CHANGELOG.md). Version 3.5 collects everything since the v3.2 tag, so the changelog is the better place to inspect what moved instead of embalming old implementation details in this README.

## License

Copyright © 2026 Mars Pater.

Slumbr is licensed under the [GNU General Public License v3.0](LICENSE).
