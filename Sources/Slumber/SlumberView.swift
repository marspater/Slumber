//
//  SlumberView.swift
//  Slumber
//
//  Root container view for the Slumber macOS menu bar popover.
//

import SwiftUI
import AppKit
import AVFoundation
import SlumberCore

// ===================================================================
// MARK: - Audio Helper
// ===================================================================

private let soundNames = ["space_timer_start", "cancel", "space_button"]

/// Owns the players off the main actor: creating one and calling `play()` each block for
/// 100-250 ms, which froze the UI (and the companion launch) the moment Start was pressed.
private actor SoundBoard {
    static let shared = SoundBoard()
    private var players: [String: AVAudioPlayer] = [:]

    func play(_ name: String) {
        guard let player = player(named: name) else { return }
        if player.isPlaying { player.currentTime = 0 }
        player.play()
    }

    func preload() {
        for name in soundNames { _ = player(named: name) }
    }

    private func player(named name: String) -> AVAudioPlayer? {
        if let player = players[name] { return player }
        guard let url = Bundle.main.url(forResource: name, withExtension: "wav") else {
            NSLog("[SlumberAudio] Audio file '%@.wav' not found in bundle resources.", name)
            return nil
        }
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            players[name] = player
            return player
        } catch {
            NSLog("[SlumberAudio] Failed to initialize AVAudioPlayer for '%@.wav': %@", name, error.localizedDescription)
            return nil
        }
    }
}

@MainActor
func playSound(_ name: String) {
    Task { await SoundBoard.shared.play(name) }
}

/// Builds every player up front so the first tap does not pay for it.
@MainActor
func preloadSounds() {
    Task { await SoundBoard.shared.preload() }
}

// ===================================================================
// MARK: - Main Slumber Container View
// ===================================================================

public struct SlumberView: View {
    @ObservedObject public var timerModel: SlumberTimer
    @AppStorage("showInDock") private var showInDock: Bool = false
    @State private var selectedMinutes: Int = 15
    @State private var isSliding: Bool = false
    @State private var currentTab: Int = 0
    @State private var companionType: Int = Int.random(in: 0...2)
    @State private var isPopoverVisible: Bool = false
    /// False when another app already owns ⌃⌥S, so Settings can say the shortcut is unavailable.
    private let hotKeyAvailable: Bool
    @Namespace private var tabNamespace
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(timerModel: SlumberTimer, hotKeyAvailable: Bool) {
        self.timerModel = timerModel
        self.hotKeyAvailable = hotKeyAvailable
    }

    private var skyPhase: Int {
        let m = timerModel.isRunning ? Int(timerModel.totalTime / 60.0) : selectedMinutes
        return SlumberTheme.Sky.phase(forMinutes: m)
    }

    public var body: some View {
        ZStack {
            if reduceTransparency {
                SlumberTheme.Colors.solidBackground
            } else {
                VisualEffectView(material: .popover, blendingMode: .behindWindow)
            }

            LinearGradient(
                colors: [
                    SlumberTheme.Sky.top[skyPhase].opacity(reduceTransparency ? 1.0 : SlumberTheme.Sky.topOpacity),
                    SlumberTheme.Sky.bottom[skyPhase].opacity(reduceTransparency ? 1.0 : SlumberTheme.Sky.bottomOpacity)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .animation(SlumberTheme.Motion.skyPhase, value: skyPhase)

            AnimatedScene(
                timerModel: timerModel,
                companionType: companionType,
                isVisible: isPopoverVisible && currentTab == 0
            )
            .opacity(currentTab == 0 ? 1 : 0)
            .accessibilityHidden(true)

            VStack(spacing: 0) {
                // Top Segmented Bar
                HStack(spacing: SlumberTheme.Metrics.spaceXS) {
                    TabButton(
                        title: "Timer",
                        icon: SlumberTheme.Icons.timerTab,
                        tag: 0,
                        currentTab: $currentTab,
                        animationNamespace: tabNamespace
                    )
                    TabButton(
                        title: "Settings",
                        icon: SlumberTheme.Icons.settingsTab,
                        tag: 1,
                        currentTab: $currentTab,
                        animationNamespace: tabNamespace
                    )
                }
                .padding(SlumberTheme.Components.TabBar.inset)
                .background(
                    RoundedRectangle(cornerRadius: SlumberTheme.Radius.card, style: .continuous)
                        .fill(reduceTransparency ? SlumberTheme.Colors.solidTabBar : Color.white.opacity(SlumberTheme.Components.TabBar.fillOpacity))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: SlumberTheme.Radius.card, style: .continuous)
                        .stroke(
                            Color.white.opacity(reduceTransparency ? SlumberTheme.Components.TabBar.strokeOpacitySolid : SlumberTheme.Components.TabBar.strokeOpacity),
                            lineWidth: SlumberTheme.Stroke.hairline
                        )
                )
                .padding(.top, SlumberTheme.Metrics.spaceLG)
                .padding(.horizontal, SlumberTheme.Metrics.horizontalPadding)

                // Tab Pages
                ZStack {
                    if currentTab == 0 {
                        timerPage
                            .transition(pageTransition(edge: .leading))
                    } else {
                        settingsPage
                            .transition(pageTransition(edge: .trailing))
                    }
                }
            }
        }
        .frame(width: SlumberTheme.Metrics.popoverWidth, height: SlumberTheme.Metrics.popoverHeight)
        .fixedSize()
        .clipShape(RoundedRectangle(cornerRadius: SlumberTheme.Radius.popover, style: .continuous))
        .preferredColorScheme(.dark)
        .allowedDynamicRange(.high)
        .onChange(of: showInDock) { _, v in applyDock(v) }
        .onReceive(NotificationCenter.default.publisher(for: .slumberOpening)) { _ in
            isPopoverVisible = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .slumberClosed)) { _ in
            isPopoverVisible = false
        }
        .onChange(of: timerModel.sleepError) { _, error in
            if let error { AccessibilityNotification.Announcement(error).post() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .slumberNudgeDuration)) { note in
            guard currentTab == 0, !timerModel.isRunning, let delta = note.object as? Int else { return }
            selectedMinutes = min(max(selectedMinutes + delta, 1), 120)
        }
    }

    private func pageTransition(edge: Edge) -> AnyTransition {
        reduceMotion ? .opacity : .asymmetric(
            insertion: .move(edge: edge).combined(with: .opacity),
            removal: .move(edge: edge).combined(with: .opacity)
        )
    }

    // MARK: - Timer Page
    private var timerPage: some View {
        ZStack(alignment: .top) {
            VStack(spacing: SlumberTheme.Components.TimerPage.spacing) {
                Spacer()

                if timerModel.isRunning || timerModel.state == .requestingSleep {
                    let total = timerModel.totalTime
                    let prog = total > 0 ? CGFloat(timerModel.timeRemaining / total) : 0

                    let hasHours = SlumberTimeFormatter.hasHours(timerModel.timeRemaining)
                    let countdown = SlumberTimeFormatter.formatCountdown(timerModel.timeRemaining)

                    ZStack {
                        PulsingRing(progress: prog)
                        VStack(spacing: SlumberTheme.Metrics.spaceXS) {
                            Text(countdown)
                                .font(hasHours ? SlumberTheme.Typography.displayHours : SlumberTheme.Typography.display)
                                .foregroundColor(SlumberTheme.Colors.textPrimary)
                                .contentTransition(reduceMotion ? .identity : .numericText(countsDown: true))
                                .lineLimit(1)
                                .minimumScaleFactor(SlumberTheme.Components.Countdown.minimumScaleFactor)
                                .frame(maxWidth: SlumberTheme.Components.Countdown.maxWidth)
                                .animation(SlumberTheme.Motion.countdownResize, value: hasHours)
                                .animation(reduceMotion ? nil : SlumberTheme.Motion.countdownTick, value: countdown)
                            Text("drifting off…")
                                .font(SlumberTheme.Typography.body)
                                .foregroundColor(SlumberTheme.Colors.textTertiary)
                        }
                    }
                    .padding(.bottom, SlumberTheme.Metrics.spaceSM)

                    CancelButton(action: {
                        playSound("cancel")
                        timerModel.stop()
                    })
                } else {
                    HStack(alignment: .firstTextBaseline, spacing: SlumberTheme.Metrics.spaceXXS) {
                        Text("\(selectedMinutes)")
                            .font(SlumberTheme.Typography.display)
                            .foregroundColor(SlumberTheme.Colors.textPrimary)
                            .contentTransition(reduceMotion ? .identity : .numericText())
                        Text("min")
                            .font(SlumberTheme.Typography.displayUnit)
                            .foregroundColor(SlumberTheme.Colors.textTertiary)
                    }

                    VStack(spacing: SlumberTheme.Components.Slider.boundsSpacing) {
                        GlowingSlider(value: $selectedMinutes, bounds: 1...120, onEditingChanged: { editing in
                            isSliding = editing
                            if !editing { playSound("space_button") }
                        })
                        .frame(width: SlumberTheme.Metrics.contentWidth)

                        HStack {
                            Text("1 min")
                            Spacer()
                            Text("120 min")
                        }
                        .font(SlumberTheme.Typography.micro)
                        .foregroundColor(SlumberTheme.Colors.textTertiary)
                        .frame(width: SlumberTheme.Metrics.contentWidth)
                    }

                    HStack(spacing: SlumberTheme.Metrics.spaceSM) {
                        PresetChip(label: "15m", value: 15, selectedMinutes: $selectedMinutes, isSliding: isSliding)
                        PresetChip(label: "30m", value: 30, selectedMinutes: $selectedMinutes, isSliding: isSliding)
                        PresetChip(label: "45m", value: 45, selectedMinutes: $selectedMinutes, isSliding: isSliding)
                        PresetChip(label: "60m", value: 60, selectedMinutes: $selectedMinutes, isSliding: isSliding)
                        PresetChip(label: "90m", value: 90, selectedMinutes: $selectedMinutes, isSliding: isSliding)
                    }

                    StartButton(action: {
                        playSound("space_timer_start")
                        // A different companion flies on every start.
                        companionType = (companionType + Int.random(in: 1...2)) % 3
                        timerModel.start(minutes: Double(selectedMinutes))
                    })
                    .padding(.top, SlumberTheme.Metrics.spaceXS)
                }

                Spacer()
            }

            if case let .sleepFailed(reason) = timerModel.state {
                ErrorBanner(
                    reason: reason,
                    onRetry: { timerModel.retrySleep() },
                    onDismiss: { timerModel.clearStatus() }
                )
                .frame(width: SlumberTheme.Metrics.contentWidth)
                .padding(.top, SlumberTheme.Metrics.spaceSM)
                .transition(reduceMotion ? .opacity : .asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity).combined(with: .scale(scale: SlumberTheme.Motion.bannerInsertScale)),
                    removal: .move(edge: .top).combined(with: .opacity)
                ))
            }
        }
        .allowsHitTesting(currentTab == 0)
        .animation(reduceMotion ? nil : SlumberTheme.Motion.stateChange, value: timerModel.state)
        .animation(reduceMotion ? nil : SlumberTheme.Motion.runningChange, value: timerModel.isRunning)
    }

    // MARK: - Settings Page
    private var settingsPage: some View {
        VStack(spacing: 0) {
            VStack(spacing: SlumberTheme.Metrics.spaceMD) {
                SettingsCard {
                    HStack(alignment: .center, spacing: SlumberTheme.Metrics.spaceMD) {
                        VStack(alignment: .leading, spacing: SlumberTheme.Metrics.spaceXS) {
                            Text("Show in Dock")
                                .font(SlumberTheme.Typography.title)
                                .foregroundColor(SlumberTheme.Colors.textPrimary)
                            Text("Display dock icon alongside the menu bar.")
                                .font(SlumberTheme.Typography.caption)
                                .foregroundColor(SlumberTheme.Colors.textSecondary)
                                .lineSpacing(SlumberTheme.Typography.captionLineSpacing)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer()
                        Toggle("", isOn: $showInDock)
                            .toggleStyle(.switch)
                            .tint(SlumberTheme.Colors.accent)
                            .labelsHidden()
                            .accessibilityLabel("Show in Dock")
                    }
                }

                SettingsCard {
                    HStack(alignment: .center, spacing: SlumberTheme.Metrics.spaceMD) {
                        VStack(alignment: .leading, spacing: SlumberTheme.Metrics.spaceXS) {
                            Text("Global Shortcut")
                                .font(SlumberTheme.Typography.title)
                                .foregroundColor(SlumberTheme.Colors.textPrimary)
                            Text(hotKeyAvailable ? "Open Slumber from anywhere." : "Unavailable: another app uses this shortcut.")
                                .font(SlumberTheme.Typography.caption)
                                .foregroundColor(SlumberTheme.Colors.textSecondary)
                                .lineSpacing(SlumberTheme.Typography.captionLineSpacing)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer()
                        KeycapBadge(keys: ["⌃", "⌥", "S"])
                            .opacity(hotKeyAvailable ? 1.0 : SlumberTheme.Opacity.disabled)
                            .accessibilityElement(children: .ignore)
                            .accessibilityLabel("Shortcut Control Option S")
                    }
                }
            }
            .padding(.top, SlumberTheme.Metrics.spaceXL)

            Spacer()

            QuitButton(action: {
                NSApp.terminate(nil)
            })
            .padding(.bottom, SlumberTheme.Metrics.spaceMD)

            let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
            Text(appVersion.map { "Slumber v\($0)" } ?? "Slumber")
                .font(SlumberTheme.Typography.caption.weight(.semibold))
                .foregroundColor(SlumberTheme.Colors.textTertiary)
                .frame(maxWidth: .infinity, alignment: .center)
            Text("Made with ❤️ for peaceful nights")
                .font(SlumberTheme.Typography.micro)
                .foregroundColor(SlumberTheme.Colors.textQuaternary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, SlumberTheme.Metrics.spaceXXS)
                .padding(.bottom, SlumberTheme.Metrics.spaceLG)
        }
        .padding(.horizontal, SlumberTheme.Metrics.horizontalPadding)
        .allowsHitTesting(currentTab == 1)
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
