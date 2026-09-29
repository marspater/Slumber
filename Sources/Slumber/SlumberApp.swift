import SwiftUI
import AppKit
import Carbon
import SlumberCore

extension Notification.Name {
    static let slumberOpening = Notification.Name("SlumberOpening")
    static let slumberClosed = Notification.Name("SlumberClosed")
    static let slumberTogglePopover = Notification.Name("SlumberTogglePopover")
    /// Keyboard duration nudge; `object` is the Int minute delta.
    static let slumberNudgeDuration = Notification.Name("SlumberNudgeDuration")
}

/// 'SLMB'
private let hotKeySignature: OSType = 0x534C4D42

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    let timerModel = SlumberTimer()
    private var globalMonitor: Any?
    private var keyMonitor: Any?
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let showInDock = UserDefaults.standard.bool(forKey: "showInDock")
        NSApp.setActivationPolicy(showInDock ? .regular : .accessory)

        popover = NSPopover()
        popover.contentSize = NSSize(
            width: SlumberTheme.Metrics.popoverWidth,
            height: SlumberTheme.Metrics.popoverHeight
        )
        popover.animates = true
        popover.behavior = .applicationDefined
        popover.appearance = NSAppearance(named: .vibrantDark)
        popover.delegate = self

        setupGlobalHotkey()
        preloadSounds()

        NotificationCenter.default.addObserver(self, selector: #selector(handleTogglePopoverNotification), name: .slumberTogglePopover, object: nil)

        let vc = NSHostingController(rootView: SlumberView(timerModel: timerModel))
        vc.view.wantsLayer = true
        vc.view.appearance = NSAppearance(named: .darkAqua)
        popover.contentViewController = vc

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.autosaveName = "SlumberMainIconV4"
        statusItem.isVisible = true
        
        if let button = statusItem.button {
            // Match the optical size/weight of the system menu bar extras (Wi-Fi, Control Center).
            let symbolConfig = NSImage.SymbolConfiguration(pointSize: 16, weight: .medium)
            if let img = NSImage(systemSymbolName: "moon.circle", accessibilityDescription: "Slumber")?
                .withSymbolConfiguration(symbolConfig) {
                img.isTemplate = true
                button.image = img
            } else if let fallback = NSImage(systemSymbolName: "moon.fill", accessibilityDescription: "Slumber")?
                .withSymbolConfiguration(symbolConfig) {
                fallback.isTemplate = true
                button.image = fallback
            } else {
                button.title = "🌙"
            }
            button.imagePosition = .imageOnly
            button.target = self
            button.action = #selector(statusBarAction(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
    }

    private func setupGlobalMonitor() {
        guard globalMonitor == nil else { return }
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self = self else { return }
            Task { @MainActor in
                guard self.popover.isShown else { return }
                
                if let button = self.statusItem.button,
                   let window = button.window {
                    let mouseLocation = NSEvent.mouseLocation
                    let buttonBoundsInWindow = button.convert(button.bounds, to: nil)
                    let buttonRect = window.convertToScreen(buttonBoundsInWindow)
                    if buttonRect.contains(mouseLocation) {
                        return
                    }
                }
                self.requestClosePopover()
            }
        }
    }

    private func removeGlobalMonitor() {
        if let monitor = globalMonitor {
            NSEvent.removeMonitor(monitor)
            globalMonitor = nil
        }
    }

    private func setupGlobalHotkey() {
        var eventSpec = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        
        let handlerUPP: EventHandlerUPP = { (nextHandler, theEvent, userData) -> OSStatus in
            var hotKeyID = EventHotKeyID()
            let status = GetEventParameter(
                theEvent,
                EventParamName(kEventParamDirectObject),
                EventParamType(typeEventHotKeyID),
                nil,
                MemoryLayout<EventHotKeyID>.size,
                nil,
                &hotKeyID
            )
            if status == noErr && hotKeyID.signature == hotKeySignature && hotKeyID.id == 1 {
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .slumberTogglePopover, object: nil)
                }
                return noErr
            }
            return CallNextEventHandler(nextHandler, theEvent)
        }
        
        let installStatus = InstallEventHandler(
            GetApplicationEventTarget(),
            handlerUPP,
            1,
            &eventSpec,
            nil,
            &eventHandlerRef
        )
        if installStatus != noErr {
            NSLog("[SlumberApp] Failed to install Carbon event handler: OSStatus %d", installStatus)
        }
        
        let hotKeyID = EventHotKeyID(signature: hotKeySignature, id: 1)
        let regStatus = RegisterEventHotKey(
            UInt32(1), // 'S' key
            UInt32(controlKey | optionKey),
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
        if regStatus != noErr {
            NSLog("[SlumberApp] Failed to register global hotkey (⌃⌥S): OSStatus %d", regStatus)
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        timerModel.stop()
        if let hk = hotKeyRef {
            UnregisterEventHotKey(hk)
            hotKeyRef = nil
        }
        if let eh = eventHandlerRef {
            RemoveEventHandler(eh)
            eventHandlerRef = nil
        }
        removeGlobalMonitor()
        if let kMon = keyMonitor {
            NSEvent.removeMonitor(kMon)
            keyMonitor = nil
        }
    }

    // MARK: - NSPopoverDelegate
    func popoverWillShow(_ notification: Notification) {
        NotificationCenter.default.post(name: .slumberOpening, object: nil)
        setupGlobalMonitor()
        if keyMonitor == nil {
            keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
                if event.keyCode == 53 { // Escape
                    self?.requestClosePopover()
                    return nil
                }
                // Arrow keys adjust the duration (the slider itself stays non-focusable to avoid
                // focus chrome). Shift steps by 5. Cmd/Opt/Ctrl combos pass through.
                let step = event.modifierFlags.contains(.shift) ? 5 : 1
                if event.modifierFlags.intersection([.command, .option, .control]).isEmpty {
                    switch event.keyCode {
                    case 123, 125: // Left, Down
                        NotificationCenter.default.post(name: .slumberNudgeDuration, object: -step)
                        return nil
                    case 124, 126: // Right, Up
                        NotificationCenter.default.post(name: .slumberNudgeDuration, object: step)
                        return nil
                    default:
                        break
                    }
                }
                return event
            }
        }
    }

    func popoverDidClose(_ notification: Notification) {
        NotificationCenter.default.post(name: .slumberClosed, object: nil)
        removeGlobalMonitor()
        if let kMon = keyMonitor {
            NSEvent.removeMonitor(kMon)
            keyMonitor = nil
        }
    }

    @objc private func handleTogglePopoverNotification(_ notification: Notification) {
        togglePopover()
    }

    @objc private func statusBarAction(_ sender: NSStatusBarButton) {
        if let event = NSApp.currentEvent, event.type == .rightMouseUp {
            let menu = NSMenu()
            menu.addItem(NSMenuItem(title: "Quit Slumber", action: #selector(quitApp), keyEquivalent: "q"))
            menu.popUp(positioning: nil, at: NSPoint(x: 0, y: sender.bounds.height), in: sender)
        } else {
            togglePopover()
        }
    }

    private func togglePopover() {
        if popover.isShown {
            requestClosePopover()
        } else {
            guard let button = statusItem.button else { return }
            showPopover(from: button)
        }
    }

    /// Activates the app so the popover window becomes key and the Escape/arrow monitors receive keys
    /// (the global hotkey path otherwise leaves another app frontmost).
    private func showPopover(from button: NSStatusBarButton) {
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        NSApp.activate(ignoringOtherApps: true)
        popover.contentViewController?.view.window?.makeKey()
    }

    private func requestClosePopover() {
        popover.performClose(nil)
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !popover.isShown {
            guard let button = statusItem.button else { return false }
            showPopover(from: button)
        }
        return true
    }
}

@main
struct SlumberApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings { EmptyView() }
            .commands { CommandGroup(replacing: .appSettings) {} }
    }
}
