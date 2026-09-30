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
    private typealias Shared = SlumberTheme.Art.Companion
    public let isNearEnd: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var breathe = false
    @State private var fidget = false
    @State private var tailSway = false
    @State private var zzz = false

    private typealias Palette = SlumberTheme.Art.Fox

    public init(isNearEnd: Bool) {
        self.isNearEnd = isNearEnd
    }

    public var body: some View {
        let box = FoxArt.box
        ZStack {
            // Curled body, breathing from the ground up
            ZStack {
                FoxArt.body.fill(LinearGradient(
                    Palette.bodyFur,
                    from: CGPoint(x: 14, y: 10), to: CGPoint(x: 52, y: 42), in: box
                ))
                FoxArt.backRim.stroke(Palette.backRim, style: .round(0.8))
                // Contact shadow so the wrapped tail reads as lying in front of the body
                FoxArt.tail.fill(Palette.tailShadow)
                    .offset(y: -1.3)
                    .mask { FoxArt.body }
                FoxArt.chest.fill(Palette.cream)
            }
            .scaleEffect(x: breathe ? 0.99 : 1.0, y: breathe ? 1.04 : 1.0, anchor: UnitPoint(35, 38, in: box))

            // Tail wrapped around the front, swaying from its root
            ZStack {
                FoxArt.tail.fill(LinearGradient(
                    Palette.tailFur,
                    from: CGPoint(x: 30, y: 34), to: CGPoint(x: 34, y: 44), in: box
                ))
                FoxArt.tailRim.stroke(Palette.tailRim, style: .round(0.8))
                FoxArt.tailTip.fill(Palette.cream)
            }
            .rotationEffect(.degrees(tailSway ? 2.5 : 0), anchor: UnitPoint(53, 26, in: box))

            // Ears, hinged at the head so they twitch in the last minute
            ZStack {
                FoxArt.earBack.fill(Palette.earBack)
                FoxArt.earBackTip.fill(Palette.ink)
            }
            .rotationEffect(.degrees(fidget ? 10 : 0), anchor: UnitPoint(23, 13.5, in: box))

            ZStack {
                FoxArt.earFront.fill(LinearGradient(Palette.headFur, from: CGPoint(x: 8, y: 10), to: CGPoint(x: 26, y: 30), in: box))
                FoxArt.earFrontInner.fill(Palette.earInner)
                FoxArt.earFrontTip.fill(Palette.ink)
            }
            .rotationEffect(.degrees(fidget ? -12 : 0), anchor: UnitPoint(15.5, 13.5, in: box))

            FoxArt.head.fill(LinearGradient(Palette.headFur, from: CGPoint(x: 8, y: 10), to: CGPoint(x: 26, y: 30), in: box))
            FoxArt.muzzle.fill(Palette.cream)
            FoxArt.nose.fill(Palette.nose)

            if isNearEnd {
                AwakeEye(color: Palette.ink).offset(x: 15 - 32, y: 20 - 22)
            } else {
                FoxArt.eye.stroke(Palette.sleepingEye, style: .round(1.2))
            }

            FoxArt.blush.fill(Palette.blush)

            // 'z' particles
            if !isNearEnd {
                Text("z").font(Shared.letterFont(size: Palette.zSizes.0))
                    .foregroundColor(Shared.z1).offset(x: zzz ? 14 : 2, y: zzz ? -28 : -18).opacity(zzz ? 0 : 0.5)
                Text("z").font(Shared.letterFont(size: Palette.zSizes.1))
                    .foregroundColor(Shared.z2).offset(x: zzz ? 20 : 8, y: zzz ? -34 : -24).opacity(zzz ? 0 : 0.35)
            }

            if isNearEnd {
                Text("?").font(Shared.letterFont(size: Palette.questionSize))
                    .foregroundColor(Palette.question).offset(x: -5, y: -23)
            }
        }
        .frame(width: box.width, height: box.height)
        .animation(.easeInOut(duration: Shared.nearEndFade), value: isNearEnd)
        .earFidget($fidget, isNearEnd: isNearEnd, reduceMotion: reduceMotion)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: Palette.breatheDuration).repeatForever(autoreverses: true)) { breathe = true }
            withAnimation(.easeInOut(duration: Palette.tailSwayDuration).repeatForever(autoreverses: true)) { tailSway = true }
            withAnimation(.easeInOut(duration: Shared.zzzDuration).repeatForever(autoreverses: false)) { zzz = true }
        }
    }
}

// MARK: - Sleeping Cat
public struct SleepingCat: View {
    private typealias Shared = SlumberTheme.Art.Companion
    public let isNearEnd: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var breathe = false
    @State private var fidget = false
    @State private var purr = false
    @State private var tailSway = false
    @State private var zzz = false

    private typealias Palette = SlumberTheme.Art.Cat

    public init(isNearEnd: Bool) {
        self.isNearEnd = isNearEnd
    }

    public var body: some View {
        let box = CatArt.box
        ZStack {
            ZStack {
                CatArt.body.fill(LinearGradient(
                    Palette.bodyFur,
                    from: CGPoint(x: 18, y: 12), to: CGPoint(x: 52, y: 40), in: box
                ))
                CatArt.stripes.stroke(Palette.stripe.opacity(0.4), style: .round(1.3))
                CatArt.backRim.stroke(Palette.backRim, style: .round(0.8))
                CatArt.tail.fill(Palette.tailShadow)
                    .offset(y: -1.1)
                    .mask { CatArt.body }
            }
            .scaleEffect(x: purr ? 1.01 : 0.99, y: 1.0, anchor: UnitPoint(36, 38, in: box))
            .scaleEffect(x: 1.0, y: breathe ? 1.04 : 1.0, anchor: UnitPoint(36, 38, in: box))

            ZStack {
                CatArt.tail.fill(LinearGradient(
                    Palette.tailFur,
                    from: CGPoint(x: 30, y: 36), to: CGPoint(x: 30, y: 42), in: box
                ))
                CatArt.tailTip.fill(Palette.stripe)
            }
            .rotationEffect(.degrees(tailSway ? 2 : 0), anchor: UnitPoint(52, 28, in: box))

            CatArt.pawFront.fill(Palette.pawFront)
            CatArt.pawBack.fill(Palette.pawBack)

            ZStack {
                CatArt.earFront.fill(LinearGradient(Palette.headFur, from: CGPoint(x: 10, y: 12), to: CGPoint(x: 28, y: 32), in: box))
                CatArt.earFrontInner.fill(Palette.innerEar.opacity(0.8))
            }
            .rotationEffect(.degrees(fidget ? -10 : 0), anchor: UnitPoint(14.8, 16.8, in: box))

            ZStack {
                CatArt.earBack.fill(Palette.earBack)
                CatArt.earBackInner.fill(Palette.innerEar.opacity(0.6))
            }
            .rotationEffect(.degrees(fidget ? 8 : 0), anchor: UnitPoint(24, 16.6, in: box))

            CatArt.head.fill(LinearGradient(Palette.headFur, from: CGPoint(x: 10, y: 12), to: CGPoint(x: 28, y: 32), in: box))
            CatArt.muzzle.fill(Palette.muzzle)
            CatArt.nose.fill(Palette.nose)
            CatArt.mouth.stroke(Palette.mouth, style: .round(0.7))

            if isNearEnd {
                let glow = Palette.awakeEye
                AwakeEye(color: glow).offset(x: 14.6 - 32, y: 23.3 - 22)
                AwakeEye(color: glow).offset(x: 22.6 - 32, y: 23.3 - 22)
            } else {
                CatArt.eyes.stroke(Palette.sleepingEyes, style: .round(1.1))
            }

            CatArt.blush.fill(Palette.blush)
            CatArt.whiskers.stroke(Palette.whiskers, style: .round(0.45))

            if !isNearEnd {
                Text("z").font(Shared.letterFont(size: Palette.zSizes.0))
                    .foregroundColor(Shared.z1).offset(x: zzz ? 12 : 0, y: zzz ? -25 : -16).opacity(zzz ? 0 : 0.5)
                Text("z").font(Shared.letterFont(size: Palette.zSizes.1))
                    .foregroundColor(Shared.z2).offset(x: zzz ? 18 : 5, y: zzz ? -31 : -22).opacity(zzz ? 0 : 0.35)
            }

            if isNearEnd {
                Text("?").font(Shared.letterFont(size: Palette.questionSize))
                    .foregroundColor(Palette.question).offset(x: 0, y: -21)
            }
        }
        .frame(width: box.width, height: box.height)
        .animation(.easeInOut(duration: Shared.nearEndFade), value: isNearEnd)
        .earFidget($fidget, isNearEnd: isNearEnd, reduceMotion: reduceMotion)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: Palette.breatheDuration).repeatForever(autoreverses: true)) { breathe = true }
            withAnimation(.easeInOut(duration: Palette.purrDuration).repeatForever(autoreverses: true)) { purr = true }
            withAnimation(.easeInOut(duration: Palette.tailSwayDuration).repeatForever(autoreverses: true)) { tailSway = true }
            withAnimation(.easeInOut(duration: Shared.zzzDuration).repeatForever(autoreverses: false)) { zzz = true }
        }
    }
}

// MARK: - Sleeping Dodo
public struct SleepingDodo: View {
    private typealias Shared = SlumberTheme.Art.Companion
    public let isNearEnd: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var breathe = false
    @State private var fidget = false
    @State private var zzz = false

    private typealias Palette = SlumberTheme.Art.Dodo

    public init(isNearEnd: Bool) {
        self.isNearEnd = isNearEnd
    }

    public var body: some View {
        let box = DodoArt.box
        let head = LinearGradient(Palette.headFeather, from: CGPoint(x: 12, y: 11), to: CGPoint(x: 27, y: 28), in: box)
        ZStack {
            // Tail plume
            DodoArt.plumeBack.fill(Palette.plumeBack)
            DodoArt.plumeTop.fill(Palette.cream)
            DodoArt.plumeFront.fill(Palette.plumeFront)

            ZStack {
                DodoArt.body.fill(LinearGradient(
                    Palette.bodyFeather,
                    from: CGPoint(x: 20, y: 11), to: CGPoint(x: 52, y: 40), in: box
                ))
                DodoArt.backRim.stroke(Palette.backRim, style: .round(0.8))
                DodoArt.belly.fill(Palette.cream.opacity(Palette.bellyOpacity))
                DodoArt.wing.fill(LinearGradient(
                    Palette.wing,
                    from: CGPoint(x: 32, y: 20), to: CGPoint(x: 48, y: 31), in: box
                ))
                DodoArt.wingLines.stroke(Palette.wingLines, style: .round(0.7))
            }
            .scaleEffect(x: breathe ? 0.98 : 1.0, y: breathe ? 1.05 : 1.0, anchor: UnitPoint(38, 39.5, in: box))

            DodoArt.footBack.fill(Palette.footBack)
            DodoArt.footFront.fill(Palette.footFront)

            DodoArt.tufts.fill(head)
                .rotationEffect(.degrees(fidget ? -12 : 0), anchor: UnitPoint(21.5, 12.8, in: box))

            // Beak sits behind the head so its root is hidden
            DodoArt.beak.fill(LinearGradient(
                Palette.beak,
                from: CGPoint(x: 4, y: 18), to: CGPoint(x: 12, y: 27), in: box
            ))
            DodoArt.beakHook.fill(Palette.beakHook)
            DodoArt.beakLower.fill(Palette.beakLower)
            DodoArt.beakLine.stroke(Palette.beakLine, style: .round(0.6))
            DodoArt.nostril.fill(Palette.nostril)

            DodoArt.head.fill(head)

            if isNearEnd {
                AwakeEye(color: Palette.ink).offset(x: 16.8 - 32, y: 19.4 - 22)
            } else {
                DodoArt.eye.stroke(Palette.ink, style: .round(1.1))
            }

            DodoArt.blush.fill(Palette.blush)

            if !isNearEnd {
                Text("z").font(Shared.letterFont(size: Palette.zSizes.0))
                    .foregroundColor(Shared.z1).offset(x: zzz ? 12 : 0, y: zzz ? -26 : -16).opacity(zzz ? 0 : 0.5)
                Text("z").font(Shared.letterFont(size: Palette.zSizes.1))
                    .foregroundColor(Shared.z2).offset(x: zzz ? 18 : 6, y: zzz ? -32 : -22).opacity(zzz ? 0 : 0.35)
            }

            if isNearEnd {
                Text("?").font(Shared.letterFont(size: Palette.questionSize))
                    .foregroundColor(Palette.question).offset(x: -6, y: -23)
            }
        }
        .frame(width: box.width, height: box.height)
        .animation(.easeInOut(duration: Shared.nearEndFade), value: isNearEnd)
        .earFidget($fidget, isNearEnd: isNearEnd, reduceMotion: reduceMotion)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: Palette.breatheDuration).repeatForever(autoreverses: true)) { breathe = true }
            withAnimation(.easeInOut(duration: Shared.zzzDuration).repeatForever(autoreverses: false)) { zzz = true }
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
                    .fill(SlumberTheme.Art.Companion.glint)
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
                withAnimation(
                    .easeInOut(duration: SlumberTheme.Art.Companion.fidgetDuration).repeatForever(autoreverses: true)
                ) { fidget.wrappedValue = true }
            } else {
                withAnimation(.easeInOut(duration: SlumberTheme.Art.Companion.fidgetSettleDuration)) { fidget.wrappedValue = false }
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

    private typealias Layout = SlumberTheme.Art.Scene
    private typealias Orbit = SlumberTheme.Art.Orbit

    private let orbitDuration = Orbit.period
    private let launchDuration = Orbit.launchDuration
    private let returnDuration = Orbit.returnDuration
    private let orbitRadiusX = Orbit.radiusX
    private let orbitRadiusY = Orbit.radiusY

    private let cloudX = Layout.companionCloud.x
    private let cloudY = Layout.companionCloud.y
    private let moonX = Layout.moon.x
    private let moonY = Layout.moon.y

    public init(timerModel: SlumberTimer, companionType: Int, isVisible: Bool = true) {
        self.timerModel = timerModel
        self.companionType = companionType
        self.isVisible = isVisible
    }

    private var flightDuration: Double { timerModel.isRunning ? launchDuration : returnDuration }

    public var body: some View {
        ZStack {
            if isVisible {
                ConstellationOverlay()
                AuroraEffect()
                StarField(count: Layout.starCount)
            }

            if isVisible && !reduceMotion {
                FireflyField(count: Layout.fireflyCount)

                ForEach(Layout.shootingStars.indices, id: \.self) { i in
                    let star = Layout.shootingStars[i]
                    ShootingStar(
                        angle: star.angle,
                        cycleDuration: star.cycle,
                        initialDelay: star.delay,
                        length: star.length,
                        startX: star.start.x,
                        startY: star.start.y
                    )
                }
            }

            if isVisible {
                CuteMoon().offset(x: moonX, y: moonY)

                CuteCloud1(scale: Layout.largeCloudScale).offset(x: Layout.largeCloud.x, y: Layout.largeCloud.y)
                CuteCloud2(scale: Layout.smallCloudScale).offset(x: Layout.smallCloud.x, y: Layout.smallCloud.y)

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

                        let arcCtrlX = Orbit.arcControl.x
                        let arcCtrlY = Orbit.arcControl.y
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
                                                Orbit.trailHead(alpha: trailAlpha),
                                                Orbit.trailTail
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

                        let tumbleSpeed = 360.0 / Orbit.tumblePeriod
                        let continuousTumble = elapsed * tumbleSpeed  // unwrapped: a 360° wrap under the p² weight would snap the sprite
                        let spaceWobble = sin(elapsed * 2.2) * 12.0
                        let zeroGRotation = continuousTumble + spaceWobble

                        let ascentBank = Double(sin(orbitProgress * .pi)) * -18.0
                        let idleTilt = sin(t * 1.0) * 2.0
                        let finalRotation = idleTilt * (1.0 - Double(orbitProgress))
                            + ascentBank * (1.0 - Double(orbitProgress)) * Double(orbitProgress) * 4.0
                            + zeroGRotation * Double(orbitProgress * orbitProgress)

                        let depthMod = 1.0 + 0.15 * CGFloat(sin(rad)) * orbitProgress
                        let scale = Orbit.companionScale[min(max(companionType, 0), 2)]
                        let baseScale = scale.rest - scale.orbitShrink * orbitProgress
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
                duration: reduceMotion ? 0 : flightDuration
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

/// Time-based cloud ⇄ orbit transfer, eased with smootherstep.
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
        // Starts and lands with zero velocity and acceleration, like a cubic in-out, but peaks at
        // 1.9x the average speed instead of 3x: ~5 pt per frame on a 60 Hz panel instead of ~8.
        let eased = x * x * x * (x * (6.0 * x - 15.0) + 10.0)
        return from + (to - from) * CGFloat(eased)
    }
}
