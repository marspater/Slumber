import Foundation
import AppKit
import IOKit.pwr_mgt
import os

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

private let log = Logger(subsystem: "com.marspater.slumbr", category: "timer")

@MainActor
public class SlumbrTimer: ObservableObject {
    public typealias SleepAction = @MainActor () -> SleepResult
    public typealias DateProvider = @MainActor () -> Date
    /// Total seconds the system has spent asleep since boot. Only grows during real system sleep.
    public typealias SleepClock = @MainActor () -> TimeInterval

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

    /// Sleep-clock growth above this means the system really slept (not a stall or clock jump).
    private static let sleepDetectionThreshold: TimeInterval = 1
    /// How long a successful sleep request may go without the Mac actually sleeping.
    static let sleepConfirmationTimeout: TimeInterval = 15
    static let sleepNotObservedReason = "Your Mac didn't go to sleep. Another app may be keeping it awake."
    
    private var timer: DispatchSourceTimer?
    private var endTime: Date?
    private var activity: NSObjectProtocol?
    private var wakeObserver: NSObjectProtocol?
    /// Sleep-clock reading at the last countdown tick, used to tell "slept through the deadline" from "tick ran late".
    private var sleepAtLastTick: TimeInterval = 0
    /// Sleep-clock reading taken just before the sleep request.
    private var sleepAtRequest: TimeInterval = 0
    /// When the timer started waiting for the requested sleep to happen.
    private var sleepRequestedAt: Date?
    /// Bumped whenever resources reset, so a slow AppleScript fallback cannot overwrite newer state.
    private var sleepGeneration = 0
    private let customSleepAction: SleepAction?
    private let dateProvider: DateProvider
    private let sleepClock: SleepClock
    
    public init(
        sleepAction: SleepAction? = nil,
        dateProvider: @escaping DateProvider = { Date() },
        sleepClock: @escaping SleepClock = { SlumbrTimer.systemSleepDuration() }
    ) {
        self.customSleepAction = sleepAction
        self.dateProvider = dateProvider
        self.sleepClock = sleepClock
    }

    /// `mach_continuous_time` keeps counting while the system sleeps and `mach_absolute_time` does not,
    /// so their difference is the total time spent asleep since boot.
    public nonisolated static func systemSleepDuration() -> TimeInterval {
        var info = mach_timebase_info_data_t()
        mach_timebase_info(&info)
        let awake = mach_absolute_time()
        let total = mach_continuous_time()
        let asleep = total &- awake
        return Double(asleep) * Double(info.numer) / Double(info.denom) / 1_000_000_000
    }
    
    public func start(minutes: Double) {
        guard minutes > 0, minutes.isFinite else {
            log.error("Invalid timer duration: \(minutes, privacy: .public) minutes")
            return
        }

        let seconds = minutes * 60
        guard seconds.isFinite else {
            log.error("Duration overflows: \(minutes, privacy: .public) minutes")
            return
        }

        resetTimerResources()

        let deadline = dateProvider().addingTimeInterval(seconds)
        self.totalTime = seconds
        self.timeRemaining = seconds
        self.endTime = deadline
        self.sleepAtLastTick = sleepClock()
        self.state = .running
        log.notice("Timer started: \(seconds, privacy: .public)s, deadline \(deadline, privacy: .public)")

        startTicking()
        
        // Prevent macOS App Nap and system idle sleep while countdown is active
        if activity == nil {
            activity = ProcessInfo.processInfo.beginActivity(
                options: [.userInitiated, .idleSystemSleepDisabled],
                reason: "Running Sleep Timer"
            )
        }
    }
    
    public func stop() {
        resetTimerResources()
        state = .idle
    }
    
    public func clearStatus() {
        stop()
    }
    
    /// Retries immediate system sleep execution after a previous attempt failed.
    /// Note: This triggers the sleep action directly without restarting a countdown timer.
    public func retrySleep() {
        guard case .sleepFailed = state else { return }
        state = .requestingSleep
        executeSleep()
    }
    
    /// Wake recalculates everything from the original deadline and the sleep clock.
    public func handleSystemWake() {
        let current = String(describing: state)
        log.notice("System woke while timer state is \(current, privacy: .public)")
        tick()
    }

    /// Starts the once-a-second tick and the wake observer. Used both for the countdown and
    /// while waiting for a requested sleep to actually happen.
    private func startTicking() {
        let source = DispatchSource.makeTimerSource(queue: .main)
        source.schedule(deadline: .now() + 1, repeating: 1.0)
        source.setEventHandler { [weak self] in
            self?.tick()
        }
        source.resume()
        self.timer = source

        // If the system wakes while the timer is active, recalculate from the original deadline.
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
    
    private func resetTimerResources() {
        sleepGeneration += 1
        timer?.cancel()
        timer = nil
        endTime = nil
        sleepRequestedAt = nil
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
        switch state {
        case .running:
            tickCountdown()
        case .requestingSleep:
            checkRequestedSleep()
        case .sleepFailed where sleepRequestedAt != nil:
            // Timed out waiting, but a slow sleep can still land: keep watching so the
            // user doesn't wake up to a stale "didn't sleep" error.
            checkRequestedSleep()
        default:
            return
        }
    }

    private func tickCountdown() {
        guard let endTime = endTime else { return }
        let remaining = endTime.timeIntervalSince(dateProvider())
        let sleptSinceLastTick = sleepClock() - sleepAtLastTick

        if remaining <= 0 && sleptSinceLastTick > Self.sleepDetectionThreshold {
            // The Mac was asleep when the deadline passed and the user has just woken it:
            // the timer's job is done, and sleeping again would knock them straight back out.
            // ponytail: a wake less than ~1s before the deadline with no tick in between also lands here;
            // track the wake instant from didWake if that ever matters.
            log.notice("Deadline passed while the Mac was asleep (\(sleptSinceLastTick, privacy: .public)s asleep). Finishing without sleeping again.")
            resetTimerResources()
            state = .completed
        } else if remaining <= 0 {
            // However late this tick is, the Mac stayed awake, so it still has to go to sleep.
            log.notice("Deadline reached (\(-remaining, privacy: .public)s overdue). Requesting sleep.")
            state = .requestingSleep
            executeSleep()
        } else {
            sleepAtLastTick = sleepClock()
            self.timeRemaining = remaining
        }
    }

    /// A sleep request reporting success is not proof the Mac slept, so confirm it from the sleep clock.
    private func checkRequestedSleep() {
        guard let requestedAt = sleepRequestedAt else { return }
        let slept = sleepClock() - sleepAtRequest
        if slept > Self.sleepDetectionThreshold {
            log.notice("Sleep confirmed (\(slept, privacy: .public)s asleep).")
            resetTimerResources()
            state = .completed
        } else if state == .requestingSleep,
                  dateProvider().timeIntervalSince(requestedAt) > Self.sleepConfirmationTimeout {
            // Ticking and the wake observer stay alive, so a sleep that lands late still completes.
            log.error("Sleep was requested but the Mac did not sleep within \(Self.sleepConfirmationTimeout, privacy: .public)s.")
            state = .sleepFailed(reason: Self.sleepNotObservedReason)
        }
    }

    /// The request was accepted: keep ticking (without blocking idle sleep) until the sleep shows up.
    private func awaitSleepConfirmation() {
        sleepRequestedAt = dateProvider()
        startTicking()
    }
    
    private func executeSleep() {
        resetTimerResources()
        sleepAtRequest = sleepClock()
        
        if let customAction = customSleepAction {
            switch customAction() {
            case .success:
                awaitSleepConfirmation()
            case .failure(let reason):
                log.error("Sleep action failed: \(reason, privacy: .public)")
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
            if sleepSucceeded {
                log.notice("IOPMSleepSystem accepted the sleep request.")
            } else {
                log.error("IOPMSleepSystem returned error code \(result, privacy: .public), falling back to AppleScript.")
            }
        } else {
            log.error("IOPMFindPowerManagement returned a null port, falling back to AppleScript.")
        }
        
        // Watch the sleep clock and the timeout while the AppleScript fallback runs too: on first use it
        // blocks on the Automation consent prompt, which nobody may answer at bedtime.
        awaitSleepConfirmation()
        if sleepSucceeded { return }

        // Offload blocking AppleScript execution to a background queue to avoid blocking the main thread / MainActor
        let generation = sleepGeneration
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            var errorDict: NSDictionary?
            let script = NSAppleScript(source: "tell application \"System Events\" to sleep")
            let result = script?.executeAndReturnError(&errorDict)
            let errorMessage = (errorDict?[NSAppleScript.errorMessage] as? String)
            let isSuccess = result != nil && errorMessage == nil

            DispatchQueue.main.async {
                guard let self = self, self.sleepGeneration == generation, self.state == .requestingSleep else { return }
                if let desc = errorMessage {
                    log.error("AppleScript fallback sleep failed: \(desc, privacy: .public)")
                    self.state = .sleepFailed(reason: "Could not put Mac to sleep: \(desc)")
                } else if !isSuccess {
                    log.error("AppleScript fallback sleep failed without an error message.")
                    self.state = .sleepFailed(reason: "Could not put Mac to sleep.")
                } else {
                    // The confirmation window is already running.
                    log.notice("AppleScript fallback accepted the sleep request.")
                }
            }
        }
    }

    isolated deinit {
        resetTimerResources()
    }
}

public enum SlumbrTimeFormatter {
    public static func hasHours(_ t: TimeInterval) -> Bool {
        let rounded = max(0, Int(ceil(t)))
        return rounded >= 3600
    }

    public static func formatCountdown(_ t: TimeInterval) -> String {
        let rounded = max(0, Int(ceil(t)))
        let hrs = rounded / 3600
        let mins = (rounded % 3600) / 60
        let secs = rounded % 60
        if hrs > 0 {
            return String(format: "%d:%02d:%02d", hrs, mins, secs)
        } else {
            return String(format: "%02d:%02d", mins, secs)
        }
    }
}
