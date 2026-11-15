//
//  SlumbrView.swift
//  Slumbr
//
//  Root container view for the Slumbr macOS menu bar popover.
//

import SwiftUI
import AppKit
import AVFoundation
import os
import SlumbrCore

// ===================================================================
// MARK: - Audio Helper
// ===================================================================

private let audioLog = Logger(subsystem: "com.marspater.slumbr", category: "audio")

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
            audioLog.error("Audio file '\(name, privacy: .public).wav' not found in bundle resources.")
            return nil
        }
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            players[name] = player
            return player
        } catch {
            audioLog.error("Failed to initialize AVAudioPlayer for '\(name, privacy: .public).wav': \(error.localizedDescription, privacy: .public)")
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
// MARK: - Main Slumbr Container View
// ===================================================================

public struct SlumbrView: View {
    public let timerModel: SlumbrTimer
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

    public init(timerModel: SlumbrTimer, hotKeyAvailable: Bool) {
        self.timerModel = timerModel
        self.hotKeyAvailable = hotKeyAvailable
    }

    private var skyPhase: Int {
        let m = timerModel.isRunning ? Int(timerModel.totalTime / 60.0) : selectedMinutes
        return SlumbrTheme.Sky.phase(forMinutes: m)
    }

    public var body: some View {
        ZStack {
            if reduceTransparency {
                SlumbrTheme.Colors.solidBackground
            } else {
                VisualEffectView(material: .popover, blendingMode: .behindWindow)
                SlumbrTheme.Colors.solidBackground.opacity(SlumbrTheme.Sky.backdropScrimOpacity)
            }

            LinearGradient(
                colors: [
                    SlumbrTheme.Sky.top[skyPhase].opacity(reduceTransparency ? 1.0 : SlumbrTheme.Sky.topOpacity),
                    SlumbrTheme.Sky.bottom[skyPhase].opacity(reduceTransparency ? 1.0 : SlumbrTheme.Sky.bottomOpacity)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .animation(SlumbrTheme.Motion.skyPhase, value: skyPhase)

            AnimatedScene(
                timerModel: timerModel,
                companionType: companionType,
                isVisible: isPopoverVisible && currentTab == 0
            )
            .opacity(currentTab == 0 ? 1 : 0)
            .accessibilityHidden(true)

            VStack(spacing: 0) {
                // Top Segmented Bar
                HStack(spacing: SlumbrTheme.Metrics.spaceXS) {
                    TabButton(
                        title: "Timer",
                        icon: SlumbrTheme.Icons.timerTab,
                        tag: 0,
                        currentTab: $currentTab,
                        animationNamespace: tabNamespace
                    )
                    TabButton(
                        title: "Settings",
                        icon: SlumbrTheme.Icons.settingsTab,
                        tag: 1,
                        currentTab: $currentTab,
                        animationNamespace: tabNamespace
                    )
                }
                .padding(SlumbrTheme.Components.TabBar.inset)
                .background {
                    RoundedRectangle(cornerRadius: SlumbrTheme.Radius.card, style: .continuous)
                        .fill(reduceTransparency ? SlumbrTheme.Colors.solidTabBar : Color.white.opacity(SlumbrTheme.Components.TabBar.fillOpacity))
                }
                .overlay {
                    RoundedRectangle(cornerRadius: SlumbrTheme.Radius.card, style: .continuous)
                        .stroke(
                            Color.white.opacity(reduceTransparency ? SlumbrTheme.Components.TabBar.strokeOpacitySolid : SlumbrTheme.Components.TabBar.strokeOpacity),
                            lineWidth: SlumbrTheme.Stroke.hairline
                        )
                }
                .padding(.top, SlumbrTheme.Metrics.spaceLG)
                .padding(.horizontal, SlumbrTheme.Metrics.horizontalPadding)

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
        .frame(width: SlumbrTheme.Metrics.popoverWidth, height: SlumbrTheme.Metrics.popoverHeight)
        .fixedSize()
        .clipShape(RoundedRectangle(cornerRadius: SlumbrTheme.Radius.popover, style: .continuous))
        .preferredColorScheme(.dark)
        .allowedDynamicRange(.high)
        .onChange(of: showInDock) { _, v in applyDock(v) }
        .onReceive(NotificationCenter.default.publisher(for: .slumbrOpening)) { _ in
            isPopoverVisible = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .slumbrClosed)) { _ in
            isPopoverVisible = false
        }
        .onChange(of: timerModel.sleepError) { _, error in
            if let error { AccessibilityNotification.Announcement(error).post() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .slumbrNudgeDuration)) { note in
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
            VStack(spacing: SlumbrTheme.Components.TimerPage.spacing) {
                Spacer()

                if timerModel.isRunning || timerModel.state == .requestingSleep {
                    let total = timerModel.totalTime
                    let prog = total > 0 ? CGFloat(timerModel.timeRemaining / total) : 0

                    let hasHours = SlumbrTimeFormatter.hasHours(timerModel.timeRemaining)
                    let countdown = SlumbrTimeFormatter.formatCountdown(timerModel.timeRemaining)

                    ZStack {
                        PulsingRing(progress: prog)
                        VStack(spacing: SlumbrTheme.Metrics.spaceXS) {
                            Text(countdown)
                                .font(hasHours ? SlumbrTheme.Typography.displayHours : SlumbrTheme.Typography.display)
                                .foregroundStyle(SlumbrTheme.Colors.textPrimary)
                                .contentTransition(reduceMotion ? .identity : .numericText(countsDown: true))
                                .lineLimit(1)
                                .minimumScaleFactor(SlumbrTheme.Components.Countdown.minimumScaleFactor)
                                .frame(maxWidth: SlumbrTheme.Components.Countdown.maxWidth)
                                .animation(SlumbrTheme.Motion.countdownResize, value: hasHours)
                                .animation(reduceMotion ? nil : SlumbrTheme.Motion.countdownTick, value: countdown)
                            Text("drifting off…")
                                .font(SlumbrTheme.Typography.body)
                                .foregroundStyle(SlumbrTheme.Colors.textTertiary)
                        }
                    }
                    .padding(.bottom, SlumbrTheme.Metrics.spaceSM)

                    CancelButton(action: {
                        playSound("cancel")
                        timerModel.stop()
                    })
                } else {
                    HStack(alignment: .firstTextBaseline, spacing: SlumbrTheme.Metrics.spaceXXS) {
                        Text("\(selectedMinutes)")
                            .font(SlumbrTheme.Typography.display)
                            .foregroundStyle(SlumbrTheme.Colors.textPrimary)
                            .contentTransition(reduceMotion ? .identity : .numericText())
                        Text("min")
                            .font(SlumbrTheme.Typography.displayUnit)
                            .foregroundStyle(SlumbrTheme.Colors.textTertiary)
                    }

                    VStack(spacing: SlumbrTheme.Components.Slider.boundsSpacing) {
                        GlowingSlider(value: $selectedMinutes, bounds: 1...120, onEditingChanged: { editing in
                            isSliding = editing
                            if !editing { playSound("space_button") }
                        })
                        .frame(width: SlumbrTheme.Metrics.contentWidth)

                        HStack {
                            Text("1 min")
                            Spacer()
                            Text("120 min")
                        }
                        .font(SlumbrTheme.Typography.micro)
                        .foregroundStyle(SlumbrTheme.Colors.textTertiary)
                        .frame(width: SlumbrTheme.Metrics.contentWidth)
                    }

                    HStack(spacing: SlumbrTheme.Metrics.spaceSM) {
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
                    .padding(.top, SlumbrTheme.Metrics.spaceXS)
                }

                Spacer()
            }

            if case let .sleepFailed(reason) = timerModel.state {
                ErrorBanner(
                    reason: reason,
                    onRetry: { timerModel.retrySleep() },
                    onDismiss: { timerModel.clearStatus() }
                )
                .frame(width: SlumbrTheme.Metrics.contentWidth)
                .padding(.top, SlumbrTheme.Metrics.spaceSM)
                .transition(reduceMotion ? .opacity : .asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity).combined(with: .scale(scale: SlumbrTheme.Motion.bannerInsertScale)),
                    removal: .move(edge: .top).combined(with: .opacity)
                ))
            }
        }
        .allowsHitTesting(currentTab == 0)
        .animation(reduceMotion ? nil : SlumbrTheme.Motion.stateChange, value: timerModel.state)
        .animation(reduceMotion ? nil : SlumbrTheme.Motion.runningChange, value: timerModel.isRunning)
    }

    // MARK: - Settings Page
    private var settingsPage: some View {
        VStack(spacing: 0) {
            VStack(spacing: SlumbrTheme.Metrics.spaceMD) {
                SettingsCard {
                    HStack(alignment: .center, spacing: SlumbrTheme.Metrics.spaceMD) {
                        VStack(alignment: .leading, spacing: SlumbrTheme.Metrics.spaceXS) {
                            Text("Show in Dock")
                                .font(SlumbrTheme.Typography.title)
                                .foregroundStyle(SlumbrTheme.Colors.textPrimary)
                            Text("Display dock icon alongside the menu bar.")
                                .font(SlumbrTheme.Typography.caption)
                                .foregroundStyle(SlumbrTheme.Colors.textSecondary)
                                .lineSpacing(SlumbrTheme.Typography.captionLineSpacing)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer()
                        Toggle("", isOn: $showInDock)
                            .toggleStyle(.switch)
                            .tint(SlumbrTheme.Colors.accent)
                            .labelsHidden()
                            .accessibilityLabel("Show in Dock")
                    }
                }

                SettingsCard {
                    HStack(alignment: .center, spacing: SlumbrTheme.Metrics.spaceMD) {
                        VStack(alignment: .leading, spacing: SlumbrTheme.Metrics.spaceXS) {
                            Text("Global Shortcut")
                                .font(SlumbrTheme.Typography.title)
                                .foregroundStyle(SlumbrTheme.Colors.textPrimary)
                            Text(hotKeyAvailable ? "Open Slumbr from anywhere." : "Unavailable: another app uses this shortcut.")
                                .font(SlumbrTheme.Typography.caption)
                                .foregroundStyle(SlumbrTheme.Colors.textSecondary)
                                .lineSpacing(SlumbrTheme.Typography.captionLineSpacing)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer()
                        KeycapBadge(keys: ["⌃", "⌥", "S"])
                            .opacity(hotKeyAvailable ? 1.0 : SlumbrTheme.Opacity.disabled)
                            .accessibilityElement(children: .ignore)
                            .accessibilityLabel("Shortcut Control Option S")
                    }
                }
            }
            .padding(.top, SlumbrTheme.Metrics.spaceXL)

            Spacer()

            QuitButton(action: {
                NSApp.terminate(nil)
            })
            .padding(.bottom, SlumbrTheme.Metrics.spaceMD)

            let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
            Text(appVersion.map { "Slumbr v\($0)" } ?? "Slumbr")
                .font(SlumbrTheme.Typography.caption.weight(.semibold))
                .foregroundStyle(SlumbrTheme.Colors.textTertiary)
                .frame(maxWidth: .infinity, alignment: .center)
            Text("Made with ❤️ for peaceful nights")
                .font(SlumbrTheme.Typography.micro)
                .foregroundStyle(SlumbrTheme.Colors.textQuaternary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, SlumbrTheme.Metrics.spaceXXS)
                .padding(.bottom, SlumbrTheme.Metrics.spaceLG)
        }
        .padding(.horizontal, SlumbrTheme.Metrics.horizontalPadding)
        .allowsHitTesting(currentTab == 1)
    }

    private func applyDock(_ show: Bool) {
        DispatchQueue.main.async {
            NSApp.setActivationPolicy(show ? .regular : .accessory)
            if show {
                NSApp.activate()
            }
        }
    }
}
