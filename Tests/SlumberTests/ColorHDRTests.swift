import XCTest
import SwiftUI
@testable import Slumber

final class ColorHDRTests: XCTestCase {

    // MARK: - RGB Clamping Edge Cases

    func testClampRGBBelowZeroClampsToZero() {
        XCTAssertEqual(Color.clampRGB(-0.001), 0.0, accuracy: 1e-9)
        XCTAssertEqual(Color.clampRGB(-0.5), 0.0, accuracy: 1e-9)
        XCTAssertEqual(Color.clampRGB(-100.0), 0.0, accuracy: 1e-9)
        XCTAssertEqual(Color.clampRGB(-.infinity), 0.0, accuracy: 1e-9)
    }

    func testClampRGBAboveOneClampsToOne() {
        XCTAssertEqual(Color.clampRGB(1.001), 1.0, accuracy: 1e-9)
        XCTAssertEqual(Color.clampRGB(1.5), 1.0, accuracy: 1e-9)
        XCTAssertEqual(Color.clampRGB(100.0), 1.0, accuracy: 1e-9)
        XCTAssertEqual(Color.clampRGB(.infinity), 1.0, accuracy: 1e-9)
    }

    func testClampRGBExactBoundariesAndMidpoints() {
        XCTAssertEqual(Color.clampRGB(0.0), 0.0, accuracy: 1e-9)
        XCTAssertEqual(Color.clampRGB(0.5), 0.5, accuracy: 1e-9)
        XCTAssertEqual(Color.clampRGB(1.0), 1.0, accuracy: 1e-9)
        XCTAssertEqual(Color.clampRGB(0.25), 0.25, accuracy: 1e-9)
        XCTAssertEqual(Color.clampRGB(0.75), 0.75, accuracy: 1e-9)
    }

    func testClampRGBMultipleComponents() {
        let rawR = -0.2
        let rawG = 1.4
        let rawB = 0.6

        let clampedR = Color.clampRGB(rawR)
        let clampedG = Color.clampRGB(rawG)
        let clampedB = Color.clampRGB(rawB)

        XCTAssertEqual(clampedR, 0.0, accuracy: 1e-9)
        XCTAssertEqual(clampedG, 1.0, accuracy: 1e-9)
        XCTAssertEqual(clampedB, 0.6, accuracy: 1e-9)
    }

    // MARK: - HDR Level Effective Headroom

    func testHDRLevelRawValues() {
        XCTAssertEqual(HDRLevel.sdr.rawValue, 1.0)
        XCTAssertEqual(HDRLevel.rimHighlight.rawValue, 1.1)
        XCTAssertEqual(HDRLevel.subtleHighlight.rawValue, 1.25)
        XCTAssertEqual(HDRLevel.visibleGlow.rawValue, 1.75)
        XCTAssertEqual(HDRLevel.strongGlow.rawValue, 2.25)
        XCTAssertEqual(HDRLevel.effect.rawValue, 3.0)
    }
}
