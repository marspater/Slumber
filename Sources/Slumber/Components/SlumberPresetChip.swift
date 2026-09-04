//
//  SlumberPresetChip.swift
//  Slumber
//
//  Standardized preset time chips pixel-aligned to the 272pt layout grid.
//

import SwiftUI

public struct PresetChip: View {
    public let label: String
    public let value: Int
    @Binding public var selectedMinutes: Int
    public let isSliding: Bool
    public let accent: Color
    @State private var isHovered = false
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    public init(
        label: String,
        value: Int,
        selectedMinutes: Binding<Int>,
        isSliding: Bool = false,
        accent: Color = SlumberTheme.Colors.accent
    ) {
        self.label = label
        self.value = value
        self._selectedMinutes = selectedMinutes
        self.isSliding = isSliding
        self.accent = accent
    }

    private var isSelected: Bool {
        !isSliding && selectedMinutes == value
    }

    public var body: some View {
        let selected = isSelected
        Button {
            if !selected { playSound("space_button") }
            withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                selectedMinutes = value
            }
        } label: {
            Text(label)
                .font(SlumberTheme.Typography.caption.weight(selected ? .semibold : .medium))
                .frame(width: 48, height: 32)
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: SlumberTheme.Radius.md, style: .continuous)
                            .fill(
                                selected
                                    ? (reduceTransparency ? Color(red: 0.38, green: 0.32, blue: 0.55) : accent.opacity(0.34))
                                    : (isHovered
                                        ? (reduceTransparency ? Color.white.opacity(0.18) : Color.white.opacity(0.10))
                                        : (reduceTransparency ? Color.white.opacity(0.12) : Color.white.opacity(0.065)))
                            )

                        VStack {
                            RoundedRectangle(cornerRadius: SlumberTheme.Radius.md, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.white.opacity(0.22), Color.clear],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(height: 10)
                            Spacer()
                        }
                        .clipShape(RoundedRectangle(cornerRadius: SlumberTheme.Radius.md, style: .continuous))
                        .opacity(selected && !reduceTransparency ? 1.0 : 0.0)
                    }
                )
                .foregroundColor(
                    selected
                        ? SlumberTheme.Colors.textPrimary
                        : (isHovered ? SlumberTheme.Colors.textPrimary : SlumberTheme.Colors.textSecondary)
                )
                .overlay {
                    if reduceTransparency {
                        RoundedRectangle(cornerRadius: SlumberTheme.Radius.md, style: .continuous)
                            .stroke(
                                selected ? Color.white.opacity(0.6) : Color.white.opacity(0.25),
                                lineWidth: 1.0
                            )
                    } else {
                        RoundedRectangle(cornerRadius: SlumberTheme.Radius.md, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(selected ? 0.38 : (isHovered ? 0.20 : 0.10)),
                                        Color.white.opacity(0.03)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 0.75
                            )
                    }
                }
                .shadow(color: selected ? accent.opacity(0.25) : .clear, radius: 6)
                .animation(.easeInOut(duration: 0.2), value: selected)
        }
        .buttonStyle(SlumberTactileButtonStyle(scaleDown: 0.95))
        .accessibilityLabel("\(value) minutes preset")
        .accessibilityValue(selected ? "Selected" : "Not selected")
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.18)) {
                isHovered = hovering
            }
        }
    }
}
