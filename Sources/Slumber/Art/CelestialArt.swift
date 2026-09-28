//
//  CelestialArt.swift
//  Slumber
//
//  Display P3 + EDR celestial artwork: moon, clouds, stars, fireflies, constellations, auroras.
//

import SwiftUI
import AppKit

// MARK: - Shapes
public struct SparkleStarShape: Shape {
    public func path(in rect: CGRect) -> Path {
        var path = Path()
        let cx = rect.midX
        let cy = rect.midY
        path.move(to: CGPoint(x: cx, y: rect.minY))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: cy), control: CGPoint(x: cx, y: cy))
        path.addQuadCurve(to: CGPoint(x: cx, y: rect.maxY), control: CGPoint(x: cx, y: cy))
        path.addQuadCurve(to: CGPoint(x: rect.minX, y: cy), control: CGPoint(x: cx, y: cy))
        path.addQuadCurve(to: CGPoint(x: cx, y: rect.minY), control: CGPoint(x: cx, y: cy))
        path.closeSubpath()
        return path
    }
}

// MARK: - Twinkling Star Field
public struct StarField: View {
    public let count: Int

    public init(count: Int) {
        self.count = count
    }

    public var body: some View {
        GeometryReader { geo in
            ForEach(0..<count, id: \.self) { i in
                TwinklingStar(
                    position: CGPoint(
                        x: seededRandom(seed: i * 3, max: geo.size.width),
                        y: seededRandom(seed: i * 7 + 1, max: geo.size.height)
                    ),
                    size: seededRandom(seed: i * 5 + 2, max: 2.2) + 0.5,
                    delay: Double(i % 10) * 0.3,
                    isSparkle: i % 8 == 0
                )
            }
        }
    }

    private func seededRandom(seed: Int, max: CGFloat) -> CGFloat {
        CGFloat(abs(sin(Double(seed) * 12.9898 + 78.233) * 43758.5453)
            .truncatingRemainder(dividingBy: 1.0)) * max
    }
}

public struct TwinklingStar: View {
    public let position: CGPoint
    public let size: CGFloat
    public let delay: Double
    public let isSparkle: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var on = false

    public var body: some View {
        Group {
            if isSparkle {
                SparkleStarShape()
                    .fill(Color.white)
                    .frame(width: size * 2.2, height: size * 2.2)
            } else {
                Circle()
                    .fill(Color.white)
                    .frame(width: size, height: size)
            }
        }
        .shadow(
            color: Color.p3(h: 0.75, s: 0.25, b: 1.0, a: on ? 0.35 : 0, level: isSparkle ? .rimHighlight : .sdr),
            radius: on ? (isSparkle ? 4 : 2) : 0
        )
        .opacity(on ? 0.75 : 0.12)
        .position(position)
        .onAppear {
            // Static but visible stars when motion is reduced (instead of the dim 0.12 rest state).
            guard !reduceMotion else { on = true; return }
            withAnimation(
                .easeInOut(duration: Double.random(in: 1.8...3.8))
                .repeatForever(autoreverses: true)
                .delay(delay)
            ) { on = true }
        }
    }
}

// MARK: - Shooting Star
public struct ShootingStar: View {
    public let angle: Double
    public let cycleDuration: Double
    public let initialDelay: Double
    public let length: CGFloat
    public let startX: CGFloat
    public let startY: CGFloat

    public init(
        angle: Double,
        cycleDuration: Double,
        initialDelay: Double,
        length: CGFloat,
        startX: CGFloat,
        startY: CGFloat
    ) {
        self.angle = angle
        self.cycleDuration = cycleDuration
        self.initialDelay = initialDelay
        self.length = length
        self.startX = startX
        self.startY = startY
    }

    public var body: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let adjusted = t - initialDelay
            let progress = adjusted > 0
                ? (adjusted.truncatingRemainder(dividingBy: cycleDuration)) / cycleDuration
                : -1

            let rad = angle * .pi / 180
            let travel: CGFloat = 280

            if progress >= 0 {
                let headPhase = max(0.0, 1.0 - progress * 2.0)
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.p3(h: 0.75, s: 0.25, b: 0.95, a: 0, level: .subtleHighlight),
                                Color.p3(
                                    h: 0.72, s: 0.15, b: 1.0, a: 0.85,
                                    headroomBetween: .subtleHighlight,
                                    and: .effect,
                                    phase: headPhase
                                )
                            ],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    .frame(width: length * 0.85, height: 1.0)
                    .blur(radius: 0.3)
                    .shadow(
                        color: Color.p3(
                            h: 0.72, s: 0.15, b: 1.0, a: 0.45,
                            headroomBetween: .subtleHighlight,
                            and: .effect,
                            phase: headPhase
                        ),
                        radius: 3.5
                    )
                    .rotationEffect(.degrees(angle))
                    .position(
                        x: startX + cos(rad) * travel * CGFloat(progress),
                        y: startY + sin(rad) * travel * CGFloat(progress)
                    )
                    .opacity(progress < 0.2 ? progress * 5.0 : (1.0 - progress) * 1.25)
            }
        }
    }
}

// MARK: - Firefly Particles
public struct FireflyField: View {
    public let count: Int

    public init(count: Int) {
        self.count = count
    }

    public var body: some View {
        GeometryReader { geo in
            ForEach(0..<count, id: \.self) { i in
                Firefly(seed: i, bounds: geo.size)
            }
        }
    }
}

public struct Firefly: View {
    public let seed: Int
    public let bounds: CGSize

    private var hue: Double {
        switch seed % 3 {
        case 0: return 0.08
        case 1: return 0.75
        default: return 0.52
        }
    }

    private var baseRGB: (Double, Double, Double) {
        switch seed % 3 {
        case 0: return (1.0, 0.85, 0.25)
        case 1: return (0.85, 0.55, 0.95)
        default: return (0.35, 0.85, 0.95)
        }
    }

    private var baseX: CGFloat { seededRandom(seed: seed * 3, max: bounds.width * 0.8) + bounds.width * 0.1 }
    private var baseY: CGFloat { seededRandom(seed: seed * 7, max: bounds.height * 0.6) + bounds.height * 0.2 }
    private var driftDX: CGFloat { seededRandom(seed: seed * 11, max: 30) - 15 }
    private var driftDY: CGFloat { seededRandom(seed: seed * 13, max: 20) - 10 }

    public var body: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let period = Double(4 + (seed % 3))
            let phaseOffset = Double(seed) * 1.2
            let phaseInfo = computePhase(t: t, period: period, offset: phaseOffset)

            let rgb = baseRGB
            let glowColor = Color.p3(
                r: rgb.0, g: rgb.1, b: rgb.2, a: 0.85,
                headroomBetween: .visibleGlow,
                and: .effect,
                phase: phaseInfo.normPhase
            )
            let dotColor = Color.p3(h: hue, s: 0.5, b: 1.0, level: .rimHighlight)
            let currentX: CGFloat = baseX + driftDX * CGFloat(phaseInfo.cycle)
            let currentY: CGFloat = baseY + driftDY * CGFloat(phaseInfo.cosTerm)
            let glowRadius: CGFloat = 2.0 + 6.0 * CGFloat(phaseInfo.normPhase)
            let currentOpacity: Double = 0.15 + 0.55 * phaseInfo.normPhase

            Circle()
                .fill(dotColor)
                .frame(width: 2.5, height: 2.5)
                .shadow(color: glowColor, radius: glowRadius)
                .opacity(currentOpacity)
                .position(x: currentX, y: currentY)
        }
    }

    private func computePhase(t: Double, period: Double, offset: Double) -> (cycle: Double, cosTerm: Double, normPhase: Double) {
        let cycle = sin((t + offset) * (2.0 * .pi / period))
        let cosVal = cos((t + offset * 0.7) * (2.0 * .pi / (period * 1.3)))
        let norm = (cycle + 1.0) / 2.0
        return (cycle, cosVal, norm)
    }

    private func seededRandom(seed: Int, max: CGFloat) -> CGFloat {
        CGFloat(abs(sin(Double(seed) * 12.9898 + 78.233) * 43758.5453)
            .truncatingRemainder(dividingBy: 1.0)) * max
    }
}

// MARK: - Constellation Overlay
public struct ConstellationOverlay: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var rotation: Double = 0

    public init() {}

    public var body: some View {
        ZStack {
            ConstellationPattern(stars: [CGPoint(x: 0.38, y: 0.18), CGPoint(x: 0.34, y: 0.28), CGPoint(x: 0.38, y: 0.30), CGPoint(x: 0.42, y: 0.29), CGPoint(x: 0.47, y: 0.17), CGPoint(x: 0.33, y: 0.40), CGPoint(x: 0.48, y: 0.38)], lines: [(0,1),(1,2),(2,3),(3,4),(1,5),(3,6)])
            ConstellationPattern(stars: [CGPoint(x: 0.62, y: 0.55), CGPoint(x: 0.67, y: 0.52), CGPoint(x: 0.72, y: 0.54), CGPoint(x: 0.75, y: 0.58), CGPoint(x: 0.77, y: 0.64), CGPoint(x: 0.82, y: 0.62), CGPoint(x: 0.84, y: 0.66)], lines: [(0,1),(1,2),(2,3),(3,4),(4,5),(5,6),(6,3)])
            ConstellationPattern(stars: [CGPoint(x: 0.12, y: 0.62), CGPoint(x: 0.17, y: 0.56), CGPoint(x: 0.22, y: 0.62), CGPoint(x: 0.27, y: 0.56), CGPoint(x: 0.32, y: 0.62)], lines: [(0,1),(1,2),(2,3),(3,4)])
        }
        .opacity(0.3)
        .rotationEffect(.degrees(rotation))
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.linear(duration: 180).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
    }
}

public struct ConstellationLinesShape: Shape {
    public let stars: [CGPoint]
    public let lines: [(Int, Int)]

    public func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        for line in lines {
            let from = stars[line.0]
            let to = stars[line.1]
            path.move(to: CGPoint(x: from.x * w, y: from.y * h))
            path.addLine(to: CGPoint(x: to.x * w, y: to.y * h))
        }
        return path
    }
}

public struct ConstellationPattern: View {
    public let stars: [CGPoint]
    public let lines: [(Int, Int)]
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pulse = false

    public var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            ZStack {
                ConstellationLinesShape(stars: stars, lines: lines)
                    .stroke(Color.white.opacity(pulse ? 0.09 : 0.04), lineWidth: 0.6)

                ForEach(0..<stars.count, id: \.self) { i in
                    Circle()
                        .fill(Color.white.opacity(pulse ? 0.30 : 0.15))
                        .frame(width: 2.5, height: 2.5)
                        .shadow(color: Color.p3(h: 0.75, s: 0.3, b: 1.0, a: pulse ? 0.35 : 0.1, level: .subtleHighlight), radius: pulse ? 3 : 1)
                        .position(x: stars[i].x * w, y: stars[i].y * h)
                }
            }
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.easeInOut(duration: 4.0).repeatForever(autoreverses: true).delay(Double(stars.count % 3) * 0.5)) {
                    pulse = true
                }
            }
        }
    }
}

// MARK: - Cute Moon
public struct CuteMoon: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var bob = false
    @State private var glow = false

    private let face = Color.p3(0.36, 0.26, 0.58)
    private let cloth = Color.p3(0.98, 0.97, 1.0, level: .subtleHighlight)

    public init() {}

    public var body: some View {
        let box = MoonArt.box
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.p3(h: 0.75, s: 0.4, b: 1.0, a: 0.3, level: .visibleGlow), .clear],
                        center: .center, startRadius: 10, endRadius: 40
                    )
                )
                .frame(width: 80, height: 80)
                .scaleEffect(glow ? 1.15 : 1.0)

            ZStack {
                MoonArt.crescent.fill(LinearGradient(
                    Gradient(stops: [
                        .init(color: .p3(0.88, 0.82, 1.0, level: .strongGlow), location: 0),
                        .init(color: .p3(0.74, 0.62, 0.95, level: .strongGlow), location: 0.55),
                        .init(color: .p3(0.60, 0.48, 0.88, level: .strongGlow), location: 1)
                    ]),
                    from: CGPoint(x: 4, y: 6), to: CGPoint(x: 34, y: 40), in: box
                ))
                MoonArt.rim.stroke(Color.p3(1, 1, 1, 0.55, level: .strongGlow), style: .round(0.8))
                MoonArt.craters.fill(Color.p3(0.62, 0.50, 0.90, 0.18))
                MoonArt.eyes.stroke(face, style: .round(1.1))
                MoonArt.mouth.stroke(face, style: .round(0.9))
                MoonArt.blush.fill(Color.p3(1, 0.50, 0.70, 0.5))

                // Nightcap (pokes out above the 44pt frame on purpose)
                MoonArt.cap.fill(LinearGradient(
                    Gradient(colors: [.p3(0.46, 0.74, 1.0, level: .rimHighlight), .p3(0.30, 0.46, 0.92, level: .rimHighlight)]),
                    from: CGPoint(x: 8, y: -3), to: CGPoint(x: 30, y: 14), in: box
                ))
                MoonArt.capFold.stroke(Color.p3(0.20, 0.30, 0.78, 0.35), style: .round(0.9))
                MoonArt.capBand.fill(cloth)
                MoonArt.pompom.fill(cloth)
            }
            .frame(width: box.width, height: box.height)
        }
        .offset(y: bob ? -5 : 5)
        .rotationEffect(.degrees(bob ? 3 : -3))
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 3.5).repeatForever(autoreverses: true)) { bob = true }
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) { glow = true }
        }
    }
}

// MARK: - Clouds
/// Sleepy cloud: soft shadow, lilac-to-white body, a fading EDR top rim and a face.
private struct SleepyCloud: View {
    let art: CloudArt
    let opacity: Double

    var body: some View {
        let box = art.box
        let face = Color.p3(0.40, 0.32, 0.62)
        ZStack {
            art.outline
                .fill(Color.p3(0.10, 0.06, 0.24, 0.22))
                .offset(y: 2.5)
                .blur(radius: 3)

            art.outline.fill(LinearGradient(
                Gradient(stops: [
                    .init(color: .p3(0.99, 0.98, 1.0, opacity), location: 0),
                    .init(color: .p3(0.88, 0.85, 0.97, opacity), location: 0.6),
                    .init(color: .p3(0.70, 0.64, 0.90, opacity), location: 1)
                ]),
                from: CGPoint(x: 0, y: 4), to: CGPoint(x: 0, y: box.height - 4), in: box
            ))

            art.outline.stroke(
                LinearGradient(
                    Gradient(colors: [.p3(1, 1, 1, 0.9 * opacity, level: .rimHighlight), .p3(1, 1, 1, 0)]),
                    from: CGPoint(x: 0, y: 4), to: CGPoint(x: 0, y: box.height * 0.7), in: box
                ),
                lineWidth: 1
            )

            art.eyes.stroke(face, style: .round(1.1))
            art.mouth.stroke(face, style: .round(0.9))
            art.blush.fill(Color.p3(1, 0.50, 0.70, 0.45))
        }
        .frame(width: box.width, height: box.height)
    }
}

public struct CuteCloud1: View {
    public let scale: CGFloat
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var bob = false

    public init(scale: CGFloat) {
        self.scale = scale
    }

    public var body: some View {
        SleepyCloud(art: .large, opacity: 0.95)
            .scaleEffect(scale)
            .offset(y: bob ? -5 : 4)
            .rotationEffect(.degrees(bob ? 2 : -2))
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.easeInOut(duration: 4.5).repeatForever(autoreverses: true)) { bob = true }
            }
    }
}

public struct CuteCloud2: View {
    public let scale: CGFloat
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var bob = false

    public init(scale: CGFloat) {
        self.scale = scale
    }

    public var body: some View {
        SleepyCloud(art: .small, opacity: 0.6)
            .scaleEffect(scale)
            .offset(y: bob ? -4 : 3)
            .rotationEffect(.degrees(bob ? -1.5 : 2))
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.easeInOut(duration: 5.5).repeatForever(autoreverses: true).delay(0.5)) { bob = true }
            }
    }
}

// MARK: - Aurora Effect
public struct AuroraEffect: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var s1 = false
    @State private var s2 = false
    @State private var s3 = false
    @State private var s4 = false

    public init() {}

    public var body: some View {
        ZStack {
            Ellipse().fill(LinearGradient(colors: [Color.p3(h: 0.75, s: 0.65, b: 0.7, a: 0.08, level: .subtleHighlight), Color.p3(h: 0.72, s: 0.5, b: 0.7, a: 0.03, level: .subtleHighlight)], startPoint: .leading, endPoint: .trailing)).frame(width: 320, height: 100).blur(radius: 45).offset(x: s1 ? 20 : -20, y: s1 ? -15 : 15)
            Ellipse().fill(LinearGradient(colors: [Color.p3(h: 0.55, s: 0.55, b: 0.7, a: 0.07, level: .subtleHighlight), Color.p3(h: 0.60, s: 0.4, b: 0.7, a: 0.02, level: .subtleHighlight)], startPoint: .trailing, endPoint: .leading)).frame(width: 260, height: 80).blur(radius: 40).offset(x: s2 ? -30 : 15, y: s2 ? 30 : -10)
            Ellipse().fill(Color.p3(h: 0.82, s: 0.55, b: 0.65, a: 0.05, level: .subtleHighlight)).frame(width: 180, height: 60).blur(radius: 35).offset(x: s3 ? 10 : -15, y: s3 ? -30 : 20)
            Ellipse().fill(LinearGradient(colors: [Color.p3(h: 0.93, s: 0.50, b: 0.7, a: 0.05, level: .subtleHighlight), Color.p3(h: 0.88, s: 0.40, b: 0.7, a: 0.02, level: .subtleHighlight)], startPoint: .top, endPoint: .bottom)).frame(width: 220, height: 70).blur(radius: 40).offset(x: s4 ? -20 : 25, y: s4 ? 20 : -25)
        }
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 6).repeatForever(autoreverses: true))  { s1 = true }
            withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true))  { s2 = true }
            withAnimation(.easeInOut(duration: 10).repeatForever(autoreverses: true))  { s3 = true }
            withAnimation(.easeInOut(duration: 12).repeatForever(autoreverses: true)) { s4 = true }
        }
    }
}

// MARK: - Pulsing Ring
public struct PulsingRing: View {
    public let progress: CGFloat

    public init(progress: CGFloat) {
        self.progress = progress
    }

    public var body: some View {
        ZStack {
            // Background track
            Circle()
                .stroke(Color.white.opacity(0.08), lineWidth: 4)
                .frame(width: 170, height: 170)

            // Progress ring with glowing gradient
            Circle()
                .trim(from: 0, to: max(0.001, progress))
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [
                            SlumberTheme.Colors.cyan,
                            SlumberTheme.Colors.accent,
                            SlumberTheme.Colors.coral,
                            SlumberTheme.Colors.cyan
                        ]),
                        center: .center,
                        // Gradient is defined pre-rotation: 0° here lands at 12 o'clock after
                        // the -90° rotation below, so it starts where the trim starts.
                        startAngle: .degrees(0),
                        endAngle: .degrees(360)
                    ),
                    style: StrokeStyle(lineWidth: 4.5, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .frame(width: 170, height: 170)
                .shadow(color: SlumberTheme.Colors.cyan.opacity(0.4), radius: 6)
                .animation(.linear(duration: 1.0), value: progress)

            // Glow dot at leading edge
            Circle()
                .fill(Color.p3(h: 0.53, s: 0.40, b: 1.0, level: .subtleHighlight))
                .frame(width: 7, height: 7)
                .shadow(color: SlumberTheme.Colors.cyan.opacity(0.8), radius: 4)
                .offset(y: -85)
                .rotationEffect(.degrees(Double(progress) * 360))
                .animation(.linear(duration: 1.0), value: progress)
        }
    }
}

// MARK: - Visual Effect View (Glassmorphism Backdrop)
public struct VisualEffectView: NSViewRepresentable {
    public let material: NSVisualEffectView.Material
    public let blendingMode: NSVisualEffectView.BlendingMode

    public init(material: NSVisualEffectView.Material, blendingMode: NSVisualEffectView.BlendingMode) {
        self.material = material
        self.blendingMode = blendingMode
    }

    public func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        view.appearance = NSAppearance(named: .vibrantDark)
        return view
    }

    public func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        if nsView.material != material { nsView.material = material }
        if nsView.blendingMode != blendingMode { nsView.blendingMode = blendingMode }
    }
}
