import Foundation
import Testing
import SlumbrCore

@Suite("SlumbrTimeFormatter")
struct SlumbrTimeFormatterTests {
    /// Rounds up, so the first second after start still reads 14:59 rather than skipping to 14:58.
    @Test(arguments: [
        (900.0, "15:00"),
        (898.99, "14:59"),
        (898.01, "14:59"),
        (898.00, "14:58"),
        (60.0, "01:00"),
        (59.9, "01:00"),
        (59.0, "00:59"),
        (1.0, "00:01"),
        (0.5, "00:01"),
        (0.0, "00:00"),
        (-0.5, "00:00"),
        (-10.0, "00:00"),
        (3600.0, "1:00:00"),
        (3665.0, "1:01:05"),
        (7199.5, "2:00:00"),
    ])
    func formatCountdown(seconds: TimeInterval, expected: String) {
        #expect(SlumbrTimeFormatter.formatCountdown(seconds) == expected)
    }

    @Test(arguments: [
        (7200.0, true),
        (3600.0, true),
        (3599.1, true),
        (3599.0, false),
        (900.0, false),
        (0.0, false),
        (-5.0, false),
    ])
    func hasHours(seconds: TimeInterval, expected: Bool) {
        #expect(SlumbrTimeFormatter.hasHours(seconds) == expected)
    }
}
