import Foundation
import Testing
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

@MainActor
@Suite("SlumbrTimer")
struct SlumbrTimerTests {
    @Test func initialStateIsIdle() {
        let timer = SlumbrTimer()
        #expect(timer.state == TimerState.idle)
        #expect(!timer.isRunning)
        #expect(timer.timeRemaining == 0)
        #expect(timer.totalTime == 0)
        #expect(timer.sleepError == nil)
    }

    @Test func startTransitionsToRunningAndSetsTotalTime() {
        let clock = MockClock()
        let timer = SlumbrTimer(dateProvider: { clock.now() }, sleepClock: { clock.asleep })
        timer.start(minutes: 15)
        #expect(timer.state == TimerState.running)
        #expect(timer.isRunning)
        #expect(timer.totalTime == 900)
        #expect(timer.timeRemaining == 900)
        timer.stop()
    }

    @Test func stopTransitionsToIdle() {
        let clock = MockClock()
        let timer = SlumbrTimer(dateProvider: { clock.now() }, sleepClock: { clock.asleep })
        timer.start(minutes: 30)
        #expect(timer.state == TimerState.running)
        timer.stop()
        #expect(timer.state == TimerState.idle)
        #expect(!timer.isRunning)
        #expect(timer.timeRemaining == 0)
    }

    @Test func clearStatusResetsToIdle() {
        let clock = MockClock()
        let timer = SlumbrTimer(
            sleepAction: { SleepResult.failure(reason: "nope") },
            dateProvider: { clock.now() }, sleepClock: { clock.asleep }
        )
        timer.start(minutes: 1)
        clock.advance(by: 61)
        timer.tick()
        #expect(timer.state == TimerState.sleepFailed(reason: "nope"))
        timer.clearStatus()
        #expect(timer.state == TimerState.idle)
        #expect(timer.sleepError == nil)
    }

    @Test func invalidMinutesDoesNotStart() {
        let timer = SlumbrTimer()
        timer.start(minutes: 0)
        #expect(timer.state == TimerState.idle)
        timer.start(minutes: -10)
        #expect(timer.state == TimerState.idle)
        timer.start(minutes: .infinity)
        #expect(timer.state == TimerState.idle)
        timer.start(minutes: .nan)
        #expect(timer.state == TimerState.idle)
        timer.start(minutes: .greatestFiniteMagnitude) // seconds overflow to infinity
        #expect(timer.state == TimerState.idle)
    }

    @Test func tickCalculatesExactRemainingTime() {
        let clock = MockClock()
        let timer = SlumbrTimer(dateProvider: { clock.now() }, sleepClock: { clock.asleep })
        timer.start(minutes: 10) // 600s
        
        clock.advance(by: 120) // 2 minutes elapsed
        timer.tick()
        
        #expect(timer.state == TimerState.running)
        #expect(timer.timeRemaining == 480)
        timer.stop()
    }

    @Test func timerExpiryTransitionsToCompletedOnSuccess() {
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
        #expect(timer.state == TimerState.running)
        
        // Advance clock beyond deadline
        clock.advance(by: 901)
        timer.tick()
        
        #expect(sleepExecuted)
        #expect(timer.state == TimerState.requestingSleep)
        #expect(timer.timeRemaining == 0)
        #expect(!timer.isRunning)

        // The Mac sleeps, then wakes: only now is the job confirmed done.
        clock.sleep(for: 3600)
        timer.handleSystemWake()
        #expect(timer.state == TimerState.completed)
    }

    @Test func sleepFailureSetsSleepFailedState() {
        let clock = MockClock()
        let timer = SlumbrTimer(
            sleepAction: {
                return SleepResult.failure(reason: "Simulated IOKit Error")
            },
            dateProvider: { clock.now() }, sleepClock: { clock.asleep }
        )
        
        timer.start(minutes: 15)
        #expect(timer.state == TimerState.running)
        
        // Advance clock beyond deadline
        clock.advance(by: 901)
        timer.tick()
        
        #expect(timer.state == TimerState.sleepFailed(reason: "Simulated IOKit Error"))
        #expect(timer.sleepError == "Simulated IOKit Error")
        #expect(!timer.isRunning)
    }

    @Test func retrySleepAfterFailure() {
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
        
        #expect(timer.state == TimerState.sleepFailed(reason: "Temporary Lock"))
        
        // Retry with success
        controller.shouldSucceed = true
        timer.retrySleep()
        #expect(timer.state == TimerState.requestingSleep)

        clock.sleep(for: 60)
        timer.tick()
        #expect(timer.state == TimerState.completed)
        #expect(timer.sleepError == nil)
    }

    @Test func repeatedStartsCleanlyResetPreviousSession() {
        let clock = MockClock()
        let timer = SlumbrTimer(dateProvider: { clock.now() }, sleepClock: { clock.asleep })
        timer.start(minutes: 15)
        #expect(timer.totalTime == 900)
        
        timer.start(minutes: 45)
        #expect(timer.state == TimerState.running)
        #expect(timer.totalTime == 2700)
        #expect(timer.timeRemaining == 2700)
        timer.stop()
    }

    @Test func wakeHandlingResumesIfTimeRemains() {
        let clock = MockClock()
        let timer = SlumbrTimer(dateProvider: { clock.now() }, sleepClock: { clock.asleep })
        timer.start(minutes: 60) // 3600 seconds
        #expect(timer.state == TimerState.running)
        
        // Advance clock 600s (10 min)
        clock.advance(by: 600)
        timer.handleSystemWake()
        
        #expect(timer.state == TimerState.running)
        #expect(timer.timeRemaining == 3000)
        timer.stop()
    }

    @Test func wakeAfterDeadlineFinishesWithoutSleepingAgain() {
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
        
        #expect(!sleepExecuted)
        #expect(timer.state == TimerState.completed)
        #expect(timer.timeRemaining == 0)
    }

    @Test func lateTickAfterSleepFinishesWithoutSleepingAgain() {
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

        #expect(!sleepExecuted)
        #expect(timer.state == TimerState.completed)
        #expect(timer.timeRemaining == 0)
    }

    @Test func lateTickWhileAwakeStillSleeps() {
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

        #expect(sleepExecuted)
        #expect(timer.state == TimerState.requestingSleep)
        timer.stop()
    }

    @Test func acceptedSleepRequestThatNeverSleepsFailsAndStaysRetryable() {
        let clock = MockClock()
        var sleeps = 0
        let timer = SlumbrTimer(
            sleepAction: { sleeps += 1; return SleepResult.success },
            dateProvider: { clock.now() }, sleepClock: { clock.asleep }
        )
        timer.start(minutes: 1)
        clock.advance(by: 60)
        timer.tick()
        #expect(timer.state == TimerState.requestingSleep)

        // Still within the confirmation window: keep waiting.
        clock.advance(by: 10)
        timer.tick()
        #expect(timer.state == TimerState.requestingSleep)

        // The request "succeeded" but the Mac never slept: say so instead of claiming success.
        clock.advance(by: 10)
        timer.tick()
        #expect(timer.sleepError == "Your Mac didn't go to sleep. Another app may be keeping it awake.")

        timer.retrySleep()
        #expect(sleeps == 2)
        #expect(timer.state == TimerState.requestingSleep)
        clock.sleep(for: 120)
        timer.tick()
        #expect(timer.state == TimerState.completed)
    }

    @Test func sleepLandingAfterTimeoutStillCompletes() {
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
        #expect(timer.sleepError != nil)

        // The slow sleep finally happens; on wake the stale error must clear itself.
        clock.sleep(for: 3600)
        timer.handleSystemWake()
        #expect(timer.state == TimerState.completed)
    }

    @Test func sleepAndWakeBeforeDeadlineKeepsCountingThenSleeps() {
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
        #expect(timer.state == TimerState.running)
        #expect(timer.timeRemaining == 500)

        // The earlier sleep must not count as sleeping through the deadline.
        clock.advance(by: 503)
        timer.tick()
        #expect(sleeps == 1)
        #expect(timer.state == TimerState.requestingSleep)
        timer.stop()
    }

    @Test func stopWhileAwaitingSleepReturnsToIdle() {
        let clock = MockClock()
        let timer = SlumbrTimer(
            sleepAction: { SleepResult.success },
            dateProvider: { clock.now() }, sleepClock: { clock.asleep }
        )
        timer.start(minutes: 1)
        clock.advance(by: 61)
        timer.tick()
        #expect(timer.state == TimerState.requestingSleep)
        timer.stop()
        #expect(timer.state == TimerState.idle)

        // A late confirmation tick after stopping changes nothing.
        clock.sleep(for: 30)
        timer.tick()
        #expect(timer.state == TimerState.idle)
    }

    @Test func deinitCancelsTimerAndCleansUpResources() {
        var timer: SlumbrTimer? = SlumbrTimer()
        weak let weakTimer = timer
        timer?.start(minutes: 10)
        #expect(timer?.state == TimerState.running)

        // Releasing the reference must not be blocked by the dispatch source or wake observer
        timer = nil
        #expect(weakTimer == nil)
    }

    @Test func doesNotSleepBeforeDeadlineButDoesAtDeadline() {
        let clock = MockClock()
        var sleeps = 0
        let timer = SlumbrTimer(sleepAction: { sleeps += 1; return SleepResult.success }, dateProvider: { clock.now() }, sleepClock: { clock.asleep })
        timer.start(minutes: 10)

        clock.advance(by: 599)
        timer.tick()
        #expect(sleeps == 0)
        #expect(timer.isRunning)

        clock.advance(by: 1) // exactly the deadline
        timer.tick()
        #expect(sleeps == 1)
        #expect(timer.state == TimerState.requestingSleep)

        clock.sleep(for: 5)
        timer.tick()
        #expect(sleeps == 1)
        #expect(timer.state == TimerState.completed)
    }

    @Test func retrySleepIsIgnoredUnlessFailed() {
        var sleeps = 0
        let timer = SlumbrTimer(sleepAction: { sleeps += 1; return SleepResult.success })
        timer.retrySleep()
        #expect(sleeps == 0)
        #expect(timer.state == TimerState.idle)
    }

    @Test func repeatedFailureStaysRetryable() {
        let timer = SlumbrTimer(sleepAction: { SleepResult.failure(reason: "busy") })
        timer.start(minutes: 1)
        timer.retrySleep() // ignored while running
        #expect(timer.isRunning)
        timer.stop()

        let clock = MockClock()
        let failing = SlumbrTimer(sleepAction: { SleepResult.failure(reason: "busy") }, dateProvider: { clock.now() }, sleepClock: { clock.asleep })
        failing.start(minutes: 1)
        clock.advance(by: 61)
        failing.tick()
        failing.retrySleep()
        #expect(failing.state == TimerState.sleepFailed(reason: "busy"))
        failing.retrySleep()
        #expect(failing.state == TimerState.sleepFailed(reason: "busy"))
    }
}
