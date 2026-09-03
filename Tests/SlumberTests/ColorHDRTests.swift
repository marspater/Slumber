import XCTest
import SwiftUI
@testable import Slumber

final class ColorHDRTests: XCTestCase {

    // Helper to assert double accuracy
    private func assertColorEqual(_ actual: (r: Double, g: Double, b: Double), _ expected: (r: Double, g: Double, b: Double), accuracy: Double = 1e-5, file: StaticString = #file, line: UInt = #line) {
        XCTAssertEqual(actual.r, expected.r, accuracy: accuracy, "Red component mismatch", file: file, line: line)
        XCTAssertEqual(actual.g, expected.g, accuracy: accuracy, "Green component mismatch", file: file, line: line)
        XCTAssertEqual(actual.b, expected.b, accuracy: accuracy, "Blue component mismatch", file: file, line: line)
    }

    // Test 6 primary and secondary hue sectors (0...1 normalized hue)
    func testHSBToRGBConversionSectors() {
        // Red: H = 0.0, S = 1.0, B = 1.0 -> (1.0, 0.0, 0.0)
        assertColorEqual(Color.hsbToRGB(h: 0.0, s: 1.0, b: 1.0), (1.0, 0.0, 0.0))

        // Yellow: H = 1/6 (0.166667), S = 1.0, B = 1.0 -> (1.0, 1.0, 0.0)
        assertColorEqual(Color.hsbToRGB(h: 1.0 / 6.0, s: 1.0, b: 1.0), (1.0, 1.0, 0.0))

        // Green: H = 2/6 (0.333333), S = 1.0, B = 1.0 -> (0.0, 1.0, 0.0)
        assertColorEqual(Color.hsbToRGB(h: 2.0 / 6.0, s: 1.0, b: 1.0), (0.0, 1.0, 0.0))

        // Cyan: H = 3/6 (0.5), S = 1.0, B = 1.0 -> (0.0, 1.0, 1.0)
        assertColorEqual(Color.hsbToRGB(h: 0.5, s: 1.0, b: 1.0), (0.0, 1.0, 1.0))

        // Blue: H = 4/6 (0.666667), S = 1.0, B = 1.0 -> (0.0, 0.0, 1.0)
        assertColorEqual(Color.hsbToRGB(h: 4.0 / 6.0, s: 1.0, b: 1.0), (0.0, 0.0, 1.0))

        // Magenta: H = 5/6 (0.833333), S = 1.0, B = 1.0 -> (1.0, 0.0, 1.0)
        assertColorEqual(Color.hsbToRGB(h: 5.0 / 6.0, s: 1.0, b: 1.0), (1.0, 0.0, 1.0))
    }

    // Test edge cases: negative hues, wrapping > 1.0, 0 saturation, 0 brightness
    func testHSBToRGBEdgeCases() {
        // Negative hue wraps using abs and truncatingRemainder
        // abs(-0.25) = 0.25 (150 deg -> Orange-Yellow/Green sector)
        let negativeHueResult = Color.hsbToRGB(h: -0.25, s: 1.0, b: 1.0)
        let expectedPositive = Color.hsbToRGB(h: 0.25, s: 1.0, b: 1.0)
        assertColorEqual(negativeHueResult, expectedPositive)

        // Hue >= 1.0 wraps via truncatingRemainder
        // 1.25 -> 0.25
        let wrappedHueResult = Color.hsbToRGB(h: 1.25, s: 1.0, b: 1.0)
        assertColorEqual(wrappedHueResult, expectedPositive)

        // Hue = 1.0 -> wraps to 0.0 (Red)
        assertColorEqual(Color.hsbToRGB(h: 1.0, s: 1.0, b: 1.0), (1.0, 0.0, 0.0))

        // Saturation = 0 -> Grayscale equal to brightness
        assertColorEqual(Color.hsbToRGB(h: 0.5, s: 0.0, b: 0.75), (0.75, 0.75, 0.75))

        // Brightness = 0 -> Black (0, 0, 0) regardless of hue / saturation
        assertColorEqual(Color.hsbToRGB(h: 0.3, s: 0.8, b: 0.0), (0.0, 0.0, 0.0))

        // White: S = 0, B = 1
        assertColorEqual(Color.hsbToRGB(h: 0.0, s: 0.0, b: 1.0), (1.0, 1.0, 1.0))
    }

    // Test p3 HSB helper instantiation
    func testP3ColorHSBVariants() {
        let redColor = Color.p3(h: 0.0, s: 1.0, b: 1.0)
        XCTAssertNotNil(redColor)

        let interpolatedColor = Color.p3(
            h: 0.5,
            s: 0.8,
            b: 0.9,
            a: 0.5,
            headroomBetween: .sdr,
            and: .effect,
            phase: 0.5
        )
        XCTAssertNotNil(interpolatedColor)
    }
}
