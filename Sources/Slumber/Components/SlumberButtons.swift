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
    @State private var isHovered = false
    private let accent = SlumberTheme.Colors.accent
    private let cyan = SlumberTheme.Colors.cyan
    private typealias Spec = SlumberTheme.Components.StartButton

    public init(action: @escaping () -> Void) {
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: SlumberTheme.Metrics.spaceSM) {
                Image(systemName: SlumberTheme.Icons.start)
                    .font(SlumberTheme.Icons.startFont)
                Text("Start Sleep Timer")
                    .font(SlumberTheme.Typography.title)
            }
            .frame(width: SlumberTheme.Metrics.contentWidth, height: SlumberTheme.Metrics.primaryButtonHeight)
            .background(
                LinearGradient(
                    colors: [
                        accent.opacity(Spec.fillOpacity(isHovered)),
                        cyan.opacity(Spec.fillOpacity(isHovered))
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            // Dark ink: white on the bright violet-cyan gradient measured about 2:1.
            .foregroundColor(SlumberTheme.Colors.onAccent)
            .clipShape(RoundedRectangle(cornerRadius: SlumberTheme.Radius.lg, style: .continuous))
            .shadow(
                color: accent.opacity(Spec.glowOpacity(isHovered)),
                radius: Spec.glowRadius(isHovered),
                x: 0,
                y: Spec.glowOffsetY(isHovered)
            )
        }
        .buttonStyle(SlumberTactileButtonStyle(scaleDown: Spec.pressScale))
        .accessibilityLabel("Start Sleep Timer")
        .accessibilityHint("Starts the sleep countdown timer")
        .onHover { hovering in
            withAnimation(SlumberTheme.Motion.hoverButton) {
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
    private typealias Spec = SlumberTheme.Components.CancelButton

    public init(action: @escaping () -> Void) {
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: SlumberTheme.Metrics.spaceXS) {
                Image(systemName: SlumberTheme.Icons.cancel)
                    .font(SlumberTheme.Icons.cancelFont)
                Text("Cancel")
                    .font(SlumberTheme.Typography.title)
            }
            .frame(width: Spec.width, height: SlumberTheme.Metrics.buttonHeight)
            .background(coral.opacity(Spec.fillOpacity(isHovered)))
            .foregroundColor(coral)
            .clipShape(RoundedRectangle(cornerRadius: SlumberTheme.Radius.lg, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: SlumberTheme.Radius.lg, style: .continuous)
                    .stroke(coral.opacity(Spec.strokeOpacity(isHovered)), lineWidth: SlumberTheme.Stroke.thin)
            )
            .shadow(color: coral.opacity(Spec.glowOpacity(isHovered)), radius: Spec.glowRadius)
        }
        .buttonStyle(SlumberTactileButtonStyle(scaleDown: Spec.pressScale))
        .accessibilityLabel("Cancel Timer")
        .accessibilityHint("Stops the active sleep countdown")
        .onHover { hovering in
            withAnimation(SlumberTheme.Motion.hoverButton) {
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
    private typealias Spec = SlumberTheme.Components.QuitButton

    public init(action: @escaping () -> Void) {
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: SlumberTheme.Metrics.spaceSM) {
                Image(systemName: SlumberTheme.Icons.quit)
                    .font(SlumberTheme.Icons.quitFont)
                Text("Quit Slumber")
                    .font(SlumberTheme.Typography.title)
            }
            .frame(maxWidth: .infinity)
            .frame(height: SlumberTheme.Metrics.buttonHeight)
            .background(coral.opacity(Spec.fillOpacity(isHovered)))
            .foregroundColor(coral)
            .clipShape(RoundedRectangle(cornerRadius: SlumberTheme.Radius.lg, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: SlumberTheme.Radius.lg, style: .continuous)
                    .stroke(coral.opacity(Spec.strokeOpacity(isHovered)), lineWidth: SlumberTheme.Stroke.thin)
            )
        }
        .buttonStyle(SlumberTactileButtonStyle(scaleDown: Spec.pressScale))
        .accessibilityLabel("Quit Slumber")
        .accessibilityHint("Terminates the Slumber application")
        .onHover { hovering in
            withAnimation(SlumberTheme.Motion.hoverButton) {
                isHovered = hovering
            }
        }
    }
}
