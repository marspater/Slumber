//
//  SlumbrButtons.swift
//  Slumbr
//
//  Production-ready tactile buttons with hover, press, and focus affordances.
//

import SwiftUI

// MARK: - Start Button (Primary Action)
public struct StartButton: View {
    public let action: () -> Void
    @State private var isHovered = false
    private let accent = SlumbrTheme.Colors.accent
    private let cyan = SlumbrTheme.Colors.cyan
    private typealias Spec = SlumbrTheme.Components.StartButton

    public init(action: @escaping () -> Void) {
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: SlumbrTheme.Metrics.spaceSM) {
                Image(systemName: SlumbrTheme.Icons.start)
                    .font(SlumbrTheme.Icons.startFont)
                Text("Start Sleep Timer")
                    .font(SlumbrTheme.Typography.title)
            }
            .frame(width: SlumbrTheme.Metrics.contentWidth, height: SlumbrTheme.Metrics.buttonHeight)
            .background(gradient(opacity: Spec.fillOpacity(isHovered)))
            .foregroundStyle(SlumbrTheme.Colors.textPrimary)
            .clipShape(RoundedRectangle(cornerRadius: SlumbrTheme.Radius.lg, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: SlumbrTheme.Radius.lg, style: .continuous)
                    .stroke(gradient(opacity: Spec.strokeOpacity(isHovered)), lineWidth: SlumbrTheme.Stroke.thin)
            }
            .shadow(
                color: accent.opacity(Spec.glowOpacity(isHovered)),
                radius: Spec.glowRadius(isHovered),
                x: 0,
                y: Spec.glowOffsetY(isHovered)
            )
        }
        .buttonStyle(SlumbrTactileButtonStyle(scaleDown: Spec.pressScale))
        .accessibilityLabel("Start Sleep Timer")
        .accessibilityHint("Starts the sleep countdown timer")
        .onHover { hovering in
            withAnimation(SlumbrTheme.Motion.hoverButton) {
                isHovered = hovering
            }
        }
    }

    private func gradient(opacity: Double) -> LinearGradient {
        LinearGradient(colors: [accent.opacity(opacity), cyan.opacity(opacity)], startPoint: .leading, endPoint: .trailing)
    }
}

// MARK: - Cancel Button (Secondary Action)
public struct CancelButton: View {
    public let action: () -> Void
    @State private var isHovered = false
    private let coral = SlumbrTheme.Colors.coral
    private typealias Spec = SlumbrTheme.Components.CancelButton

    public init(action: @escaping () -> Void) {
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: SlumbrTheme.Metrics.spaceXS) {
                Image(systemName: SlumbrTheme.Icons.cancel)
                    .font(SlumbrTheme.Icons.cancelFont)
                Text("Cancel")
                    .font(SlumbrTheme.Typography.title)
            }
            .frame(width: Spec.width, height: SlumbrTheme.Metrics.buttonHeight)
            .background(coral.opacity(Spec.fillOpacity(isHovered)))
            .foregroundStyle(coral)
            .clipShape(RoundedRectangle(cornerRadius: SlumbrTheme.Radius.lg, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: SlumbrTheme.Radius.lg, style: .continuous)
                    .stroke(coral.opacity(Spec.strokeOpacity(isHovered)), lineWidth: SlumbrTheme.Stroke.thin)
            }
            .shadow(color: coral.opacity(Spec.glowOpacity(isHovered)), radius: Spec.glowRadius)
        }
        .buttonStyle(SlumbrTactileButtonStyle(scaleDown: Spec.pressScale))
        .accessibilityLabel("Cancel Timer")
        .accessibilityHint("Stops the active sleep countdown")
        .onHover { hovering in
            withAnimation(SlumbrTheme.Motion.hoverButton) {
                isHovered = hovering
            }
        }
    }
}

// MARK: - Quit Button (Destructive App Action)
public struct QuitButton: View {
    public let action: () -> Void
    @State private var isHovered = false
    private let coral = SlumbrTheme.Colors.coral
    private typealias Spec = SlumbrTheme.Components.QuitButton

    public init(action: @escaping () -> Void) {
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: SlumbrTheme.Metrics.spaceSM) {
                Image(systemName: SlumbrTheme.Icons.quit)
                    .font(SlumbrTheme.Icons.quitFont)
                Text("Quit Slumbr")
                    .font(SlumbrTheme.Typography.title)
            }
            .frame(maxWidth: .infinity)
            .frame(height: SlumbrTheme.Metrics.buttonHeight)
            .background(coral.opacity(Spec.fillOpacity(isHovered)))
            .foregroundStyle(coral)
            .clipShape(RoundedRectangle(cornerRadius: SlumbrTheme.Radius.lg, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: SlumbrTheme.Radius.lg, style: .continuous)
                    .stroke(coral.opacity(Spec.strokeOpacity(isHovered)), lineWidth: SlumbrTheme.Stroke.thin)
            }
        }
        .buttonStyle(SlumbrTactileButtonStyle(scaleDown: Spec.pressScale))
        .accessibilityLabel("Quit Slumbr")
        .accessibilityHint("Terminates the Slumbr application")
        .onHover { hovering in
            withAnimation(SlumbrTheme.Motion.hoverButton) {
                isHovered = hovering
            }
        }
    }
}
