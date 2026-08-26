import Foundation
import AppKit
import IOKit.pwr_mgt

public enum TimerState: Equatable, Sendable {
    case idle
    case running
    case requestingSleep
    case sleepFailed(reason: String)
    case completed
}

public enum SleepResult: Sendable, Equatable {
    case success
    case failure(reason: String)
}

@MainActor
public class SlumberTimer: ObservableObject {
    public typealias SleepAction = @MainActor () -> SleepResult
    public typealias DateProvider = @Sendable () -> Date

    @Published public private(set) var state: TimerState = .idle
    @Published public private(set) var timeRemaining: TimeInterval = 0
    @Published public private(set) var totalTime: TimeInterval = 0
    
    public var isRunning: Bool {
        state == .running
    }
    
    public var sleepError: String? {
        if case let .sleepFailed(reason) = state {
            return reason
        }
        return nil
    }
    
    private var timer: DispatchSourceTimer?
    private var endTime: Date?
    private var activity: NSObjectProtocol?
    private var wakeObserver: NSObjectProtocol?
    private let customSleepAction: SleepAction?
    private let dateProvider: DateProvider
    
    public init(
        sleepAction: SleepAction? = nil,
        dateProvider: @escaping DateProvider = { Date() }
    ) {
        self.customSleepAction = sleepAction
        self.dateProvider = dateProvider
    }
    
    public func start(minutes: Double) {
        guard minutes > 0, minutes.isFinite else {
            NSLog("[SlumberTimer] Invalid timer duration: %f minutes", minutes)
            return
        }

        resetTimerResources()
        
        let seconds = minutes * 60
        self.totalTime = seconds
        self.timeRemaining = seconds
        self.endTime = dateProvider().addingTimeInterval(seconds)
        self.state = .running
        
        // DispatchSourceTimer on main queue
        let source = DispatchSource.makeTimerSource(queue: .main)
        source.schedule(deadline: .now() + 1, repeating: 1.0)
        source.setEventHandler { [weak self] in
            self?.tick()
        }
        source.resume()
        self.timer = source
        
        // Prevent macOS App Nap and system idle sleep while countdown is active
        if activity == nil {
            activity = ProcessInfo.processInfo.beginActivity(
                options: [.userInitiated, .idleSystemSleepDisabled],
                reason: "Running Sleep Timer"
            )
        }
        
        // Register for system wake notifications: if system wakes while timer is active,
        // recalculate remaining time from the original deadline and resume seamlessly.
        if wakeObserver == nil {
            wakeObserver = NSWorkspace.shared.notificationCenter.addObserver(
                forName: NSWorkspace.didWakeNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                MainActor.assumeIsolated {
                    self?.handleSystemWake()
                }
            }
        }
    }
    
    public func stop() {
        resetTimerResources()
        state = .idle
    }
    
    public func clearStatus() {
        resetTimerResources()
        state = .idle
    }
    
    public func retrySleep() {
        guard case .sleepFailed = state else { return }
        state = .requestingSleep
        executeSleep()
    }
    
    public func handleSystemWake() {
        guard state == .running, let deadline = endTime else { return }
        let remaining = deadline.timeIntervalSince(dateProvider())
        if remaining <= 0 {
            NSLog("[SlumberTimer] System woke but timer deadline passed. Triggering sleep.")
            tick()
        } else {
            NSLog("[SlumberTimer] System woke. Resuming countdown with %.0f seconds remaining.", remaining)
            self.timeRemaining = remaining
        }
    }
    
    private func resetTimerResources() {
        timer?.cancel()
        timer = nil
        endTime = nil
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
    
    public func tick() {
        guard state == .running, let endTime = endTime else { return }
        let remaining = endTime.timeIntervalSince(dateProvider())
        
        if remaining <= 0 {
            state = .requestingSleep
            executeSleep()
        } else {
            self.timeRemaining = remaining
        }
    }
    
    private func executeSleep() {
        resetTimerResources()
        
        if let customAction = customSleepAction {
            switch customAction() {
            case .success:
                self.state = .completed
            case .failure(let reason):
                self.state = .sleepFailed(reason: reason)
            }
            return
        }
        
        // Native macOS IOKit C API for putting the system to sleep directly
        let port = IOPMFindPowerManagement(mach_port_t(MACH_PORT_NULL))
        var sleepSucceeded = false
        if port != 0 {
            let result = IOPMSleepSystem(port)
            IOServiceClose(port)
            sleepSucceeded = (result == kIOReturnSuccess)
            if !sleepSucceeded {
                NSLog("[SlumberTimer] IOPMSleepSystem returned error code: %d, falling back to AppleScript.", result)
            }
        } else {
            NSLog("[SlumberTimer] IOPMFindPowerManagement returned null port, falling back to AppleScript.")
        }
        
        if !sleepSucceeded {
            var errorDict: NSDictionary?
            let script = NSAppleScript(source: "tell application \"System Events\" to sleep")
            let result = script?.executeAndReturnError(&errorDict)
            if let error = errorDict {
                let desc = (error[NSAppleScript.errorMessage] as? String) ?? "AppleScript execution error"
                NSLog("[SlumberTimer] AppleScript fallback sleep failed: %@", error)
                self.state = .sleepFailed(reason: "Could not put Mac to sleep: \(desc)")
                return
            } else if result == nil {
                self.state = .sleepFailed(reason: "Could not put Mac to sleep.")
                return
            }
        }
        
        self.state = .completed
    }
}
