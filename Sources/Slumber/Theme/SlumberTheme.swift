//
//  SlumberTheme.swift
//  Slumber
//
//  Design system tokens: colors, sky palette, typography, iconography, metrics, radii, strokes,
//  motion, per-component specs, and the tactile press style. Artwork tokens (moon, clouds,
//  companions, stars, scene layout) live in SlumberTheme+Art.swift; the P3/EDR color API in
//  Color+HDR.swift. docs/DESIGN.md documents all of it.
//
//  Animations are `static var` so each use builds a fresh value; everything else is `static let`.
//

import SwiftUI
import AppKit

public enum SlumberTheme {
    // MARK: - Colors
    public enum Colors {
        /// Primary celestial accent (Lavender / Moonlit Violet)
        public static let accent = Color.p3(h: 0.75, s: 0.65, b: 0.92)
        /// Atmospheric accent (Cyan / Cosmic Blue)
        public static let cyan   = Color.p3(h: 0.53, s: 0.55, b: 0.97)
        /// Label ink for text on the accent-to-cyan gradient (meets 4.5:1).
        public static let onAccent = Color.p3(h: 0.72, s: 0.70, b: 0.14)
        /// Soft alert / destructive action (Coral / Soft Rosé)
        public static let coral  = Color.p3(h: 0.98, s: 0.65, b: 0.95)
        /// Warning / retry accent (Warm Amber)
        public static let amber  = Color.p3(h: 0.08, s: 0.85, b: 0.98)

        // Text & Hierarchy
        public static let textPrimary    = Color.white
        public static let textSecondary  = Color.white.opacity(0.72)
        public static let textTertiary   = Color.white.opacity(0.50)
        public static let textQuaternary = Color.white.opacity(0.35)

        // Reduce Transparency solid fallbacks (sRGB, tuned to match the translucent originals)
        public static let solidBackground    = Color(red: 0.07, green: 0.06, blue: 0.12)
        public static let solidTabBar        = Color(red: 0.13, green: 0.12, blue: 0.19)
        public static let solidCard          = Color(red: 0.14, green: 0.13, blue: 0.21)
        public static let solidTabActive     = Color(red: 0.24, green: 0.20, blue: 0.36)
        public static let solidChipSelected  = Color(red: 0.38, green: 0.32, blue: 0.55)
        public static let solidErrorBanner   = Color(red: 0.16, green: 0.10, blue: 0.09)
        public static let solidRetry         = Color(red: 0.35, green: 0.20, blue: 0.12)

        /// Drop-shadow ink under raised controls and the error banner.
        public static let shadow = Color.black

        // Surfaces & Materials
        public static func cardBackground(reduceTransparency: Bool) -> Color {
            reduceTransparency ? solidCard : Color.white.opacity(0.045)
        }

        public static func cardBorder(isHovered: Bool, reduceTransparency: Bool) -> AnyShapeStyle {
            if reduceTransparency {
                return AnyShapeStyle(Color.white.opacity(isHovered ? 0.35 : 0.22))
            } else {
                return AnyShapeStyle(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(isHovered ? 0.22 : 0.14),
                            Color.white.opacity(0.03)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            }
        }
    }

    // MARK: - Sky
    /// The popover's background gradient darkens through five phases as the duration grows.
    public enum Sky {
        /// Upper minute bound of phases 0-3; anything longer is phase 4.
        /// Sunset Glow (1-20), Evening Twilight (21-38), Late Dusk (39-50), Midnight Blue (51-75),
        /// Deep Cosmic Space (76-120).
        public static let phaseUpperBounds = [20, 38, 50, 75]

        public static func phase(forMinutes minutes: Int) -> Int {
            phaseUpperBounds.firstIndex { minutes <= $0 } ?? phaseUpperBounds.count
        }

        /// Gradient top color per phase.
        public static let top: [Color] = [
            Color.p3(h: 0.83, s: 0.50, b: 0.24),
            Color.p3(h: 0.70, s: 0.72, b: 0.20),
            Color.p3(r: 0.05, g: 0.04, b: 0.14),
            Color.p3(r: 0.02, g: 0.03, b: 0.12),
            Color.p3(r: 0.005, g: 0.002, b: 0.02)
        ]

        /// Gradient bottom color per phase.
        public static let bottom: [Color] = [
            Color.p3(h: 0.88, s: 0.60, b: 0.10),
            Color.p3(h: 0.78, s: 0.55, b: 0.12),
            Color.p3(r: 0.14, g: 0.08, b: 0.22),
            Color.p3(r: 0.05, g: 0.05, b: 0.25),
            Color.p3(h: 0.76, s: 0.90, b: 0.06)
        ]

        /// Opacity over the popover material (Reduce Transparency draws the sky opaque).
        public static let topOpacity: Double = 0.65
        public static let bottomOpacity: Double = 0.75
    }

    // MARK: - Typography
    public enum Typography {
        /// Central timer display (e.g. "59:47" or "15") with fixed digit width
        public static let display = Font.system(size: 48, weight: .bold, design: .rounded).monospacedDigit()
        /// Central timer display for hour-scale countdowns (e.g. "1:24:45") perfectly fitted to holo circle
        public static let displayHours = Font.system(size: 34, weight: .bold, design: .rounded).monospacedDigit()
        /// Unit label beside display (e.g. "min")
        public static let displayUnit = Font.system(size: 16, weight: .semibold, design: .rounded)
        /// Section and card titles
        public static let title = Font.system(size: 14, weight: .semibold, design: .rounded)
        /// Subtitles and secondary descriptors
        public static let body = Font.system(size: 12, weight: .medium, design: .rounded)
        /// Caption, tags, and small control labels
        public static let caption = Font.system(size: 11, weight: .medium, design: .rounded)
        /// Micro labels (slider bounds, footer tagline)
        public static let micro = Font.system(size: 10, weight: .medium, design: .rounded)
        /// Monospaced keyboard shortcut badges
        public static let keycap = Font.system(size: 11, weight: .bold, design: .monospaced)

        /// Extra leading for multi-line captions (settings descriptions).
        public static let captionLineSpacing: CGFloat = 2
    }

    // MARK: - Iconography
    /// SF Symbol names and the glyph sizes they are drawn at.
    public enum Icons {
        public static let timerTab = "moon.zzz"
        public static let settingsTab = "gearshape"
        public static let start = "bed.double.fill"
        public static let cancel = "xmark"
        public static let quit = "power"
        public static let warning = "exclamationmark.triangle.fill"
        public static let dismiss = "xmark.circle.fill"

        public static let startFont = Font.system(size: 13, weight: .semibold)
        public static let cancelFont = Font.system(size: 11, weight: .bold)
        public static let quitFont = Font.system(size: 12, weight: .semibold)
        public static let tabFont = Font.system(size: 11, weight: .semibold)
        public static let warningFont = Font.system(size: 13, weight: .semibold)
        public static let dismissFont = Font.system(size: 15)
    }

    // MARK: - Menu Bar
    public enum MenuBar {
        /// Template symbol, with a fallback symbol and then an emoji title if neither exists.
        public static let symbol = "moon.circle"
        public static let fallbackSymbol = "moon.fill"
        public static let fallbackTitle = "🌙"
        /// Matches the optical size/weight of the system menu bar extras (Wi-Fi, Control Center).
        public static let symbolPointSize: CGFloat = 16
        public static var symbolWeight: NSFont.Weight { .medium }
    }

    // MARK: - Metrics & Spacing
    public enum Metrics {
        public static let popoverWidth: CGFloat = 320
        public static let popoverHeight: CGFloat = 440
        public static let horizontalPadding: CGFloat = 24
        /// Unified content width: 320 - (2 * 24) = 272
        public static let contentWidth: CGFloat = 272

        // Control heights
        public static let buttonHeight: CGFloat = 38
        public static let primaryButtonHeight: CGFloat = 42

        // Spacing scale
        public static let spaceXXS: CGFloat = 2
        public static let spaceXS:  CGFloat = 4
        public static let spaceSM:  CGFloat = 8
        public static let spaceMD:  CGFloat = 12
        public static let spaceLG:  CGFloat = 16
        public static let spaceXL:  CGFloat = 20
    }

    // MARK: - Corner Radii
    public enum Radius {
        public static let xs:      CGFloat = 6
        public static let sm:      CGFloat = 8
        public static let md:      CGFloat = 10
        public static let lg:      CGFloat = 12
        public static let card:    CGFloat = 14
        public static let popover: CGFloat = 20
    }

    // MARK: - Strokes
    public enum Stroke {
        /// Tab bar outline.
        public static let hairline: CGFloat = 0.5
        /// Default control and card border.
        public static let thin: CGFloat = 0.75
        /// Reduce Transparency borders, which need to read without the glass gradient.
        public static let solid: CGFloat = 1.0
    }

    // MARK: - Motion
    public enum Motion {
        /// Hover fade for cards, chips and tabs.
        public static var hover: Animation { .easeOut(duration: 0.18) }
        /// Hover fade for the error banner's small buttons.
        public static var hoverQuick: Animation { .easeOut(duration: 0.15) }
        /// Hover glow on the slider.
        public static var hoverSlider: Animation { .easeOut(duration: 0.2) }
        /// Hover lift on the Start, Cancel and Quit buttons.
        public static var hoverButton: Animation { .spring(response: 0.2, dampingFraction: 0.8) }
        /// Press-down scale of `SlumberTactileButtonStyle`.
        public static var press: Animation { .spring(response: 0.20, dampingFraction: 0.75) }
        /// Preset chip selection.
        public static var select: Animation { .spring(response: 0.25, dampingFraction: 0.75) }
        /// Preset chip highlight cross-fade.
        public static var selectFade: Animation { .easeInOut(duration: 0.2) }
        /// Slider thumb grow/shrink when a drag starts or ends.
        public static var drag: Animation { .spring(response: 0.15, dampingFraction: 0.8) }
        /// Timer / Settings tab switch.
        public static var tabSwitch: Animation { .spring(response: 0.35, dampingFraction: 0.8) }
        /// Timer state changes (error banner in/out).
        public static var stateChange: Animation { .spring(response: 0.38, dampingFraction: 0.8) }
        /// Idle ⇄ running layout swap.
        public static var runningChange: Animation { .spring(response: 0.5, dampingFraction: 0.75) }
        /// Countdown digits rolling.
        public static var countdownTick: Animation { .snappy(duration: 0.35) }
        /// Countdown font swap between minutes and hours.
        public static var countdownResize: Animation { .easeInOut(duration: 0.3) }
        /// Sky gradient cross-fade between phases.
        public static var skyPhase: Animation { .easeInOut(duration: 1.0) }
        /// Progress ring and its dot gliding between the 1 Hz timer ticks.
        public static var ringProgress: Animation { .linear(duration: 1.0) }
        /// Pressed controls dim to this opacity.
        public static let pressedOpacity: Double = 0.90
        /// Error banner inserts from this scale.
        public static let bannerInsertScale: CGFloat = 0.95
    }

    // MARK: - Opacity
    public enum Opacity {
        /// Shortcut badge when the hotkey could not be registered.
        public static let disabled: Double = 0.4
    }

    // MARK: - Components
    /// Per-control sizes, state opacities and shadows. Values are opacities of the named color
    /// unless noted; `HoverPair` holds the resting and hovered value.
    public enum Components {
        public enum TabBar {
            public static let inset: CGFloat = 3
            public static let fillOpacity: Double = 0.05
            public static let strokeOpacity: Double = 0.08
            public static let strokeOpacitySolid: Double = 0.22
        }

        public enum Tab {
            public static let verticalPadding: CGFloat = 7
            public static let horizontalPadding: CGFloat = Metrics.spaceLG
            public static let iconSpacing: CGFloat = Metrics.spaceXS + 2
            /// Accent wash behind the active tab.
            public static let activeFillOpacity: Double = 0.18
            public static let activeStrokeOpacity: Double = 0.30
            public static let activeStrokeOpacitySolid: Double = 0.45
            public static let hoverFillOpacity: Double = 0.05
            public static let hoverFillOpacitySolid: Double = 0.12
            public static let pressScale: CGFloat = 0.98
        }

        public enum StartButton {
            public static let fillOpacity = HoverPair<Double>(0.92, hover: 1.0)
            public static let glowOpacity = HoverPair<Double>(0.35, hover: 0.55)
            public static let glowRadius = HoverPair<CGFloat>(9, hover: 14)
            public static let glowOffsetY = HoverPair<CGFloat>(2, hover: 4)
            public static let pressScale: CGFloat = 0.97
        }

        public enum CancelButton {
            public static let width: CGFloat = 140
            public static let fillOpacity = HoverPair<Double>(0.14, hover: 0.24)
            public static let strokeOpacity = HoverPair<Double>(0.25, hover: 0.45)
            public static let glowOpacity = HoverPair<Double>(0, hover: 0.25)
            public static let glowRadius: CGFloat = 8
            public static let pressScale: CGFloat = 0.96
        }

        public enum QuitButton {
            public static let fillOpacity = HoverPair<Double>(0.08, hover: 0.18)
            public static let strokeOpacity = HoverPair<Double>(0.18, hover: 0.32)
            public static let pressScale: CGFloat = 0.98
        }

        public enum Card {
            public static let padding: CGFloat = 14
        }

        public enum Keycap {
            public static let verticalPadding: CGFloat = 5
            public static let fillOpacity: Double = 0.10
            public static let strokeTopOpacity: Double = 0.30
            public static let strokeBottomOpacity: Double = 0.08
            public static let shadowOpacity: Double = 0.2
            public static let shadowRadius: CGFloat = 2
            public static let shadowOffsetY: CGFloat = 1
        }

        public enum ErrorBanner {
            public static let spacing: CGFloat = 10
            public static let verticalPadding: CGFloat = 9
            /// Black scrim plus a white glass wash behind the text.
            public static let scrimOpacity: Double = 0.45
            public static let glassOpacity: Double = 0.06
            /// Amber border.
            public static let strokeOpacity: Double = 0.4
            public static let strokeOpacitySolid: Double = 0.7
            public static let shadowOpacity: Double = 0.35
            public static let shadowRadius: CGFloat = 10
            public static let shadowOffsetY: CGFloat = 4

            public static let retryHorizontalPadding: CGFloat = 10
            public static let retryVerticalPadding: CGFloat = 5
            /// Amber fill.
            public static let retryFillOpacity = HoverPair<Double>(0.35, hover: 0.50)
            public static let retryStrokeOpacity = HoverPair<Double>(0.25, hover: 0.40)
            public static let retryStrokeOpacitySolid = HoverPair<Double>(0.45, hover: 0.70)
            public static let retryPressScale: CGFloat = 0.96

            public static let dismissSize: CGFloat = 24
            /// Rest opacity of the dismiss glyph; it turns fully white on hover.
            public static let dismissOpacity: Double = 0.45
            public static let dismissOpacitySolid: Double = 0.75
        }

        public enum Chip {
            public static let size = CGSize(width: 48, height: 32)
            /// Accent fill when selected.
            public static let selectedFillOpacity: Double = 0.34
            public static let fillOpacity = HoverPair<Double>(0.065, hover: 0.10)
            public static let fillOpacitySolid = HoverPair<Double>(0.12, hover: 0.18)
            /// Top-lit gloss on the selected chip.
            public static let glossOpacity: Double = 0.22
            public static let glossHeight: CGFloat = 10
            public static let selectedStrokeOpacity: Double = 0.38
            public static let strokeOpacity = HoverPair<Double>(0.10, hover: 0.20)
            public static let strokeFadeOpacity: Double = 0.03
            public static let selectedStrokeOpacitySolid: Double = 0.6
            public static let strokeOpacitySolid: Double = 0.25
            /// Accent glow around the selected chip.
            public static let glowOpacity: Double = 0.25
            public static let glowRadius: CGFloat = 6
            public static let pressScale: CGFloat = 0.95
        }

        public enum Slider {
            public static let thumbSize: CGFloat = 16
            public static let trackHeight: CGFloat = 7
            /// Hit and accessibility frame height.
            public static let height: CGFloat = 28
            public static let trackOpacity: Double = 0.10
            /// Cyan glow under the filled track: resting, hovered, dragging.
            public static let fillGlowOpacity = (rest: 0.2, hover: 0.4, drag: 0.6)
            public static let fillGlowRadius = (rest: CGFloat(4), drag: CGFloat(8))
            public static let thumbStrokeOpacity: Double = 0.85
            public static let thumbShadowOpacity: Double = 0.35
            public static let thumbShadowRadius: CGFloat = 2.5
            public static let thumbShadowOffsetY: CGFloat = 1
            /// Accent glow around the thumb.
            public static let thumbGlowOpacity: Double = 0.45
            public static let thumbGlowRadius = (rest: CGFloat(5), drag: CGFloat(8))
            public static let thumbScale = (rest: CGFloat(1.0), hover: CGFloat(1.12), drag: CGFloat(1.25))
        }

        public enum Countdown {
            /// Keeps "1:24:45" inside the progress ring.
            public static let maxWidth: CGFloat = 136
            public static let minimumScaleFactor: CGFloat = 0.75
        }

        public enum Ring {
            public static let diameter: CGFloat = 170
            public static let trackWidth: CGFloat = 4
            public static let trackOpacity: Double = 0.08
            public static let progressWidth: CGFloat = 4.5
            public static let glowOpacity: Double = 0.4
            public static let glowRadius: CGFloat = 6
            /// Sweep from 12 o'clock, cyan through violet and coral back to cyan.
            public static let gradient = [Colors.cyan, Colors.accent, Colors.coral, Colors.cyan]
            public static let dot = Color.p3(h: 0.53, s: 0.40, b: 1.0, level: .subtleHighlight)
            public static let dotSize: CGFloat = 7
            public static let dotGlowOpacity: Double = 0.8
            public static let dotGlowRadius: CGFloat = 4
        }
    }
}

// MARK: - Hover Pair
/// A token's resting and hovered value. Call it with the hover state to pick one.
public struct HoverPair<Value: Sendable>: Sendable {
    public let rest: Value
    public let hover: Value

    public init(_ rest: Value, hover: Value) {
        self.rest = rest
        self.hover = hover
    }

    public func callAsFunction(_ isHovered: Bool) -> Value {
        isHovered ? hover : rest
    }
}

// MARK: - Tactile Button Style
public struct SlumberTactileButtonStyle: ButtonStyle {
    public let scaleDown: CGFloat

    public init(scaleDown: CGFloat = 0.97) {
        self.scaleDown = scaleDown
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scaleDown : 1.0)
            .opacity(configuration.isPressed ? SlumberTheme.Motion.pressedOpacity : 1.0)
            .animation(SlumberTheme.Motion.press, value: configuration.isPressed)
    }
}
