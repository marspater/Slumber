//
//  SlumbrCards.swift
//  Slumbr
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
            .padding(SlumbrTheme.Components.Card.padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(SlumbrTheme.Colors.cardBackground(reduceTransparency: reduceTransparency))
            .clipShape(RoundedRectangle(cornerRadius: SlumbrTheme.Radius.card, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: SlumbrTheme.Radius.card, style: .continuous)
                    .stroke(
                        SlumbrTheme.Colors.cardBorder(isHovered: isHovered, reduceTransparency: reduceTransparency),
                        lineWidth: reduceTransparency ? SlumbrTheme.Stroke.solid : SlumbrTheme.Stroke.thin
                    )
            }
            .onHover { hovering in
                withAnimation(SlumbrTheme.Motion.hover) {
                    isHovered = hovering
                }
            }
    }
}

// MARK: - Keycap Badge
public struct KeycapBadge: View {
    public let keys: [String]
    private typealias Spec = SlumbrTheme.Components.Keycap

    public init(keys: [String]) {
        self.keys = keys
    }

    public var body: some View {
        HStack(spacing: SlumbrTheme.Metrics.spaceXXS) {
            ForEach(keys, id: \.self) { key in
                Text(key)
            }
        }
        .font(SlumbrTheme.Typography.keycap)
        .foregroundStyle(SlumbrTheme.Colors.textPrimary)
        .padding(.horizontal, SlumbrTheme.Metrics.spaceSM)
        .padding(.vertical, Spec.verticalPadding)
        .background {
            RoundedRectangle(cornerRadius: SlumbrTheme.Radius.xs, style: .continuous)
                .fill(Color.white.opacity(Spec.fillOpacity))
        }
        .overlay {
            RoundedRectangle(cornerRadius: SlumbrTheme.Radius.xs, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [Color.white.opacity(Spec.strokeTopOpacity), Color.white.opacity(Spec.strokeBottomOpacity)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: SlumbrTheme.Stroke.thin
                )
        }
        .shadow(color: SlumbrTheme.Colors.shadow.opacity(Spec.shadowOpacity), radius: Spec.shadowRadius, y: Spec.shadowOffsetY)
    }
}

// MARK: - Error Banner
public struct ErrorBanner: View {
    public let reason: String
    public let onRetry: () -> Void
    public let onDismiss: () -> Void
    @State private var isDismissHovered = false
    @State private var isRetryHovered = false
    private typealias Spec = SlumbrTheme.Components.ErrorBanner
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
            Image(systemName: SlumbrTheme.Icons.warning)
                .font(SlumbrTheme.Icons.warningFont)
                .foregroundStyle(SlumbrTheme.Colors.amber)

            Text(reason)
                .font(SlumbrTheme.Typography.caption)
                .foregroundStyle(SlumbrTheme.Colors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()

            Button(action: onRetry) {
                Text("Retry")
                    .font(SlumbrTheme.Typography.caption.weight(.semibold))
                    .foregroundStyle(SlumbrTheme.Colors.textPrimary)
                    .padding(.horizontal, Spec.retryHorizontalPadding)
                    .padding(.vertical, Spec.retryVerticalPadding)
                    .background {
                        ZStack {
                            RoundedRectangle(cornerRadius: SlumbrTheme.Radius.sm, style: .continuous)
                                .fill(
                                    reduceTransparency
                                        ? SlumbrTheme.Colors.solidRetry
                                        : SlumbrTheme.Colors.amber.opacity(Spec.retryFillOpacity(isRetryHovered))
                                )
                            RoundedRectangle(cornerRadius: SlumbrTheme.Radius.sm, style: .continuous)
                                .stroke(
                                    Color.white.opacity(
                                        reduceTransparency
                                            ? Spec.retryStrokeOpacitySolid(isRetryHovered)
                                            : Spec.retryStrokeOpacity(isRetryHovered)
                                    ),
                                    lineWidth: SlumbrTheme.Stroke.thin
                                )
                        }
                    }
            }
            .buttonStyle(SlumbrTactileButtonStyle(scaleDown: Spec.retryPressScale))
            .accessibilityLabel("Retry put Mac to sleep")
            .onHover { hovering in
                withAnimation(SlumbrTheme.Motion.hoverQuick) {
                    isRetryHovered = hovering
                }
            }

            Button(action: onDismiss) {
                Image(systemName: SlumbrTheme.Icons.dismiss)
                    .font(SlumbrTheme.Icons.dismissFont)
                    .foregroundStyle(
                        isDismissHovered
                            ? SlumbrTheme.Colors.textPrimary
                            : SlumbrTheme.Colors.textPrimary.opacity(reduceTransparency ? Spec.dismissOpacitySolid : Spec.dismissOpacity)
                    )
                    .frame(width: Spec.dismissSize, height: Spec.dismissSize)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Dismiss error notification")
            .onHover { hovering in
                withAnimation(SlumbrTheme.Motion.hoverQuick) {
                    isDismissHovered = hovering
                }
            }
        }
        .padding(.horizontal, SlumbrTheme.Metrics.spaceMD)
        .padding(.vertical, Spec.verticalPadding)
        .background {
            ZStack {
                if reduceTransparency {
                    RoundedRectangle(cornerRadius: SlumbrTheme.Radius.lg, style: .continuous)
                        .fill(SlumbrTheme.Colors.solidErrorBanner)
                } else {
                    RoundedRectangle(cornerRadius: SlumbrTheme.Radius.lg, style: .continuous)
                        .fill(SlumbrTheme.Colors.shadow.opacity(Spec.scrimOpacity))
                    RoundedRectangle(cornerRadius: SlumbrTheme.Radius.lg, style: .continuous)
                        .fill(Color.white.opacity(Spec.glassOpacity))
                }
                RoundedRectangle(cornerRadius: SlumbrTheme.Radius.lg, style: .continuous)
                    .stroke(
                        SlumbrTheme.Colors.amber.opacity(reduceTransparency ? Spec.strokeOpacitySolid : Spec.strokeOpacity),
                        lineWidth: reduceTransparency ? SlumbrTheme.Stroke.solid : SlumbrTheme.Stroke.thin
                    )
            }
        }
        .shadow(color: SlumbrTheme.Colors.shadow.opacity(Spec.shadowOpacity), radius: Spec.shadowRadius, y: Spec.shadowOffsetY)
    }
}
