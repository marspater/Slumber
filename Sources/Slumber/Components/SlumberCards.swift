//
//  SlumberCards.swift
//  Slumber
//
//  Settings cards, shortcut keycap badges, and accessible error banners.
//

import SwiftUI

// MARK: - Settings Card
public struct SettingsCard<Content: View>: View {
    private let content: Content
    @State private var isHovered = false
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        content
            .padding(SlumberTheme.Components.Card.padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(SlumberTheme.Colors.cardBackground(reduceTransparency: reduceTransparency))
            .clipShape(RoundedRectangle(cornerRadius: SlumberTheme.Radius.card, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: SlumberTheme.Radius.card, style: .continuous)
                    .stroke(
                        SlumberTheme.Colors.cardBorder(isHovered: isHovered, reduceTransparency: reduceTransparency),
                        lineWidth: reduceTransparency ? SlumberTheme.Stroke.solid : SlumberTheme.Stroke.thin
                    )
            )
            .onHover { hovering in
                withAnimation(SlumberTheme.Motion.hover) {
                    isHovered = hovering
                }
            }
    }
}

// MARK: - Keycap Badge
public struct KeycapBadge: View {
    public let keys: [String]
    private typealias Spec = SlumberTheme.Components.Keycap

    public init(keys: [String]) {
        self.keys = keys
    }

    public var body: some View {
        HStack(spacing: SlumberTheme.Metrics.spaceXXS) {
            ForEach(keys, id: \.self) { key in
                Text(key)
            }
        }
        .font(SlumberTheme.Typography.keycap)
        .foregroundColor(SlumberTheme.Colors.textPrimary)
        .padding(.horizontal, SlumberTheme.Metrics.spaceSM)
        .padding(.vertical, Spec.verticalPadding)
        .background(
            RoundedRectangle(cornerRadius: SlumberTheme.Radius.xs, style: .continuous)
                .fill(Color.white.opacity(Spec.fillOpacity))
        )
        .overlay(
            RoundedRectangle(cornerRadius: SlumberTheme.Radius.xs, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [Color.white.opacity(Spec.strokeTopOpacity), Color.white.opacity(Spec.strokeBottomOpacity)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: SlumberTheme.Stroke.thin
                )
        )
        .shadow(color: SlumberTheme.Colors.shadow.opacity(Spec.shadowOpacity), radius: Spec.shadowRadius, y: Spec.shadowOffsetY)
    }
}

// MARK: - Error Banner
public struct ErrorBanner: View {
    public let reason: String
    public let onRetry: () -> Void
    public let onDismiss: () -> Void
    @State private var isDismissHovered = false
    @State private var isRetryHovered = false
    private typealias Spec = SlumberTheme.Components.ErrorBanner
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    public init(
        reason: String,
        onRetry: @escaping () -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.reason = reason
        self.onRetry = onRetry
        self.onDismiss = onDismiss
    }

    public var body: some View {
        HStack(spacing: Spec.spacing) {
            Image(systemName: SlumberTheme.Icons.warning)
                .font(SlumberTheme.Icons.warningFont)
                .foregroundColor(SlumberTheme.Colors.amber)

            Text(reason)
                .font(SlumberTheme.Typography.caption)
                .foregroundColor(SlumberTheme.Colors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()

            Button(action: onRetry) {
                Text("Retry")
                    .font(SlumberTheme.Typography.caption.weight(.semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, Spec.retryHorizontalPadding)
                    .padding(.vertical, Spec.retryVerticalPadding)
                    .background(
                        ZStack {
                            RoundedRectangle(cornerRadius: SlumberTheme.Radius.sm, style: .continuous)
                                .fill(
                                    reduceTransparency
                                        ? SlumberTheme.Colors.solidRetry
                                        : SlumberTheme.Colors.amber.opacity(Spec.retryFillOpacity(isRetryHovered))
                                )
                            RoundedRectangle(cornerRadius: SlumberTheme.Radius.sm, style: .continuous)
                                .stroke(
                                    Color.white.opacity(
                                        reduceTransparency
                                            ? Spec.retryStrokeOpacitySolid(isRetryHovered)
                                            : Spec.retryStrokeOpacity(isRetryHovered)
                                    ),
                                    lineWidth: SlumberTheme.Stroke.thin
                                )
                        }
                    )
            }
            .buttonStyle(SlumberTactileButtonStyle(scaleDown: Spec.retryPressScale))
            .accessibilityLabel("Retry put Mac to sleep")
            .onHover { hovering in
                withAnimation(SlumberTheme.Motion.hoverQuick) {
                    isRetryHovered = hovering
                }
            }

            Button(action: onDismiss) {
                Image(systemName: SlumberTheme.Icons.dismiss)
                    .font(SlumberTheme.Icons.dismissFont)
                    .foregroundColor(
                        isDismissHovered
                            ? Color.white
                            : Color.white.opacity(reduceTransparency ? Spec.dismissOpacitySolid : Spec.dismissOpacity)
                    )
                    .frame(width: Spec.dismissSize, height: Spec.dismissSize)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Dismiss error notification")
            .onHover { hovering in
                withAnimation(SlumberTheme.Motion.hoverQuick) {
                    isDismissHovered = hovering
                }
            }
        }
        .padding(.horizontal, SlumberTheme.Metrics.spaceMD)
        .padding(.vertical, Spec.verticalPadding)
        .background(
            ZStack {
                if reduceTransparency {
                    RoundedRectangle(cornerRadius: SlumberTheme.Radius.lg, style: .continuous)
                        .fill(SlumberTheme.Colors.solidErrorBanner)
                } else {
                    RoundedRectangle(cornerRadius: SlumberTheme.Radius.lg, style: .continuous)
                        .fill(SlumberTheme.Colors.shadow.opacity(Spec.scrimOpacity))
                    RoundedRectangle(cornerRadius: SlumberTheme.Radius.lg, style: .continuous)
                        .fill(Color.white.opacity(Spec.glassOpacity))
                }
                RoundedRectangle(cornerRadius: SlumberTheme.Radius.lg, style: .continuous)
                    .stroke(
                        SlumberTheme.Colors.amber.opacity(reduceTransparency ? Spec.strokeOpacitySolid : Spec.strokeOpacity),
                        lineWidth: reduceTransparency ? SlumberTheme.Stroke.solid : SlumberTheme.Stroke.thin
                    )
            }
        )
        .shadow(color: SlumberTheme.Colors.shadow.opacity(Spec.shadowOpacity), radius: Spec.shadowRadius, y: Spec.shadowOffsetY)
    }
}
