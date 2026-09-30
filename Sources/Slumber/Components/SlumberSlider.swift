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

    @State private var isDragging = false
    @State private var isHovered = false

    private let sliderWidth: CGFloat = SlumberTheme.Metrics.contentWidth
    private let thumbSize: CGFloat = SlumberTheme.Components.Slider.thumbSize
    private let trackHeight: CGFloat = SlumberTheme.Components.Slider.trackHeight
    private typealias Spec = SlumberTheme.Components.Slider

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
                .frame(width: sliderWidth, height: Spec.height)
                .contentShape(Rectangle())
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Sleep timer duration")
                .accessibilityValue("\(value) minutes")
                .accessibilityAdjustableAction { direction in
                    switch direction {
                    // Step along the 5-minute grid (1 → 5 → 10 …) rather than 1 → 6 → 11.
                    case .increment:
                        if value < bounds.upperBound {
                            value = min((value / 5 + 1) * 5, bounds.upperBound)
                            onEditingChanged(false)
                        }
                    case .decrement:
                        if value > bounds.lowerBound {
                            value = max((value - 1) / 5 * 5, bounds.lowerBound)
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
                .fill(Color.white.opacity(Spec.trackOpacity))
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
                    color: SlumberTheme.Colors.cyan.opacity(
                        isDragging ? Spec.fillGlowOpacity.drag : (isHovered ? Spec.fillGlowOpacity.hover : Spec.fillGlowOpacity.rest)
                    ),
                    radius: isDragging ? Spec.fillGlowRadius.drag : Spec.fillGlowRadius.rest
                )

            // Thumb
            RoundedRectangle(cornerRadius: thumbSize / 2.0, style: .continuous)
                .fill(Color.white)
                .frame(width: thumbSize, height: thumbSize)
                .overlay(
                    RoundedRectangle(cornerRadius: thumbSize / 2.0, style: .continuous)
                        .stroke(Color.white.opacity(Spec.thumbStrokeOpacity), lineWidth: SlumberTheme.Stroke.hairline)
                )
                .shadow(color: SlumberTheme.Colors.shadow.opacity(Spec.thumbShadowOpacity), radius: Spec.thumbShadowRadius, x: 0, y: Spec.thumbShadowOffsetY)
                .shadow(
                    color: SlumberTheme.Colors.accent.opacity(Spec.thumbGlowOpacity),
                    radius: isDragging ? Spec.thumbGlowRadius.drag : Spec.thumbGlowRadius.rest
                )
                .scaleEffect(isDragging ? Spec.thumbScale.drag : (isHovered ? Spec.thumbScale.hover : Spec.thumbScale.rest))
                .offset(x: thumbOffset)
        }
        .frame(width: sliderWidth, height: Spec.height)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { gesture in
                    if !isDragging {
                        withAnimation(SlumberTheme.Motion.drag) {
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
                    withAnimation(SlumberTheme.Motion.drag) {
                        isDragging = false
                    }
                    onEditingChanged(false)
                }
        )
        .onHover { hovering in
            withAnimation(SlumberTheme.Motion.hoverSlider) {
                isHovered = hovering
            }
        }
    }
}
