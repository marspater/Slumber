//
//  Companions.swift
//  Slumber
//
//  Vector companion characters (Sleeping Fox, Kitten, Dodo Bird) and Keplerian orbital physics.
//

import SwiftUI
import SlumberCore

// MARK: - Tail Shapes
public struct FoxTailShape: Shape {
    public init() {}
    public func path(in rect: CGRect) -> Path {
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

public struct FoxTailTipShape: Shape {
    public init() {}
    public func path(in rect: CGRect) -> Path {
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

public struct CatTailShape: Shape {
    public init() {}
    public func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: 2, y: rect.height * 0.55))
        p.addCurve(
            to: CGPoint(x: rect.width - 3, y: 4),
            control1: CGPoint(x: rect.width * 0.42, y: rect.height + 6),
            control2: CGPoint(x: rect.width + 5, y: rect.height * 0.48)
        )
        return p
    }
}

// MARK: - Sleeping Fox
public struct SleepingFox: View {
    public let isNearEnd: Bool
    @State private var breathe = false
    @State private var fidget = false
    @State private var tailSway = false
    @State private var zzz = false

    private let fur     = Color.p3(r: 0.94, g: 0.50, b: 0.15)
    private let furDk   = Color.p3(r: 0.76, g: 0.32, b: 0.08)
    private let cream   = Color.p3(r: 0.98, g: 0.94, b: 0.88)
    private let dark    = Color.p3(r: 0.12, g: 0.08, b: 0.06)

    public init(isNearEnd: Bool) {
        self.isNearEnd = isNearEnd
    }

    public var body: some View {
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

            // Tucked Little Paws
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
            ZStack {
                Triangle().fill(dark.opacity(0.85)).frame(width: 9, height: 16)
                Triangle().fill(fur).frame(width: 8, height: 14).offset(y: 1)
                Triangle().fill(cream).frame(width: 5, height: 10).offset(y: 2)
                Triangle().fill(Color.pink.opacity(0.35)).frame(width: 3.5, height: 7).offset(y: 3)
            }
            .rotationEffect(.degrees(isNearEnd ? (fidget ? -22 : 0) : -10))
            .offset(x: -22, y: -20)

            ZStack {
                Triangle().fill(dark.opacity(0.85)).frame(width: 9, height: 16)
                Triangle().fill(fur).frame(width: 8, height: 14).offset(y: 1)
                Triangle().fill(cream).frame(width: 5, height: 10).offset(y: 2)
                Triangle().fill(Color.pink.opacity(0.35)).frame(width: 3.5, height: 7).offset(y: 3)
            }
            .rotationEffect(.degrees(isNearEnd ? (fidget ? 16 : -2) : 6))
            .offset(x: -9, y: -21)

            // Snout & Cheeks
            Ellipse()
                .fill(cream)
                .frame(width: 14, height: 8)
                .offset(x: -24, y: -4)

            // Button Nose
            Circle()
                .fill(dark)
                .frame(width: 3, height: 3)
                .offset(x: -29, y: -5)

            // Eyes
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

            // Cheek Blush
            Circle()
                .fill(Color.pink.opacity(0.30))
                .frame(width: 5, height: 5)
                .offset(x: -24, y: -1)

            // 'z' particles
            Text("z").font(.system(size: 7, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.4)).offset(x: zzz ? 14 : 2, y: zzz ? -28 : -18).opacity(isNearEnd ? 0 : (zzz ? 0 : 0.5))
            Text("z").font(.system(size: 5, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.3)).offset(x: zzz ? 20 : 8, y: zzz ? -34 : -24).opacity(isNearEnd ? 0 : (zzz ? 0 : 0.35))

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

// MARK: - Sleeping Cat
public struct SleepingCat: View {
    public let isNearEnd: Bool
    @State private var breathe = false
    @State private var fidget = false
    @State private var purr = false
    @State private var tailSway = false
    @State private var zzz = false

    private let fur     = Color.p3(r: 0.54, g: 0.48, b: 0.70)
    private let furDk   = Color.p3(r: 0.36, g: 0.30, b: 0.50)
    private let furLt   = Color.p3(r: 0.74, g: 0.68, b: 0.86)

    public init(isNearEnd: Bool) {
        self.isNearEnd = isNearEnd
    }

    public var body: some View {
        ZStack {
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

                Circle()
                    .fill(furDk)
                    .frame(width: 5, height: 5)
                    .offset(x: 9, y: -8)
            }
            .frame(width: 24, height: 20)
            .offset(x: 17, y: 1)
            .rotationEffect(.degrees(tailSway ? 6 : -3), anchor: .bottomLeading)

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

            Ellipse()
                .fill(furLt.opacity(0.40))
                .frame(width: 14, height: 10)
                .offset(x: -4, y: 4)

            Circle()
                .fill(fur)
                .frame(width: 18, height: 18)
                .offset(x: -11, y: -6)

            ZStack {
                Triangle().fill(furDk).frame(width: 7, height: 11)
                Triangle().fill(fur).frame(width: 6, height: 9.5).offset(y: 1)
                Triangle().fill(Color.pink.opacity(0.40)).frame(width: 3.5, height: 6.5).offset(y: 2)
            }
            .rotationEffect(.degrees(isNearEnd ? (fidget ? -18 : -2) : -12))
            .offset(x: -16, y: -14)

            ZStack {
                Triangle().fill(furDk).frame(width: 7, height: 11)
                Triangle().fill(fur).frame(width: 6, height: 9.5).offset(y: 1)
                Triangle().fill(Color.pink.opacity(0.40)).frame(width: 3.5, height: 6.5).offset(y: 2)
            }
            .rotationEffect(.degrees(isNearEnd ? (fidget ? 12 : -2) : 6))
            .offset(x: -6, y: -15)

            Triangle()
                .fill(Color.pink.opacity(0.80))
                .frame(width: 3, height: 2)
                .rotationEffect(.degrees(180))
                .offset(x: -14, y: -4)

            if isNearEnd {
                Capsule().fill(Color.p3(h: 0.35, s: 0.65, b: 0.85, level: .rimHighlight)).frame(width: 2.5, height: 1.5).offset(x: -13, y: -7)
                Capsule().fill(Color.p3(h: 0.35, s: 0.65, b: 0.85, level: .rimHighlight)).frame(width: 2.5, height: 1.5).offset(x: -8, y: -7)
            } else {
                Arc().stroke(Color.white.opacity(0.80), lineWidth: 1.1).frame(width: 4, height: 2).rotationEffect(.degrees(180)).offset(x: -13, y: -7)
                Arc().stroke(Color.white.opacity(0.80), lineWidth: 1.1).frame(width: 4, height: 2).rotationEffect(.degrees(180)).offset(x: -8, y: -7)
            }

            ForEach(0..<3, id: \.self) { i in
                Capsule()
                    .fill(Color.white.opacity(0.35))
                    .frame(width: 8, height: 0.6)
                    .rotationEffect(.degrees(Double(i - 1) * 12 - 5))
                    .offset(x: -20, y: -3 + CGFloat(i) * 2)
            }

            Ellipse().fill(fur).frame(width: 5.5, height: 4.5).offset(x: -5, y: 6)
            Ellipse().fill(fur).frame(width: 5.5, height: 4.5).offset(x: 2, y: 6)
            Circle().fill(Color.pink.opacity(0.40)).frame(width: 2.5, height: 2.5).offset(x: -5, y: 6.5)
            Circle().fill(Color.pink.opacity(0.40)).frame(width: 2.5, height: 2.5).offset(x: 2, y: 6.5)

            Circle().fill(Color.pink.opacity(0.30)).frame(width: 4, height: 4).offset(x: -15, y: -2)

            Text("z").font(.system(size: 6, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.4)).offset(x: zzz ? 12 : 0, y: zzz ? -25 : -16).opacity(isNearEnd ? 0 : (zzz ? 0 : 0.5))
            Text("z").font(.system(size: 5, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.3)).offset(x: zzz ? 18 : 5, y: zzz ? -31 : -22).opacity(isNearEnd ? 0 : (zzz ? 0 : 0.35))

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

// MARK: - Sleeping Dodo
public struct SleepingDodo: View {
    public let isNearEnd: Bool
    @State private var breathe = false
    @State private var fidget = false
    @State private var zzz = false

    private let feather     = Color.p3(r: 0.38, g: 0.68, b: 0.74)
    private let featherDk   = Color.p3(r: 0.26, g: 0.52, b: 0.60)
    private let cream       = Color.p3(r: 0.96, g: 0.94, b: 0.88)
    private let beakAmber   = Color.p3(r: 0.98, g: 0.78, b: 0.38)
    private let beakTip     = Color.p3(r: 0.42, g: 0.78, b: 0.68)
    private let dark        = Color.p3(r: 0.14, g: 0.12, b: 0.18)

    public init(isNearEnd: Bool) {
        self.isNearEnd = isNearEnd
    }

    public var body: some View {
        ZStack {
            Circle().fill(cream.opacity(0.85)).frame(width: 8, height: 8).offset(x: 18, y: -2)
            Circle().fill(feather.opacity(0.9)).frame(width: 9, height: 9).offset(x: 16, y: 3)
            Circle().fill(cream.opacity(0.95)).frame(width: 7, height: 7).offset(x: 20, y: 1)

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

            Ellipse()
                .fill(cream.opacity(0.75))
                .frame(width: 18, height: 14)
                .offset(x: -6, y: 5)

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

            Arc()
                .stroke(Color.white.opacity(0.35), lineWidth: 1)
                .frame(width: 10, height: 5)
                .rotationEffect(.degrees(-15))
                .offset(x: 3, y: 3)

            Ellipse().fill(beakAmber).frame(width: 6, height: 4).offset(x: -8, y: 12)
            Ellipse().fill(beakAmber).frame(width: 6, height: 4).offset(x: 0, y: 12)

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

            Circle()
                .fill(feather)
                .frame(width: 20, height: 20)
                .offset(x: -12, y: -7)

            Ellipse()
                .fill(beakAmber)
                .frame(width: 13, height: 8)
                .rotationEffect(.degrees(12))
                .offset(x: -24, y: -4)

            Circle()
                .fill(beakTip)
                .frame(width: 7, height: 7)
                .offset(x: -28, y: -2)

            Circle()
                .fill(dark.opacity(0.6))
                .frame(width: 1.5, height: 1.5)
                .offset(x: -22, y: -5)

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

            Circle()
                .fill(Color.pink.opacity(0.35))
                .frame(width: 4.5, height: 4.5)
                .offset(x: -18, y: -2)

            Text("z").font(.system(size: 7, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.4)).offset(x: zzz ? 12 : 0, y: zzz ? -26 : -16).opacity(isNearEnd ? 0 : (zzz ? 0 : 0.5))
            Text("z").font(.system(size: 5, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.3)).offset(x: zzz ? 18 : 6, y: zzz ? -32 : -22).opacity(isNearEnd ? 0 : (zzz ? 0 : 0.35))

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

// MARK: - Animated Scene with Orbiting Companions
public struct AnimatedScene: View {
    @ObservedObject public var timerModel: SlumberTimer
    public let companionType: Int
    public let isVisible: Bool
    @Environment(\.colorScheme) var colorScheme

    @State private var orbitStartTime: Date? = nil
    @State private var orbitProgress:  CGFloat = 0.0

    private let orbitDuration: Double = 90.0
    private let orbitRadiusX: CGFloat = 56
    private let orbitRadiusY: CGFloat = 28

    private let cloudX: CGFloat =  -95
    private let cloudY: CGFloat =  146
    private let moonX:  CGFloat =   95
    private let moonY:  CGFloat = -135

    public init(timerModel: SlumberTimer, companionType: Int, isVisible: Bool = true) {
        self.timerModel = timerModel
        self.companionType = companionType
        self.isVisible = isVisible
    }

    public var body: some View {
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

                CuteCloud1(scale: 1.00).offset(x: cloudX, y: 170)
                CuteCloud2(scale: 0.75).offset(x: 105, y: -30)
            }

            if isVisible {
                TimelineView(.animation(paused: !isVisible || (!timerModel.isRunning && orbitProgress == 0.0))) { timeline in
                    let t = timeline.date.timeIntervalSinceReferenceDate
                    let elapsed: Double = {
                        guard let start = orbitStartTime else { return 0 }
                        return max(0, t - start.timeIntervalSinceReferenceDate)
                    }()

                    let baseAngle = (elapsed / orbitDuration) * 360.0
                    let baseRad = baseAngle * .pi / 180.0
                    let angle = baseAngle - 12.0 * cos(baseRad)
                    let rad = angle * .pi / 180.0

                    let orbitX = moonX + CGFloat(cos(rad)) * orbitRadiusX
                    let orbitY = moonY + CGFloat(sin(rad)) * orbitRadiusY

                    let arcCtrlX: CGFloat = -132
                    let arcCtrlY: CGFloat = -8
                    let p = orbitProgress
                    let u = 1.0 - p

                    let targetX = u * u * cloudX + 2.0 * u * p * arcCtrlX + p * p * orbitX
                    let targetY = u * u * cloudY + 2.0 * u * p * arcCtrlY + p * p * orbitY

                    let isTransferring = orbitProgress > 0.04 && orbitProgress < 0.96
                    if isTransferring {
                        ForEach(1...4, id: \.self) { trailIdx in
                            let lagP = max(0.0, orbitProgress - CGFloat(trailIdx) * 0.05)
                            let lagU = 1.0 - lagP
                            let trailX = lagU * lagU * cloudX + 2.0 * lagU * lagP * arcCtrlX + lagP * lagP * orbitX
                            let trailY = lagU * lagU * cloudY + 2.0 * lagU * lagP * arcCtrlX + lagP * lagP * orbitY
                            let trailAlpha = Double(sin(orbitProgress * .pi)) * (1.0 - Double(trailIdx) * 0.22) * 0.65

                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.p3(h: 0.78, s: 0.6, b: 1.0, a: trailAlpha, level: .rimHighlight),
                                            Color.p3(h: 0.55, s: 0.5, b: 0.9, a: 0.0, level: .subtleHighlight)
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(width: CGFloat(7 - trailIdx), height: CGFloat(7 - trailIdx))
                                .blur(radius: 0.8)
                                .offset(x: trailX, y: trailY)
                        }
                    }

                    let idleBobY = CGFloat(sin(t * 1.2)) * 1.5 * (1.0 - orbitProgress)
                    let zeroGDriftX = CGFloat(cos(t * 1.3 + 0.4)) * 5.0 * orbitProgress
                    let zeroGDriftY = CGFloat(sin(t * 1.8)) * 6.5 * orbitProgress
                    let finalX = targetX + zeroGDriftX
                    let finalY = targetY + idleBobY + zeroGDriftY

                    let tumbleSpeed = 360.0 / 6.5
                    let continuousTumble = (elapsed * tumbleSpeed).truncatingRemainder(dividingBy: 360.0)
                    let spaceWobble = sin(elapsed * 2.2) * 12.0
                    let zeroGRotation = continuousTumble + spaceWobble

                    let ascentBank = Double(sin(orbitProgress * .pi)) * -18.0
                    let idleTilt = sin(t * 1.0) * 2.0
                    let finalRotation = idleTilt * (1.0 - Double(orbitProgress))
                        + ascentBank * (1.0 - Double(orbitProgress)) * Double(orbitProgress) * 4.0
                        + zeroGRotation * Double(orbitProgress * orbitProgress)

                    let depthMod = 1.0 + 0.15 * CGFloat(sin(rad)) * orbitProgress
                    let baseScale: CGFloat = {
                        switch companionType {
                        case 0:  return (0.65 - 0.15 * orbitProgress)
                        case 1:  return (0.82 - 0.12 * orbitProgress)
                        default: return (0.75 - 0.14 * orbitProgress)
                        }
                    }()
                    let finalScale = baseScale * depthMod

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
            syncSceneState()
        }
        .onAppear { syncSceneState() }
        .onChange(of: isVisible) { _, visible in if visible { syncSceneState() } }
        .onChange(of: timerModel.isRunning) { _, running in
            if running {
                let total = timerModel.totalTime
                let remaining = timerModel.timeRemaining
                let elapsed = total - remaining
                orbitStartTime = Date().addingTimeInterval(-elapsed)
                withAnimation(.spring(response: 2.2, dampingFraction: 0.82)) {
                    orbitProgress = 1.0
                }
            } else {
                withAnimation(.spring(response: 1.6, dampingFraction: 0.84)) {
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
