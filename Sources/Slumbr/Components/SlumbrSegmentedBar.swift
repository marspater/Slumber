//
//  SlumbrSegmentedBar.swift
//  Slumbr
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
    private typealias Spec = SlumbrTheme.Components.Tab
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
            withAnimation(SlumbrTheme.Motion.tabSwitch) {
                currentTab = tag
            }
        } label: {
            HStack(spacing: Spec.iconSpacing) {
                Image(systemName: icon)
                    .font(SlumbrTheme.Icons.tabFont)
                // Reserve the bold width so the bar doesn't reflow when the weight changes.
                Text(title)
                    .font(SlumbrTheme.Typography.title.weight(.bold))
                    .hidden()
                    .overlay {
                        Text(title)
                            .font(SlumbrTheme.Typography.title.weight(active ? .bold : .medium))
                    }
            }
            .foregroundColor(
                active || isHovered
                    ? SlumbrTheme.Colors.textPrimary
                    : SlumbrTheme.Colors.textSecondary
            )
            .padding(.vertical, Spec.verticalPadding)
            .padding(.horizontal, Spec.horizontalPadding)
            .background {
                if active {
                    RoundedRectangle(cornerRadius: SlumbrTheme.Radius.md, style: .continuous)
                        .fill(
                            reduceTransparency
                                ? SlumbrTheme.Colors.solidTabActive
                                : SlumbrTheme.Colors.accent.opacity(Spec.activeFillOpacity)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: SlumbrTheme.Radius.md, style: .continuous)
                                .stroke(
                                    Color.white.opacity(reduceTransparency ? Spec.activeStrokeOpacitySolid : Spec.activeStrokeOpacity),
                                    lineWidth: reduceTransparency ? SlumbrTheme.Stroke.solid : SlumbrTheme.Stroke.thin
                                )
                        )
                        .matchedGeometryEffect(id: "activeTabIndicator", in: animationNamespace)
                } else if isHovered {
                    RoundedRectangle(cornerRadius: SlumbrTheme.Radius.md, style: .continuous)
                        .fill(Color.white.opacity(reduceTransparency ? Spec.hoverFillOpacitySolid : Spec.hoverFillOpacity))
                }
            }
            .contentShape(RoundedRectangle(cornerRadius: SlumbrTheme.Radius.md, style: .continuous))
        }
        .buttonStyle(SlumbrTactileButtonStyle(scaleDown: Spec.pressScale))
        .accessibilityLabel("\(title) tab")
        .accessibilityValue(active ? "Selected" : "Not selected")
        .onHover { hovering in
            withAnimation(SlumbrTheme.Motion.hover) {
                isHovered = hovering
            }
        }
    }
}
