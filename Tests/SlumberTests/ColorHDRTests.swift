import XCTest
import SwiftUI
@testable import SlumberCore

final class ColorHDRTests: XCTestCase {

    // MARK: - RGB Clamping Edge Cases

    func testClampRGBEdgeCases() {
        let testCases: [(input: Double, expected: Double)] = [
            (-0.001, 0.0), (-0.5, 0.0), (-100.0, 0.0), (-.infinity, 0.0),
            (1.001, 1.0), (1.5, 1.0), (100.0, 1.0), (.infinity, 1.0),
            (0.0, 0.0), (0.25, 0.25), (0.5, 0.5), (0.75, 0.75), (1.0, 1.0)
        ]
        for testCase in testCases {
            XCTAssertEqual(Color.clampRGB(testCase.input), testCase.expected, accuracy: 1e-9)
        }
    }

    func testClampRGBMultipleComponents() {
        let components = (r: -0.2, g: 1.4, b: 0.6)
        XCTAssertEqual(Color.clampRGB(components.r), 0.0, accuracy: 1e-9)
        XCTAssertEqual(Color.clampRGB(components.g), 1.0, accuracy: 1e-9)
        XCTAssertEqual(Color.clampRGB(components.b), 0.6, accuracy: 1e-9)
    }

    // MARK: - HDR Level Effective Headroom

    func testHDRLevelRawValues() {
        let levels: [(HDRLevel, Double)] = [
            (.sdr, 1.0), (.rimHighlight, 1.1), (.subtleHighlight, 1.25),
            (.visibleGlow, 1.75), (.strongGlow, 2.25), (.effect, 3.0)
        ]
        for (level, expectedRaw) in levels {
            XCTAssertEqual(level.rawValue, expectedRaw)
        }
    }
}
