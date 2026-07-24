import Foundation
import AppKit
import IOKit.pwr_mgt

@MainActor
public class SlumberTimer: ObservableObject {
    @Published public var timeRemaining: TimeInterval = 0
    @Published public var totalTime: TimeInterval = 0
    @Published public var isRunning: Bool = false
    
    private var timer: DispatchSourceTimer?
    private var endTime: Date?
    private var activity: NSObjectProtocol?
    private var wakeObserver: NSObjectProtocol?
    
    public init() {}
    
    public func start(minutes: Double) {
        // Guard against double-start — cancel any existing timer first
        if timer != nil {
            stop()
        }
        
        let seconds = minutes * 60
        self.totalTime = seconds
        self.timeRemaining = seconds
        self.endTime = Date().addingTimeInterval(seconds)
        self.isRunning = true
        
        // DispatchSourceTimer is more reliable than Timer.publish:
        // it doesn't depend on RunLoop mode and fires correctly even
        // when the popover is closed and reopened.
        let source = DispatchSource.makeTimerSource(queue: .main)
        source.schedule(deadline: .now() + 1, repeating: 1.0)
        source.setEventHandler { [weak self] in
            Task { @MainActor in
                self?.tick()
            }
        }
        source.resume()
        self.timer = source
        
        // Prevent macOS App Nap and system idle sleep from throttling/sleeping prematurely
        if activity == nil {
            activity = ProcessInfo.processInfo.beginActivity(
                options: [.userInitiated, .idleSystemSleepDisabled],
                reason: "Running Sleep Timer"
            )
        }
        
        // Register for system wake notifications to cancel the timer on wake.
        // If the user wakes the computer, they are active; we shouldn't trigger an overdue sleep command.
        if wakeObserver == nil {
            wakeObserver = NSWorkspace.shared.notificationCenter.addObserver(
                forName: NSWorkspace.didWakeNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor in
                    self?.stop()
                }
            }
        }
    }
    
    public func stop() {
        timer?.cancel()
        timer = nil
        isRunning = false
        timeRemaining = 0
        
        if let currentActivity = activity {
            ProcessInfo.processInfo.endActivity(currentActivity)
            activity = nil
        }
        
        if let observer = wakeObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
            wakeObserver = nil
        }
    }
    
    private func tick() {
        guard let endTime = endTime else { return }
        let remaining = endTime.timeIntervalSinceNow
        
        if remaining <= 0 {
            self.stop()
            self.executeSleep()
        } else {
            self.timeRemaining = remaining
        }
    }
    
    private func executeSleep() {
        // Native macOS IOKit C API for putting the system to sleep directly without spawning subprocesses
        let port = IOPMFindPowerManagement(mach_port_t(MACH_PORT_NULL))
        if port != 0 {
            IOPMSleepSystem(port)
            IOServiceClose(port)
        } else {
            let script = NSAppleScript(source: "tell application \"System Events\" to sleep")
            script?.executeAndReturnError(nil)
        }
    }
}
