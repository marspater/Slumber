import SwiftUI
import AppKit
import SlumberCore

// ===================================================================
// MARK: - Audio Helper
// ===================================================================

import AVFoundation

@MainActor private var audioPlayers: [String: AVAudioPlayer] = [:]

@MainActor
func playSound(_ name: String) {
    if let player = audioPlayers[name] {
        if player.isPlaying { player.currentTime = 0 }
        player.play()
        return
    }
    
    guard let url = Bundle.main.url(forResource: name, withExtension: "wav") else {
        NSLog("[SlumberAudio] Audio file '%@.wav' not found in bundle resources.", name)
        return
    }
    do {
        let player = try AVAudioPlayer(contentsOf: url)
        player.prepareToPlay()
        audioPlayers[name] = player
        player.play()
    } catch {
        NSLog("[SlumberAudio] Failed to initialize AVAudioPlayer for '%@.wav': %@", name, error.localizedDescription)
    }
}

// ===================================================================
// MARK: - Layout Constants
// ===================================================================

private let slumberLightFg = Color(red: 0.12, green: 0.10, blue: 0.22)

// ===================================================================
// MARK: - Shapes
// ===================================================================

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

struct Arc: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addArc(
            center: CGPoint(x: rect.midX, y: rect.midY),
            radius: rect.width / 2,
            startAngle: .degrees(0),
            endAngle: .degrees(180),
            clockwise: false
        )
        return path
    }
}

// ===================================================================
// MARK: - Sparkle Star Shape
// ===================================================================

struct SparkleStarShape: Shape {
    func path(in rect: CGRect) -> Path {
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

// ===================================================================
// MARK: - Twinkling Star Field
// ===================================================================

struct StarField: View {
    let count: Int

    var body: some View {
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

struct TwinklingStar: View {
    let position: CGPoint
    let size: CGFloat
    let delay: Double
    let isSparkle: Bool
    @State private var on = false

    var body: some View {
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
            withAnimation(
                .easeInOut(duration: Double.random(in: 1.8...3.8))
                .repeatForever(autoreverses: true)
                .delay(delay)
            ) { on = true }
        }
    }
}

// ===================================================================
// MARK: - Shooting Star
// ===================================================================

struct ShootingStar: View {
    let angle: Double
    let cycleDuration: Double
    let initialDelay: Double
    let length: CGFloat
    let startX: CGFloat
    let startY: CGFloat

    var body: some View {
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
                        radius: 2
                    )
                    .rotationEffect(.degrees(angle))
                    .offset(
                        x: startX + CGFloat(cos(rad)) * travel * CGFloat(progress),
                        y: startY + CGFloat(sin(rad)) * travel * CGFloat(progress)
                    )
                    .opacity(
                        progress < 0.12
                             ? (progress / 0.12) * 0.6
                             : (progress > 0.55 ? max(0, ((1 - progress) / 0.45) * 0.6) : 0.6)
                    )
            }
        }
    }
}

// ===================================================================
// MARK: - Firefly Particles
// ===================================================================

struct FireflyField: View {
    let count: Int

    var body: some View {
        GeometryReader { geo in
            ForEach(0..<count, id: \.self) { i in
                Firefly(seed: i, bounds: geo.size)
            }
        }
    }
}

struct Firefly: View {
    let seed: Int
    let bounds: CGSize

    private var hue: Double {
        switch seed % 3 {
        case 0: return 0.08
        case 1: return 0.75
        default: return 0.52
        }
    }

    private var baseRGB: (Double, Double, Double) {
        switch seed % 3 {
        case 0: return (1.0, 0.85, 0.25) // Gold
        case 1: return (0.85, 0.55, 0.95) // Violet
        default: return (0.35, 0.85, 0.95) // Cyan
        }
    }

    private var baseX: CGFloat { seededRandom(seed: seed * 3, max: bounds.width * 0.8) + bounds.width * 0.1 }
    private var baseY: CGFloat { seededRandom(seed: seed * 7, max: bounds.height * 0.6) + bounds.height * 0.2 }
    private var driftDX: CGFloat { seededRandom(seed: seed * 11, max: 30) - 15 }
    private var driftDY: CGFloat { seededRandom(seed: seed * 13, max: 20) - 10 }

    var body: some View {
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

// ===================================================================
// MARK: - Constellation Overlay
// ===================================================================

struct ConstellationOverlay: View {
    @State private var rotation: Double = 0

    var body: some View {
        ZStack {
            ConstellationPattern(stars: [CGPoint(x: 0.38, y: 0.18), CGPoint(x: 0.34, y: 0.28), CGPoint(x: 0.38, y: 0.30), CGPoint(x: 0.42, y: 0.29), CGPoint(x: 0.47, y: 0.17), CGPoint(x: 0.33, y: 0.40), CGPoint(x: 0.48, y: 0.38)], lines: [(0,1),(1,2),(2,3),(3,4),(1,5),(3,6)])
            ConstellationPattern(stars: [CGPoint(x: 0.62, y: 0.55), CGPoint(x: 0.67, y: 0.52), CGPoint(x: 0.72, y: 0.54), CGPoint(x: 0.75, y: 0.58), CGPoint(x: 0.77, y: 0.64), CGPoint(x: 0.82, y: 0.62), CGPoint(x: 0.84, y: 0.66)], lines: [(0,1),(1,2),(2,3),(3,4),(4,5),(5,6),(6,3)])
            ConstellationPattern(stars: [CGPoint(x: 0.12, y: 0.62), CGPoint(x: 0.17, y: 0.56), CGPoint(x: 0.22, y: 0.62), CGPoint(x: 0.27, y: 0.56), CGPoint(x: 0.32, y: 0.62)], lines: [(0,1),(1,2),(2,3),(3,4)])
        }
        .opacity(0.3)
        .rotationEffect(.degrees(rotation))
        .onAppear {
            withAnimation(.linear(duration: 180).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
    }
}

struct ConstellationPattern: View {
    let stars: [CGPoint]
    let lines: [(Int, Int)]
    @State private var pulse = false

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            ZStack {
                Path { path in
                    for line in lines {
                        let from = stars[line.0]
                        let to = stars[line.1]
                        path.move(to: CGPoint(x: from.x * w, y: from.y * h))
                        path.addLine(to: CGPoint(x: to.x * w, y: to.y * h))
                    }
                }
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
                withAnimation(.easeInOut(duration: 4.0).repeatForever(autoreverses: true).delay(Double(stars.count % 3) * 0.5)) {
                    pulse = true
                }
            }
        }
    }
}

// ===================================================================
// MARK: - Cute Moon
// ===================================================================

struct CuteMoon: View {
    @State private var bob = false
    @State private var glow = false

    var body: some View {
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
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.p3(h: 0.73, s: 0.35, b: 0.95, level: .strongGlow),
                                Color.p3(h: 0.78, s: 0.45, b: 0.80, level: .strongGlow)
                            ],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)

                HStack(spacing: 6) { CuteEye(); CuteEye() }.offset(x: -4, y: 2)
                Circle().fill(Color.pink.opacity(0.5)).frame(width: 6, height: 6).offset(x: -12, y: 8)
                Arc().stroke(Color.white.opacity(0.7), lineWidth: 1.2).frame(width: 8, height: 4).offset(x: -5, y: 10)
            }
            // Use native transparent masking to cut out the top right crescent section
            // This prevents the "blackeye" solid circle artifact on standard backgrounds
            .mask(
                ZStack {
                    Rectangle().fill(Color.white).frame(width: 80, height: 80)
                    Circle()
                        .fill(Color.black)
                        .frame(width: 38, height: 38)
                        .offset(x: 12, y: -10)
                        .blendMode(.destinationOut)
                }
                .compositingGroup()
            )
        }
        .offset(y: bob ? -5 : 5)
        .rotationEffect(.degrees(bob ? 3 : -3))
        .onAppear {
            withAnimation(.easeInOut(duration: 3.5).repeatForever(autoreverses: true)) { bob = true }
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) { glow = true }
        }
    }
}

struct CuteEye: View {
    var body: some View {
        Arc()
            .stroke(Color.white.opacity(0.9), lineWidth: 1.5)
            .frame(width: 5, height: 3)
            .rotationEffect(.degrees(180))
    }
}

// ===================================================================
// MARK: - Cute Clouds (Visually Distinct)
// ===================================================================

struct VectorCloudShape1: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        
        path.move(to: CGPoint(x: w * 0.2, y: h * 0.85))
        path.addQuadCurve(to: CGPoint(x: w * 0.8, y: h * 0.85), control: CGPoint(x: w * 0.5, y: h * 0.95))
        path.addCurve(to: CGPoint(x: w * 0.78, y: h * 0.35), control1: CGPoint(x: w * 1.02, y: h * 0.78), control2: CGPoint(x: w * 0.95, y: h * 0.38))
        path.addCurve(to: CGPoint(x: w * 0.42, y: h * 0.22), control1: CGPoint(x: w * 0.68, y: h * 0.05), control2: CGPoint(x: w * 0.48, y: h * 0.08))
        path.addCurve(to: CGPoint(x: w * 0.12, y: h * 0.52), control1: CGPoint(x: w * 0.28, y: h * 0.18), control2: CGPoint(x: w * 0.1, y: h * 0.35))
        path.addCurve(to: CGPoint(x: w * 0.2, y: h * 0.85), control1: CGPoint(x: w * -0.02, y: h * 0.68), control2: CGPoint(x: w * 0.08, y: h * 0.85))
        path.closeSubpath()
        return path
    }
}

struct VectorCloudShape2: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        
        path.move(to: CGPoint(x: w * 0.15, y: h * 0.82))
        path.addQuadCurve(to: CGPoint(x: w * 0.85, y: h * 0.82), control: CGPoint(x: w * 0.5, y: h * 0.92))
        path.addCurve(to: CGPoint(x: w * 0.72, y: h * 0.32), control1: CGPoint(x: w * 1.0, y: h * 0.72), control2: CGPoint(x: w * 0.9, y: h * 0.32))
        path.addCurve(to: CGPoint(x: w * 0.32, y: h * 0.22), control1: CGPoint(x: w * 0.58, y: h * 0.08), control2: CGPoint(x: w * 0.42, y: h * 0.12))
        path.addCurve(to: CGPoint(x: w * 0.15, y: h * 0.82), control1: CGPoint(x: w * 0.1, y: h * 0.32), control2: CGPoint(x: w * -0.02, y: h * 0.65))
        path.closeSubpath()
        return path
    }
}

struct CuteCloud1: View {
    let scale: CGFloat
    @State private var bob = false

    var body: some View {
        ZStack {
            VectorCloudShape1()
                .fill(Color.black.opacity(0.2))
                .blur(radius: 4 * scale)
                .offset(y: 3 * scale)

            VectorCloudShape1()
                .fill(
                    LinearGradient(
                        colors: [Color.p3(r: 0.95, g: 0.95, b: 0.98, a: 0.92), Color.p3(h: 0.72, s: 0.25, b: 0.82, a: 0.85)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )

            VectorCloudShape1()
                .stroke(
                    LinearGradient(
                        colors: [Color.p3(1.0, 1.0, 1.0, 0.9, level: .rimHighlight), Color.p3(1.0, 1.0, 1.0, 0.1, level: .sdr)],
                        startPoint: .top, endPoint: .bottom
                    ),
                    lineWidth: 1.2 * scale
                )

            HStack(spacing: 5 * scale) { CuteEye(); CuteEye() }.scaleEffect(scale).offset(y: -1 * scale)
            Circle().fill(Color.pink.opacity(0.40)).frame(width: 5 * scale, height: 5 * scale).offset(x: -11 * scale, y: 4 * scale)
            Circle().fill(Color.pink.opacity(0.40)).frame(width: 5 * scale, height: 5 * scale).offset(x: 11 * scale, y: 4 * scale)
        }
        .frame(width: 64 * scale, height: 40 * scale)
        .offset(y: bob ? -5 : 4)
        .rotationEffect(.degrees(bob ? 2 : -2))
        .onAppear {
            withAnimation(.easeInOut(duration: 4.5).repeatForever(autoreverses: true)) { bob = true }
        }
    }
}

struct CuteCloud2: View {
    let scale: CGFloat
    @State private var bob = false

    var body: some View {
        ZStack {
            VectorCloudShape2()
                .fill(Color.black.opacity(0.12))
                .blur(radius: 3 * scale)
                .offset(y: 2 * scale)

            VectorCloudShape2()
                .fill(
                    LinearGradient(
                        colors: [Color.p3(r: 0.85, g: 0.85, b: 0.92, a: 0.55), Color.p3(h: 0.65, s: 0.22, b: 0.75, a: 0.40)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )

            VectorCloudShape2()
                .stroke(
                    LinearGradient(
                        colors: [Color.p3(1.0, 1.0, 1.0, 0.45, level: .rimHighlight), Color.p3(1.0, 1.0, 1.0, 0.08, level: .sdr)],
                        startPoint: .top, endPoint: .bottom
                    ),
                    lineWidth: 0.8 * scale
                )

            HStack(spacing: 5 * scale) { CuteEye(); CuteEye() }.scaleEffect(scale).offset(y: -1 * scale).opacity(0.6)
            Circle().fill(Color.pink.opacity(0.25)).frame(width: 4 * scale, height: 4 * scale).offset(x: -10 * scale, y: 4 * scale)
            Circle().fill(Color.pink.opacity(0.25)).frame(width: 4 * scale, height: 4 * scale).offset(x: 10 * scale, y: 4 * scale)
        }
        .frame(width: 58 * scale, height: 34 * scale)
        .offset(y: bob ? -4 : 3)
        .rotationEffect(.degrees(bob ? -1.5 : 2))
        .onAppear {
            withAnimation(.easeInOut(duration: 5.5).repeatForever(autoreverses: true).delay(0.5)) { bob = true }
        }
    }
}

// ===================================================================
// MARK: - Aurora Effect
// ===================================================================

struct AuroraEffect: View {
    @State private var s1 = false
    @State private var s2 = false
    @State private var s3 = false
    @State private var s4 = false

    var body: some View {
        ZStack {
            Ellipse().fill(LinearGradient(colors: [Color.p3(h: 0.75, s: 0.65, b: 0.7, a: 0.08, level: .subtleHighlight), Color.p3(h: 0.72, s: 0.5, b: 0.7, a: 0.03, level: .subtleHighlight)], startPoint: .leading, endPoint: .trailing)).frame(width: 320, height: 100).blur(radius: 45).offset(x: s1 ? 20 : -20, y: s1 ? -15 : 15)
            Ellipse().fill(LinearGradient(colors: [Color.p3(h: 0.55, s: 0.55, b: 0.7, a: 0.07, level: .subtleHighlight), Color.p3(h: 0.60, s: 0.4, b: 0.7, a: 0.02, level: .subtleHighlight)], startPoint: .trailing, endPoint: .leading)).frame(width: 260, height: 80).blur(radius: 40).offset(x: s2 ? -30 : 15, y: s2 ? 30 : -10)
            Ellipse().fill(Color.p3(h: 0.82, s: 0.55, b: 0.65, a: 0.05, level: .subtleHighlight)).frame(width: 180, height: 60).blur(radius: 35).offset(x: s3 ? 10 : -15, y: s3 ? -30 : 20)
            Ellipse().fill(LinearGradient(colors: [Color.p3(h: 0.93, s: 0.50, b: 0.7, a: 0.05, level: .subtleHighlight), Color.p3(h: 0.88, s: 0.40, b: 0.7, a: 0.02, level: .subtleHighlight)], startPoint: .top, endPoint: .bottom)).frame(width: 220, height: 70).blur(radius: 40).offset(x: s4 ? -20 : 25, y: s4 ? 20 : -25)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 6).repeatForever(autoreverses: true))  { s1 = true }
            withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true))  { s2 = true }
            withAnimation(.easeInOut(duration: 10).repeatForever(autoreverses: true))  { s3 = true }
            withAnimation(.easeInOut(duration: 12).repeatForever(autoreverses: true)) { s4 = true }
        }
    }
}

// ===================================================================
// MARK: - Characters & Companion Vector Shapes
// ===================================================================

struct FoxTailShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: 2, y: rect.height * 0.72))
        p.addCurve(
            to: CGPoint(x: rect.width - 2, y: rect.height * 0.18),
            control1: CGPoint(x: rect.width * 0.40, y: rect.height * 1.05),
            control2: CGPoint(x: rect.width + 5, y: rect.height * 0.62)
        )
        p.addCurve(
            to: CGPoint(x: 2, y: rect.height * 0.72),
            control1: CGPoint(x: rect.width * 0.68, y: -rect.height * 0.10),
            control2: CGPoint(x: rect.width * 0.15, y: rect.height * 0.22)
        )
        p.closeSubpath()
        return p
    }
}

struct FoxTailTipShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.width * 0.52, y: 0))
        p.addCurve(
            to: CGPoint(x: rect.width - 2, y: rect.height * 0.18),
            control1: CGPoint(x: rect.width * 0.75, y: -rect.height * 0.05),
            control2: CGPoint(x: rect.width + 2, y: rect.height * 0.06)
        )
        p.addCurve(
            to: CGPoint(x: rect.width * 0.48, y: rect.height * 0.62),
            control1: CGPoint(x: rect.width + 3, y: rect.height * 0.45),
            control2: CGPoint(x: rect.width * 0.70, y: rect.height * 0.60)
        )
        p.addCurve(
            to: CGPoint(x: rect.width * 0.40, y: rect.height * 0.32),
            control1: CGPoint(x: rect.width * 0.42, y: rect.height * 0.48),
            control2: CGPoint(x: rect.width * 0.40, y: rect.height * 0.38)
        )
        p.addCurve(
            to: CGPoint(x: rect.width * 0.52, y: 0),
            control1: CGPoint(x: rect.width * 0.42, y: rect.height * 0.20),
            control2: CGPoint(x: rect.width * 0.46, y: rect.height * 0.08)
        )
        p.closeSubpath()
        return p
    }
}

struct CatTailShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        // Starts at right rear of sleeping cat, sweeps downward and curls back up gracefully in a J-hook
        p.move(to: CGPoint(x: 2, y: rect.height * 0.55))
        p.addCurve(
            to: CGPoint(x: rect.width - 3, y: 4),
            control1: CGPoint(x: rect.width * 0.42, y: rect.height + 6),
            control2: CGPoint(x: rect.width + 5, y: rect.height * 0.48)
        )
        return p
    }
}

struct SleepingFox: View {
    let isNearEnd: Bool
    @State private var breathe = false
    @State private var fidget = false
    @State private var tailSway = false
    @State private var zzz = false

    private let fur     = Color.p3(r: 0.94, g: 0.50, b: 0.15)
    private let furDk   = Color.p3(r: 0.76, g: 0.32, b: 0.08)
    private let cream   = Color.p3(r: 0.98, g: 0.94, b: 0.88)
    private let dark    = Color.p3(r: 0.12, g: 0.08, b: 0.06)

    var body: some View {
        ZStack {
            // Big Fluffy Fox Tail with Snowy Tip
            ZStack {
                FoxTailShape()
                    .fill(
                        LinearGradient(
                            colors: [fur, furDk],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                FoxTailTipShape()
                    .fill(cream)
                
                // Fluffy tip highlight
                Circle()
                    .fill(cream.opacity(0.95))
                    .frame(width: 7, height: 7)
                    .offset(x: 14, y: -6)
            }
            .frame(width: 38, height: 26)
            .offset(x: 17, y: -2)
            .rotationEffect(.degrees(tailSway ? 3.5 : -2), anchor: .bottomLeading)

            // Curled Fox Body
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [fur, furDk],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 38, height: 23)
                .scaleEffect(y: breathe ? 1.04 : 1.0)
                .scaleEffect(x: breathe ? 0.99 : 1.0)

            // Fluffy Cream Chest / Belly Ruff
            Ellipse()
                .fill(cream.opacity(0.85))
                .frame(width: 18, height: 12)
                .offset(x: -6, y: 5)

            // Tucked Little Paws with Dark Fox Socks
            Ellipse().fill(dark.opacity(0.75)).frame(width: 6, height: 4.5).offset(x: -10, y: 8)
            Ellipse().fill(fur).frame(width: 6, height: 4.5).offset(x: -9, y: 7.5)
            Ellipse().fill(dark.opacity(0.75)).frame(width: 6, height: 4.5).offset(x: -4, y: 9)
            Ellipse().fill(fur).frame(width: 6, height: 4.5).offset(x: -3, y: 8.5)

            // Fox Head
            Circle()
                .fill(fur)
                .frame(width: 22, height: 22)
                .offset(x: -14, y: -7)

            // Fox Ears
            // Left Ear
            ZStack {
                Triangle().fill(dark.opacity(0.85)).frame(width: 9, height: 16)
                Triangle().fill(fur).frame(width: 8, height: 14).offset(y: 1)
                Triangle().fill(cream).frame(width: 5, height: 10).offset(y: 2)
                Triangle().fill(Color.pink.opacity(0.35)).frame(width: 3.5, height: 7).offset(y: 3)
            }
            .rotationEffect(.degrees(isNearEnd ? (fidget ? -22 : 0) : -10))
            .offset(x: -22, y: -20)

            // Right Ear
            ZStack {
                Triangle().fill(dark.opacity(0.85)).frame(width: 9, height: 16)
                Triangle().fill(fur).frame(width: 8, height: 14).offset(y: 1)
                Triangle().fill(cream).frame(width: 5, height: 10).offset(y: 2)
                Triangle().fill(Color.pink.opacity(0.35)).frame(width: 3.5, height: 7).offset(y: 3)
            }
            .rotationEffect(.degrees(isNearEnd ? (fidget ? 16 : -2) : 6))
            .offset(x: -9, y: -21)

            // Cream Pointed Snout & Cheeks
            Ellipse()
                .fill(cream)
                .frame(width: 14, height: 8)
                .offset(x: -24, y: -4)

            // Dark Button Nose
            Circle()
                .fill(dark)
                .frame(width: 3, height: 3)
                .offset(x: -29, y: -5)

            // Sleeping Eye or Alert Eye
            if isNearEnd {
                Capsule()
                    .fill(Color.p3(h: 0.10, s: 0.8, b: 0.85, level: .rimHighlight))
                    .frame(width: 3, height: 1.5)
                    .offset(x: -18, y: -9)
                Capsule()
                    .fill(Color.p3(h: 0.10, s: 0.8, b: 0.85, level: .rimHighlight))
                    .frame(width: 3, height: 1.5)
                    .offset(x: -12, y: -9)
            } else {
                Arc()
                    .stroke(dark.opacity(0.75), lineWidth: 1.2)
                    .frame(width: 4.5, height: 2.5)
                    .rotationEffect(.degrees(180))
                    .offset(x: -18, y: -9)
                Arc()
                    .stroke(dark.opacity(0.75), lineWidth: 1.2)
                    .frame(width: 4.5, height: 2.5)
                    .rotationEffect(.degrees(180))
                    .offset(x: -12, y: -9)
            }

            // Rosy Cheek Blush
            Circle()
                .fill(Color.pink.opacity(0.30))
                .frame(width: 5, height: 5)
                .offset(x: -24, y: -1)

            // Sleeping 'z' particles
            Text("z").font(.system(size: 7, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.4)).offset(x: zzz ? 14 : 2, y: zzz ? -28 : -18).opacity(isNearEnd ? 0 : (zzz ? 0 : 0.5))
            Text("z").font(.system(size: 5, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.3)).offset(x: zzz ? 20 : 8, y: zzz ? -34 : -24).opacity(isNearEnd ? 0 : (zzz ? 0 : 0.35))

            // Near-End Alert '?'
            if isNearEnd {
                Text("?").font(.system(size: 8, weight: .bold, design: .rounded))
                    .foregroundColor(Color.p3(h: 0.08, s: 0.6, b: 1.0, a: 0.75, level: .rimHighlight)).offset(x: -5, y: -23)
            }
        }
        .animation(.easeInOut(duration: 0.6), value: isNearEnd)
        .onAppear {
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) { breathe = true }
            withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) { fidget = true }
            withAnimation(.easeInOut(duration: 4.0).repeatForever(autoreverses: true)) { tailSway = true }
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: false)) { zzz = true }
        }
    }
}

struct SleepingCat: View {
    let isNearEnd: Bool
    @State private var breathe = false
    @State private var fidget = false
    @State private var purr = false
    @State private var tailSway = false
    @State private var zzz = false

    private let fur     = Color.p3(r: 0.54, g: 0.48, b: 0.70)
    private let furDk   = Color.p3(r: 0.36, g: 0.30, b: 0.50)
    private let furLt   = Color.p3(r: 0.74, g: 0.68, b: 0.86)

    var body: some View {
        ZStack {
            // Graceful Curved Vector Cat Tail
            ZStack {
                CatTailShape()
                    .stroke(
                        LinearGradient(
                            colors: [fur, furDk],
                            startPoint: .leading,
                            endPoint: .topTrailing
                        ),
                        style: StrokeStyle(lineWidth: 5.0, lineCap: .round, lineJoin: .round)
                    )
                
                // Dark tail tip cap
                Circle()
                    .fill(furDk)
                    .frame(width: 5, height: 5)
                    .offset(x: 9, y: -8)
            }
            .frame(width: 24, height: 20)
            .offset(x: 17, y: 1)
            .rotationEffect(.degrees(tailSway ? 6 : -3), anchor: .bottomLeading)

            // Curled Sleeping Kitten Body
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [fur, furDk],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 32, height: 23)
                .scaleEffect(y: breathe ? 1.04 : 1.0)
                .scaleEffect(x: purr ? 1.01 : 0.99)

            // Soft Lavender Belly Patch
            Ellipse()
                .fill(furLt.opacity(0.40))
                .frame(width: 14, height: 10)
                .offset(x: -4, y: 4)

            // Kitten Head
            Circle()
                .fill(fur)
                .frame(width: 18, height: 18)
                .offset(x: -11, y: -6)

            // Cat Ears
            // Left Ear
            ZStack {
                Triangle().fill(furDk).frame(width: 7, height: 11)
                Triangle().fill(fur).frame(width: 6, height: 9.5).offset(y: 1)
                Triangle().fill(Color.pink.opacity(0.40)).frame(width: 3.5, height: 6.5).offset(y: 2)
            }
            .rotationEffect(.degrees(isNearEnd ? (fidget ? -18 : -2) : -12))
            .offset(x: -16, y: -14)

            // Right Ear
            ZStack {
                Triangle().fill(furDk).frame(width: 7, height: 11)
                Triangle().fill(fur).frame(width: 6, height: 9.5).offset(y: 1)
                Triangle().fill(Color.pink.opacity(0.40)).frame(width: 3.5, height: 6.5).offset(y: 2)
            }
            .rotationEffect(.degrees(isNearEnd ? (fidget ? 12 : -2) : 6))
            .offset(x: -6, y: -15)

            // Tiny Pink Nose
            Triangle()
                .fill(Color.pink.opacity(0.80))
                .frame(width: 3, height: 2)
                .rotationEffect(.degrees(180))
                .offset(x: -14, y: -4)

            // Sleeping Eye or Alert Eye
            if isNearEnd {
                Capsule().fill(Color.p3(h: 0.35, s: 0.65, b: 0.85, level: .rimHighlight)).frame(width: 2.5, height: 1.5).offset(x: -13, y: -7)
                Capsule().fill(Color.p3(h: 0.35, s: 0.65, b: 0.85, level: .rimHighlight)).frame(width: 2.5, height: 1.5).offset(x: -8, y: -7)
            } else {
                Arc().stroke(Color.white.opacity(0.80), lineWidth: 1.1).frame(width: 4, height: 2).rotationEffect(.degrees(180)).offset(x: -13, y: -7)
                Arc().stroke(Color.white.opacity(0.80), lineWidth: 1.1).frame(width: 4, height: 2).rotationEffect(.degrees(180)).offset(x: -8, y: -7)
            }

            // Fine Whiskers
            ForEach(0..<3, id: \.self) { i in
                Capsule()
                    .fill(Color.white.opacity(0.35))
                    .frame(width: 8, height: 0.6)
                    .rotationEffect(.degrees(Double(i - 1) * 12 - 5))
                    .offset(x: -20, y: -3 + CGFloat(i) * 2)
            }

            // Tucked Paws with Cute Pink Toe Beans
            Ellipse().fill(fur).frame(width: 5.5, height: 4.5).offset(x: -5, y: 6)
            Ellipse().fill(fur).frame(width: 5.5, height: 4.5).offset(x: 2, y: 6)
            Circle().fill(Color.pink.opacity(0.40)).frame(width: 2.5, height: 2.5).offset(x: -5, y: 6.5)
            Circle().fill(Color.pink.opacity(0.40)).frame(width: 2.5, height: 2.5).offset(x: 2, y: 6.5)

            // Rosy Blush
            Circle().fill(Color.pink.opacity(0.30)).frame(width: 4, height: 4).offset(x: -15, y: -2)

            // Sleeping 'z' bubbles
            Text("z").font(.system(size: 6, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.4)).offset(x: zzz ? 12 : 0, y: zzz ? -25 : -16).opacity(isNearEnd ? 0 : (zzz ? 0 : 0.5))
            Text("z").font(.system(size: 5, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.3)).offset(x: zzz ? 18 : 5, y: zzz ? -31 : -22).opacity(isNearEnd ? 0 : (zzz ? 0 : 0.35))

            // Near-End Alert '?'
            if isNearEnd {
                Text("?").font(.system(size: 7, weight: .bold, design: .rounded))
                    .foregroundColor(Color.p3(h: 0.72, s: 0.45, b: 1.0, a: 0.7, level: .rimHighlight)).offset(x: 0, y: -21)
            }
        }
        .animation(.easeInOut(duration: 0.6), value: isNearEnd)
        .onAppear {
            withAnimation(.easeInOut(duration: 2.8).repeatForever(autoreverses: true)) { breathe = true }
            withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) { fidget = true }
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) { purr = true }
            withAnimation(.easeInOut(duration: 3.5).repeatForever(autoreverses: true)) { tailSway = true }
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: false)) { zzz = true }
        }
    }
}

struct SleepingDodo: View {
    let isNearEnd: Bool
    @State private var breathe = false
    @State private var fidget = false
    @State private var zzz = false

    private let feather     = Color.p3(r: 0.38, g: 0.68, b: 0.74)
    private let featherDk   = Color.p3(r: 0.26, g: 0.52, b: 0.60)
    private let cream       = Color.p3(r: 0.96, g: 0.94, b: 0.88)
    private let beakAmber   = Color.p3(r: 0.98, g: 0.78, b: 0.38)
    private let beakTip     = Color.p3(r: 0.42, g: 0.78, b: 0.68)
    private let dark        = Color.p3(r: 0.14, g: 0.12, b: 0.18)

    var body: some View {
        ZStack {
            // Curly Fluffy Tail Tufts
            Circle().fill(cream.opacity(0.85)).frame(width: 8, height: 8).offset(x: 18, y: -2)
            Circle().fill(feather.opacity(0.9)).frame(width: 9, height: 9).offset(x: 16, y: 3)
            Circle().fill(cream.opacity(0.95)).frame(width: 7, height: 7).offset(x: 20, y: 1)

            // Plump Rotund Body
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [feather, featherDk],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 36, height: 26)
                .scaleEffect(y: breathe ? 1.05 : 1.0)
                .scaleEffect(x: breathe ? 0.98 : 1.0)

            // Creamy Breast & Belly Patch
            Ellipse()
                .fill(cream.opacity(0.75))
                .frame(width: 18, height: 14)
                .offset(x: -6, y: 5)

            // Little Cute Tucked Wing
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [featherDk, feather],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 16, height: 10)
                .rotationEffect(.degrees(-15))
                .offset(x: 4, y: 3)

            // Wing feather detail line
            Arc()
                .stroke(Color.white.opacity(0.35), lineWidth: 1)
                .frame(width: 10, height: 5)
                .rotationEffect(.degrees(-15))
                .offset(x: 3, y: 3)

            // Little Feet tucked in sleep
            Ellipse().fill(beakAmber).frame(width: 6, height: 4).offset(x: -8, y: 12)
            Ellipse().fill(beakAmber).frame(width: 6, height: 4).offset(x: 0, y: 12)

            // Cute Head Tuft / Feathers
            Triangle()
                .fill(feather)
                .frame(width: 5, height: 9)
                .rotationEffect(.degrees(isNearEnd ? (fidget ? -20 : -5) : -12))
                .offset(x: -18, y: -19)
            Triangle()
                .fill(cream)
                .frame(width: 4, height: 7)
                .rotationEffect(.degrees(isNearEnd ? (fidget ? 18 : 2) : 8))
                .offset(x: -14, y: -20)

            // Round Head
            Circle()
                .fill(feather)
                .frame(width: 20, height: 20)
                .offset(x: -12, y: -7)

            // Bulbous Curved Dodo Beak
            Ellipse()
                .fill(beakAmber)
                .frame(width: 13, height: 8)
                .rotationEffect(.degrees(12))
                .offset(x: -24, y: -4)

            // Characteristic Curved Beak Hook (Mint tip)
            Circle()
                .fill(beakTip)
                .frame(width: 7, height: 7)
                .offset(x: -28, y: -2)

            // Beak nostril dot
            Circle()
                .fill(dark.opacity(0.6))
                .frame(width: 1.5, height: 1.5)
                .offset(x: -22, y: -5)

            // Sleeping Eye or Alert Eye
            if isNearEnd {
                Capsule()
                    .fill(Color.p3(h: 0.12, s: 0.8, b: 0.9, level: .rimHighlight))
                    .frame(width: 3, height: 1.5)
                    .offset(x: -14, y: -8)
            } else {
                Arc()
                    .stroke(dark.opacity(0.75), lineWidth: 1.2)
                    .frame(width: 4.5, height: 2.5)
                    .rotationEffect(.degrees(180))
                    .offset(x: -14, y: -8)
            }

            // Rosy Cheek Blush
            Circle()
                .fill(Color.pink.opacity(0.35))
                .frame(width: 4.5, height: 4.5)
                .offset(x: -18, y: -2)

            // Sleeping 'z' bubbles
            Text("z").font(.system(size: 7, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.4)).offset(x: zzz ? 12 : 0, y: zzz ? -26 : -16).opacity(isNearEnd ? 0 : (zzz ? 0 : 0.5))
            Text("z").font(.system(size: 5, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.3)).offset(x: zzz ? 18 : 6, y: zzz ? -32 : -22).opacity(isNearEnd ? 0 : (zzz ? 0 : 0.35))

            // Near-End Alert '?'
            if isNearEnd {
                Text("?").font(.system(size: 8, weight: .bold, design: .rounded))
                    .foregroundColor(Color.p3(h: 0.50, s: 0.7, b: 1.0, a: 0.8, level: .rimHighlight)).offset(x: -6, y: -23)
            }
        }
        .animation(.easeInOut(duration: 0.6), value: isNearEnd)
        .onAppear {
            withAnimation(.easeInOut(duration: 2.9).repeatForever(autoreverses: true)) { breathe = true }
            withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) { fidget = true }
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: false)) { zzz = true }
        }
    }
}

// ===================================================================
// MARK: - Animated Scene with Orbiting Companions
// ===================================================================

struct AnimatedScene: View {
    @ObservedObject var timerModel: SlumberTimer
    let companionType: Int
    @Environment(\.colorScheme) var colorScheme

    @State private var orbitStartTime: Date? = nil
    @State private var orbitProgress:  CGFloat = 0.0
    @State private var isVisible:      Bool = true

    // 90 s per full lap around the moon
    private let orbitDuration: Double = 90.0

    // Elliptical orbit — wider than tall gives a natural tilted-plane feel
    private let orbitRadiusX: CGFloat = 56
    private let orbitRadiusY: CGFloat = 28

    // Scene anchor positions
    private let cloudX: CGFloat =  -95
    private let cloudY: CGFloat =  146
    private let moonX:  CGFloat =   95
    private let moonY:  CGFloat = -135

    var body: some View {
        ZStack {
            if isVisible {
                ConstellationOverlay().opacity(1.0)
                AuroraEffect().opacity(1.0)
                StarField(count: 45).opacity(1.0)
                FireflyField(count: 8).opacity(1.0)

                ShootingStar(angle: 32,  cycleDuration: 4.0, initialDelay:  1.0, length: 50, startX: -60, startY:  20)
                ShootingStar(angle: 45,  cycleDuration: 5.5, initialDelay:  4.0, length: 35, startX:  80, startY: -30)
                ShootingStar(angle: 25,  cycleDuration: 3.8, initialDelay:  7.0, length: 45, startX: -20, startY: -50)
                ShootingStar(angle: 38,  cycleDuration: 6.0, initialDelay: 10.5, length: 40, startX:  40, startY:  60)
                ShootingStar(angle: 18,  cycleDuration: 4.5, initialDelay: 14.0, length: 55, startX: -90, startY: -80)

                CuteMoon().offset(x: moonX, y: moonY).opacity(1.0)

                // Kept at Y: 170 so companion rests perfectly on top when idle
                CuteCloud1(scale: 1.00).offset(x: cloudX, y: 170)
                CuteCloud2(scale: 0.75).offset(x: 105, y: -30)
            }

            // Companion — position, 360° space somersault tumble, depth & floating drift
            // all driven by real time inside TimelineView so values are continuous.
            if isVisible {
                TimelineView(.animation(paused: !isVisible || !timerModel.isRunning)) { timeline in
                    let t = timeline.date.timeIntervalSinceReferenceDate
                    let elapsed: Double = {
                        guard let start = orbitStartTime else { return 0 }
                        return max(0, t - start.timeIntervalSinceReferenceDate)
                    }()

                    // --- Keplerian Orbital Path around Moon ---
                    let baseAngle = (elapsed / orbitDuration) * 360.0
                    let baseRad = baseAngle * .pi / 180.0
                    // Keplerian speed adjustment: speeds up in front / slows down behind
                    let angle = baseAngle - 12.0 * cos(baseRad)
                    let rad = angle * .pi / 180.0

                    // Orbit target position around moon
                    let orbitX = moonX + CGFloat(cos(rad)) * orbitRadiusX
                    let orbitY = moonY + CGFloat(sin(rad)) * orbitRadiusY

                    // Smooth transition between idle (cloud) and orbit target
                    let targetX = cloudX + (orbitX - cloudX) * orbitProgress
                    let targetY = cloudY + (orbitY - cloudY) * orbitProgress

                    // --- Zero-Gravity Harmonic Space Float & Micro-Drift ---
                    let idleBobY = CGFloat(sin(t * 1.2)) * 1.5 * (1.0 - orbitProgress)
                    let zeroGDriftX = CGFloat(cos(t * 1.3 + 0.4)) * 5.0 * orbitProgress
                    let zeroGDriftY = CGFloat(sin(t * 1.8)) * 6.5 * orbitProgress
                    let finalX = targetX + zeroGDriftX
                    let finalY = targetY + idleBobY + zeroGDriftY

                    // --- Zero-Gravity 360° Axis Somersault Tumble Physics ---
                    // In orbit, companion does a slow, playful 360° cartoon space tumble (~6.5s per rotation)
                    let tumbleSpeed = 360.0 / 6.5
                    let continuousTumble = (elapsed * tumbleSpeed).truncatingRemainder(dividingBy: 360.0)
                    let spaceWobble = sin(elapsed * 2.2) * 12.0
                    let zeroGRotation = continuousTumble + spaceWobble

                    // When idle on cloud: gentle subtle breathing tilt
                    let idleTilt = sin(t * 1.0) * 2.0
                    let finalRotation = idleTilt * (1.0 - Double(orbitProgress)) + zeroGRotation * Double(orbitProgress)

                    // --- Depth Scale (Perspective & Orbit Scaling) ---
                    let depthMod = 1.0 + 0.15 * CGFloat(sin(rad)) * orbitProgress
                    let baseScale: CGFloat = {
                        switch companionType {
                        case 0:  return (0.65 - 0.15 * orbitProgress) // Fox
                        case 1:  return (0.82 - 0.12 * orbitProgress) // Cat
                        default: return (0.75 - 0.14 * orbitProgress) // Dodo
                        }
                    }()
                    let finalScale = baseScale * depthMod

                    // --- Near-end alert ---
                    let nearEnd = timerModel.isRunning
                        && timerModel.timeRemaining < 60
                        && timerModel.timeRemaining > 0

                    Group {
                        switch companionType {
                        case 0:  SleepingFox(isNearEnd: nearEnd)
                        case 1:  SleepingCat(isNearEnd: nearEnd)
                        default: SleepingDodo(isNearEnd: nearEnd)
                        }
                    }
                    .scaleEffect(finalScale)
                    .rotationEffect(.degrees(finalRotation))
                    .offset(x: finalX, y: finalY)
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(
            for: .slumberOpening)
        ) { _ in
            isVisible = true
            syncSceneState()
        }
        .onReceive(NotificationCenter.default.publisher(
            for: .slumberClosed)
        ) { _ in
            isVisible = false
        }
        .onAppear   { syncSceneState() }
        .onChange(of: isVisible) { _, visible in if visible { syncSceneState() } }
        .onChange(of: timerModel.isRunning) { _, running in
            if running {
                let total = timerModel.totalTime
                let remaining = timerModel.timeRemaining
                let elapsed = total - remaining
                orbitStartTime = Date().addingTimeInterval(-elapsed)
                withAnimation(.spring(response: 1.0, dampingFraction: 0.72)) {
                    orbitProgress = 1.0
                }
            } else {
                withAnimation(.spring(response: 0.8, dampingFraction: 0.75)) {
                    orbitProgress = 0.0
                }
            }
        }
    }

    private func syncSceneState() {
        if timerModel.isRunning {
            let total = timerModel.totalTime
            let remaining = timerModel.timeRemaining
            let elapsed = total - remaining
            orbitStartTime = Date().addingTimeInterval(-elapsed)
            orbitProgress = 1.0
        } else {
            orbitProgress  = 0.0
        }
    }
}

// ===================================================================
// MARK: - Pulsing Ring
// ===================================================================

struct PulsingRing: View {
    let progress: CGFloat
    @State private var pulse = false

    var body: some View {
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
                            Color.p3(h: 0.53, s: 0.70, b: 0.98, level: .subtleHighlight),
                            Color.p3(h: 0.75, s: 0.75, b: 0.95, level: .subtleHighlight),
                            Color.p3(h: 0.88, s: 0.65, b: 0.92, level: .subtleHighlight),
                            Color.p3(h: 0.53, s: 0.70, b: 0.98, level: .subtleHighlight)
                        ]),
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(lineWidth: 4.5, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .frame(width: 170, height: 170)
                .shadow(color: Color.p3(h: 0.55, s: 0.6, b: 0.98, level: .subtleHighlight).opacity(0.4), radius: 6)

            // Glow dot at leading edge
            Circle()
                .fill(Color.p3(h: 0.53, s: 0.40, b: 1.0, level: .subtleHighlight))
                .frame(width: 7, height: 7)
                .shadow(color: Color.p3(h: 0.53, s: 0.6, b: 1.0, level: .subtleHighlight).opacity(0.8), radius: 4)
                .offset(y: -85)
                .rotationEffect(.degrees(Double(progress) * 360))
        }
    }
}

// ===================================================================
// MARK: - Visual Effect View (Glassmorphism Backdrop)
// ===================================================================

struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        view.appearance = NSAppearance(named: .vibrantDark)
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        if nsView.material != material { nsView.material = material }
        if nsView.blendingMode != blendingMode { nsView.blendingMode = blendingMode }
    }
}

// ===================================================================
// MARK: - Custom Interactive Components
// ===================================================================

struct GlowingSlider: View {
    @Binding var value: Int
    let bounds: ClosedRange<Int>
    let onEditingChanged: (Bool) -> Void
    @Environment(\.colorScheme) var colorScheme
    private var chrome: Color { colorScheme == .dark ? .white : .black }
    
    @State private var isDragging = false
    @State private var isHovered = false
    
    // Slumber is a fixed 320 width popover, slider has 24 horizontal padding
    private let sliderWidth: CGFloat = 272.0
    private let thumbSize: CGFloat = 16.0
    private let trackHeight: CGFloat = 7.0
    
    var body: some View {
        let totalRange = Double(bounds.upperBound - bounds.lowerBound)
        let percentage = totalRange > 0 ? max(0, min(1.0, CGFloat(Double(value - bounds.lowerBound) / totalRange))) : 0
        let trackTravel: CGFloat = sliderWidth - thumbSize
        let thumbOffset = percentage * trackTravel
        let trackFillWidth = max(0, min(sliderWidth, thumbOffset + (thumbSize / 2.0)))
        
        ZStack(alignment: .leading) {
            // Background Track
            RoundedRectangle(cornerRadius: trackHeight / 2.0, style: .continuous)
                .fill(chrome.opacity(0.09))
                .frame(width: sliderWidth, height: trackHeight)
            
            // Filled Track with Glow
            RoundedRectangle(cornerRadius: trackHeight / 2.0, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.p3(h: 0.75, s: 0.65, b: 0.92, level: .sdr),
                            Color.p3(h: 0.53, s: 0.55, b: 0.97, level: .sdr)
                        ],
                        startPoint: .leading, endPoint: .trailing
                    )
                )
                .frame(width: trackFillWidth, height: trackHeight)
                .shadow(color: Color.p3(h: 0.65, s: 0.6, b: 0.95, level: isDragging ? .subtleHighlight : .sdr).opacity(isDragging ? 0.6 : (isHovered ? 0.4 : 0.2)), radius: isDragging ? 8 : 4)
            
            // Thumb
            RoundedRectangle(cornerRadius: thumbSize / 2.0, style: .continuous)
                .fill(Color.white)
                .frame(width: thumbSize, height: thumbSize)
                .overlay(
                    RoundedRectangle(cornerRadius: thumbSize / 2.0, style: .continuous)
                        .stroke(Color.white.opacity(0.8), lineWidth: 0.5)
                )
                .shadow(color: Color.black.opacity(0.35), radius: 2.5, x: 0, y: 1)
                .shadow(color: Color.p3(h: 0.65, s: 0.6, b: 0.95, level: isDragging ? .subtleHighlight : .rimHighlight).opacity(0.45), radius: 6)
                .scaleEffect(isDragging ? 1.25 : (isHovered ? 1.12 : 1.0))
                .offset(x: thumbOffset)
        }
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
        .frame(width: sliderWidth, height: thumbSize)
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }
}

struct TabButton: View {
    let title: String
    let icon: String
    let tag: Int
    @Binding var currentTab: Int
    var animationNamespace: Namespace.ID
    @State private var isHovered = false
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    
    var body: some View {
        let active = currentTab == tag
        Button {
            playSound("space_button")
            withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
                currentTab = tag
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
                Text(title)
                    .font(.system(size: 13, weight: active ? .bold : .medium, design: .rounded))
            }
            .foregroundColor(active ? .white : (isHovered ? .white.opacity(0.85) : .white.opacity(reduceTransparency ? 0.65 : 0.45)))
            .padding(.vertical, 7)
            .padding(.horizontal, 16)
            .background {
                if active {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(reduceTransparency ? Color(red: 0.24, green: 0.20, blue: 0.36) : Color.p3(h: 0.75, s: 0.65, b: 0.92).opacity(0.16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(
                                    reduceTransparency ? Color.white.opacity(0.45) : Color.white.opacity(0.30),
                                    lineWidth: reduceTransparency ? 1.0 : 0.75
                                )
                        )
                        .matchedGeometryEffect(id: "activeTabIndicator", in: animationNamespace)
                } else if isHovered {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(reduceTransparency ? Color.white.opacity(0.12) : Color.white.opacity(0.05))
                }
            }
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.18)) {
                isHovered = hovering
            }
        }
    }
}

struct PresetChip: View {
    let label: String
    let value: Int
    @Binding var selectedMinutes: Int
    let accent: Color
    @State private var isHovered = false
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    
    var body: some View {
        let selected = selectedMinutes == value
        Button {
            if !selected { playSound("space_button") }
            withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) { selectedMinutes = value }
        } label: {
            Text(label)
                .font(.system(size: 12, weight: selected ? .bold : .medium, design: .rounded))
                .frame(width: 44, height: 32)
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(
                                selected
                                    ? (reduceTransparency ? Color(red: 0.38, green: 0.32, blue: 0.55) : accent.opacity(0.34))
                                    : (isHovered ? (reduceTransparency ? Color.white.opacity(0.18) : Color.white.opacity(0.10)) : (reduceTransparency ? Color.white.opacity(0.12) : Color.white.opacity(0.065)))
                            )
                        
                        if selected && !reduceTransparency {
                            VStack {
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(LinearGradient(colors: [Color.white.opacity(0.22), Color.clear], startPoint: .top, endPoint: .bottom))
                                    .frame(height: 10)
                                Spacer()
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                    }
                )
                .foregroundColor(selected ? .white : (isHovered ? .white : .white.opacity(reduceTransparency ? 0.85 : 0.65)))
                .scaleEffect(selected ? 1.04 : (isHovered ? 1.02 : 1.0))
                .overlay {
                    if reduceTransparency {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(selected ? Color.white.opacity(0.6) : Color.white.opacity(0.25), lineWidth: 1.0)
                    } else {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(selected ? 0.38 : (isHovered ? 0.20 : 0.10)),
                                        Color.white.opacity(0.03)
                                    ],
                                    startPoint: .topLeading, endPoint: .bottomTrailing
                                ),
                                lineWidth: 0.75
                            )
                    }
                }
                .shadow(color: selected ? accent.opacity(0.25) : .clear, radius: 6)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.18)) {
                isHovered = hovering
            }
        }
    }
}

// ===================================================================
// MARK: - Error Banner Component
// ===================================================================

struct ErrorBanner: View {
    let reason: String
    let onRetry: () -> Void
    let onDismiss: () -> Void
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color.p3(h: 0.08, s: 0.85, b: 0.98, level: .rimHighlight))
            
            Text(reason)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.95))
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
            
            Button(action: onRetry) {
                Text("Retry")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        ZStack {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(reduceTransparency ? Color(red: 0.35, green: 0.20, blue: 0.12) : Color.p3(h: 0.08, s: 0.75, b: 0.65).opacity(0.35))
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(Color.white.opacity(reduceTransparency ? 0.45 : 0.25), lineWidth: 0.75)
                        }
                    )
            }
            .buttonStyle(.plain)
            
            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(reduceTransparency ? 0.7 : 0.4))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(
            ZStack {
                if reduceTransparency {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(red: 0.16, green: 0.10, blue: 0.09))
                } else {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.black.opacity(0.45))
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.white.opacity(0.06))
                }
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(
                        Color.p3(h: 0.08, s: 0.85, b: 0.98).opacity(reduceTransparency ? 0.7 : 0.4),
                        lineWidth: reduceTransparency ? 1.0 : 0.75
                    )
            }
        )
        .shadow(color: Color.black.opacity(0.35), radius: 10, y: 4)
    }
}

struct StartButton: View {
    let action: () -> Void
    let accent: Color
    let cyan: Color
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 7) {
                Image(systemName: "bed.double.fill").font(.system(size: 13, weight: .semibold))
                Text("Start Sleep Timer").font(.system(size: 14, weight: .bold, design: .rounded))
            }
            .frame(width: 210, height: 42)
            .background(
                LinearGradient(
                    colors: [
                        accent.opacity(isHovered ? 1.0 : 0.92),
                        cyan.opacity(isHovered ? 1.0 : 0.92)
                    ],
                    startPoint: .leading, endPoint: .trailing
                )
            )
            .foregroundColor(.white)
            .cornerRadius(12)
            .scaleEffect(isHovered ? 1.03 : 1.0)
            .shadow(color: accent.opacity(isHovered ? 0.55 : 0.35), radius: isHovered ? 14 : 10, x: 0, y: isHovered ? 4 : 2)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                isHovered = hovering
            }
        }
    }
}

struct CancelButton: View {
    let action: () -> Void
    @State private var isHovered = false
    private let coral = Color.p3(h: 0.98, s: 0.60, b: 0.95)
    
    var body: some View {
        Button(action: action) {
            Text("Cancel")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .frame(width: 120, height: 38)
                .background(coral.opacity(isHovered ? 0.25 : 0.15))
                .foregroundColor(coral)
                .cornerRadius(12)
                .scaleEffect(isHovered ? 1.03 : 1.0)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(coral.opacity(isHovered ? 0.45 : 0.25), lineWidth: 0.75)
                )
                .shadow(color: coral.opacity(isHovered ? 0.20 : 0), radius: 8)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                isHovered = hovering
            }
        }
    }
}

struct QuitButton: View {
    let action: () -> Void
    @State private var isHovered = false
    private let coral = Color.p3(h: 0.98, s: 0.60, b: 0.95)
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: "power").font(.system(size: 12, weight: .semibold))
                Text("Quit Slumber").font(.system(size: 13, weight: .medium, design: .rounded))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 38)
            .background(coral.opacity(isHovered ? 0.18 : 0.08))
            .foregroundColor(coral)
            .cornerRadius(12)
            .scaleEffect(isHovered ? 1.02 : 1.0)
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(coral.opacity(isHovered ? 0.30 : 0.16), lineWidth: 0.75)
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                isHovered = hovering
            }
        }
    }
}

struct SettingsCard<Content: View>: View {
    let content: Content
    @State private var isHovered = false
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(reduceTransparency ? Color(red: 0.14, green: 0.13, blue: 0.21) : Color.white.opacity(isHovered ? 0.06 : 0.035))
            .cornerRadius(14)
            .scaleEffect(isHovered ? 1.01 : 1.0)
            .overlay {
                if reduceTransparency {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.white.opacity(isHovered ? 0.35 : 0.22), lineWidth: 1.0)
                } else {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(isHovered ? 0.20 : 0.12),
                                    Color.white.opacity(0.03)
                                ],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.75
                        )
                }
            }
            .onHover { hovering in
                withAnimation(.easeOut(duration: 0.18)) {
                    isHovered = hovering
                }
            }
    }
}

// ===================================================================
// MARK: - Main Slumber Container View
// ===================================================================

struct SlumberView: View {
    @ObservedObject var timerModel: SlumberTimer
    @AppStorage("showInDock") private var showInDock: Bool = false
    @State private var selectedMinutes: Int = 15
    @State private var currentTab = 0
    @State private var companionType: Int = Int.random(in: 0...2)
    @Namespace private var tabNamespace
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    private let accent = Color.p3(h: 0.75, s: 0.65, b: 0.92)
    private let cyan   = Color.p3(h: 0.53, s: 0.55, b: 0.97)

    private var skyPhase: Int {
        let m = timerModel.isRunning ? Int(timerModel.totalTime / 60.0) : selectedMinutes
        if m <= 20 { return 0 }     // Sunset Glow (1-20 min)
        if m <= 38 { return 1 }     // Evening Twilight (21-38 min)
        if m <= 50 { return 2 }     // Late Dusk (39-50 min)
        if m <= 75 { return 3 }     // Midnight Blue (51-75 min)
        return 4                    // Deep Cosmic Space (76-120 min)
    }

    private var skyTop: Color {
        switch skyPhase {
        case 0:  return Color.p3(h: 0.83, s: 0.50, b: 0.24)
        case 1:  return Color.p3(h: 0.70, s: 0.72, b: 0.20)
        case 2:  return Color.p3(r: 0.05, g: 0.04, b: 0.14)
        case 3:  return Color.p3(r: 0.02, g: 0.03, b: 0.12)
        default: return Color.p3(r: 0.005, g: 0.002, b: 0.02)
        }
    }

    private var skyBot: Color {
        switch skyPhase {
        case 0:  return Color.p3(h: 0.88, s: 0.60, b: 0.10)
        case 1:  return Color.p3(h: 0.78, s: 0.55, b: 0.12)
        case 2:  return Color.p3(r: 0.14, g: 0.08, b: 0.22)
        case 3:  return Color.p3(r: 0.05, g: 0.05, b: 0.25)
        default: return Color.p3(h: 0.76, s: 0.90, b: 0.06)
        }
    }

    var body: some View {
        ZStack {
            if reduceTransparency {
                Color(red: 0.07, green: 0.06, blue: 0.12)
            } else {
                VisualEffectView(material: .popover, blendingMode: .behindWindow)
            }

            LinearGradient(
                colors: [
                    skyTop.opacity(reduceTransparency ? 1.0 : 0.65),
                    skyBot.opacity(reduceTransparency ? 1.0 : 0.75)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .animation(.easeInOut(duration: 1.0), value: skyPhase)

            AnimatedScene(
                timerModel: timerModel,
                companionType: companionType
            )
            .opacity(currentTab == 0 ? 1 : 0)
            .animation(.easeInOut(duration: 0.3), value: currentTab)

            VStack(spacing: 0) {
                HStack(spacing: 4) {
                    TabButton(title: "Timer", icon: "moon.zzz", tag: 0, currentTab: $currentTab, animationNamespace: tabNamespace)
                    TabButton(title: "Settings", icon: "gearshape", tag: 1, currentTab: $currentTab, animationNamespace: tabNamespace)
                }
                .padding(3)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(reduceTransparency ? Color(red: 0.13, green: 0.12, blue: 0.19) : Color.white.opacity(0.05))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(reduceTransparency ? Color.white.opacity(0.22) : Color.white.opacity(0.08), lineWidth: 0.5)
                )
                .padding(.top, 16)
                .padding(.horizontal, 16)

                ZStack {
                    if currentTab == 0 {
                        timerPage
                            .transition(.asymmetric(insertion: .move(edge: .leading).combined(with: .opacity), removal: .move(edge: .leading).combined(with: .opacity)))
                    } else {
                        settingsPage
                            .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .move(edge: .trailing).combined(with: .opacity)))
                    }
                }
                .animation(.spring(response: 0.35, dampingFraction: 0.8), value: currentTab)
            }
        }
        .frame(width: 320, height: 440)
        .fixedSize()
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .preferredColorScheme(.dark)
        .allowedDynamicRange(.high)
        .onChange(of: showInDock) { _, v in applyDock(v) }
    }

    private var timerPage: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 14) {
                Spacer()

                if timerModel.isRunning {
                    let total = timerModel.totalTime
                    let prog = total > 0 ? CGFloat(timerModel.timeRemaining / total) : 0

                    ZStack {
                        PulsingRing(progress: prog)
                        VStack(spacing: 4) {
                            Text(fmt(timerModel.timeRemaining))
                                .font(.system(size: 46, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .contentTransition(.numericText())
                            Text("drifting off...")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(.white.opacity(0.5))
                        }
                    }
                    .padding(.bottom, 10)

                    CancelButton(action: {
                        playSound("cancel")
                        timerModel.stop()
                    })
                } else {
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("\(selectedMinutes)")
                            .font(.system(size: 54, weight: .heavy, design: .rounded))
                            .foregroundColor(.white)
                            .contentTransition(.numericText())
                        Text("min")
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.5))
                    }

                    VStack(spacing: 6) {
                        GlowingSlider(value: $selectedMinutes, bounds: 1...120, onEditingChanged: { editing in
                            if !editing { playSound("space_button") }
                        })
                        .padding(.horizontal, 24)
                        HStack {
                            Text("1 min"); Spacer(); Text("120 min")
                        }
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.3))
                        .padding(.horizontal, 24)
                    }

                    HStack(spacing: 8) {
                        PresetChip(label: "15m", value: 15, selectedMinutes: $selectedMinutes, accent: accent)
                        PresetChip(label: "30m", value: 30, selectedMinutes: $selectedMinutes, accent: accent)
                        PresetChip(label: "45m", value: 45, selectedMinutes: $selectedMinutes, accent: accent)
                        PresetChip(label: "60m", value: 60, selectedMinutes: $selectedMinutes, accent: accent)
                        PresetChip(label: "90m", value: 90, selectedMinutes: $selectedMinutes, accent: accent)
                    }

                    StartButton(action: {
                        playSound("space_timer_start")
                        companionType = Int.random(in: 0...2)
                        timerModel.start(minutes: Double(selectedMinutes))
                    }, accent: accent, cyan: cyan)
                    .padding(.top, 6)
                }

                Spacer()
            }

            if case let .sleepFailed(reason) = timerModel.state {
                ErrorBanner(
                    reason: reason,
                    onRetry: { timerModel.retrySleep() },
                    onDismiss: { timerModel.clearStatus() }
                )
                .padding(.horizontal, 20)
                .padding(.top, 6)
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity).combined(with: .scale(scale: 0.95)),
                    removal: .move(edge: .top).combined(with: .opacity)
                ))
            }
        }
        .allowsHitTesting(currentTab == 0)
        .animation(.spring(response: 0.38, dampingFraction: 0.8), value: timerModel.state)
        .animation(.spring(response: 0.5, dampingFraction: 0.75), value: timerModel.isRunning)
    }

    private var settingsPage: some View {
        VStack(spacing: 0) {
            Text("Settings")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 24)
                .padding(.bottom, 20)

            SettingsCard {
                HStack(alignment: .center, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Show in Dock")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                        Text("Display dock icon alongside the menu bar.")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.45))
                            .lineSpacing(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer()
                    Toggle("", isOn: $showInDock)
                        .toggleStyle(.switch)
                        .tint(accent)
                        .labelsHidden()
                }
            }

            SettingsCard {
                HStack(alignment: .center, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Global Shortcut")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                        Text("Open Slumber from anywhere.")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.45))
                            .lineSpacing(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer()
                    HStack(spacing: 2) {
                        Text("⌃")
                        Text("⌥")
                        Text("S")
                    }
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.85))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(Color.white.opacity(0.10))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
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
            .padding(.top, 10)

            Spacer()

            QuitButton(action: {
                NSApp.terminate(nil)
            })
            .padding(.bottom, 12)

            Text("Slumber v3.0")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.40))
                .frame(maxWidth: .infinity, alignment: .center)
            Text("Made with ❤️ for peaceful nights")
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.32))
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 2)
                .padding(.bottom, 12)
        }
        .padding(.horizontal, 24)
        .allowsHitTesting(currentTab == 1)
        .preferredColorScheme(.dark)
    }

    private func fmt(_ t: TimeInterval) -> String {
        let hrs = Int(t) / 3600
        let mins = (Int(t) % 3600) / 60
        let secs = Int(t) % 60
        if hrs > 0 {
            return String(format: "%d:%02d:%02d", hrs, mins, secs)
        } else {
            return String(format: "%02d:%02d", mins, secs)
        }
    }

    private func applyDock(_ show: Bool) {
        DispatchQueue.main.async {
            NSApp.setActivationPolicy(show ? .regular : .accessory)
            if show {
                NSApp.activate(ignoringOtherApps: true)
            }
        }
    }
}
