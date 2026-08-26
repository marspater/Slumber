import XCTest
import SlumberCore

final class MockClock: @unchecked Sendable {
    var currentDate: Date
    
    init(initialDate: Date = Date(timeIntervalSince1970: 1000000)) {
        self.currentDate = initialDate
    }
    
    func advance(by seconds: TimeInterval) {
        currentDate = currentDate.addingTimeInterval(seconds)
    }
    
    func now() -> Date {
        return currentDate
    }
}

final class SlumberTimerTests: XCTestCase {
    @MainActor
    func testInitialStateIsIdle() {
        let timer = SlumberTimer()
        XCTAssertEqual(timer.state, TimerState.idle)
        XCTAssertFalse(timer.isRunning)
        XCTAssertEqual(timer.timeRemaining, 0)
        XCTAssertEqual(timer.totalTime, 0)
        XCTAssertNil(timer.sleepError)
    }

    @MainActor
    func testStartTransitionsToRunningAndSetsTotalTime() {
        let clock = MockClock()
        let timer = SlumberTimer(dateProvider: { clock.now() })
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
        let timer = SlumberTimer(dateProvider: { clock.now() })
        timer.start(minutes: 30)
        XCTAssertEqual(timer.state, TimerState.running)
        timer.stop()
        XCTAssertEqual(timer.state, TimerState.idle)
        XCTAssertFalse(timer.isRunning)
        XCTAssertEqual(timer.timeRemaining, 0)
    }

    @MainActor
    func testClearStatusResetsToIdle() {
        let timer = SlumberTimer()
        timer.clearStatus()
        XCTAssertEqual(timer.state, TimerState.idle)
    }

    @MainActor
    func testInvalidMinutesDoesNotStart() {
        let timer = SlumberTimer()
        timer.start(minutes: 0)
        XCTAssertEqual(timer.state, TimerState.idle)
        timer.start(minutes: -10)
        XCTAssertEqual(timer.state, TimerState.idle)
        timer.start(minutes: .infinity)
        XCTAssertEqual(timer.state, TimerState.idle)
    }

    @MainActor
    func testTickCalculatesExactRemainingTime() {
        let clock = MockClock()
        let timer = SlumberTimer(dateProvider: { clock.now() })
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
        let timer = SlumberTimer(
            sleepAction: {
                sleepExecuted = true
                return SleepResult.success
            },
            dateProvider: { clock.now() }
        )
        
        timer.start(minutes: 15) // 900 seconds
        XCTAssertEqual(timer.state, TimerState.running)
        
        // Advance clock beyond deadline
        clock.advance(by: 901)
        timer.tick()
        
        XCTAssertTrue(sleepExecuted)
        XCTAssertEqual(timer.state, TimerState.completed)
        XCTAssertEqual(timer.timeRemaining, 0)
        XCTAssertFalse(timer.isRunning)
    }

    @MainActor
    func testSleepFailureSetsSleepFailedState() {
        let clock = MockClock()
        let timer = SlumberTimer(
            sleepAction: {
                return SleepResult.failure(reason: "Simulated IOKit Error")
            },
            dateProvider: { clock.now() }
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
        final class SleepController: @unchecked Sendable {
            var shouldSucceed = false
        }
        let controller = SleepController()
        let clock = MockClock()
        let timer = SlumberTimer(
            sleepAction: {
                return controller.shouldSucceed ? SleepResult.success : SleepResult.failure(reason: "Temporary Lock")
            },
            dateProvider: { clock.now() }
        )
        
        timer.start(minutes: 5)
        clock.advance(by: 301)
        timer.tick()
        
        XCTAssertEqual(timer.state, TimerState.sleepFailed(reason: "Temporary Lock"))
        
        // Retry with success
        controller.shouldSucceed = true
        timer.retrySleep()
        
        XCTAssertEqual(timer.state, TimerState.completed)
        XCTAssertNil(timer.sleepError)
    }

    @MainActor
    func testRepeatedStartsCleanlyResetPreviousSession() {
        let clock = MockClock()
        let timer = SlumberTimer(dateProvider: { clock.now() })
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
        let timer = SlumberTimer(dateProvider: { clock.now() })
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
    func testWakeHandlingTriggersSleepIfDeadlinePassed() {
        let clock = MockClock()
        var sleepExecuted = false
        let timer = SlumberTimer(
            sleepAction: {
                sleepExecuted = true
                return SleepResult.success
            },
            dateProvider: { clock.now() }
        )
        
        timer.start(minutes: 10) // 600s
        
        // Advance clock beyond 10 min
        clock.advance(by: 700)
        timer.handleSystemWake()
        
        XCTAssertTrue(sleepExecuted)
        XCTAssertEqual(timer.state, TimerState.completed)
        XCTAssertEqual(timer.timeRemaining, 0)
    }
}
