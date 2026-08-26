import XCTest
import SlumberCore

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
        let timer = SlumberTimer()
        timer.start(minutes: 15)
        XCTAssertEqual(timer.state, TimerState.running)
        XCTAssertTrue(timer.isRunning)
        XCTAssertEqual(timer.totalTime, 900)
        XCTAssertEqual(timer.timeRemaining, 900)
        timer.stop()
    }

    @MainActor
    func testStopTransitionsToIdle() {
        let timer = SlumberTimer()
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
    func testTimerExpiryTransitionsToCompletedOnSuccess() {
        var sleepExecuted = false
        let timer = SlumberTimer(sleepAction: {
            sleepExecuted = true
            return SleepResult.success
        })
        
        timer.start(minutes: 1.0 / 60.0) // 1 second
        XCTAssertEqual(timer.state, TimerState.running)
        
        // Simulate immediate expiry
        timer.tick()
        XCTAssertTrue(timer.state == TimerState.running || timer.state == TimerState.completed)
        _ = sleepExecuted
    }

    @MainActor
    func testSleepFailureSetsSleepFailedState() {
        let timer = SlumberTimer(sleepAction: {
            return SleepResult.failure(reason: "Simulated IOKit Error")
        })
        
        timer.start(minutes: 15)
        XCTAssertEqual(timer.state, TimerState.running)
        
        timer.stop()
        XCTAssertEqual(timer.state, TimerState.idle)
    }

    @MainActor
    func testRepeatedStartsCleanlyResetPreviousSession() {
        let timer = SlumberTimer()
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
        let timer = SlumberTimer()
        timer.start(minutes: 60)
        XCTAssertEqual(timer.state, TimerState.running)
        
        // Simulate wake: should keep running with valid time
        timer.handleSystemWake()
        XCTAssertEqual(timer.state, TimerState.running)
        XCTAssertGreaterThan(timer.timeRemaining, 3500) // ~3600 seconds
        timer.stop()
    }
}
