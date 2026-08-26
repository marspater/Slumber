import XCTest

final class SlumberTimerTests: XCTestCase {
    @MainActor
    func testInitialStateIsIdle() {
        let timer = SlumberTimer()
        XCTAssertEqual(timer.state, .idle)
        XCTAssertFalse(timer.isRunning)
        XCTAssertEqual(timer.timeRemaining, 0)
        XCTAssertEqual(timer.totalTime, 0)
    }

    @MainActor
    func testStartTransitionsToRunningAndSetsTotalTime() {
        let timer = SlumberTimer()
        timer.start(minutes: 15)
        XCTAssertEqual(timer.state, .running)
        XCTAssertTrue(timer.isRunning)
        XCTAssertEqual(timer.totalTime, 900)
        XCTAssertEqual(timer.timeRemaining, 900)
        timer.stop()
    }

    @MainActor
    func testStopTransitionsToIdle() {
        let timer = SlumberTimer()
        timer.start(minutes: 30)
        XCTAssertEqual(timer.state, .running)
        timer.stop()
        XCTAssertEqual(timer.state, .idle)
        XCTAssertFalse(timer.isRunning)
        XCTAssertEqual(timer.timeRemaining, 0)
    }

    @MainActor
    func testDismissStatusResetsToIdle() {
        let timer = SlumberTimer()
        timer.dismissStatus()
        XCTAssertEqual(timer.state, .idle)
    }

    @MainActor
    func testInvalidMinutesDoesNotStart() {
        let timer = SlumberTimer()
        timer.start(minutes: 0)
        XCTAssertEqual(timer.state, .idle)
        timer.start(minutes: -10)
        XCTAssertEqual(timer.state, .idle)
    }
}
