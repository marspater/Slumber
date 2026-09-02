//
//  SlumberTheme.swift
//  Slumber
//
//  Design system tokens: colors, typography, metrics, shapes, and tactile interaction styles.
//

import SwiftUI

public enum SlumberTheme {
    // MARK: - Colors
    public enum Colors {
        /// Primary celestial accent (Lavender / Moonlit Violet)
        public static let accent = Color.p3(h: 0.75, s: 0.65, b: 0.92)
        /// Atmospheric accent (Cyan / Cosmic Blue)
        public static let cyan   = Color.p3(h: 0.53, s: 0.55, b: 0.97)
        /// Soft alert / destructive action (Coral / Soft Rosé)
        public static let coral  = Color.p3(h: 0.98, s: 0.65, b: 0.95)
        /// Warning / retry accent (Warm Amber)
        public static let amber  = Color.p3(h: 0.08, s: 0.85, b: 0.98)

        // Text & Hierarchy
        public static let textPrimary    = Color.white
        public static let textSecondary  = Color.white.opacity(0.72)
        public static let textTertiary   = Color.white.opacity(0.50)
        public static let textQuaternary = Color.white.opacity(0.35)

        // Surfaces & Materials
        public static func cardBackground(reduceTransparency: Bool) -> Color {
            reduceTransparency ? Color(red: 0.14, green: 0.13, blue: 0.21) : Color.white.opacity(0.045)
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

    // MARK: - Typography
    public enum Typography {
        /// Central timer display (e.g. "59:47" or "15") with fixed digit width
        public static let display = Font.system(size: 48, weight: .bold, design: .rounded).monospacedDigit()
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
    }

    // MARK: - Metrics & Spacing
    public enum Metrics {
        public static let popoverWidth: CGFloat = 320
        public static let popoverHeight: CGFloat = 440
        public static let horizontalPadding: CGFloat = 24
        /// Unified content width: 320 - (2 * 24) = 272
        public static let contentWidth: CGFloat = 272

        // Spacing scale
        public static let spaceXXS: CGFloat = 2
        public static let spaceXS:  CGFloat = 4
        public static let spaceSM:  CGFloat = 8
        public static let spaceMD:  CGFloat = 12
        public static let spaceLG:  CGFloat = 16
        public static let spaceXL:  CGFloat = 20
        public static let spaceXXL: CGFloat = 24
    }

    // MARK: - Corner Radii
    public enum Radius {
        public static let sm:      CGFloat = 8
        public static let md:      CGFloat = 10
        public static let lg:      CGFloat = 12
        public static let card:    CGFloat = 14
        public static let popover: CGFloat = 20
        public static let pill:    CGFloat = 999
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
            .opacity(configuration.isPressed ? 0.90 : 1.0)
            .animation(.spring(response: 0.20, dampingFraction: 0.75), value: configuration.isPressed)
    }
}
