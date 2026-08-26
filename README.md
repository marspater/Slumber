<div align="center">
  <img src="Assets/app_icon.png" alt="Slumber App Icon" width="128"/>
  <h1>Slumber 🌙✨</h1>
  <p><b>An aesthetic macOS menu bar sleep timer with vector graphics, companion animations, and P3 wide-gamut visuals.</b></p>

  [![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](LICENSE)
  [![macOS 14+](https://img.shields.io/badge/macOS-14.0%2B-purple.svg)]()
  [![Version](https://img.shields.io/badge/Version-2.8-orange.svg)](https://github.com/marspater/Slumber/releases/latest)
  [![Download](https://img.shields.io/badge/Download-Slumber.zip-brightgreen.svg)](https://github.com/marspater/Slumber/releases/latest/download/Slumber.zip)
</div>

---

## 🌟 Overview

**Slumber** is an ambient, minimalist menu bar application for macOS. Built with native Swift 6 and SwiftUI, it puts your Mac to sleep after a customizable countdown timer while providing a relaxing visual experience.

Slumber features a Display P3 wide-gamut cosmic sky, soft vector clouds, dynamic shooting stars, and orbiting **animal companions** (the sleeping fox, purple kitten, and sleeping dodo bird) that somersault and float around the moon in zero-gravity as you drift off to sleep.

---

## 📦 Download & Quick Install

### Option 1: Direct Download (Recommended)
1. Download the latest **[Slumber.zip](https://github.com/marspater/Slumber/releases/latest/download/Slumber.zip)**.
2. Unzip and drag `Slumber.app` into your `/Applications` folder.
3. Open Slumber from Spotlight or `/Applications`!

### Option 2: Build from Source
```bash
git clone https://github.com/marspater/Slumber.git
cd Slumber
chmod +x build.sh
./build.sh
cp -R Slumber.app /Applications/
open /Applications/Slumber.app
```

---

## 📝 Recent Changes (v2.8)

- **🎨 Apple Icon Composer Artwork**:
  - Implemented the official Apple Icon Composer bundle format (`New_Icon.icon`) with multi-layer SVG vector depth, translucency, refractivity, and Display P3 wide-gamut rendering.
  - Native generation of multi-resolution `AppIcon.icns` (`16x16` through `1024x1024`).

- **🦤 3rd Companion: Sleeping Dodo Bird**:
  - Added the **Sleeping Dodo** (`SleepingDodo`) with celestial turquoise plumage, hooked amber beak, fluffy tail tufts, breathing animations, and sleepy `"zzz"` particles.
  - The app randomly selects from all 3 companions (**Fox**, **Cat**, **Dodo**) on launch and timer start.

- **🛰️ Zero-Gravity 360° Space Somersault & Floating Physics**:
  - Orbiting companions perform continuous, playful 360° axial somersaults and Lissajous floating micro-drifts simulating cartoon space weightlessness.

- **✨ UI Polish & Design System Tokens**:
  - Unified corner radii tokens (`20pt` popover, `14pt` cards, `12pt` buttons, `10pt` chips).
  - Perfect track alignment for the min/max slider labels.
  - Interactive liquid glass sliding indicator tab bar with audio cues.
  - Frosted glass keycap badge (`[ ⌃⌥S ]`) for the global hotkey.
  - Shifted destructive actions to a luminous, bedtime-friendly coral tone.

---

## ✨ Features & Architecture

### 🎨 1. Beautiful Vector Graphics Engine
- Pure SwiftUI vector path shapes for clouds, twinkling stars, and cosmic auroras.
- Display P3 wide-gamut color definitions (`Color.p3(...)`) for vibrant colors across both Light & Dark OS themes.

### 🦊 2. Animated Animal Companions
- **Sleeping Fox, Kitten & Dodo**: Interactive companions resting on soft clouds during idle state, smoothly transitioning to orbit and somersault around the sleeping moon when a countdown starts.
- **Keplerian Orbital Motion & Zero-G Physics**: Continuous wall-clock time math using `TimelineView` for zero-g floating, breathing sine-wave motions, and spring-interpolated position lerping.

### 🖥️ 3. Native macOS Support
- Native `.icon` bundle format support (`New_Icon.icon`) compiled with Apple standard `actool` and `iconutil`.
- Display parameter change listener for SDR & HDR display adaptation.
- System wake notifications automatically cancel pending timers if the Mac is opened.
- Native macOS `Toggle` switch style with system accessibility.

### 🎵 4. Soft Ambient Bedtime Audio
- Synthesized low-volume sine-wave audio cues for timer start, preset selection, and button presses.

---

## 📄 License

Slumber is open-source software licensed under the **[GNU General Public License v3.0 (GPL-3.0)](LICENSE)**.

---

## 👤 Author

Developed with ❤️ by **Mars Pater** ([@marspater](https://github.com/marspater)).
