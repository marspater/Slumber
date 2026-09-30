//
//  Color+HDR.swift
//  Slumber
//
//  Display P3 + EDR (Extended Dynamic Range) color system for Slumber.
//  Glowing tiers are brightened above SDR white; macOS tone-maps them back to the plain
//  P3 color wherever the display has no headroom left (SDR monitors, or a MacBook Air at
//  full brightness), so no per-display detection is needed.
//

import SwiftUI

// MARK: - Semantic HDR tiers

/// Named brightness levels for Slumber's UI, as multiples of SDR white.
public enum HDRLevel: Double, Sendable {
    /// Background sky, companion bodies (fox/cat/dodo), base controls, chips, text.
    case sdr = 1.0
    /// Small highlights: cloud rims, the moon's nightcap, sparkle stars, firefly cores,
    /// the companions' '?' and awake eyes.
    case rimHighlight = 1.1
    /// Ambient light: aurora washes, constellation glow, the nightcap trim, the progress ring's dot.
    case subtleHighlight = 1.25
    /// Moon halo, a firefly's resting glow, a companion's eye glint.
    case visibleGlow = 1.75
    /// Moon core glow.
    case strongGlow = 2.25
    /// Shooting star flash, a firefly's peak twinkle frame.
    case effect = 3.0
}

// MARK: - Color Extension

extension Color {
    /// Display P3 color, brightened to `level` on EDR displays.
    public static func p3(
        _ red: Double,
        _ green: Double,
        _ blue: Double,
        _ opacity: Double = 1.0,
        level: HDRLevel = .sdr
    ) -> Color {
        edr(Color(.displayP3, red: red, green: green, blue: blue, opacity: opacity), level.rawValue)
    }

    /// Display P3 color with labeled RGB parameters and an explicit HDR tier.
    public static func p3(
        r red: Double,
        g green: Double,
        b blue: Double,
        a opacity: Double = 1.0,
        level: HDRLevel = .sdr
    ) -> Color {
        p3(red, green, blue, opacity, level: level)
    }

    /// Display P3 color with HSB parameters and an explicit HDR tier.
    public static func p3(
        h hue: Double,
        s saturation: Double,
        b brightness: Double,
        a opacity: Double = 1.0,
        level: HDRLevel = .sdr
    ) -> Color {
        let (r, g, bl) = hsbToRGB(hue: hue, saturation: saturation, brightness: brightness)
        return p3(r, g, bl, opacity, level: level)
    }

    /// Brightness interpolated between two tiers for continuous animations (e.g. firefly twinkle, shooting stars).
    public static func p3(
        _ red: Double,
        _ green: Double,
        _ blue: Double,
        _ opacity: Double = 1.0,
        headroomBetween low: HDRLevel,
        and high: HDRLevel,
        phase: Double // 0...1
    ) -> Color {
        let clampedPhase = min(max(phase, 0.0), 1.0)
        let level = low.rawValue + clampedPhase * (high.rawValue - low.rawValue)
        return edr(Color(.displayP3, red: red, green: green, blue: blue, opacity: opacity), level)
    }

    /// Interpolated brightness with labeled RGB parameters.
    public static func p3(
        r red: Double,
        g green: Double,
        b blue: Double,
        a opacity: Double = 1.0,
        headroomBetween low: HDRLevel,
        and high: HDRLevel,
        phase: Double
    ) -> Color {
        p3(red, green, blue, opacity, headroomBetween: low, and: high, phase: phase)
    }

    /// Interpolated brightness with HSB parameters.
    public static func p3(
        h hue: Double,
        s saturation: Double,
        b brightness: Double,
        a opacity: Double = 1.0,
        headroomBetween low: HDRLevel,
        and high: HDRLevel,
        phase: Double
    ) -> Color {
        let (r, g, bl) = hsbToRGB(hue: hue, saturation: saturation, brightness: brightness)
        return p3(r, g, bl, opacity, headroomBetween: low, and: high, phase: phase)
    }

    // MARK: - Private Helpers

    /// Scales the color's linear light by `level`. `exposureAdjust` also tags the result's headroom,
    /// which lets macOS tone-map it on displays with less headroom. `headroom(_:)` alone only tags:
    /// it renders no brighter on EDR displays and is dimmed (down to 0.66x) when tone-mapped to SDR.
    private static func edr(_ base: Color, _ level: Double) -> Color {
        level > 1.0 ? base.exposureAdjust(log2(level)) : base
    }

    /// Converts HSB parameters to RGB components.
    private static func hsbToRGB(
        hue: Double,
        saturation: Double,
        brightness: Double
    ) -> (red: Double, green: Double, blue: Double) {
        let c = brightness * saturation
        let hp = abs(hue).truncatingRemainder(dividingBy: 1.0) * 6.0
        let x = c * (1.0 - abs(hp.truncatingRemainder(dividingBy: 2.0) - 1.0))
        let m = brightness - c
        let r: Double, g: Double, bl: Double
        switch Int(hp) % 6 {
        case 0:  r = c;  g = x;  bl = 0
        case 1:  r = x;  g = c;  bl = 0
        case 2:  r = 0;  g = c;  bl = x
        case 3:  r = 0;  g = x;  bl = c
        case 4:  r = x;  g = 0;  bl = c
        default: r = c;  g = 0;  bl = x
        }
        return (r + m, g + m, bl + m)
    }
}
