# Slumber 🌙✨

> A minimalist, aesthetic macOS menu bar sleep timer app built with Swift and SwiftUI.

> ⚠️ **Notice**: A major application overhaul is coming soon! This repository currently reflects the functional baseline state of the application.

---

## 🌟 Overview

**Slumber** is an elegant menu bar utility for macOS designed to put your Mac to sleep after a customizable countdown timer. Featuring a wide-gamut Display P3 dynamic starfield background, ambient sound effects, and a global hotkey, Slumber ensures your device sleeps when you do.

---

## ✨ Key Features

- **Menu Bar Integration**: Resides conveniently in your macOS menu bar (`NSStatusItem`) for instant access.
- **Custom Sleep Countdown**: Quick duration presets (15m, 30m, 45m, 60m) as well as custom minute inputs.
- **App Nap & Idle Prevention**: Prevents system idle sleep during active countdowns via `ProcessInfo` activity assertions.
- **System Wake Protection**: Automatically cancels pending timers when the Mac is woken up to prevent accidental late sleep triggers.
- **Global Hotkey**: Press `Ctrl + Option + S` anytime from any application to toggle the Slumber popover.
- **Cosmic Aesthetic UI**: Features an animated twinkling starfield with shooting star visual effects and interactive audio feedback.
- **Standalone Build Script**: Compiles cleanly into a native `.app` bundle via a single command line script using `swiftc`.

---

## 🚀 Building & Running

### Prerequisites

- **macOS**: 15.0 or later recommended.
- **Swift / Xcode Command Line Tools**: `swiftc`, `sips`, `iconutil`, `codesign`.

### Build Commands

1. Clone the repository:
   ```bash
   git clone https://github.com/marspater/Slumber.git
   cd Slumber
   ```

2. Run the build script:
   ```bash
   chmod +x build.sh
   ./build.sh
   ```

3. Launch the application:
   ```bash
   open Slumber.app
   ```

---

## 📁 Repository Structure

```text
.
├── SlumberApp.swift      # Main application entry point, AppDelegate, status bar item & hotkeys
├── SlumberTimer.swift    # Timer model, power management assertions & pmset sleep execution
├── SlumberView.swift     # SwiftUI popover interface, dynamic Starfield canvas & audio handlers
├── Assets/               # Audio effects (.wav) and app icon resources (.png)
├── FutureIconAsset.svg   # Vector icon artwork asset
└── build.sh              # Standalone shell script compiling the app bundle & iconsets
```

---

## 🛠 Tech Stack

- **Language**: Swift 6
- **UI Frameworks**: SwiftUI & AppKit (`NSStatusItem`, `NSPopover`, `NSHostingController`)
- **System APIs**: `Carbon` (Global Hotkeys), `AVFoundation` (Audio Playback), `ProcessInfo` (Activity assertions), `pmset`
- **Tooling**: `swiftc`, `sips`, `iconutil`, `codesign`

---

## 🔮 Upcoming Overhaul

A complete application overhaul is coming soon! Planned enhancements include:

- Modernized UI layout & view transitions optimized for macOS Sequoia and high dynamic range displays.
- Dedicated Preferences pane with customizable hotkeys and notification triggers.
- Full Xcode project (`.xcodeproj`) & Swift Package Manager setup.
- Launch-at-login and menu bar customization controls.

---

## 👤 Author

Developed by **Mars Pater** ([@marspater](https://github.com/marspater)).
