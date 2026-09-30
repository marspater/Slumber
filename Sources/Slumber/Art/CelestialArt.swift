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
    private typealias Stars = SlumberTheme.Art.Stars
    public let position: CGPoint
    public let size: CGFloat
    public let delay: Double
    public let isSparkle: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var on = false

    private var glowRadius: CGFloat { isSparkle ? Stars.sparkleGlowRadius : Stars.glowRadius }

    public var body: some View {
        Group {
            if isSparkle {
                SparkleStarShape()
                    .fill(Color.white)
                    .frame(width: size * Stars.sparkleScale, height: size * Stars.sparkleScale)
            } else {
                Circle()
                    .fill(Color.white)
                    .frame(width: size, height: size)
            }
        }
        .shadow(
            color: Stars.glow(alpha: on ? Stars.glowOpacity : 0, level: isSparkle ? .rimHighlight : .sdr),
            radius: on ? glowRadius : 0
        )
        .opacity(on ? Stars.litOpacity : Stars.restOpacity)
        .position(position)
        .onAppear {
            // Static but visible stars when motion is reduced (instead of the dim rest state).
            guard !reduceMotion else { on = true; return }
            withAnimation(
                .easeInOut(duration: Double.random(in: Stars.twinkleDuration))
                .repeatForever(autoreverses: true)
                .delay(delay)
            ) { on = true }
        }
    }
}

// MARK: - Shooting Star
public struct ShootingStar: View {
    private typealias Streak = SlumberTheme.Art.ShootingStar
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
        TimelineView(.animation(minimumInterval: 1.0 / Streak.frameRate)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let adjusted = t - initialDelay
            let progress = adjusted > 0
                ? (adjusted.truncatingRemainder(dividingBy: cycleDuration)) / cycleDuration
                : -1

            let rad = angle * .pi / 180
            let travel = Streak.travel

            if progress >= 0 {
                let headPhase = max(0.0, 1.0 - progress * 2.0)
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                Streak.tail,
                                Streak.head(alpha: Streak.headOpacity, phase: headPhase)
                            ],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    .frame(width: length * Streak.lengthRatio, height: Streak.thickness)
                    .blur(radius: Streak.blur)
                    .shadow(
                        color: Streak.head(alpha: Streak.glowOpacity, phase: headPhase),
                        radius: Streak.glowRadius
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
    private typealias Fly = SlumberTheme.Art.Firefly
    public let seed: Int
    public let bounds: CGSize

    private var tone: (hue: Double, glow: (r: Double, g: Double, b: Double)) {
        Fly.tones[seed % Fly.tones.count]
    }

    private var baseX: CGFloat { seededRandom(seed: seed * 3, max: bounds.width * 0.8) + bounds.width * 0.1 }
    private var baseY: CGFloat { seededRandom(seed: seed * 7, max: bounds.height * 0.6) + bounds.height * 0.2 }
    private var driftDX: CGFloat { seededRandom(seed: seed * 11, max: 30) - 15 }
    private var driftDY: CGFloat { seededRandom(seed: seed * 13, max: 20) - 10 }

    public var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / Fly.frameRate)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let period = Double(4 + (seed % 3))
            let phaseOffset = Double(seed) * 1.2
            let phaseInfo = computePhase(t: t, period: period, offset: phaseOffset)

            let glowColor = Fly.glow(tone.glow, phase: phaseInfo.normPhase)
            let dotColor = Fly.core(hue: tone.hue)
            let currentX: CGFloat = baseX + driftDX * CGFloat(phaseInfo.cycle)
            let currentY: CGFloat = baseY + driftDY * CGFloat(phaseInfo.cosTerm)
            let glowRadius: CGFloat = Fly.glowRadius.rest + Fly.glowRadius.peak * CGFloat(phaseInfo.normPhase)
            let currentOpacity: Double = Fly.opacity.rest + Fly.opacity.peak * phaseInfo.normPhase

            Circle()
                .fill(dotColor)
                .frame(width: Fly.size, height: Fly.size)
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
    private typealias Constellation = SlumberTheme.Art.Constellation
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var rotation: Double = 0

    public init() {}

    public var body: some View {
        ZStack {
            ConstellationPattern(stars: [CGPoint(x: 0.38, y: 0.18), CGPoint(x: 0.34, y: 0.28), CGPoint(x: 0.38, y: 0.30), CGPoint(x: 0.42, y: 0.29), CGPoint(x: 0.47, y: 0.17), CGPoint(x: 0.33, y: 0.40), CGPoint(x: 0.48, y: 0.38)], lines: [(0,1),(1,2),(2,3),(3,4),(1,5),(3,6)])
            ConstellationPattern(stars: [CGPoint(x: 0.62, y: 0.55), CGPoint(x: 0.67, y: 0.52), CGPoint(x: 0.72, y: 0.54), CGPoint(x: 0.75, y: 0.58), CGPoint(x: 0.77, y: 0.64), CGPoint(x: 0.82, y: 0.62), CGPoint(x: 0.84, y: 0.66)], lines: [(0,1),(1,2),(2,3),(3,4),(4,5),(5,6),(6,3)])
            ConstellationPattern(stars: [CGPoint(x: 0.12, y: 0.62), CGPoint(x: 0.17, y: 0.56), CGPoint(x: 0.22, y: 0.62), CGPoint(x: 0.27, y: 0.56), CGPoint(x: 0.32, y: 0.62)], lines: [(0,1),(1,2),(2,3),(3,4)])
        }
        .opacity(Constellation.layerOpacity)
        .rotationEffect(.degrees(rotation))
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.linear(duration: Constellation.rotationPeriod).repeatForever(autoreverses: false)) {
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
    private typealias Constellation = SlumberTheme.Art.Constellation
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
                    .stroke(Color.white.opacity(pulse ? Constellation.lineOpacity.lit : Constellation.lineOpacity.dim), lineWidth: Constellation.lineWidth)

                ForEach(0..<stars.count, id: \.self) { i in
                    Circle()
                        .fill(Color.white.opacity(pulse ? Constellation.starOpacity.lit : Constellation.starOpacity.dim))
                        .frame(width: Constellation.starSize, height: Constellation.starSize)
                        .shadow(
                            color: Constellation.glow(alpha: pulse ? Constellation.glowOpacity.lit : Constellation.glowOpacity.dim),
                            radius: pulse ? Constellation.glowRadius.lit : Constellation.glowRadius.dim
                        )
                        .position(x: stars[i].x * w, y: stars[i].y * h)
                }
            }
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.easeInOut(duration: Constellation.pulseDuration).repeatForever(autoreverses: true).delay(Double(stars.count % 3) * 0.5)) {
                    pulse = true
                }
            }
        }
    }
}

// MARK: - Cute Moon
public struct CuteMoon: View {
    private typealias Moon = SlumberTheme.Art.Moon
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var bob = false
    @State private var glow = false


    public init() {}

    public var body: some View {
        let box = MoonArt.box
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Moon.halo, .clear],
                        center: .center, startRadius: Moon.haloRadii.start, endRadius: Moon.haloRadii.end
                    )
                )
                .frame(width: Moon.haloSize, height: Moon.haloSize)
                .scaleEffect(glow ? Moon.haloPulseScale : 1.0)

            ZStack {
                MoonArt.crescent.fill(LinearGradient(
                    Moon.crescent,
                    from: CGPoint(x: 4, y: 6), to: CGPoint(x: 34, y: 40), in: box
                ))
                MoonArt.rim.stroke(Moon.rim, style: .round(0.8))
                MoonArt.craters.fill(Moon.craters)
                MoonArt.eyes.stroke(Moon.face, style: .round(1.1))
                MoonArt.mouth.stroke(Moon.face, style: .round(0.9))
                MoonArt.blush.fill(Moon.blush)

                // Nightcap (pokes out above the 44pt frame on purpose)
                MoonArt.cap.fill(LinearGradient(
                    Moon.cap,
                    from: CGPoint(x: 8, y: -3), to: CGPoint(x: 30, y: 14), in: box
                ))
                MoonArt.capFold.stroke(Moon.capFold, style: .round(0.9))
                MoonArt.capBand.fill(Moon.cloth)
                MoonArt.pompom.fill(Moon.cloth)
            }
            .frame(width: box.width, height: box.height)
        }
        .offset(y: bob ? -Moon.bob : Moon.bob)
        .rotationEffect(.degrees(bob ? Moon.tilt : -Moon.tilt))
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: Moon.bobDuration).repeatForever(autoreverses: true)) { bob = true }
            withAnimation(.easeInOut(duration: Moon.haloPulseDuration).repeatForever(autoreverses: true)) { glow = true }
        }
    }
}

// MARK: - Clouds
/// Sleepy cloud: soft shadow, lilac-to-white body, a fading EDR top rim and a face.
private struct SleepyCloud: View {
    private typealias Palette = SlumberTheme.Art.Cloud
    let art: CloudArt
    let opacity: Double

    var body: some View {
        let box = art.box
        ZStack {
            art.outline
                .fill(Palette.shadow)
                .offset(y: Palette.shadowOffsetY)
                .blur(radius: Palette.shadowBlur)

            art.outline.fill(LinearGradient(
                Palette.body(opacity: opacity),
                from: CGPoint(x: 0, y: 4), to: CGPoint(x: 0, y: box.height - 4), in: box
            ))

            art.outline.stroke(
                LinearGradient(
                    Palette.rim(opacity: opacity),
                    from: CGPoint(x: 0, y: 4), to: CGPoint(x: 0, y: box.height * 0.7), in: box
                ),
                lineWidth: Palette.rimWidth
            )

            art.eyes.stroke(Palette.face, style: .round(1.1))
            art.mouth.stroke(Palette.face, style: .round(0.9))
            art.blush.fill(Palette.blush)
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
        SleepyCloud(art: .large, opacity: SlumberTheme.Art.Cloud.largeOpacity)
            .scaleEffect(scale)
            .offset(y: bob ? -5 : 4)
            .rotationEffect(.degrees(bob ? 2 : -2))
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.easeInOut(duration: SlumberTheme.Art.Cloud.largeBobDuration).repeatForever(autoreverses: true)) { bob = true }
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
        SleepyCloud(art: .small, opacity: SlumberTheme.Art.Cloud.smallOpacity)
            .scaleEffect(scale)
            .offset(y: bob ? -4 : 3)
            .rotationEffect(.degrees(bob ? -1.5 : 2))
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(
                    .easeInOut(duration: SlumberTheme.Art.Cloud.smallBobDuration)
                    .repeatForever(autoreverses: true)
                    .delay(SlumberTheme.Art.Cloud.smallBobDelay)
                ) { bob = true }
            }
    }
}

// MARK: - Aurora Effect
public struct AuroraEffect: View {
    private typealias Aurora = SlumberTheme.Art.Aurora
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var s1 = false
    @State private var s2 = false
    @State private var s3 = false
    @State private var s4 = false

    public init() {}

    public var body: some View {
        ZStack {
            Ellipse().fill(LinearGradient(colors: Aurora.bands[0], startPoint: .leading, endPoint: .trailing)).frame(width: 320, height: 100).blur(radius: 45).offset(x: s1 ? 20 : -20, y: s1 ? -15 : 15)
            Ellipse().fill(LinearGradient(colors: Aurora.bands[1], startPoint: .trailing, endPoint: .leading)).frame(width: 260, height: 80).blur(radius: 40).offset(x: s2 ? -30 : 15, y: s2 ? 30 : -10)
            Ellipse().fill(Aurora.bands[2][0]).frame(width: 180, height: 60).blur(radius: 35).offset(x: s3 ? 10 : -15, y: s3 ? -30 : 20)
            Ellipse().fill(LinearGradient(colors: Aurora.bands[3], startPoint: .top, endPoint: .bottom)).frame(width: 220, height: 70).blur(radius: 40).offset(x: s4 ? -20 : 25, y: s4 ? 20 : -25)
        }
        .onAppear {
            guard !reduceMotion else { return }
            let drift = Aurora.driftDurations
            withAnimation(.easeInOut(duration: drift[0]).repeatForever(autoreverses: true)) { s1 = true }
            withAnimation(.easeInOut(duration: drift[1]).repeatForever(autoreverses: true)) { s2 = true }
            withAnimation(.easeInOut(duration: drift[2]).repeatForever(autoreverses: true)) { s3 = true }
            withAnimation(.easeInOut(duration: drift[3]).repeatForever(autoreverses: true)) { s4 = true }
        }
    }
}

// MARK: - Pulsing Ring
public struct PulsingRing: View {
    private typealias Ring = SlumberTheme.Components.Ring
    public let progress: CGFloat

    public init(progress: CGFloat) {
        self.progress = progress
    }

    public var body: some View {
        ZStack {
            // Background track
            Circle()
                .stroke(Color.white.opacity(Ring.trackOpacity), lineWidth: Ring.trackWidth)
                .frame(width: Ring.diameter, height: Ring.diameter)

            // Progress ring with glowing gradient
            Circle()
                .trim(from: 0, to: max(0.001, progress))
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: Ring.gradient),
                        center: .center,
                        // Gradient is defined pre-rotation: 0° here lands at 12 o'clock after
                        // the -90° rotation below, so it starts where the trim starts.
                        startAngle: .degrees(0),
                        endAngle: .degrees(360)
                    ),
                    style: StrokeStyle(lineWidth: Ring.progressWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .frame(width: Ring.diameter, height: Ring.diameter)
                .shadow(color: SlumberTheme.Colors.cyan.opacity(Ring.glowOpacity), radius: Ring.glowRadius)
                .animation(SlumberTheme.Motion.ringProgress, value: progress)

            // Glow dot at leading edge
            Circle()
                .fill(Ring.dot)
                .frame(width: Ring.dotSize, height: Ring.dotSize)
                .shadow(color: SlumberTheme.Colors.cyan.opacity(Ring.dotGlowOpacity), radius: Ring.dotGlowRadius)
                .offset(y: -Ring.diameter / 2)
                .rotationEffect(.degrees(Double(progress) * 360))
                .animation(SlumberTheme.Motion.ringProgress, value: progress)
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

    public func makeNSView(context _: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        view.appearance = NSAppearance(named: .vibrantDark)
        return view
    }

    public func updateNSView(_ nsView: NSVisualEffectView, context _: Context) {
        if nsView.material != material { nsView.material = material }
        if nsView.blendingMode != blendingMode { nsView.blendingMode = blendingMode }
    }
}
