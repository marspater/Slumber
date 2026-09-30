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
    private typealias Spec = SlumberTheme.Components.Tab
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
            guard !active else { return }
            playSound("space_button")
            withAnimation(SlumberTheme.Motion.tabSwitch) {
                currentTab = tag
            }
        } label: {
            HStack(spacing: Spec.iconSpacing) {
                Image(systemName: icon)
                    .font(SlumberTheme.Icons.tabFont)
                // Reserve the bold width so the bar doesn't reflow when the weight changes.
                Text(title)
                    .font(SlumberTheme.Typography.title.weight(.bold))
                    .hidden()
                    .overlay {
                        Text(title)
                            .font(SlumberTheme.Typography.title.weight(active ? .bold : .medium))
                    }
            }
            .foregroundColor(
                active || isHovered
                    ? SlumberTheme.Colors.textPrimary
                    : SlumberTheme.Colors.textSecondary
            )
            .padding(.vertical, Spec.verticalPadding)
            .padding(.horizontal, Spec.horizontalPadding)
            .background {
                if active {
                    RoundedRectangle(cornerRadius: SlumberTheme.Radius.md, style: .continuous)
                        .fill(
                            reduceTransparency
                                ? SlumberTheme.Colors.solidTabActive
                                : SlumberTheme.Colors.accent.opacity(Spec.activeFillOpacity)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: SlumberTheme.Radius.md, style: .continuous)
                                .stroke(
                                    Color.white.opacity(reduceTransparency ? Spec.activeStrokeOpacitySolid : Spec.activeStrokeOpacity),
                                    lineWidth: reduceTransparency ? SlumberTheme.Stroke.solid : SlumberTheme.Stroke.thin
                                )
                        )
                        .matchedGeometryEffect(id: "activeTabIndicator", in: animationNamespace)
                } else if isHovered {
                    RoundedRectangle(cornerRadius: SlumberTheme.Radius.md, style: .continuous)
                        .fill(Color.white.opacity(reduceTransparency ? Spec.hoverFillOpacitySolid : Spec.hoverFillOpacity))
                }
            }
            .contentShape(RoundedRectangle(cornerRadius: SlumberTheme.Radius.md, style: .continuous))
        }
        .buttonStyle(SlumberTactileButtonStyle(scaleDown: Spec.pressScale))
        .accessibilityLabel("\(title) tab")
        .accessibilityValue(active ? "Selected" : "Not selected")
        .onHover { hovering in
            withAnimation(SlumberTheme.Motion.hover) {
                isHovered = hovering
            }
        }
    }
}
