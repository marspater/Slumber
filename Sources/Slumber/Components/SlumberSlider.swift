//
//  SlumberSlider.swift
//  Slumber
//
//  Accessible, wide-gamut glowing slider aligned to standard 272pt content grid.
//

import SwiftUI

public struct GlowingSlider: View {
    @Binding public var value: Int
    public let bounds: ClosedRange<Int>
    public let onEditingChanged: (Bool) -> Void
    @Environment(\.colorScheme) var colorScheme
    private var chrome: Color { colorScheme == .dark ? .white : .black }

    @State private var isDragging = false
    @State private var isHovered = false

    private let sliderWidth: CGFloat = SlumberTheme.Metrics.contentWidth
    private let thumbSize: CGFloat = 16.0
    private let trackHeight: CGFloat = 7.0

    public init(
        value: Binding<Int>,
        bounds: ClosedRange<Int> = 1...120,
        onEditingChanged: @escaping (Bool) -> Void = { _ in }
    ) {
        self._value = value
        self.bounds = bounds
        self.onEditingChanged = onEditingChanged
    }

    public var body: some View {
        ZStack {
            // 1. Visual & Interactive Slider (Hidden from accessibility system chrome)
            sliderVisuals
                .accessibilityHidden(true)

            // 2. Decoupled Accessibility Control Layer for Assistive Technologies
            Color.clear
                .frame(width: sliderWidth, height: 28)
                .contentShape(Rectangle())
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Sleep timer duration")
                .accessibilityValue("\(value) minutes")
                .accessibilityAdjustableAction { direction in
                    switch direction {
                    case .increment:
                        if value < bounds.upperBound {
                            value = min(value + 5, bounds.upperBound)
                            onEditingChanged(false)
                        }
                    case .decrement:
                        if value > bounds.lowerBound {
                            value = max(value - 5, bounds.lowerBound)
                            onEditingChanged(false)
                        }
                    @unknown default:
                        break
                    }
                }
                .allowsHitTesting(false)
        }
        .focusable(false)
        .focusEffectDisabled()
    }

    private var sliderVisuals: some View {
        let totalRange = Double(bounds.upperBound - bounds.lowerBound)
        let percentage = totalRange > 0 ? max(0, min(1.0, CGFloat(Double(value - bounds.lowerBound) / totalRange))) : 0
        let trackTravel: CGFloat = sliderWidth - thumbSize
        let thumbOffset = percentage * trackTravel
        let trackFillWidth = max(0, min(sliderWidth, thumbOffset + (thumbSize / 2.0)))

        return ZStack(alignment: .leading) {
            // Background Track
            RoundedRectangle(cornerRadius: trackHeight / 2.0, style: .continuous)
                .fill(chrome.opacity(0.10))
                .frame(width: sliderWidth, height: trackHeight)

            // Filled Track with Wide-gamut Glow
            RoundedRectangle(cornerRadius: trackHeight / 2.0, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            SlumberTheme.Colors.accent,
                            SlumberTheme.Colors.cyan
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: trackFillWidth, height: trackHeight)
                .shadow(
                    color: SlumberTheme.Colors.cyan.opacity(isDragging ? 0.6 : (isHovered ? 0.4 : 0.2)),
                    radius: isDragging ? 8 : 4
                )

            // Thumb
            RoundedRectangle(cornerRadius: thumbSize / 2.0, style: .continuous)
                .fill(Color.white)
                .frame(width: thumbSize, height: thumbSize)
                .overlay(
                    RoundedRectangle(cornerRadius: thumbSize / 2.0, style: .continuous)
                        .stroke(Color.white.opacity(0.85), lineWidth: 0.5)
                )
                .shadow(color: Color.black.opacity(0.35), radius: 2.5, x: 0, y: 1)
                .shadow(
                    color: SlumberTheme.Colors.accent.opacity(0.45),
                    radius: isDragging ? 8 : 5
                )
                .scaleEffect(isDragging ? 1.25 : (isHovered ? 1.12 : 1.0))
                .offset(x: thumbOffset)
        }
        .frame(width: sliderWidth, height: 28)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { gesture in
                    if !isDragging {
                        withAnimation(.spring(response: 0.15, dampingFraction: 0.8)) {
                            isDragging = true
                        }
                        onEditingChanged(true)
                    }
                    let halfThumb = thumbSize / 2.0
                    let clampedX = max(halfThumb, min(sliderWidth - halfThumb, gesture.location.x))
                    let fraction = Double((clampedX - halfThumb) / trackTravel)
                    let rawVal = Double(bounds.lowerBound) + fraction * totalRange
                    let computed = Int(round(rawVal))
                    value = min(max(computed, bounds.lowerBound), bounds.upperBound)
                }
                .onEnded { _ in
                    withAnimation(.spring(response: 0.15, dampingFraction: 0.8)) {
                        isDragging = false
                    }
                    onEditingChanged(false)
                }
        )
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }
}
