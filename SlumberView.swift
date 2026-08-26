import SwiftUI
import AppKit

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
// MARK: - Display P3 Wide-Gamut + HDR Color Helpers
// ===================================================================

extension Color {
    static func p3(h: Double, s: Double, b: Double, a: Double = 1) -> Color {
        let c = b * s
        let hp = abs(h).truncatingRemainder(dividingBy: 1) * 6
        let x = c * (1 - abs(hp.truncatingRemainder(dividingBy: 2) - 1))
        let m = b - c
        let r: Double, g: Double, bl: Double
        switch Int(hp) % 6 {
        case 0:  r = c;  g = x;  bl = 0
        case 1:  r = x;  g = c;  bl = 0
        case 2:  r = 0;  g = c;  bl = x
        case 3:  r = 0;  g = x;  bl = c
        case 4:  r = x;  g = 0;  bl = c
        default: r = c;  g = 0;  bl = x
        }
        return Color(.displayP3, red: r + m, green: g + m, blue: bl + m, opacity: a)
    }

    static func p3(r: Double, g: Double, b: Double, a: Double = 1) -> Color {
        Color(.displayP3, red: r, green: g, blue: b, opacity: a)
    }
}

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
        .shadow(color: Color.p3(h: 0.75, s: 0.25, b: 1.0, a: on ? 0.35 : 0), radius: on ? (isSparkle ? 4 : 2) : 0)
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
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.p3(h: 0.75, s: 0.25, b: 0.95, a: 0),
                                Color.p3(h: 0.72, s: 0.15, b: 1.0, a: 0.35)
                            ],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    .frame(width: length * 0.85, height: 1.0)
                    .blur(radius: 0.3)
                    .rotationEffect(.degrees(angle))
                    .offset(
                        x: startX + CGFloat(cos(rad)) * travel * CGFloat(progress),
                        y: startY + CGFloat(sin(rad)) * travel * CGFloat(progress)
                    )
                    .opacity(
                        progress < 0.12
                             ? (progress / 0.12) * 0.4
                             : (progress > 0.55 ? max(0, ((1 - progress) / 0.45) * 0.4) : 0.4)
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
    @State private var drift = false

    private var hue: Double {
        switch seed % 3 {
        case 0: return 0.08
        case 1: return 0.75
        default: return 0.52
        }
    }

    private var glowColor: Color {
        switch seed % 3 {
        case 0: return Color.p3(r: 1.4, g: 1.0, b: 0.35, a: 0.85) // High-HDR Gold
        case 1: return Color.p3(r: 1.2, g: 0.8, b: 1.4, a: 0.85)  // High-HDR Violet
        default: return Color.p3(r: 0.45, g: 1.3, b: 1.4, a: 0.85) // High-HDR Cyan
        }
    }

    private var baseX: CGFloat { seededRandom(seed: seed * 3, max: bounds.width * 0.8) + bounds.width * 0.1 }
    private var baseY: CGFloat { seededRandom(seed: seed * 7, max: bounds.height * 0.6) + bounds.height * 0.2 }
    private var driftDX: CGFloat { seededRandom(seed: seed * 11, max: 30) - 15 }
    private var driftDY: CGFloat { seededRandom(seed: seed * 13, max: 20) - 10 }

    var body: some View {
        Circle()
            .fill(Color.p3(h: hue, s: 0.5, b: 1.0))
            .frame(width: 2.5, height: 2.5)
            .shadow(color: glowColor, radius: drift ? 8 : 2)
            .opacity(drift ? 0.7 : 0.15)
            .position(
                x: baseX + (drift ? driftDX : 0),
                y: baseY + (drift ? driftDY : 0)
            )
            .onAppear {
                withAnimation(
                    .easeInOut(duration: Double(4 + seed % 3))
                    .repeatForever(autoreverses: true)
                    .delay(Double(seed) * 0.6)
                ) { drift = true }
            }
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
                        .shadow(color: Color.p3(h: 0.75, s: 0.3, b: 1.0, a: pulse ? 0.35 : 0.1), radius: pulse ? 3 : 1)
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
                        colors: [Color.p3(h: 0.75, s: 0.4, b: 1.0, a: 0.3), .clear],
                        center: .center, startRadius: 10, endRadius: 40
                    )
                )
                .frame(width: 80, height: 80)
                .scaleEffect(glow ? 1.15 : 1.0)

            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.p3(h: 0.73, s: 0.35, b: 0.95), Color.p3(h: 0.78, s: 0.45, b: 0.80)],
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
                        colors: [Color.white.opacity(0.9), Color.white.opacity(0.1)],
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
                        colors: [Color.white.opacity(0.4), Color.white.opacity(0.08)],
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
            Ellipse().fill(LinearGradient(colors: [Color.p3(h: 0.75, s: 0.65, b: 0.7, a: 0.08), Color.p3(h: 0.72, s: 0.5, b: 0.7, a: 0.03)], startPoint: .leading, endPoint: .trailing)).frame(width: 320, height: 100).blur(radius: 45).offset(x: s1 ? 20 : -20, y: s1 ? -15 : 15)
            Ellipse().fill(LinearGradient(colors: [Color.p3(h: 0.55, s: 0.55, b: 0.7, a: 0.07), Color.p3(h: 0.60, s: 0.4, b: 0.7, a: 0.02)], startPoint: .trailing, endPoint: .leading)).frame(width: 260, height: 80).blur(radius: 40).offset(x: s2 ? -30 : 15, y: s2 ? 30 : -10)
            Ellipse().fill(Color.p3(h: 0.82, s: 0.55, b: 0.65, a: 0.05)).frame(width: 180, height: 60).blur(radius: 35).offset(x: s3 ? 10 : -15, y: s3 ? -30 : 20)
            Ellipse().fill(LinearGradient(colors: [Color.p3(h: 0.93, s: 0.50, b: 0.7, a: 0.05), Color.p3(h: 0.88, s: 0.40, b: 0.7, a: 0.02)], startPoint: .top, endPoint: .bottom)).frame(width: 220, height: 70).blur(radius: 40).offset(x: s4 ? -20 : 25, y: s4 ? 20 : -25)
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
// MARK: - Characters
// ===================================================================

struct SleepingFox: View {
    let isNearEnd: Bool
    @State private var breathe = false
    @State private var fidget = false
    @State private var zzz = false

    private let fur     = Color.p3(r: 0.93, g: 0.50, b: 0.15)
    private let furDk   = Color.p3(r: 0.78, g: 0.35, b: 0.10)
    private let cream   = Color.p3(r: 0.98, g: 0.93, b: 0.85)
    private let dark    = Color.p3(r: 0.12, g: 0.08, b: 0.06)

    var body: some View {
        ZStack {
            Capsule().fill(LinearGradient(colors: [fur, furDk], startPoint: .leading, endPoint: .trailing)).frame(width: 38, height: 11).rotationEffect(.degrees(-22)).offset(x: 20, y: 3)
            Ellipse().fill(fur.opacity(0.9)).frame(width: 16, height: 13).offset(x: 34, y: -3)
            Ellipse().fill(cream.opacity(0.9)).frame(width: 10, height: 8).offset(x: 38, y: -5)
            Ellipse().fill(LinearGradient(colors: [fur, furDk], startPoint: .topLeading, endPoint: .bottomTrailing)).frame(width: 38, height: 22).scaleEffect(y: breathe ? 1.04 : 1.0)
            Ellipse().fill(cream.opacity(0.65)).frame(width: 18, height: 10).offset(x: -5, y: 4)
            Ellipse().fill(fur.opacity(0.85)).frame(width: 6, height: 5).offset(x: -9, y: 7)
            Ellipse().fill(fur.opacity(0.85)).frame(width: 6, height: 5).offset(x: -3, y: 8)
            Circle().fill(fur).frame(width: 22, height: 22).offset(x: -14, y: -7)
            Triangle().fill(fur).frame(width: 9, height: 15).rotationEffect(.degrees(isNearEnd ? (fidget ? -22 : 0) : -8)).offset(x: -22, y: -20)
            Triangle().fill(Color.pink.opacity(0.40)).frame(width: 5, height: 9).rotationEffect(.degrees(-8)).offset(x: -22, y: -18)
            Triangle().fill(dark.opacity(0.5)).frame(width: 5, height: 4).rotationEffect(.degrees(-8)).offset(x: -22, y: -25)
            Triangle().fill(fur).frame(width: 9, height: 15).rotationEffect(.degrees(isNearEnd ? (fidget ? 16 : -2) : 6)).offset(x: -9, y: -21)
            Triangle().fill(Color.pink.opacity(0.40)).frame(width: 5, height: 9).rotationEffect(.degrees(6)).offset(x: -9, y: -19)
            Triangle().fill(dark.opacity(0.5)).frame(width: 5, height: 4).rotationEffect(.degrees(6)).offset(x: -9, y: -26)
            Ellipse().fill(cream).frame(width: 13, height: 7).offset(x: -23, y: -4)
            Circle().fill(dark).frame(width: 3, height: 3).offset(x: -28, y: -5)

            if isNearEnd {
                Capsule().fill(Color.p3(h: 0.10, s: 0.8, b: 0.85)).frame(width: 3, height: 1.5).offset(x: -18, y: -9)
                Capsule().fill(Color.p3(h: 0.10, s: 0.8, b: 0.85)).frame(width: 3, height: 1.5).offset(x: -12, y: -9)
            } else {
                Arc().stroke(dark.opacity(0.7), lineWidth: 1.2).frame(width: 5, height: 2.5).rotationEffect(.degrees(180)).offset(x: -18, y: -9)
                Arc().stroke(dark.opacity(0.7), lineWidth: 1.2).frame(width: 5, height: 2.5).rotationEffect(.degrees(180)).offset(x: -12, y: -9)
            }

            Circle().fill(Color.pink.opacity(0.30)).frame(width: 5, height: 5).offset(x: -24, y: -1)

            Text("z").font(.system(size: 7, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.4)).offset(x: zzz ? 14 : 2, y: zzz ? -28 : -18).opacity(isNearEnd ? 0 : (zzz ? 0 : 0.5))
            Text("z").font(.system(size: 5, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.3)).offset(x: zzz ? 20 : 8, y: zzz ? -34 : -24).opacity(isNearEnd ? 0 : (zzz ? 0 : 0.35))

            if isNearEnd {
                Text("?").font(.system(size: 8, weight: .bold, design: .rounded))
                    .foregroundColor(Color.p3(h: 0.08, s: 0.6, b: 1.0, a: 0.65)).offset(x: -5, y: -23)
            }
        }
        .animation(.easeInOut(duration: 0.6), value: isNearEnd)
        .onAppear {
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) { breathe = true }
            withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) { fidget = true }
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: false)) { zzz = true }
        }
    }
}

struct SleepingCat: View {
    let isNearEnd: Bool
    @State private var breathe = false
    @State private var fidget = false
    @State private var purr = false
    @State private var zzz = false

    private let fur   = Color.p3(r: 0.52, g: 0.46, b: 0.68)
    private let furDk = Color.p3(r: 0.38, g: 0.33, b: 0.52)

    var body: some View {
        ZStack {
            Capsule().fill(LinearGradient(colors: [fur, furDk], startPoint: .leading, endPoint: .trailing)).frame(width: 22, height: 6).rotationEffect(.degrees(35)).offset(x: 14, y: 8)
            Capsule().fill(furDk).frame(width: 10, height: 5).rotationEffect(.degrees(80)).offset(x: 20, y: 3)
            Ellipse().fill(LinearGradient(colors: [fur, furDk], startPoint: .top, endPoint: .bottom)).frame(width: 30, height: 22).scaleEffect(y: breathe ? 1.04 : 1.0).scaleEffect(x: purr ? 1.01 : 0.99)
            Circle().fill(fur).frame(width: 16, height: 16).offset(x: -9, y: -6)
            Triangle().fill(fur).frame(width: 6, height: 10).rotationEffect(.degrees(isNearEnd ? (fidget ? -18 : -2) : -10)).offset(x: -15, y: -14)
            Triangle().fill(Color.pink.opacity(0.35)).frame(width: 3.5, height: 6).rotationEffect(.degrees(-10)).offset(x: -15, y: -13)
            Triangle().fill(fur).frame(width: 6, height: 10).rotationEffect(.degrees(isNearEnd ? (fidget ? 12 : -2) : 5)).offset(x: -5, y: -15)
            Triangle().fill(Color.pink.opacity(0.35)).frame(width: 3.5, height: 6).rotationEffect(.degrees(5)).offset(x: -5, y: -14)
            Triangle().fill(Color.pink.opacity(0.7)).frame(width: 3, height: 2).rotationEffect(.degrees(180)).offset(x: -12, y: -4)

            if isNearEnd {
                Capsule().fill(Color.p3(h: 0.35, s: 0.65, b: 0.85)).frame(width: 2.5, height: 1.5).offset(x: -12, y: -7)
                Capsule().fill(Color.p3(h: 0.35, s: 0.65, b: 0.85)).frame(width: 2.5, height: 1.5).offset(x: -7, y: -7)
            } else {
                Arc().stroke(Color.white.opacity(0.7), lineWidth: 1).frame(width: 4, height: 2).rotationEffect(.degrees(180)).offset(x: -12, y: -7)
                Arc().stroke(Color.white.opacity(0.7), lineWidth: 1).frame(width: 4, height: 2).rotationEffect(.degrees(180)).offset(x: -7, y: -7)
            }

            ForEach(0..<3, id: \.self) { i in
                Capsule().fill(Color.white.opacity(0.25)).frame(width: 8, height: 0.5).rotationEffect(.degrees(Double(i - 1) * 12 - 5)).offset(x: -18, y: -3 + CGFloat(i) * 2)
            }

            Ellipse().fill(fur.opacity(0.8)).frame(width: 5, height: 4).offset(x: -4, y: 5)
            Ellipse().fill(fur.opacity(0.8)).frame(width: 5, height: 4).offset(x: 3, y: 5)
            Circle().fill(Color.pink.opacity(0.25)).frame(width: 2.5, height: 2.5).offset(x: -4, y: 5.5)
            Circle().fill(Color.pink.opacity(0.25)).frame(width: 2.5, height: 2.5).offset(x: 3, y: 5.5)

            Text("z").font(.system(size: 6, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.4)).offset(x: zzz ? 12 : 0, y: zzz ? -25 : -16).opacity(isNearEnd ? 0 : (zzz ? 0 : 0.5))
            Text("z").font(.system(size: 5, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.3)).offset(x: zzz ? 18 : 5, y: zzz ? -31 : -22).opacity(isNearEnd ? 0 : (zzz ? 0 : 0.35))

            if isNearEnd {
                Text("?").font(.system(size: 7, weight: .bold, design: .rounded))
                    .foregroundColor(Color.p3(h: 0.72, s: 0.45, b: 1.0, a: 0.6)).offset(x: 0, y: -21)
            }
        }
        .animation(.easeInOut(duration: 0.6), value: isNearEnd)
        .onAppear {
            withAnimation(.easeInOut(duration: 2.8).repeatForever(autoreverses: true)) { breathe = true }
            withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) { fidget = true }
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) { purr = true }
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

    // 90 s per full lap
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

            // Companion — position, lean, depth & bob all driven by
            // real time inside TimelineView so values are continuous.
            if isVisible {
                TimelineView(.animation) { timeline in
                    let t = timeline.date.timeIntervalSinceReferenceDate

                    // --- Angle (advances continuously with wall clock) ---
                    // Keplerian speed adjustment: speeds up at front (closest/bottom) and slows down at back (farthest/top)
                    let baseAngle: Double = {
                        guard let start = orbitStartTime else { return 0 }
                        let elapsed = t - start.timeIntervalSinceReferenceDate
                        return (elapsed / orbitDuration) * 360
                    }()
                    let baseRad = baseAngle * .pi / 180
                    let angle = baseAngle - 10.0 * cos(baseRad)
                    let rad = angle * .pi / 180

                    // --- Elliptical orbit target position ---
                    let orbitX = moonX + CGFloat(cos(rad)) * orbitRadiusX
                    let orbitY = moonY + CGFloat(sin(rad)) * orbitRadiusY

                    // --- Lerp: cloud (idle) → orbit position (running) ---
                    let finalX = cloudX + (orbitX - cloudX) * orbitProgress
                    let finalY = cloudY + (orbitY - cloudY) * orbitProgress

                    // --- Depth scale: bigger at "front" (bottom), smaller at "back" (top) ---
                    // sin(rad) = +1 at bottom (near), −1 at top (far)
                    // Fades in with orbitProgress so it only applies during orbit
                    let depthMod = 1.0 + 0.12 * CGFloat(sin(rad)) * orbitProgress

                    // Base scale shrinks a little when orbiting (companion looks smaller near moon)
                    let baseScale: CGFloat = companionType == 0
                        ? (0.65 - 0.15 * orbitProgress)   // Fox  0.65 → 0.50
                        : (0.82 - 0.12 * orbitProgress)   // Cat  0.82 → 0.70

                    let finalScale = baseScale * depthMod

                    // --- Tangential lean ---
                    // −sin(angle) makes the companion rock left going up, right going down.
                    // Capped at ±18° so it never looks weird; fades in with orbitProgress.
                    let leanDegrees = -sin(rad) * 18.0 * Double(orbitProgress)

                    // --- Organic float bob ---
                    // Slow breathing bob on the cloud, blending to a faster float bob in orbit
                    let idleBob = CGFloat(sin(t * 1.0) * 1.5) * (1.0 - orbitProgress)
                    let orbitBob = CGFloat(sin(t * 1.8) * 2.8) * orbitProgress
                    let bobY = idleBob + orbitBob

                    // --- Near-end alert ---
                    let nearEnd = timerModel.isRunning
                        && timerModel.timeRemaining < 60
                        && timerModel.timeRemaining > 0

                    Group {
                        if companionType == 0 {
                            SleepingFox(isNearEnd: nearEnd)
                        } else {
                            SleepingCat(isNearEnd: nearEnd)
                        }
                    }
                    .scaleEffect(finalScale)
                    .rotationEffect(.degrees(leanDegrees))
                    .offset(x: finalX, y: finalY + bobY)
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
        .onReceive(NotificationCenter.default.publisher(
            for: NSWindow.didChangeOcclusionStateNotification)
        ) { notification in
            if let window = notification.object as? NSWindow {
                isVisible = window.occlusionState.contains(.visible)
                if isVisible { syncSceneState() }
            }
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
    @State private var colorShift = false

    var body: some View {
        ZStack {
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [Color.p3(h: colorShift ? 0.58 : 0.72, s: 0.6, b: 0.9), Color.p3(h: colorShift ? 0.72 : 0.58, s: 0.5, b: 0.95)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ),
                    lineWidth: 3
                )
                .frame(width: 170, height: 170)
                .scaleEffect(pulse ? 1.06 : 1.0)
                .opacity(pulse ? 0.35 : 0.15)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(colors: [Color.p3(h: 0.75, s: 0.7, b: 0.95), Color.p3(h: 0.55, s: 0.65, b: 1.0), Color.p3(h: 0.75, s: 0.7, b: 0.95)], center: .center),
                    style: StrokeStyle(lineWidth: 5, lineCap: .round)
                )
                .frame(width: 160, height: 160)
                .rotationEffect(.degrees(-90))
                .shadow(color: Color.p3(h: colorShift ? 0.55 : 0.72, s: 0.8, b: 1.1, a: 0.5), radius: 8)

            if progress > 0.01 {
                Circle()
                    .fill(Color.p3(r: 0.6, g: 1.1, b: 1.2))
                    .frame(width: 6, height: 6)
                    .shadow(color: Color.p3(r: 0.5, g: 1.0, b: 1.15), radius: 5)
                    .offset(y: -80)
                    .rotationEffect(.degrees(360 * Double(progress)))
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) { pulse = true }
            withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) { colorShift = true }
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
        nsView.material = material
        nsView.blendingMode = blendingMode
        nsView.appearance = NSAppearance(named: .vibrantDark)
    }
}

// ===================================================================
// MARK: - Custom Interactive Components
// ===================================================================

struct GlowingSlider: View {
    @Binding var value: Double
    let bounds: ClosedRange<Double>
    let onEditingChanged: (Bool) -> Void
    @Environment(\.colorScheme) var colorScheme
    private var chrome: Color { colorScheme == .dark ? .white : .black }
    
    @State private var isDragging = false
    @State private var isHovered = false
    
    // Slumber is a fixed 320 width popover, slider has 24 horizontal padding
    private let sliderWidth: CGFloat = 272.0
    
    var body: some View {
        let percentage = max(0, min(1.0, CGFloat((value - bounds.lowerBound) / (bounds.upperBound - bounds.lowerBound))))
        let thumbOffset = percentage * (sliderWidth - 14)
        let trackFillWidth = max(0, min(sliderWidth, thumbOffset + 7))
        
        ZStack(alignment: .leading) {
            // Background Track
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(chrome.opacity(0.08))
                .frame(width: sliderWidth, height: 6)
            
            // Filled Track with Glow
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.p3(h: 0.75, s: 0.65, b: 0.92),
                            Color.p3(h: 0.53, s: 0.55, b: 0.97)
                        ],
                        startPoint: .leading, endPoint: .trailing
                    )
                )
                .frame(width: trackFillWidth, height: 6)
                .shadow(color: Color.p3(h: 0.65, s: 0.6, b: 0.95).opacity(isDragging ? 0.6 : (isHovered ? 0.4 : 0.2)), radius: isDragging ? 8 : 4)
            
            // Thumb
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(Color.white)
                .frame(width: 14, height: 14)
                .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 1)
                .shadow(color: Color.p3(h: 0.65, s: 0.6, b: 0.95).opacity(0.4), radius: 5)
                .scaleEffect(isDragging ? 1.3 : (isHovered ? 1.15 : 1.0))
                .offset(x: thumbOffset)
                // Removed all persistent .animation modifiers here to prevent transition hijacking
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
                    let locationX = gesture.location.x
                    let relativeX = max(0, min(sliderWidth, locationX))
                    let newFraction = Double(relativeX / sliderWidth)
                    value = bounds.lowerBound + newFraction * (bounds.upperBound - bounds.lowerBound)
                }
                .onEnded { _ in
                    withAnimation(.spring(response: 0.15, dampingFraction: 0.8)) {
                        isDragging = false
                    }
                    onEditingChanged(false)
                }
        )
        .frame(width: sliderWidth, height: 14)
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
            .foregroundColor(active ? .white : (isHovered ? .white.opacity(0.85) : .white.opacity(0.45)))
            .padding(.vertical, 7)
            .padding(.horizontal, 16)
            .background {
                if active {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.white.opacity(0.12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(
                                    LinearGradient(
                                        colors: [Color.white.opacity(0.25), Color.white.opacity(0.05)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 0.75
                                )
                        )
                        .matchedGeometryEffect(id: "activeTabIndicator", in: animationNamespace)
                } else if isHovered {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.white.opacity(0.04))
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
    let value: Double
    @Binding var selectedMinutes: Double
    let accent: Color
    @State private var isHovered = false
    
    var body: some View {
        let selected = selectedMinutes == value
        Button {
            if !selected { playSound("space_button") }
            withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) { selectedMinutes = value }
        } label: {
            Text(label)
                .font(.system(size: 12, weight: selected ? .bold : .medium, design: .rounded))
                .frame(width: 46, height: 32)
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(selected ? accent.opacity(0.42) : (isHovered ? Color.white.opacity(0.08) : Color.white.opacity(0.035)))
                        
                        if selected {
                            VStack {
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(LinearGradient(colors: [Color.white.opacity(0.20), Color.clear], startPoint: .top, endPoint: .bottom))
                                    .frame(height: 10)
                                Spacer()
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                    }
                )
                .foregroundColor(selected ? .white : (isHovered ? .white : .white.opacity(0.55)))
                .scaleEffect(selected ? 1.04 : (isHovered ? 1.02 : 1.0))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(selected ? 0.35 : (isHovered ? 0.18 : 0.08)),
                                    Color.white.opacity(0.02)
                                ],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.75
                        )
                )
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
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white.opacity(isHovered ? 0.06 : 0.035))
            .cornerRadius(14)
            .scaleEffect(isHovered ? 1.01 : 1.0)
            .overlay(
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
            )
            .onHover { hovering in
                withAnimation(.easeOut(duration: 0.18)) {
                    isHovered = hovering
                }
            }
    }
}

// ===================================================================
// MARK: - Main View
// ===================================================================

struct SlumberView: View {
    @ObservedObject var timerModel: SlumberTimer
    @AppStorage("showInDock") private var showInDock: Bool = false
    @State private var selectedMinutes: Double = 15
    @State private var currentTab = 0
    @State private var companionType: Int = 0
    @Namespace private var tabNamespace

    private let accent = Color.p3(h: 0.75, s: 0.65, b: 0.92)
    private let cyan   = Color.p3(h: 0.53, s: 0.55, b: 0.97)

    private var skyPhase: Int {
        let m = timerModel.isRunning ? timerModel.totalTime / 60.0 : selectedMinutes
        if m <= 20 { return 0 }     // Sunset (for 15m preset)
        if m <= 38 { return 1 }     // Evening Twilight (for 30m preset)
        if m <= 50 { return 2 }     // Late Dusk (for 45m preset)
        if m <= 75 { return 3 }     // Midnight Blue (for 60m preset)
        return 4                    // Cosmic Space (for 90m preset)
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
            VisualEffectView(material: .popover, blendingMode: .behindWindow)

            LinearGradient(colors: [skyTop.opacity(0.65), skyBot.opacity(0.75)], startPoint: .top, endPoint: .bottom)
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
                        .fill(Color.white.opacity(0.05))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
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
        .onChange(of: showInDock) { _, v in applyDock(v) }
    }

    private var timerPage: some View {
        VStack(spacing: 14) {
            Spacer()

            if timerModel.isRunning {
                let total = timerModel.totalTime
                let prog = total > 0 ? CGFloat(timerModel.timeRemaining / total) : 0

                ZStack {
                    PulsingRing(progress: prog)
                    VStack(spacing: 4) {
                        Text(fmt(timerModel.timeRemaining))
                            .font(.system(size: 44, weight: .bold, design: .rounded))
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
                    Text("\(Int(selectedMinutes))")
                        .font(.system(size: 58, weight: .heavy, design: .rounded))
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
                    .onChange(of: selectedMinutes) { _, newValue in
                        let rounded = round(newValue)
                        if selectedMinutes != rounded {
                            selectedMinutes = rounded
                        }
                    }
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
                    companionType = Int.random(in: 0...1)
                    timerModel.start(minutes: selectedMinutes)
                }, accent: accent, cyan: cyan)
                .padding(.top, 6)
            }

            Spacer()
        }
        .allowsHitTesting(currentTab == 0)
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
                        Text("Toggle the popover from anywhere, even if hidden by the notch.")
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

            Text("Slumber v2.7")
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.2))
                .frame(maxWidth: .infinity, alignment: .center)
            Text("Made with love")
                .font(.system(size: 9, weight: .regular, design: .rounded))
                .foregroundColor(.white.opacity(0.15))
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
