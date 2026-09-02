//
//  SlumberButtons.swift
//  Slumber
//
//  Production-ready tactile buttons with hover, press, and focus affordances.
//

import SwiftUI

// MARK: - Start Button (Primary Action)
public struct StartButton: View {
    public let action: () -> Void
    public let accent: Color
    public let cyan: Color
    @State private var isHovered = false

    public init(
        action: @escaping () -> Void,
        accent: Color = SlumberTheme.Colors.accent,
        cyan: Color = SlumberTheme.Colors.cyan
    ) {
        self.action = action
        self.accent = accent
        self.cyan = cyan
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: SlumberTheme.Metrics.spaceSM) {
                Image(systemName: "bed.double.fill")
                    .font(.system(size: 13, weight: .semibold))
                Text("Start Sleep Timer")
                    .font(SlumberTheme.Typography.title)
            }
            .frame(width: 240, height: 42)
            .background(
                LinearGradient(
                    colors: [
                        accent.opacity(isHovered ? 1.0 : 0.92),
                        cyan.opacity(isHovered ? 1.0 : 0.92)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: SlumberTheme.Radius.lg, style: .continuous))
            .shadow(
                color: accent.opacity(isHovered ? 0.55 : 0.35),
                radius: isHovered ? 14 : 9,
                x: 0,
                y: isHovered ? 4 : 2
            )
        }
        .buttonStyle(SlumberTactileButtonStyle(scaleDown: 0.97))
        .accessibilityLabel("Start Sleep Timer")
        .accessibilityHint("Starts the sleep countdown timer")
        .onHover { hovering in
            withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                isHovered = hovering
            }
        }
    }
}

// MARK: - Cancel Button (Secondary Action)
public struct CancelButton: View {
    public let action: () -> Void
    @State private var isHovered = false
    private let coral = SlumberTheme.Colors.coral

    public init(action: @escaping () -> Void) {
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: SlumberTheme.Metrics.spaceXS) {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .bold))
                Text("Cancel")
                    .font(SlumberTheme.Typography.title)
            }
            .frame(width: 140, height: 38)
            .background(coral.opacity(isHovered ? 0.24 : 0.14))
            .foregroundColor(coral)
            .clipShape(RoundedRectangle(cornerRadius: SlumberTheme.Radius.lg, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: SlumberTheme.Radius.lg, style: .continuous)
                    .stroke(coral.opacity(isHovered ? 0.45 : 0.25), lineWidth: 0.75)
            )
            .shadow(color: coral.opacity(isHovered ? 0.25 : 0), radius: 8)
        }
        .buttonStyle(SlumberTactileButtonStyle(scaleDown: 0.96))
        .accessibilityLabel("Cancel Timer")
        .accessibilityHint("Stops the active sleep countdown")
        .onHover { hovering in
            withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                isHovered = hovering
            }
        }
    }
}

// MARK: - Quit Button (Destructive App Action)
public struct QuitButton: View {
    public let action: () -> Void
    @State private var isHovered = false
    private let coral = SlumberTheme.Colors.coral

    public init(action: @escaping () -> Void) {
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: SlumberTheme.Metrics.spaceSM) {
                Image(systemName: "power")
                    .font(.system(size: 12, weight: .semibold))
                Text("Quit Slumber")
                    .font(SlumberTheme.Typography.title)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 38)
            .background(coral.opacity(isHovered ? 0.18 : 0.08))
            .foregroundColor(coral)
            .clipShape(RoundedRectangle(cornerRadius: SlumberTheme.Radius.lg, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: SlumberTheme.Radius.lg, style: .continuous)
                    .stroke(coral.opacity(isHovered ? 0.32 : 0.18), lineWidth: 0.75)
            )
        }
        .buttonStyle(SlumberTactileButtonStyle(scaleDown: 0.98))
        .accessibilityLabel("Quit Slumber")
        .accessibilityHint("Terminates the Slumber application")
        .onHover { hovering in
            withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                isHovered = hovering
            }
        }
    }
}
