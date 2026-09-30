# Slumber Design Reference

Every visual value in Slumber lives in `Sources/Slumber/Theme/`. Views read tokens from there and should not hardcode colors, sizes, opacities, radii, shadows or timings. To change how Slumber looks, change a token; to add a control, add its spec next to the others.

| File | Holds |
|------|-------|
| `Theme/SlumberTheme.swift` | UI tokens: colors, sky, typography, icons, menu bar, metrics, radii, strokes, motion, per-component specs, `HoverPair`, `SlumberTactileButtonStyle` |
| `Theme/SlumberTheme+Art.swift` | Artwork tokens: scene layout, companion orbit, stars, shooting stars, fireflies, constellations, aurora, moon, clouds, fox, cat, dodo |
| `Theme/Color+HDR.swift` | `Color.p3(...)` constructors and the `HDRLevel` brightness tiers |
| `Art/ArtPaths.swift` | SVG path data for the moon, clouds and companions (viewBox units = points) |

What stays next to the views on purpose: layout structure, per-shape geometry in viewBox coordinates (gradient endpoints, rotation anchors, eye offsets), particle drift and fidget angles, and the orbit math. These describe how one drawing is built rather than a reusable design decision.

## Color

All brand colors are Display P3. Never convert them to sRGB, and never drop the `level:` argument on art colors: it is what makes glows exceed SDR white on EDR displays.

| Token | Value (P3 HSB) | Use |
|-------|----------------|-----|
| `Colors.accent` | h 0.75 s 0.65 b 0.92 | Lavender. Primary accent, selected chip, active tab, slider fill start |
| `Colors.cyan` | h 0.53 s 0.55 b 0.97 | Cosmic blue. Gradient partner of accent, ring and slider glow |
| `Colors.onAccent` | h 0.72 s 0.70 b 0.14 | Label ink on the accent→cyan gradient (4.5:1) |
| `Colors.coral` | h 0.98 s 0.65 b 0.95 | Cancel and Quit |
| `Colors.amber` | h 0.08 s 0.85 b 0.98 | Error banner and Retry |
| `Colors.textPrimary…Quaternary` | white at 1.0 / 0.72 / 0.50 / 0.35 | Text hierarchy |
| `Colors.shadow` | black | Drop-shadow and scrim ink |

**Reduce Transparency** swaps glass surfaces for the opaque sRGB `Colors.solid*` fallbacks (background, tab bar, card, active tab, selected chip, error banner, retry) and uses the `*Solid` opacity variants in each component spec.

### Sky

The popover background is a vertical gradient that darkens as the chosen duration grows (`Sky.phase(forMinutes:)`), cross-fading over `Motion.skyPhase`.

| Phase | Minutes | Name |
|-------|---------|------|
| 0 | 1–20 | Sunset Glow |
| 1 | 21–38 | Evening Twilight |
| 2 | 39–50 | Late Dusk |
| 3 | 51–75 | Midnight Blue |
| 4 | 76–120 | Deep Cosmic Space |

Top and bottom colors are `Sky.top[phase]` and `Sky.bottom[phase]`, drawn at 65% / 75% over the popover material (opaque under Reduce Transparency).

### HDR levels

`HDRLevel` sets how far above SDR white a color is pushed on EDR displays. Displays without headroom tone-map back to the plain P3 color.

| Level | × SDR white | Used for |
|-------|-------------|----------|
| `.sdr` | 1.0 | Sky, companion bodies, controls, text |
| `.rimHighlight` | 1.1 | Cloud rims, nightcap, sparkle stars, firefly cores, the companions' `?` and open eyes |
| `.subtleHighlight` | 1.25 | Aurora, constellation glow, nightcap trim, progress-ring dot |
| `.visibleGlow` | 1.75 | Moon halo, firefly resting glow, eye glint |
| `.strongGlow` | 2.25 | Moon crescent |
| `.effect` | 3.0 | Shooting-star flash, firefly peak |

## Typography

SF Rounded throughout, SF Mono for keycaps.

| Token | Size / weight | Use |
|-------|---------------|-----|
| `display` | 48 bold, monospaced digits | Idle minutes and countdown |
| `displayHours` | 34 bold, monospaced digits | Countdown ≥ 1 hour |
| `displayUnit` | 16 semibold | "min" |
| `title` | 14 semibold | Buttons, tabs, card titles |
| `body` | 12 medium | "drifting off…" |
| `caption` | 11 medium | Chips, descriptions, error text |
| `micro` | 10 medium | Slider bounds, footer |
| `keycap` | 11 bold mono | Shortcut badge |

`captionLineSpacing` (2pt) adds leading to multi-line captions. SF Symbol names and glyph sizes are in `Icons`.

## Layout

The popover is 320×440 with 24pt side margins, which gives the **272pt content grid**: slider, preset row (5 × 48 + 4 × 8), Start and Quit buttons all span exactly 272pt.

| Spacing | pt | | Radius | pt |
|---------|----|-|--------|----|
| `spaceXXS` | 2 | | `xs` (keycap) | 6 |
| `spaceXS` | 4 | | `sm` (retry) | 8 |
| `spaceSM` | 8 | | `md` (chip, tab) | 10 |
| `spaceMD` | 12 | | `lg` (buttons, banner) | 12 |
| `spaceLG` | 16 | | `card` (cards, tab bar) | 14 |
| `spaceXL` | 20 | | `popover` | 20 |

Control heights: `buttonHeight` 38, `primaryButtonHeight` 42 (Start is 4pt taller on purpose). Off-scale paddings (3, 5, 7, 9, 14) are optical sizing and live in the component specs.

Strokes: `hairline` 0.5 (tab bar, slider thumb), `thin` 0.75 (default borders), `solid` 1.0 (Reduce Transparency borders). All rounded rectangles use `.continuous` corners.

## Motion

| Token | Curve | Use |
|-------|-------|-----|
| `hover` | easeOut 0.18 | Cards, chips, tabs |
| `hoverQuick` | easeOut 0.15 | Error banner buttons |
| `hoverSlider` | easeOut 0.2 | Slider glow |
| `hoverButton` | spring 0.2 / 0.8 | Start, Cancel, Quit lift |
| `press` | spring 0.20 / 0.75 | Tactile press (scale + 90% opacity) |
| `select` / `selectFade` | spring 0.25 / 0.75, easeInOut 0.2 | Preset chip |
| `drag` | spring 0.15 / 0.8 | Slider thumb grab |
| `tabSwitch` | spring 0.35 / 0.8 | Timer ⇄ Settings |
| `stateChange` | spring 0.38 / 0.8 | Error banner in/out |
| `runningChange` | spring 0.5 / 0.75 | Idle ⇄ running layout |
| `countdownTick` | snappy 0.35 | Rolling digits |
| `countdownResize` | easeInOut 0.3 | Minutes ⇄ hours font |
| `skyPhase` | easeInOut 1.0 | Sky cross-fade |
| `ringProgress` | linear 1.0 | Ring glide between 1 Hz ticks |

Every perpetual or decorative animation must check `accessibilityReduceMotion` and stay still (or be hidden) when it is on. Press scales per control: Start 0.97, Cancel and Retry 0.96, Quit and tabs 0.98, chips 0.95.

## Components

`SlumberTheme.Components` holds one spec per control: sizes, state opacities and shadows. `HoverPair(rest, hover:)` stores a resting and hovered value and is called with the hover state, for example `Spec.fillOpacity(isHovered)`.

| Spec | Control |
|------|---------|
| `TabBar`, `Tab` | Segmented Timer / Settings bar |
| `StartButton`, `CancelButton`, `QuitButton` | Primary gradient button, coral secondary, coral destructive |
| `Card`, `Keycap` | Settings cards, shortcut badge |
| `ErrorBanner` | Sleep-failure banner with Retry and Dismiss |
| `Chip` | 48×32 preset chips |
| `Slider` | 272pt duration slider (visual layer only; the accessibility layer is separate on purpose) |
| `Countdown`, `Ring` | Countdown text and the 170pt progress ring |

## Artwork

The scene is vector art authored as SVG paths in `ArtPaths.swift` and colored from `SlumberTheme.Art`.

- **Moon** (`Art.Moon`): lavender crescent at `.strongGlow` with a halo, sleepy face, blush and a blue nightcap with pompom. Bobs 5pt and tilts 3° over 3.5 s.
- **Clouds** (`Art.Cloud`): lilac-to-white sleepy clouds with a fading EDR rim; large at 95% opacity, small at 60%.
- **Companions** (`Art.Fox`, `Art.Cat`, `Art.Dodo`, shared `Art.Companion`): one is picked at random each time the popover closes. They nap on the large cloud while idle, arc up to orbit the moon when the timer starts (`Art.Orbit`), and in the last minute open their eyes, twitch their ears and show a `?`.
- **Sky effects**: 45 twinkling stars (`Art.Stars`), 5 shooting stars (`Art.Scene.shootingStars`, `Art.ShootingStar`), 8 fireflies in amber, violet and cyan (`Art.Firefly`), three rotating constellations (`Art.Constellation`) and four aurora washes (`Art.Aurora`).

To preview art changes without a Mac, redraw the paths as SVG with the same viewBox and colors and render them in a browser.

## Icons and assets

| Asset | Notes |
|-------|-------|
| `Assets/AppIcon.icon` | Icon Composer package, compiled by `build.sh` with `actool`. Four layers over a P3 violet gradient (dark-mode variant darker): Sparkles, Moon, Timer Ring (glass, specular, translucent) and flat Stars. Edit it in Icon Composer only. |
| Menu bar | SF Symbol `moon.circle` at 16pt medium as a template image, falling back to `moon.fill`, then 🌙 (`SlumberTheme.MenuBar`). |
| `Assets/*.wav` | `space_timer_start` (Start), `cancel` (Cancel), `space_button` (chips, tabs, slider release). |
| `Assets/screenshot.png` | README preview. |

## Rules

- Reuse a token before adding one; add a new token rather than a literal in a view.
- Keep every surface usable under Reduce Transparency and Reduce Motion.
- Keep art colors in P3 with their HDR level.
- The custom slider stays non-focusable with a separate accessibility element; do not reintroduce focus chrome.
