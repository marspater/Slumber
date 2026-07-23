<div align="center">
  <h1>Slumber 🌙✨</h1>
  <p><b>An aesthetic macOS 26 & 27 menu bar sleep timer with vector graphics, companion animations, and P3 wide-gamut visuals.</b></p>

  [![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](LICENSE)
  [![macOS 26+](https://img.shields.io/badge/macOS-26.0%2B-purple.svg)]()
  [![Swift 6](https://img.shields.io/badge/Swift-6.0-orange.svg)]()
</div>

---

## 🌟 Overview

**Slumber** is an ambient, minimalist menu bar application for macOS. Built with native Swift and SwiftUI, it puts your Mac to sleep after a customizable countdown timer while providing a relaxing visual experience.

Slumber features a Display P3 wide-gamut cosmic sky, soft vector clouds, dynamic shooting stars, and orbiting **animal companions** (like the sleeping fox and purple kitten) that accompany you as you drift off to sleep.

---

## 📸 Screenshots & UI

<div align="center">
  <img src="Assets/screenshot.png" alt="Slumber App UI Screenshot" width="440"/>
  <br/>
  <em>(Experience peaceful bedtime timers right from your macOS menu bar!)</em>
</div>

---

## ✨ Features & Architecture

### 🎨 1. Beautiful Vector Graphics Engine
- Pure SwiftUI vector path shapes for clouds, twinkling stars, and cosmic auroras.
- Display P3 wide-gamut color definitions (`Color.p3(...)`) for vibrant colors across both Light & Dark OS themes.

### 🦊 2. Animated Animal Companions
- **Sleeping Fox & Kitten**: Interactive companions resting on soft clouds during idle state, smoothly transitioning to orbit around the sleeping moon when a countdown starts.
- **Keplerian Orbital Motion & Physics**: Continuous wall-clock time math using `TimelineView` for smooth floating, breathing sine-wave motions, and spring-interpolated position lerping.

### 🖥️ 3. Full macOS 26 & macOS 27 Support
- Native `.icon` bundle format support (`Main_Icon.icon`) with 3 adaptive modes and zero white borders.
- Display parameter change listener for SDR & HDR display adaptation.
- System wake notifications automatically cancel pending timers if the Mac is opened.

### 🎵 4. Soft Ambient Bedtime Audio
- Synthesized low-volume sine-wave audio cues for timer start, button presses, and cancellations.

---

## 🚀 Installation & Building

### Prerequisites
- **macOS 26.0** or later.
- Swift Command Line Tools (`swiftc`, `sips`, `iconutil`).

### 1-Click Build & Install

1. **Clone the repository:**
   ```bash
   git clone https://github.com/marspater/Slumber.git
   cd Slumber
   ```

2. **Build & install:**
   ```bash
   chmod +x build.sh
   ./build.sh
   cp -R Slumber.app /Applications/
   ```

3. **Launch Slumber:**
   ```bash
   open /Applications/Slumber.app
   ```

---

## 📄 License

Slumber is open-source software licensed under the **[GNU General Public License v3.0 (GPL-3.0)](LICENSE)**.

---

## 👤 Author

Developed with ❤️ by **Mars Pater** ([@marspater](https://github.com/marspater)).
