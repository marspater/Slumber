//
//  SlumbrPresetChip.swift
//  Slumbr
//
//  Standardized preset time chips pixel-aligned to the 272pt layout grid.
//

import SwiftUI

public struct PresetChip: View {
    public let label: String
    public let value: Int
    @Binding public var selectedMinutes: Int
    public let isSliding: Bool
    @State private var isHovered = false
    private let accent = SlumbrTheme.Colors.accent
    private typealias Spec = SlumbrTheme.Components.Chip
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    public init(
        label: String,
        value: Int,
        selectedMinutes: Binding<Int>,
        isSliding: Bool = false
    ) {
        self.label = label
        self.value = value
        self._selectedMinutes = selectedMinutes
        self.isSliding = isSliding
    }

    private var isSelected: Bool {
        !isSliding && selectedMinutes == value
    }

    private var fillColor: Color {
        if isSelected {
            return reduceTransparency ? SlumbrTheme.Colors.solidChipSelected : accent.opacity(Spec.selectedFillOpacity)
        }
        return Color.white.opacity(reduceTransparency ? Spec.fillOpacitySolid(isHovered) : Spec.fillOpacity(isHovered))
    }

    public var body: some View {
        let selected = isSelected
        Button {
            if !selected { playSound("space_button") }
            withAnimation(SlumbrTheme.Motion.select) {
                selectedMinutes = value
            }
        } label: {
            Text(label)
                .font(SlumbrTheme.Typography.caption.weight(selected ? .semibold : .medium))
                .frame(width: Spec.size.width, height: Spec.size.height)
                .background {
                    ZStack {
                        RoundedRectangle(cornerRadius: SlumbrTheme.Radius.md, style: .continuous)
                            .fill(fillColor)

                        VStack {
                            RoundedRectangle(cornerRadius: SlumbrTheme.Radius.md, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.white.opacity(Spec.glossOpacity), Color.clear],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(height: Spec.glossHeight)
                            Spacer()
                        }
                        .clipShape(RoundedRectangle(cornerRadius: SlumbrTheme.Radius.md, style: .continuous))
                        .opacity(selected && !reduceTransparency ? 1.0 : 0.0)
                    }
                }
                .foregroundStyle(
                    selected || isHovered
                        ? SlumbrTheme.Colors.textPrimary
                        : SlumbrTheme.Colors.textSecondary
                )
                .overlay {
                    if reduceTransparency {
                        RoundedRectangle(cornerRadius: SlumbrTheme.Radius.md, style: .continuous)
                            .stroke(
                                Color.white.opacity(selected ? Spec.selectedStrokeOpacitySolid : Spec.strokeOpacitySolid),
                                lineWidth: SlumbrTheme.Stroke.solid
                            )
                    } else {
                        RoundedRectangle(cornerRadius: SlumbrTheme.Radius.md, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(selected ? Spec.selectedStrokeOpacity : Spec.strokeOpacity(isHovered)),
                                        Color.white.opacity(Spec.strokeFadeOpacity)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: SlumbrTheme.Stroke.thin
                            )
                    }
                }
                .shadow(color: selected ? accent.opacity(Spec.glowOpacity) : .clear, radius: Spec.glowRadius)
                .animation(SlumbrTheme.Motion.selectFade, value: selected)
        }
        .buttonStyle(SlumbrTactileButtonStyle(scaleDown: Spec.pressScale))
        .accessibilityLabel("\(value) minutes preset")
        .accessibilityValue(selected ? "Selected" : "Not selected")
        .onHover { hovering in
            withAnimation(SlumbrTheme.Motion.hover) {
                isHovered = hovering
            }
        }
    }
}
