import SwiftUI
import AppKit
import Carbon

extension Notification.Name {
    static let slumberOpening = Notification.Name("SlumberOpening")
    static let slumberClosed = Notification.Name("SlumberClosed")
    static let slumberCloseRequested = Notification.Name("SlumberCloseRequested")
    static let slumberActuallyClose = Notification.Name("SlumberActuallyClose")
    static let slumberTogglePopover = Notification.Name("SlumberTogglePopover")
}

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    let timerModel = SlumberTimer()
    private var globalMonitor: Any?
    private var keyMonitor: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let showInDock = UserDefaults.standard.bool(forKey: "showInDock")
        NSApp.setActivationPolicy(showInDock ? .regular : .accessory)

        // Load custom app icon from bundle resources or asset artwork
        let iconURL = Bundle.main.url(forResource: "AppIcon", withExtension: "icns")
            ?? Bundle.main.url(forResource: "app_icon", withExtension: "png")
            ?? Bundle.main.urls(forResourcesWithExtension: "png", subdirectory: "Assets/New_Icon.icon/Assets")?.first
            ?? Bundle.main.urls(forResourcesWithExtension: "png", subdirectory: nil)?.first(where: { $0.path.contains(".icon") })
        if let url = iconURL, let customIcon = NSImage(contentsOf: url) {
            NSApp.applicationIconImage = customIcon
        }

        popover = NSPopover()
        popover.contentSize = NSSize(width: 320, height: 440)
        popover.animates = true
        popover.behavior = .applicationDefined
        popover.appearance = NSAppearance(named: .vibrantDark)
        popover.delegate = self

        setupGlobalMonitor()
        setupGlobalHotkey()
        setupDisplayObserver()

        NotificationCenter.default.addObserver(self, selector: #selector(handleActuallyClose), name: .slumberActuallyClose, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleTogglePopoverNotification), name: .slumberTogglePopover, object: nil)

        let vc = NSHostingController(rootView: SlumberView(timerModel: timerModel))
        vc.view.wantsLayer = true
        vc.view.appearance = NSAppearance(named: .darkAqua)
        popover.contentViewController = vc

        statusItem = NSStatusBar.system.statusItem(withLength: 28)
        statusItem.autosaveName = "SlumberMainIconV4"
        statusItem.isVisible = true
        
        if let button = statusItem.button {
            if let img = NSImage(systemSymbolName: "cat.fill", accessibilityDescription: "Slumber") {
                img.isTemplate = true
                button.image = img
            } else if let fallback = NSImage(systemSymbolName: "moon.fill", accessibilityDescription: "Slumber") {
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
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self = self else { return }
            Task { @MainActor in
                guard self.popover.isShown else { return }
                
                if let button = self.statusItem.button,
                   let window = button.window {
                    let mouseLocation = NSEvent.mouseLocation
                    let buttonRect = window.convertToScreen(button.frame)
                    if buttonRect.contains(mouseLocation) {
                        return
                    }
                }
                self.requestClosePopover()
            }
        }
    }

    private func setupGlobalHotkey() {
        var eventSpec = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        
        let handlerUPP: EventHandlerUPP = { (nextHandler, theEvent, userData) -> OSStatus in
            NotificationCenter.default.post(name: .slumberTogglePopover, object: nil)
            return noErr
        }
        
        let installStatus = InstallEventHandler(
            GetApplicationEventTarget(),
            handlerUPP,
            1,
            &eventSpec,
            nil,
            nil
        )
        if installStatus != noErr {
            NSLog("[SlumberApp] Failed to install Carbon event handler: OSStatus %d", installStatus)
        }
        
        let hotKeyID = EventHotKeyID(signature: 1397443650, id: 1) // 'SLMB'
        var hotKeyRef: EventHotKeyRef?
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

    private func setupDisplayObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleDisplayModeChange),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }

    @objc private func handleDisplayModeChange() {
        guard let screen = NSScreen.main else { return }
        let _ = screen.maximumExtendedDynamicRangeColorComponentValue
        Task { @MainActor in
            popover?.contentViewController?.view.needsDisplay = true
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        if let monitor = globalMonitor {
            NSEvent.removeMonitor(monitor)
            globalMonitor = nil
        }
        if let kMon = keyMonitor {
            NSEvent.removeMonitor(kMon)
            keyMonitor = nil
        }
    }

    // MARK: - NSPopoverDelegate
    func popoverWillShow(_ notification: Notification) {
        NotificationCenter.default.post(name: .slumberOpening, object: nil)
        if keyMonitor == nil {
            keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
                if event.keyCode == 53 { // Escape
                    self?.requestClosePopover()
                    return nil
                }
                return event
            }
        }
    }

    func popoverDidClose(_ notification: Notification) {
        NotificationCenter.default.post(name: .slumberClosed, object: nil)
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
            statusItem.menu = menu
            statusItem.button?.performClick(nil)
            DispatchQueue.main.async { [weak self] in
                self?.statusItem.menu = nil
            }
        } else {
            togglePopover()
        }
    }

    private func togglePopover() {
        if popover.isShown {
            requestClosePopover()
        } else {
            guard let button = statusItem.button else { return }
            NotificationCenter.default.post(name: .slumberOpening, object: nil)
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }

    private func requestClosePopover() {
        popover.performClose(nil)
    }

    @objc private func handleActuallyClose() {
        popover.performClose(nil)
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        togglePopover()
        return true
    }
}

@main
struct SlumberApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings { EmptyView() }
    }
}
