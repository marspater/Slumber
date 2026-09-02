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
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(SlumberTheme.Colors.cardBackground(reduceTransparency: reduceTransparency))
            .clipShape(RoundedRectangle(cornerRadius: SlumberTheme.Radius.card, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: SlumberTheme.Radius.card, style: .continuous)
                    .stroke(
                        SlumberTheme.Colors.cardBorder(isHovered: isHovered, reduceTransparency: reduceTransparency),
                        lineWidth: reduceTransparency ? 1.0 : 0.75
                    )
            )
            .onHover { hovering in
                withAnimation(.easeOut(duration: 0.18)) {
                    isHovered = hovering
                }
            }
    }
}

// MARK: - Keycap Badge
public struct KeycapBadge: View {
    public let keys: [String]

    public init(keys: [String] = ["⌃", "⌥", "S"]) {
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
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(
            RoundedRectangle(cornerRadius: SlumberTheme.Radius.sm - 2, style: .continuous)
                .fill(Color.white.opacity(0.10))
        )
        .overlay(
            RoundedRectangle(cornerRadius: SlumberTheme.Radius.sm - 2, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [Color.white.opacity(0.30), Color.white.opacity(0.08)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.75
                )
        )
        .shadow(color: Color.black.opacity(0.2), radius: 2, y: 1)
    }
}

// MARK: - Error Banner
public struct ErrorBanner: View {
    public let reason: String
    public let onRetry: () -> Void
    public let onDismiss: () -> Void
    @State private var isDismissHovered = false
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
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(SlumberTheme.Colors.amber)

            Text(reason)
                .font(SlumberTheme.Typography.caption)
                .foregroundColor(SlumberTheme.Colors.textPrimary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()

            Button(action: onRetry) {
                Text("Retry")
                    .font(SlumberTheme.Typography.caption.weight(.semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        ZStack {
                            RoundedRectangle(cornerRadius: SlumberTheme.Radius.sm, style: .continuous)
                                .fill(
                                    reduceTransparency
                                        ? Color(red: 0.35, green: 0.20, blue: 0.12)
                                        : SlumberTheme.Colors.amber.opacity(0.35)
                                )
                            RoundedRectangle(cornerRadius: SlumberTheme.Radius.sm, style: .continuous)
                                .stroke(
                                    Color.white.opacity(reduceTransparency ? 0.45 : 0.25),
                                    lineWidth: 0.75
                                )
                        }
                    )
            }
            .buttonStyle(SlumberTactileButtonStyle(scaleDown: 0.96))
            .accessibilityLabel("Retry put Mac to sleep")

            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 15))
                    .foregroundColor(
                        isDismissHovered
                            ? Color.white
                            : Color.white.opacity(reduceTransparency ? 0.75 : 0.45)
                    )
                    .frame(width: 24, height: 24)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Dismiss error notification")
            .onHover { hovering in
                withAnimation(.easeOut(duration: 0.15)) {
                    isDismissHovered = hovering
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(
            ZStack {
                if reduceTransparency {
                    RoundedRectangle(cornerRadius: SlumberTheme.Radius.lg, style: .continuous)
                        .fill(Color(red: 0.16, green: 0.10, blue: 0.09))
                } else {
                    RoundedRectangle(cornerRadius: SlumberTheme.Radius.lg, style: .continuous)
                        .fill(Color.black.opacity(0.45))
                    RoundedRectangle(cornerRadius: SlumberTheme.Radius.lg, style: .continuous)
                        .fill(Color.white.opacity(0.06))
                }
                RoundedRectangle(cornerRadius: SlumberTheme.Radius.lg, style: .continuous)
                    .stroke(
                        SlumberTheme.Colors.amber.opacity(reduceTransparency ? 0.7 : 0.4),
                        lineWidth: reduceTransparency ? 1.0 : 0.75
                    )
            }
        )
        .shadow(color: Color.black.opacity(0.35), radius: 10, y: 4)
    }
}
