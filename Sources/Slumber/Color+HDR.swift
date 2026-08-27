//
//  Color+HDR.swift
//  Slumber
//
//  Display P3 + EDR (Extended Dynamic Range) color system for Slumber.
//  Provides named design tiers for HDR headroom, automatic fallback on
//  non-HDR external screens, and continuous headroom interpolation for animations.
//

import SwiftUI
#if os(macOS)
import AppKit
#endif

// MARK: - Semantic HDR tiers

/// Named headroom levels for Slumber's UI.
public enum HDRLevel: Double, CaseIterable, Sendable {
    /// Background sky, companion bodies (fox/cat/dodo), base controls, chips, text.
    case sdr = 1.0
    /// A thin specular highlight on an otherwise-SDR surface — a companion's eye
    /// glint, a cloud edge catching moonlight, or active slider thumb rim.
    case rimHighlight = 1.1
    /// Ambient gradients, cloud rim light, aurora washes, progress ring pulse.
    case subtleHighlight = 1.25
    /// Firefly glow (resting), moon halo outer edge.
    case visibleGlow = 1.75
    /// Moon core glow.
    case strongGlow = 2.25
    /// Shooting star flash, a firefly's peak twinkle frame.
    case effect = 3.0
}

// MARK: - Display capability

#if os(macOS)
/// Whether the *current* screen can actually render extended dynamic range.
///
/// Slumber is a menu bar app: its popover can be shown on whichever display
/// currently owns the menu bar (e.g. non-HDR external monitor). Always check
/// before assuming EDR headroom is available.
public enum DisplayHeadroom {
    /// True if this screen supports EDR at all (independent of current brightness state).
    public static func supportsEDR(_ screen: NSScreen? = .main) -> Bool {
        Double(screen?.maximumPotentialExtendedDynamicRangeColorComponentValue ?? 1.0) > 1.0
    }

    /// The live headroom currently available on screen right now.
    public static func currentHeadroom(_ screen: NSScreen? = .main) -> Double {
        Double(screen?.maximumExtendedDynamicRangeColorComponentValue ?? 1.0)
    }
}
#endif

extension HDRLevel {
    /// This level, or `.sdr` if the current display can't render EDR at all.
    public var effective: HDRLevel {
        #if os(macOS)
        DisplayHeadroom.supportsEDR() ? self : .sdr
        #else
        self
        #endif
    }
}

// MARK: - Color Extension

extension Color {
    /// Display P3 color with an explicit, named HDR headroom tier (unlabeled RGB).
    public static func p3(
        _ red: Double,
        _ green: Double,
        _ blue: Double,
        _ opacity: Double = 1.0,
        level: HDRLevel = .sdr
    ) -> Color {
        let base = Color(.displayP3, red: red, green: green, blue: blue, opacity: opacity)
        let effectiveLevel = level.effective
        guard effectiveLevel != .sdr else { return base }
        return base.headroom(effectiveLevel.rawValue)
    }

    /// Display P3 color with labeled RGB parameters and an explicit HDR headroom tier.
    public static func p3(
        r red: Double,
        g green: Double,
        b blue: Double,
        a opacity: Double = 1.0,
        level: HDRLevel = .sdr
    ) -> Color {
        p3(red, green, blue, opacity, level: level)
    }

    /// Display P3 color with HSB parameters and an explicit HDR headroom tier.
    public static func p3(
        h hue: Double,
        s saturation: Double,
        b brightness: Double,
        a opacity: Double = 1.0,
        level: HDRLevel = .sdr
    ) -> Color {
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
        return p3(r + m, g + m, bl + m, opacity, level: level)
    }

    /// Smoothly interpolates headroom between two HDR levels during continuous animations (e.g. firefly twinkle, shooting stars).
    public static func p3(
        _ red: Double,
        _ green: Double,
        _ blue: Double,
        _ opacity: Double = 1.0,
        headroomBetween low: HDRLevel,
        and high: HDRLevel,
        phase: Double // 0...1
    ) -> Color {
        let base = Color(.displayP3, red: red, green: green, blue: blue, opacity: opacity)
        guard low.effective != .sdr || high.effective != .sdr else { return base }
        let clampedPhase = min(max(phase, 0.0), 1.0)
        let lowVal = low.effective.rawValue
        let highVal = high.effective.rawValue
        let interpolated = lowVal + clampedPhase * (highVal - lowVal)
        guard interpolated > 1.0 else { return base }
        return base.headroom(interpolated)
    }

    /// Smoothly interpolates headroom with labeled RGB parameters.
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

    /// Smoothly interpolates headroom with HSB parameters.
    public static func p3(
        h hue: Double,
        s saturation: Double,
        b brightness: Double,
        a opacity: Double = 1.0,
        headroomBetween low: HDRLevel,
        and high: HDRLevel,
        phase: Double
    ) -> Color {
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
        return p3(r + m, g + m, bl + m, opacity, headroomBetween: low, and: high, phase: phase)
    }
}
