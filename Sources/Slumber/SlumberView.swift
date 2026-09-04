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
// MARK: - Main Slumber Container View
// ===================================================================

public struct SlumberView: View {
    @ObservedObject public var timerModel: SlumberTimer
    @AppStorage("showInDock") private var showInDock: Bool = false
    @State private var selectedMinutes: Int = 15
    @State private var currentTab: Int = 0
    @State private var companionType: Int = Int.random(in: 0...2)
    @State private var isPopoverVisible: Bool = false
    @Namespace private var tabNamespace
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    public init(timerModel: SlumberTimer) {
        self.timerModel = timerModel
    }

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

    public var body: some View {
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
                companionType: companionType,
                isVisible: isPopoverVisible && currentTab == 0
            )
            .opacity(currentTab == 0 ? 1 : 0)
            .animation(.easeInOut(duration: 0.3), value: currentTab)

            VStack(spacing: 0) {
                // Top Segmented Bar
                HStack(spacing: SlumberTheme.Metrics.spaceXS) {
                    TabButton(
                        title: "Timer",
                        icon: "moon.zzz",
                        tag: 0,
                        currentTab: $currentTab,
                        animationNamespace: tabNamespace
                    )
                    TabButton(
                        title: "Settings",
                        icon: "gearshape",
                        tag: 1,
                        currentTab: $currentTab,
                        animationNamespace: tabNamespace
                    )
                }
                .padding(3)
                .background(
                    RoundedRectangle(cornerRadius: SlumberTheme.Radius.card, style: .continuous)
                        .fill(reduceTransparency ? Color(red: 0.13, green: 0.12, blue: 0.19) : Color.white.opacity(0.05))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: SlumberTheme.Radius.card, style: .continuous)
                        .stroke(reduceTransparency ? Color.white.opacity(0.22) : Color.white.opacity(0.08), lineWidth: 0.5)
                )
                .padding(.top, SlumberTheme.Metrics.spaceLG)
                .padding(.horizontal, SlumberTheme.Metrics.horizontalPadding)

                // Tab Pages
                ZStack {
                    if currentTab == 0 {
                        timerPage
                            .transition(.asymmetric(
                                insertion: .move(edge: .leading).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                    } else {
                        settingsPage
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .trailing).combined(with: .opacity)
                            ))
                    }
                }
                .animation(.spring(response: 0.35, dampingFraction: 0.8), value: currentTab)
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
    }

    // MARK: - Timer Page
    private var timerPage: some View {
        ZStack(alignment: .top) {
            VStack(spacing: SlumberTheme.Metrics.spaceMD + 2) {
                Spacer()

                if timerModel.isRunning {
                    let total = timerModel.totalTime
                    let prog = total > 0 ? CGFloat(timerModel.timeRemaining / total) : 0

                    ZStack {
                        PulsingRing(progress: prog)
                        VStack(spacing: SlumberTheme.Metrics.spaceXS) {
                            Text(SlumberTimeFormatter.formatCountdown(timerModel.timeRemaining))
                                .font(SlumberTheme.Typography.display)
                                .foregroundColor(SlumberTheme.Colors.textPrimary)
                                .contentTransition(.numericText())
                            Text("drifting off...")
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
                            .contentTransition(.numericText())
                        Text("min")
                            .font(SlumberTheme.Typography.displayUnit)
                            .foregroundColor(SlumberTheme.Colors.textTertiary)
                    }

                    VStack(spacing: SlumberTheme.Metrics.spaceXS + 2) {
                        GlowingSlider(value: $selectedMinutes, bounds: 1...120, onEditingChanged: { editing in
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
                        PresetChip(label: "15m", value: 15, selectedMinutes: $selectedMinutes)
                        PresetChip(label: "30m", value: 30, selectedMinutes: $selectedMinutes)
                        PresetChip(label: "45m", value: 45, selectedMinutes: $selectedMinutes)
                        PresetChip(label: "60m", value: 60, selectedMinutes: $selectedMinutes)
                        PresetChip(label: "90m", value: 90, selectedMinutes: $selectedMinutes)
                    }

                    StartButton(action: {
                        playSound("space_timer_start")
                        companionType = Int.random(in: 0...2)
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
                                .lineSpacing(2)
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
                            Text("Open Slumber from anywhere.")
                                .font(SlumberTheme.Typography.caption)
                                .foregroundColor(SlumberTheme.Colors.textSecondary)
                                .lineSpacing(2)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer()
                        KeycapBadge(keys: ["⌃", "⌥", "S"])
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

            let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "3.1"
            Text("Slumber v\(appVersion)")
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
        .preferredColorScheme(.dark)
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
