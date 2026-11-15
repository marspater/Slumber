import XCTest
import SlumbrCore

@MainActor
final class MockClock {
    var currentDate: Date
    
    init(initialDate: Date = Date(timeIntervalSince1970: 1000000)) {
        self.currentDate = initialDate
    }
    
    /// Total seconds the simulated system has spent asleep.
    var asleep: TimeInterval = 0

    /// Wall-clock time passes while the Mac stays awake.
    func advance(by seconds: TimeInterval) {
        currentDate = currentDate.addingTimeInterval(seconds)
    }

    /// Wall-clock time passes while the Mac is asleep.
    func sleep(for seconds: TimeInterval) {
        advance(by: seconds)
        asleep += seconds
    }
    
    func now() -> Date {
        return currentDate
    }
}

final class SlumbrTimerTests: XCTestCase {
    @MainActor
    func testInitialStateIsIdle() {
        let timer = SlumbrTimer()
        XCTAssertEqual(timer.state, TimerState.idle)
        XCTAssertFalse(timer.isRunning)
        XCTAssertEqual(timer.timeRemaining, 0)
        XCTAssertEqual(timer.totalTime, 0)
        XCTAssertNil(timer.sleepError)
    }

    @MainActor
    func testStartTransitionsToRunningAndSetsTotalTime() {
        let clock = MockClock()
        let timer = SlumbrTimer(dateProvider: { clock.now() }, sleepClock: { clock.asleep })
        timer.start(minutes: 15)
        XCTAssertEqual(timer.state, TimerState.running)
        XCTAssertTrue(timer.isRunning)
        XCTAssertEqual(timer.totalTime, 900)
        XCTAssertEqual(timer.timeRemaining, 900)
        timer.stop()
    }

    @MainActor
    func testStopTransitionsToIdle() {
        let clock = MockClock()
        let timer = SlumbrTimer(dateProvider: { clock.now() }, sleepClock: { clock.asleep })
        timer.start(minutes: 30)
        XCTAssertEqual(timer.state, TimerState.running)
        timer.stop()
        XCTAssertEqual(timer.state, TimerState.idle)
        XCTAssertFalse(timer.isRunning)
        XCTAssertEqual(timer.timeRemaining, 0)
    }

    @MainActor
    func testClearStatusResetsToIdle() {
        let clock = MockClock()
        let timer = SlumbrTimer(
            sleepAction: { SleepResult.failure(reason: "nope") },
            dateProvider: { clock.now() }, sleepClock: { clock.asleep }
        )
        timer.start(minutes: 1)
        clock.advance(by: 61)
        timer.tick()
        XCTAssertEqual(timer.state, TimerState.sleepFailed(reason: "nope"))
        timer.clearStatus()
        XCTAssertEqual(timer.state, TimerState.idle)
        XCTAssertNil(timer.sleepError)
    }

    @MainActor
    func testInvalidMinutesDoesNotStart() {
        let timer = SlumbrTimer()
        timer.start(minutes: 0)
        XCTAssertEqual(timer.state, TimerState.idle)
        timer.start(minutes: -10)
        XCTAssertEqual(timer.state, TimerState.idle)
        timer.start(minutes: .infinity)
        XCTAssertEqual(timer.state, TimerState.idle)
        timer.start(minutes: .nan)
        XCTAssertEqual(timer.state, TimerState.idle)
        timer.start(minutes: .greatestFiniteMagnitude) // seconds overflow to infinity
        XCTAssertEqual(timer.state, TimerState.idle)
    }

    @MainActor
    func testTickCalculatesExactRemainingTime() {
        let clock = MockClock()
        let timer = SlumbrTimer(dateProvider: { clock.now() }, sleepClock: { clock.asleep })
        timer.start(minutes: 10) // 600s
        
        clock.advance(by: 120) // 2 minutes elapsed
        timer.tick()
        
        XCTAssertEqual(timer.state, TimerState.running)
        XCTAssertEqual(timer.timeRemaining, 480)
        timer.stop()
    }

    @MainActor
    func testTimerExpiryTransitionsToCompletedOnSuccess() {
        let clock = MockClock()
        var sleepExecuted = false
        let timer = SlumbrTimer(
            sleepAction: {
                sleepExecuted = true
                return SleepResult.success
            },
            dateProvider: { clock.now() }, sleepClock: { clock.asleep }
        )
        
        timer.start(minutes: 15) // 900 seconds
        XCTAssertEqual(timer.state, TimerState.running)
        
        // Advance clock beyond deadline
        clock.advance(by: 901)
        timer.tick()
        
        XCTAssertTrue(sleepExecuted)
        XCTAssertEqual(timer.state, TimerState.requestingSleep)
        XCTAssertEqual(timer.timeRemaining, 0)
        XCTAssertFalse(timer.isRunning)

        // The Mac sleeps, then wakes: only now is the job confirmed done.
        clock.sleep(for: 3600)
        timer.handleSystemWake()
        XCTAssertEqual(timer.state, TimerState.completed)
    }

    @MainActor
    func testSleepFailureSetsSleepFailedState() {
        let clock = MockClock()
        let timer = SlumbrTimer(
            sleepAction: {
                return SleepResult.failure(reason: "Simulated IOKit Error")
            },
            dateProvider: { clock.now() }, sleepClock: { clock.asleep }
        )
        
        timer.start(minutes: 15)
        XCTAssertEqual(timer.state, TimerState.running)
        
        // Advance clock beyond deadline
        clock.advance(by: 901)
        timer.tick()
        
        XCTAssertEqual(timer.state, TimerState.sleepFailed(reason: "Simulated IOKit Error"))
        XCTAssertEqual(timer.sleepError, "Simulated IOKit Error")
        XCTAssertFalse(timer.isRunning)
    }

    @MainActor
    func testRetrySleepAfterFailure() {
        @MainActor final class SleepController {
            var shouldSucceed = false
        }
        let controller = SleepController()
        let clock = MockClock()
        let timer = SlumbrTimer(
            sleepAction: {
                return controller.shouldSucceed ? SleepResult.success : SleepResult.failure(reason: "Temporary Lock")
            },
            dateProvider: { clock.now() }, sleepClock: { clock.asleep }
        )
        
        timer.start(minutes: 5)
        clock.advance(by: 301)
        timer.tick()
        
        XCTAssertEqual(timer.state, TimerState.sleepFailed(reason: "Temporary Lock"))
        
        // Retry with success
        controller.shouldSucceed = true
        timer.retrySleep()
        XCTAssertEqual(timer.state, TimerState.requestingSleep)

        clock.sleep(for: 60)
        timer.tick()
        XCTAssertEqual(timer.state, TimerState.completed)
        XCTAssertNil(timer.sleepError)
    }

    @MainActor
    func testRepeatedStartsCleanlyResetPreviousSession() {
        let clock = MockClock()
        let timer = SlumbrTimer(dateProvider: { clock.now() }, sleepClock: { clock.asleep })
        timer.start(minutes: 15)
        XCTAssertEqual(timer.totalTime, 900)
        
        timer.start(minutes: 45)
        XCTAssertEqual(timer.state, TimerState.running)
        XCTAssertEqual(timer.totalTime, 2700)
        XCTAssertEqual(timer.timeRemaining, 2700)
        timer.stop()
    }

    @MainActor
    func testWakeHandlingResumesIfTimeRemains() {
        let clock = MockClock()
        let timer = SlumbrTimer(dateProvider: { clock.now() }, sleepClock: { clock.asleep })
        timer.start(minutes: 60) // 3600 seconds
        XCTAssertEqual(timer.state, TimerState.running)
        
        // Advance clock 600s (10 min)
        clock.advance(by: 600)
        timer.handleSystemWake()
        
        XCTAssertEqual(timer.state, TimerState.running)
        XCTAssertEqual(timer.timeRemaining, 3000)
        timer.stop()
    }

    @MainActor
    func testWakeAfterDeadlineFinishesWithoutSleepingAgain() {
        let clock = MockClock()
        var sleepExecuted = false
        let timer = SlumbrTimer(
            sleepAction: {
                sleepExecuted = true
                return SleepResult.success
            },
            dateProvider: { clock.now() }, sleepClock: { clock.asleep }
        )
        
        timer.start(minutes: 10) // 600s
        
        // The Mac slept through the deadline; the user has just woken it.
        clock.sleep(for: 700)
        timer.handleSystemWake()
        
        XCTAssertFalse(sleepExecuted)
        XCTAssertEqual(timer.state, TimerState.completed)
        XCTAssertEqual(timer.timeRemaining, 0)
    }

    @MainActor
    func testLateTickAfterSleepFinishesWithoutSleepingAgain() {
        let clock = MockClock()
        var sleepExecuted = false
        let timer = SlumbrTimer(
            sleepAction: {
                sleepExecuted = true
                return SleepResult.success
            },
            dateProvider: { clock.now() }, sleepClock: { clock.asleep }
        )

        timer.start(minutes: 10) // 600s

        // The once-a-second tick can fire right after wake, before the wake notification.
        clock.sleep(for: 700)
        timer.tick()

        XCTAssertFalse(sleepExecuted)
        XCTAssertEqual(timer.state, TimerState.completed)
        XCTAssertEqual(timer.timeRemaining, 0)
    }

    @MainActor
    func testLateTickWhileAwakeStillSleeps() {
        let clock = MockClock()
        var sleepExecuted = false
        let timer = SlumbrTimer(
            sleepAction: {
                sleepExecuted = true
                return SleepResult.success
            },
            dateProvider: { clock.now() }, sleepClock: { clock.asleep }
        )

        timer.start(minutes: 10)

        // The Mac stayed awake, but the tick ran late (main-thread stall, timer delay, clock jump).
        clock.advance(by: 700)
        timer.tick()

        XCTAssertTrue(sleepExecuted)
        XCTAssertEqual(timer.state, TimerState.requestingSleep)
        timer.stop()
    }

    @MainActor
    func testAcceptedSleepRequestThatNeverSleepsFailsAndStaysRetryable() {
        let clock = MockClock()
        var sleeps = 0
        let timer = SlumbrTimer(
            sleepAction: { sleeps += 1; return SleepResult.success },
            dateProvider: { clock.now() }, sleepClock: { clock.asleep }
        )
        timer.start(minutes: 1)
        clock.advance(by: 60)
        timer.tick()
        XCTAssertEqual(timer.state, TimerState.requestingSleep)

        // Still within the confirmation window: keep waiting.
        clock.advance(by: 10)
        timer.tick()
        XCTAssertEqual(timer.state, TimerState.requestingSleep)

        // The request "succeeded" but the Mac never slept: say so instead of claiming success.
        clock.advance(by: 10)
        timer.tick()
        XCTAssertEqual(timer.sleepError, "Your Mac didn't go to sleep. Another app may be keeping it awake.")

        timer.retrySleep()
        XCTAssertEqual(sleeps, 2)
        XCTAssertEqual(timer.state, TimerState.requestingSleep)
        clock.sleep(for: 120)
        timer.tick()
        XCTAssertEqual(timer.state, TimerState.completed)
    }

    @MainActor
    func testSleepLandingAfterTimeoutStillCompletes() {
        let clock = MockClock()
        let timer = SlumbrTimer(
            sleepAction: { SleepResult.success },
            dateProvider: { clock.now() }, sleepClock: { clock.asleep }
        )
        timer.start(minutes: 1)
        clock.advance(by: 60)
        timer.tick()
        clock.advance(by: 20)
        timer.tick()
        XCTAssertNotNil(timer.sleepError)

        // The slow sleep finally happens; on wake the stale error must clear itself.
        clock.sleep(for: 3600)
        timer.handleSystemWake()
        XCTAssertEqual(timer.state, TimerState.completed)
    }

    @MainActor
    func testSleepAndWakeBeforeDeadlineKeepsCountingThenSleeps() {
        let clock = MockClock()
        var sleeps = 0
        let timer = SlumbrTimer(
            sleepAction: { sleeps += 1; return SleepResult.success },
            dateProvider: { clock.now() }, sleepClock: { clock.asleep }
        )
        timer.start(minutes: 10)

        // Lid closed for 100s, reopened long before the deadline.
        clock.sleep(for: 100)
        timer.handleSystemWake()
        XCTAssertEqual(timer.state, TimerState.running)
        XCTAssertEqual(timer.timeRemaining, 500)

        // The earlier sleep must not count as sleeping through the deadline.
        clock.advance(by: 503)
        timer.tick()
        XCTAssertEqual(sleeps, 1)
        XCTAssertEqual(timer.state, TimerState.requestingSleep)
        timer.stop()
    }

    @MainActor
    func testStopWhileAwaitingSleepReturnsToIdle() {
        let clock = MockClock()
        let timer = SlumbrTimer(
            sleepAction: { SleepResult.success },
            dateProvider: { clock.now() }, sleepClock: { clock.asleep }
        )
        timer.start(minutes: 1)
        clock.advance(by: 61)
        timer.tick()
        XCTAssertEqual(timer.state, TimerState.requestingSleep)
        timer.stop()
        XCTAssertEqual(timer.state, TimerState.idle)

        // A late confirmation tick after stopping changes nothing.
        clock.sleep(for: 30)
        timer.tick()
        XCTAssertEqual(timer.state, TimerState.idle)
    }

    @MainActor
    func testCountdownFormattingDoesNotSkipFirstSecond() {
        // Initial state at 15m
        XCTAssertEqual(SlumbrTimeFormatter.formatCountdown(900.0), "15:00")
        
        // 1 second later: 898.99s remaining. Truncation previously caused this to skip to 14:58.
        // Ceil rounding correctly preserves 14:59.
        XCTAssertEqual(SlumbrTimeFormatter.formatCountdown(898.99), "14:59")
        XCTAssertEqual(SlumbrTimeFormatter.formatCountdown(898.01), "14:59")
        XCTAssertEqual(SlumbrTimeFormatter.formatCountdown(898.00), "14:58")
        
        // Sub-minute boundary
        XCTAssertEqual(SlumbrTimeFormatter.formatCountdown(60.0), "01:00")
        XCTAssertEqual(SlumbrTimeFormatter.formatCountdown(59.9), "01:00")
        XCTAssertEqual(SlumbrTimeFormatter.formatCountdown(59.0), "00:59")
        
        // Final seconds down to zero
        XCTAssertEqual(SlumbrTimeFormatter.formatCountdown(1.0), "00:01")
        XCTAssertEqual(SlumbrTimeFormatter.formatCountdown(0.5), "00:01")
        XCTAssertEqual(SlumbrTimeFormatter.formatCountdown(0.0), "00:00")
        
        // Negative edge cases should clamp to zero, never displaying negative numbers
        XCTAssertEqual(SlumbrTimeFormatter.formatCountdown(-0.5), "00:00")
        XCTAssertEqual(SlumbrTimeFormatter.formatCountdown(-10.0), "00:00")
        
        // Multi-hour display
        XCTAssertEqual(SlumbrTimeFormatter.formatCountdown(3665.0), "1:01:05")
    }

    @MainActor
    func testHasHoursAccuratelyDetectsHourScaleTime() {
        XCTAssertTrue(SlumbrTimeFormatter.hasHours(7200.0))
        XCTAssertTrue(SlumbrTimeFormatter.hasHours(3600.0))
        XCTAssertTrue(SlumbrTimeFormatter.hasHours(3599.1))
        XCTAssertFalse(SlumbrTimeFormatter.hasHours(3599.0))
        XCTAssertFalse(SlumbrTimeFormatter.hasHours(900.0))
        XCTAssertFalse(SlumbrTimeFormatter.hasHours(0.0))
        XCTAssertFalse(SlumbrTimeFormatter.hasHours(-5.0))
    }

    @MainActor
    func testDeinitCancelsTimerAndCleansUpResources() {
        var timer: SlumbrTimer? = SlumbrTimer()
        weak var weakTimer = timer
        timer?.start(minutes: 10)
        XCTAssertEqual(timer?.state, TimerState.running)

        // Releasing the reference must not be blocked by the dispatch source or wake observer
        timer = nil
        XCTAssertNil(weakTimer)
    }

    @MainActor
    func testDoesNotSleepBeforeDeadlineButDoesAtDeadline() {
        let clock = MockClock()
        var sleeps = 0
        let timer = SlumbrTimer(sleepAction: { sleeps += 1; return SleepResult.success }, dateProvider: { clock.now() }, sleepClock: { clock.asleep })
        timer.start(minutes: 10)

        clock.advance(by: 599)
        timer.tick()
        XCTAssertEqual(sleeps, 0)
        XCTAssertTrue(timer.isRunning)

        clock.advance(by: 1) // exactly the deadline
        timer.tick()
        XCTAssertEqual(sleeps, 1)
        XCTAssertEqual(timer.state, TimerState.requestingSleep)

        clock.sleep(for: 5)
        timer.tick()
        XCTAssertEqual(sleeps, 1)
        XCTAssertEqual(timer.state, TimerState.completed)
    }

    @MainActor
    func testRetrySleepIsIgnoredUnlessFailed() {
        var sleeps = 0
        let timer = SlumbrTimer(sleepAction: { sleeps += 1; return SleepResult.success })
        timer.retrySleep()
        XCTAssertEqual(sleeps, 0)
        XCTAssertEqual(timer.state, TimerState.idle)
    }

    @MainActor
    func testRepeatedFailureStaysRetryable() {
        let timer = SlumbrTimer(sleepAction: { SleepResult.failure(reason: "busy") })
        timer.start(minutes: 1)
        timer.retrySleep() // ignored while running
        XCTAssertTrue(timer.isRunning)
        timer.stop()

        let clock = MockClock()
        let failing = SlumbrTimer(sleepAction: { SleepResult.failure(reason: "busy") }, dateProvider: { clock.now() }, sleepClock: { clock.asleep })
        failing.start(minutes: 1)
        clock.advance(by: 61)
        failing.tick()
        failing.retrySleep()
        XCTAssertEqual(failing.state, TimerState.sleepFailed(reason: "busy"))
        failing.retrySleep()
        XCTAssertEqual(failing.state, TimerState.sleepFailed(reason: "busy"))
    }
}
