import Foundation
import AppKit

@MainActor
class SlumberTimer: ObservableObject {
    @Published var timeRemaining: TimeInterval = 0
    @Published var totalTime: TimeInterval = 0
    @Published var isRunning: Bool = false
    
    private var timer: DispatchSourceTimer?
    private var endTime: Date?
    private var activity: NSObjectProtocol?
    private var wakeObserver: NSObjectProtocol?
    
    func start(minutes: Double) {
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
    
    func stop() {
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
        // Force sleep using pmset to override any active power assertions (like playing media)
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/pmset")
        process.arguments = ["sleepnow"]
        
        do {
            try process.run()
        } catch {
            NSLog("Slumber Error: Failed to execute sleep command - \(error.localizedDescription)")
        }
    }
}
