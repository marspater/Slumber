import SwiftUI
import AppKit
import Carbon
import os
import SlumbrCore

private let appLog = Logger(subsystem: "com.marspater.slumbr", category: "app")

extension Notification.Name {
    static let slumbrOpening = Notification.Name("SlumbrOpening")
    static let slumbrClosed = Notification.Name("SlumbrClosed")
    static let slumbrTogglePopover = Notification.Name("SlumbrTogglePopover")
    /// Keyboard duration nudge; `object` is the Int minute delta.
    static let slumbrNudgeDuration = Notification.Name("SlumbrNudgeDuration")
}

/// 'SLMB'
private let hotKeySignature: OSType = 0x534C4D42

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    let timerModel = SlumbrTimer()
    private var globalMonitor: Any?
    private var keyMonitor: Any?
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?

    static let isRunningAsTestHost = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil

    func applicationDidFinishLaunching(_: Notification) {
        // Tests are hosted in the real app: skip the hotkey, status item and defaults setup there.
        guard !AppDelegate.isRunningAsTestHost else { return }
        let showInDock = UserDefaults.standard.bool(forKey: "showInDock")
        NSApp.setActivationPolicy(showInDock ? .regular : .accessory)

        popover = NSPopover()
        popover.contentSize = NSSize(
            width: SlumbrTheme.Metrics.popoverWidth,
            height: SlumbrTheme.Metrics.popoverHeight
        )
        popover.animates = true
        popover.behavior = .applicationDefined
        popover.appearance = NSAppearance(named: .vibrantDark)
        popover.delegate = self

        let hotKeyAvailable = setupGlobalHotkey()
        preloadSounds()

        NotificationCenter.default.addObserver(self, selector: #selector(handleTogglePopoverNotification), name: .slumbrTogglePopover, object: nil)

        let vc = NSHostingController(rootView: SlumbrView(timerModel: timerModel, hotKeyAvailable: hotKeyAvailable))
        vc.view.wantsLayer = true
        vc.view.appearance = NSAppearance(named: .darkAqua)
        popover.contentViewController = vc

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.autosaveName = "SlumbrMainIconV4"
        statusItem.isVisible = true
        
        if let button = statusItem.button {
            let symbolConfig = NSImage.SymbolConfiguration(pointSize: SlumbrTheme.MenuBar.symbolPointSize, weight: SlumbrTheme.MenuBar.symbolWeight)
            if let img = NSImage(systemSymbolName: SlumbrTheme.MenuBar.symbol, accessibilityDescription: "Slumbr")?
                .withSymbolConfiguration(symbolConfig) {
                img.isTemplate = true
                button.image = img
            } else if let fallback = NSImage(systemSymbolName: SlumbrTheme.MenuBar.fallbackSymbol, accessibilityDescription: "Slumbr")?
                .withSymbolConfiguration(symbolConfig) {
                fallback.isTemplate = true
                button.image = fallback
            } else {
                button.title = SlumbrTheme.MenuBar.fallbackTitle
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

    /// Returns false when ⌃⌥S could not be registered (usually another app already owns it).
    private func setupGlobalHotkey() -> Bool {
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
                    NotificationCenter.default.post(name: .slumbrTogglePopover, object: nil)
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
            appLog.error("Failed to install Carbon event handler: OSStatus \(installStatus, privacy: .public)")
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
            appLog.error("Failed to register global hotkey (⌃⌥S): OSStatus \(regStatus, privacy: .public)")
        }
        return installStatus == noErr && regStatus == noErr
    }

    func applicationWillTerminate(_: Notification) {
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
    func popoverWillShow(_: Notification) {
        NotificationCenter.default.post(name: .slumbrOpening, object: nil)
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
                        NotificationCenter.default.post(name: .slumbrNudgeDuration, object: -step)
                        return nil
                    case 124, 126: // Right, Up
                        NotificationCenter.default.post(name: .slumbrNudgeDuration, object: step)
                        return nil
                    default:
                        break
                    }
                }
                return event
            }
        }
    }

    func popoverDidClose(_: Notification) {
        NotificationCenter.default.post(name: .slumbrClosed, object: nil)
        removeGlobalMonitor()
        if let kMon = keyMonitor {
            NSEvent.removeMonitor(kMon)
            keyMonitor = nil
        }
    }

    @objc private func handleTogglePopoverNotification(_: Notification) {
        togglePopover()
    }

    @objc private func statusBarAction(_ sender: NSStatusBarButton) {
        if let event = NSApp.currentEvent, event.type == .rightMouseUp {
            let menu = NSMenu()
            menu.addItem(NSMenuItem(title: "Quit Slumbr", action: #selector(quitApp), keyEquivalent: "q"))
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
        NSApp.activate()
        popover.contentViewController?.view.window?.makeKey()
    }

    private func requestClosePopover() {
        popover.performClose(nil)
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_: NSApplication) -> Bool {
        return false
    }

    func applicationShouldHandleReopen(_: NSApplication, hasVisibleWindows _: Bool) -> Bool {
        if !popover.isShown {
            guard let button = statusItem.button else { return false }
            showPopover(from: button)
        }
        return true
    }
}

@main
struct SlumbrApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings { EmptyView() }
            .commands {
                CommandGroup(replacing: .appSettings) {
                    // Empty on purpose: removes the standard Settings… menu item.
                }
            }
    }
}
