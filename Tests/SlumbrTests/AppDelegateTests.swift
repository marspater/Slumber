import Testing
@testable import Slumbr

@Suite("AppDelegate")
@MainActor
struct AppDelegateTests {
    @Test("a hosted test run is detected so launch setup is skipped")
    func detectsTestHost() {
        #expect(AppDelegate.isRunningAsTestHost)
    }
}
