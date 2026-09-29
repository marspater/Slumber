//
//  Companions.swift
//  Slumber
//
//  Vector companion characters (Sleeping Fox, Kitten, Dodo Bird) and Keplerian orbital physics.
//  Path data lives in ArtPaths.swift.
//

import SwiftUI
import SlumberCore

// MARK: - Sleeping Fox
public struct SleepingFox: View {
    public let isNearEnd: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var breathe = false
    @State private var fidget = false
    @State private var tailSway = false
    @State private var zzz = false

    private let cream = Color.p3(0.99, 0.95, 0.89)
    private let ink = Color.p3(0.22, 0.12, 0.10)
    private let headFur = Gradient(colors: [.p3(1.0, 0.62, 0.24), .p3(0.86, 0.40, 0.10)])

    public init(isNearEnd: Bool) {
        self.isNearEnd = isNearEnd
    }

    public var body: some View {
        let box = FoxArt.box
        ZStack {
            // Curled body, breathing from the ground up
            ZStack {
                FoxArt.body.fill(LinearGradient(
                    Gradient(colors: [.p3(0.98, 0.58, 0.20), .p3(0.78, 0.32, 0.08)]),
                    from: CGPoint(x: 14, y: 10), to: CGPoint(x: 52, y: 42), in: box
                ))
                FoxArt.backRim.stroke(Color.p3(1, 0.80, 0.55, 0.35), style: .round(0.8))
                // Contact shadow so the wrapped tail reads as lying in front of the body
                FoxArt.tail.fill(Color.p3(0.45, 0.14, 0.04, 0.35))
                    .offset(y: -1.3)
                    .mask { FoxArt.body }
                FoxArt.chest.fill(cream)
            }
            .scaleEffect(x: breathe ? 0.99 : 1.0, y: breathe ? 1.04 : 1.0, anchor: UnitPoint(35, 38, in: box))

            // Tail wrapped around the front, swaying from its root
            ZStack {
                FoxArt.tail.fill(LinearGradient(
                    Gradient(colors: [.p3(1.0, 0.60, 0.22), .p3(0.80, 0.33, 0.08)]),
                    from: CGPoint(x: 30, y: 34), to: CGPoint(x: 34, y: 44), in: box
                ))
                FoxArt.tailRim.stroke(Color.p3(1, 0.78, 0.5, 0.3), style: .round(0.8))
                FoxArt.tailTip.fill(cream)
            }
            .rotationEffect(.degrees(tailSway ? 2.5 : 0), anchor: UnitPoint(53, 26, in: box))

            // Ears, hinged at the head so they twitch in the last minute
            ZStack {
                FoxArt.earBack.fill(Color.p3(0.86, 0.40, 0.10))
                FoxArt.earBackTip.fill(ink)
            }
            .rotationEffect(.degrees(fidget ? 10 : 0), anchor: UnitPoint(23, 13.5, in: box))

            ZStack {
                FoxArt.earFront.fill(LinearGradient(headFur, from: CGPoint(x: 8, y: 10), to: CGPoint(x: 26, y: 30), in: box))
                FoxArt.earFrontInner.fill(Color.p3(0.99, 0.90, 0.84))
                FoxArt.earFrontTip.fill(ink)
            }
            .rotationEffect(.degrees(fidget ? -12 : 0), anchor: UnitPoint(15.5, 13.5, in: box))

            FoxArt.head.fill(LinearGradient(headFur, from: CGPoint(x: 8, y: 10), to: CGPoint(x: 26, y: 30), in: box))
            FoxArt.muzzle.fill(cream)
            FoxArt.nose.fill(Color.p3(0.16, 0.09, 0.08))

            if isNearEnd {
                AwakeEye(color: ink).offset(x: 15 - 32, y: 20 - 22)
            } else {
                FoxArt.eye.stroke(Color.p3(0.22, 0.11, 0.08), style: .round(1.2))
            }

            FoxArt.blush.fill(Color.p3(1, 0.45, 0.55, 0.45))

            // 'z' particles
            if !isNearEnd {
                Text("z").font(.system(size: 7, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.4)).offset(x: zzz ? 14 : 2, y: zzz ? -28 : -18).opacity(zzz ? 0 : 0.5)
                Text("z").font(.system(size: 5, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.3)).offset(x: zzz ? 20 : 8, y: zzz ? -34 : -24).opacity(zzz ? 0 : 0.35)
            }

            if isNearEnd {
                Text("?").font(.system(size: 8, weight: .bold, design: .rounded))
                    .foregroundColor(Color.p3(h: 0.08, s: 0.6, b: 1.0, a: 0.75, level: .rimHighlight)).offset(x: -5, y: -23)
            }
        }
        .frame(width: box.width, height: box.height)
        .animation(.easeInOut(duration: 0.6), value: isNearEnd)
        .earFidget($fidget, isNearEnd: isNearEnd, reduceMotion: reduceMotion)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) { breathe = true }
            withAnimation(.easeInOut(duration: 4.0).repeatForever(autoreverses: true)) { tailSway = true }
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: false)) { zzz = true }
        }
    }
}

// MARK: - Sleeping Cat
public struct SleepingCat: View {
    public let isNearEnd: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var breathe = false
    @State private var fidget = false
    @State private var purr = false
    @State private var tailSway = false
    @State private var zzz = false

    private let stripe = Color.p3(0.36, 0.29, 0.52)
    private let innerEar = Color.p3(1, 0.66, 0.80)
    private let headFur = Gradient(colors: [.p3(0.74, 0.67, 0.90), .p3(0.50, 0.43, 0.68)])

    public init(isNearEnd: Bool) {
        self.isNearEnd = isNearEnd
    }

    public var body: some View {
        let box = CatArt.box
        ZStack {
            ZStack {
                CatArt.body.fill(LinearGradient(
                    Gradient(colors: [.p3(0.68, 0.61, 0.86), .p3(0.42, 0.35, 0.60)]),
                    from: CGPoint(x: 18, y: 12), to: CGPoint(x: 52, y: 40), in: box
                ))
                CatArt.stripes.stroke(stripe.opacity(0.4), style: .round(1.3))
                CatArt.backRim.stroke(Color.p3(0.86, 0.82, 0.98, 0.35), style: .round(0.8))
                CatArt.tail.fill(Color.p3(0.20, 0.14, 0.34, 0.25))
                    .offset(y: -1.1)
                    .mask { CatArt.body }
            }
            .scaleEffect(x: purr ? 1.01 : 0.99, y: 1.0, anchor: UnitPoint(36, 38, in: box))
            .scaleEffect(x: 1.0, y: breathe ? 1.04 : 1.0, anchor: UnitPoint(36, 38, in: box))

            ZStack {
                CatArt.tail.fill(LinearGradient(
                    Gradient(colors: [.p3(0.66, 0.59, 0.84), .p3(0.42, 0.35, 0.60)]),
                    from: CGPoint(x: 30, y: 36), to: CGPoint(x: 30, y: 42), in: box
                ))
                CatArt.tailTip.fill(stripe)
            }
            .rotationEffect(.degrees(tailSway ? 2 : 0), anchor: UnitPoint(52, 28, in: box))

            CatArt.pawFront.fill(Color.p3(0.80, 0.75, 0.93))
            CatArt.pawBack.fill(Color.p3(0.76, 0.70, 0.90))

            ZStack {
                CatArt.earFront.fill(LinearGradient(headFur, from: CGPoint(x: 10, y: 12), to: CGPoint(x: 28, y: 32), in: box))
                CatArt.earFrontInner.fill(innerEar.opacity(0.8))
            }
            .rotationEffect(.degrees(fidget ? -10 : 0), anchor: UnitPoint(14.8, 16.8, in: box))

            ZStack {
                CatArt.earBack.fill(Color.p3(0.50, 0.43, 0.68))
                CatArt.earBackInner.fill(innerEar.opacity(0.6))
            }
            .rotationEffect(.degrees(fidget ? 8 : 0), anchor: UnitPoint(24, 16.6, in: box))

            CatArt.head.fill(LinearGradient(headFur, from: CGPoint(x: 10, y: 12), to: CGPoint(x: 28, y: 32), in: box))
            CatArt.muzzle.fill(Color.p3(0.86, 0.82, 0.96))
            CatArt.nose.fill(Color.p3(1, 0.55, 0.70))
            CatArt.mouth.stroke(Color.p3(0.32, 0.24, 0.44), style: .round(0.7))

            if isNearEnd {
                let glow = Color.p3(h: 0.35, s: 0.65, b: 0.85, level: .rimHighlight)
                AwakeEye(color: glow).offset(x: 14.6 - 32, y: 23.3 - 22)
                AwakeEye(color: glow).offset(x: 22.6 - 32, y: 23.3 - 22)
            } else {
                CatArt.eyes.stroke(Color.p3(0.26, 0.19, 0.38), style: .round(1.1))
            }

            CatArt.blush.fill(Color.p3(1, 0.50, 0.65, 0.45))
            CatArt.whiskers.stroke(Color.white.opacity(0.55), style: .round(0.45))

            if !isNearEnd {
                Text("z").font(.system(size: 6, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.4)).offset(x: zzz ? 12 : 0, y: zzz ? -25 : -16).opacity(zzz ? 0 : 0.5)
                Text("z").font(.system(size: 5, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.3)).offset(x: zzz ? 18 : 5, y: zzz ? -31 : -22).opacity(zzz ? 0 : 0.35)
            }

            if isNearEnd {
                Text("?").font(.system(size: 7, weight: .bold, design: .rounded))
                    .foregroundColor(Color.p3(h: 0.72, s: 0.45, b: 1.0, a: 0.7, level: .rimHighlight)).offset(x: 0, y: -21)
            }
        }
        .frame(width: box.width, height: box.height)
        .animation(.easeInOut(duration: 0.6), value: isNearEnd)
        .earFidget($fidget, isNearEnd: isNearEnd, reduceMotion: reduceMotion)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 2.8).repeatForever(autoreverses: true)) { breathe = true }
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) { purr = true }
            withAnimation(.easeInOut(duration: 3.5).repeatForever(autoreverses: true)) { tailSway = true }
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: false)) { zzz = true }
        }
    }
}

// MARK: - Sleeping Dodo
public struct SleepingDodo: View {
    public let isNearEnd: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var breathe = false
    @State private var fidget = false
    @State private var zzz = false

    private let cream = Color.p3(0.97, 0.95, 0.89)
    private let ink = Color.p3(0.14, 0.14, 0.20)
    private let headFeather = Gradient(colors: [.p3(0.56, 0.84, 0.87), .p3(0.30, 0.58, 0.65)])

    public init(isNearEnd: Bool) {
        self.isNearEnd = isNearEnd
    }

    public var body: some View {
        let box = DodoArt.box
        let head = LinearGradient(headFeather, from: CGPoint(x: 12, y: 11), to: CGPoint(x: 27, y: 28), in: box)
        ZStack {
            // Tail plume
            DodoArt.plumeBack.fill(Color.p3(0.88, 0.86, 0.80))
            DodoArt.plumeTop.fill(cream)
            DodoArt.plumeFront.fill(Color.p3(0.94, 0.92, 0.86))

            ZStack {
                DodoArt.body.fill(LinearGradient(
                    Gradient(colors: [.p3(0.50, 0.80, 0.84), .p3(0.24, 0.50, 0.58)]),
                    from: CGPoint(x: 20, y: 11), to: CGPoint(x: 52, y: 40), in: box
                ))
                DodoArt.backRim.stroke(Color.p3(0.80, 0.96, 0.98, 0.35), style: .round(0.8))
                DodoArt.belly.fill(cream.opacity(0.92))
                DodoArt.wing.fill(LinearGradient(
                    Gradient(colors: [.p3(0.34, 0.62, 0.70), .p3(0.20, 0.44, 0.52)]),
                    from: CGPoint(x: 32, y: 20), to: CGPoint(x: 48, y: 31), in: box
                ))
                DodoArt.wingLines.stroke(Color.p3(0.70, 0.90, 0.93, 0.45), style: .round(0.7))
            }
            .scaleEffect(x: breathe ? 0.98 : 1.0, y: breathe ? 1.05 : 1.0, anchor: UnitPoint(38, 39.5, in: box))

            DodoArt.footBack.fill(Color.p3(0.95, 0.70, 0.32))
            DodoArt.footFront.fill(Color.p3(0.98, 0.76, 0.38))

            DodoArt.tufts.fill(head)
                .rotationEffect(.degrees(fidget ? -12 : 0), anchor: UnitPoint(21.5, 12.8, in: box))

            // Beak sits behind the head so its root is hidden
            DodoArt.beak.fill(LinearGradient(
                Gradient(colors: [.p3(1.0, 0.84, 0.46), .p3(0.92, 0.64, 0.28)]),
                from: CGPoint(x: 4, y: 18), to: CGPoint(x: 12, y: 27), in: box
            ))
            DodoArt.beakHook.fill(Color.p3(0.40, 0.66, 0.60))
            DodoArt.beakLower.fill(Color.p3(0.99, 0.86, 0.56))
            DodoArt.beakLine.stroke(Color.p3(0.70, 0.46, 0.18, 0.5), style: .round(0.6))
            DodoArt.nostril.fill(Color.p3(0.55, 0.36, 0.16, 0.7))

            DodoArt.head.fill(head)

            if isNearEnd {
                AwakeEye(color: ink).offset(x: 16.8 - 32, y: 19.4 - 22)
            } else {
                DodoArt.eye.stroke(ink, style: .round(1.1))
            }

            DodoArt.blush.fill(Color.p3(1, 0.50, 0.62, 0.45))

            if !isNearEnd {
                Text("z").font(.system(size: 7, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.4)).offset(x: zzz ? 12 : 0, y: zzz ? -26 : -16).opacity(zzz ? 0 : 0.5)
                Text("z").font(.system(size: 5, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.3)).offset(x: zzz ? 18 : 6, y: zzz ? -32 : -22).opacity(zzz ? 0 : 0.35)
            }

            if isNearEnd {
                Text("?").font(.system(size: 8, weight: .bold, design: .rounded))
                    .foregroundColor(Color.p3(h: 0.50, s: 0.7, b: 1.0, a: 0.8, level: .rimHighlight)).offset(x: -6, y: -23)
            }
        }
        .frame(width: box.width, height: box.height)
        .animation(.easeInOut(duration: 0.6), value: isNearEnd)
        .earFidget($fidget, isNearEnd: isNearEnd, reduceMotion: reduceMotion)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 2.9).repeatForever(autoreverses: true)) { breathe = true }
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: false)) { zzz = true }
        }
    }
}

/// Open eye with a small EDR glint, shown in the last minute.
private struct AwakeEye: View {
    let color: Color

    var body: some View {
        Ellipse()
            .fill(color)
            .frame(width: 2.6, height: 3.0)
            .overlay(alignment: .topLeading) {
                Circle()
                    .fill(Color.p3(1, 1, 1, level: .rimHighlight))
                    .frame(width: 1.1, height: 1.1)
                    .offset(x: 0.4, y: 0.4)
            }
    }
}

@MainActor
private extension View {
    /// Twitches ears (or tufts) while the last minute runs. Started on entry rather than on appear,
    /// so the loop runs even when the companion appeared before the last minute.
    func earFidget(_ fidget: Binding<Bool>, isNearEnd: Bool, reduceMotion: Bool) -> some View {
        onChange(of: isNearEnd, initial: true) { _, nearEnd in
            if nearEnd && !reduceMotion {
                withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) { fidget.wrappedValue = true }
            } else {
                withAnimation(.easeInOut(duration: 0.3)) { fidget.wrappedValue = false }
            }
        }
    }
}

// MARK: - Animated Scene with Orbiting Companions
public struct AnimatedScene: View {
    @ObservedObject public var timerModel: SlumberTimer
    public let companionType: Int
    public let isVisible: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var orbitStartTime: Date? = nil
    @State private var transfer = OrbitTransfer(settledAt: 0)

    private let orbitDuration: Double = 90.0
    private let launchDuration: Double = 2.2
    private let returnDuration: Double = 1.6
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
                ConstellationOverlay()
                AuroraEffect()
                StarField(count: 45)
            }

            if isVisible && !reduceMotion {
                FireflyField(count: 8)

                ShootingStar(angle: 32,  cycleDuration: 4.0, initialDelay:  1.0, length: 50, startX: -60, startY:  20)
                ShootingStar(angle: 45,  cycleDuration: 5.5, initialDelay:  4.0, length: 35, startX:  80, startY: -30)
                ShootingStar(angle: 25,  cycleDuration: 3.8, initialDelay:  7.0, length: 45, startX: -20, startY: -50)
                ShootingStar(angle: 38,  cycleDuration: 6.0, initialDelay: 10.5, length: 40, startX:  40, startY:  60)
                ShootingStar(angle: 18,  cycleDuration: 4.5, initialDelay: 14.0, length: 55, startX: -90, startY:  90)
            }

            if isVisible {
                CuteMoon().offset(x: moonX, y: moonY)

                CuteCloud1(scale: 1.00).offset(x: cloudX, y: 170)
                CuteCloud2(scale: 0.75).offset(x: 105, y: -30)
            }

            if isVisible {
                TimelineView(.animation(paused: reduceMotion)) { timeline in
                    // TimelineView stacks several children like a VStack, so the trail appearing
                    // (p > 0.04) and vanishing (p > 0.96) shoved the companion ~25 pt mid-launch.
                    ZStack {
                        let t = timeline.date.timeIntervalSinceReferenceDate
                        let orbitProgress = transfer.progress(at: timeline.date)
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
                                // Trail lags behind the direction of travel (up on launch, down on return).
                                let lagP = min(1.0, max(0.0, orbitProgress - transfer.direction * CGFloat(trailIdx) * 0.05))
                                let lagU = 1.0 - lagP
                                let trailX = lagU * lagU * cloudX + 2.0 * lagU * lagP * arcCtrlX + lagP * lagP * orbitX
                                let trailY = lagU * lagU * cloudY + 2.0 * lagU * lagP * arcCtrlY + lagP * lagP * orbitY
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
                        let continuousTumble = elapsed * tumbleSpeed  // unwrapped: a 360° wrap under the p² weight would snap the sprite
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
        }
        .onReceive(NotificationCenter.default.publisher(
            for: .slumberOpening)
        ) { _ in
            syncSceneState()
        }
        .onAppear { syncSceneState() }
        .onChange(of: isVisible) { _, visible in if visible { syncSceneState() } }
        .onChange(of: timerModel.isRunning) { _, running in
            let now = Date()
            if running {
                let total = timerModel.totalTime
                let remaining = timerModel.timeRemaining
                let elapsed = total - remaining
                orbitStartTime = now.addingTimeInterval(-elapsed)
            }
            // Progress is sampled from the timeline clock rather than animated through
            // @State, so the Bézier arc and trail are actually traversed frame by frame.
            // Retarget from the current position so an interrupted launch reverses smoothly.
            transfer = OrbitTransfer(
                from: transfer.progress(at: now),
                to: running ? 1.0 : 0.0,
                start: now,
                duration: reduceMotion ? 0 : (running ? launchDuration : returnDuration)
            )
        }
    }

    private func syncSceneState() {
        if timerModel.isRunning {
            let total = timerModel.totalTime
            let remaining = timerModel.timeRemaining
            let elapsed = total - remaining
            orbitStartTime = Date().addingTimeInterval(-elapsed)
            transfer = OrbitTransfer(settledAt: 1.0)
        } else {
            transfer = OrbitTransfer(settledAt: 0.0)
        }
    }
}

/// Time-based cloud ⇄ orbit transfer, eased with a cubic in-out curve.
private struct OrbitTransfer {
    var from: CGFloat
    var to: CGFloat
    var start: Date
    var duration: Double

    init(from: CGFloat, to: CGFloat, start: Date, duration: Double) {
        self.from = from
        self.to = to
        self.start = start
        self.duration = duration
    }

    init(settledAt value: CGFloat) {
        self.init(from: value, to: value, start: .distantPast, duration: 0)
    }

    /// +1 while launching toward the orbit, -1 while returning to the cloud.
    var direction: CGFloat { to >= from ? 1.0 : -1.0 }

    func progress(at date: Date) -> CGFloat {
        guard duration > 0 else { return to }
        let x = min(max(date.timeIntervalSince(start) / duration, 0.0), 1.0)
        let eased = x < 0.5 ? 4.0 * x * x * x : 1.0 - pow(-2.0 * x + 2.0, 3.0) / 2.0
        return from + (to - from) * CGFloat(eased)
    }
}
