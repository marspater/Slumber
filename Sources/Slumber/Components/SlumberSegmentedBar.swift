//
//  SlumberSegmentedBar.swift
//  Slumber
//
//  Tactile segmented tab navigation between Timer and Settings.
//

import SwiftUI

public struct TabButton: View {
    public let title: String
    public let icon: String
    public let tag: Int
    @Binding public var currentTab: Int
    public var animationNamespace: Namespace.ID
    @State private var isHovered = false
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    public init(
        title: String,
        icon: String,
        tag: Int,
        currentTab: Binding<Int>,
        animationNamespace: Namespace.ID
    ) {
        self.title = title
        self.icon = icon
        self.tag = tag
        self._currentTab = currentTab
        self.animationNamespace = animationNamespace
    }

    public var body: some View {
        let active = currentTab == tag
        Button {
            playSound("space_button")
            withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
                currentTab = tag
            }
        } label: {
            HStack(spacing: SlumberTheme.Metrics.spaceXS + 2) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
                Text(title)
                    .font(SlumberTheme.Typography.title.weight(active ? .bold : .medium))
            }
            .foregroundColor(
                active
                    ? SlumberTheme.Colors.textPrimary
                    : (isHovered
                        ? SlumberTheme.Colors.textPrimary
                        : SlumberTheme.Colors.textSecondary)
            )
            .padding(.vertical, 7)
            .padding(.horizontal, 16)
            .background {
                if active {
                    RoundedRectangle(cornerRadius: SlumberTheme.Radius.md, style: .continuous)
                        .fill(
                            reduceTransparency
                                ? Color(red: 0.24, green: 0.20, blue: 0.36)
                                : SlumberTheme.Colors.accent.opacity(0.18)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: SlumberTheme.Radius.md, style: .continuous)
                                .stroke(
                                    reduceTransparency ? Color.white.opacity(0.45) : Color.white.opacity(0.30),
                                    lineWidth: reduceTransparency ? 1.0 : 0.75
                                )
                        )
                        .matchedGeometryEffect(id: "activeTabIndicator", in: animationNamespace)
                } else if isHovered {
                    RoundedRectangle(cornerRadius: SlumberTheme.Radius.md, style: .continuous)
                        .fill(reduceTransparency ? Color.white.opacity(0.12) : Color.white.opacity(0.05))
                }
            }
        }
        .buttonStyle(SlumberTactileButtonStyle(scaleDown: 0.98))
        .accessibilityLabel("\(title) tab")
        .accessibilityValue(active ? "Selected" : "Not selected")
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.18)) {
                isHovered = hovering
            }
        }
    }
}
