import SwiftUI
import AppKit
import Carbon

extension Notification.Name {
    static let slumberOpening = Notification.Name("SlumberOpening")
    static let slumberCloseRequested = Notification.Name("SlumberCloseRequested")
    static let slumberActuallyClose = Notification.Name("SlumberActuallyClose")
    static let slumberTogglePopover = Notification.Name("SlumberTogglePopover")
}

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    let timerModel = SlumberTimer()
    private var globalMonitor: Any?
    private var fallbackWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let showInDock = UserDefaults.standard.bool(forKey: "showInDock")
        NSApp.setActivationPolicy(showInDock ? .regular : .accessory)

        popover = NSPopover()
        popover.contentSize = NSSize(width: 320, height: 440)
        popover.animates = true
        popover.behavior = .applicationDefined

        setupGlobalMonitor()
        setupGlobalHotkey()

        NotificationCenter.default.addObserver(self, selector: #selector(handleActuallyClose), name: .slumberActuallyClose, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleTogglePopoverNotification), name: .slumberTogglePopover, object: nil)

        let vc = NSHostingController(rootView: SlumberView(timerModel: timerModel))
        vc.view.wantsLayer = true
        vc.view.appearance = NSAppearance(named: .darkAqua)
        popover.contentViewController = vc
        DispatchQueue.main.async {
            if #available(macOS 27.0, *) {
                vc.view.layer?.preferredDynamicRange = .high
            }
        }

        statusItem = NSStatusBar.system.statusItem(withLength: 28)
        statusItem.autosaveName = "SlumberMainIconV4"
        statusItem.isVisible = true
        
        if let button = statusItem.button {
            if let img = NSImage(systemSymbolName: "cat.fill", accessibilityDescription: "Slumber") {
                img.isTemplate = true
                button.image = img
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
        
        InstallEventHandler(
            GetApplicationEventTarget(),
            handlerUPP,
            1,
            &eventSpec,
            nil,
            nil
        )
        
        let hotKeyID = EventHotKeyID(signature: 1397443650, id: 1) // 'SLMB'
        var hotKeyRef: EventHotKeyRef?
        RegisterEventHotKey(
            UInt32(1), // 'S' key
            UInt32(controlKey | optionKey),
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
    }

    func applicationWillTerminate(_ notification: Notification) {
        if let monitor = globalMonitor {
            NSEvent.removeMonitor(monitor)
            globalMonitor = nil
        }
    }

    @objc private func handleTogglePopoverNotification(_ notification: Notification) {
        if let button = statusItem.button {
            statusBarAction(button)
        }
    }

    @objc private func statusBarAction(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }
        if event.type == .rightMouseUp {
            let menu = NSMenu()
            menu.addItem(NSMenuItem(title: "Quit Slumber", action: #selector(quitApp), keyEquivalent: ""))
            statusItem.menu = menu
            statusItem.button?.performClick(nil)
            statusItem.menu = nil
        } else {
            if popover.isShown {
                requestClosePopover()
            } else {
                guard let button = statusItem.button else { return }
                
                // Set initial state for animation
                NotificationCenter.default.post(name: .slumberOpening, object: nil)
                
                // Show popover
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                
                if let layer = popover.contentViewController?.view.layer {
                    if #available(macOS 27.0, *) {
                        layer.preferredDynamicRange = .high
                    }
                }
            }
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
        guard !flag else { return true }
        if fallbackWindow == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 320, height: 440),
                styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView],
                backing: .buffered, defer: false)
            window.center()
            window.titleVisibility = .hidden
            window.titlebarAppearsTransparent = true
            window.isMovableByWindowBackground = true
            window.isReleasedWhenClosed = false
            window.isOpaque = false
            window.backgroundColor = .clear
            
            let vc = NSHostingController(rootView: SlumberView(timerModel: timerModel))
            vc.view.wantsLayer = true
            vc.view.appearance = NSAppearance(named: .darkAqua)
            if #available(macOS 27.0, *) {
                vc.view.layer?.preferredDynamicRange = .high
            }
            window.contentViewController = vc
            fallbackWindow = window
        }
        fallbackWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
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
