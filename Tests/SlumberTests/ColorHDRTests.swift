import XCTest
import SwiftUI
@testable import Slumber

final class ColorHDRTests: XCTestCase {
    func testHDRLevelRawValues() {
        XCTAssertEqual(HDRLevel.sdr.rawValue, 1.0)
        XCTAssertEqual(HDRLevel.rimHighlight.rawValue, 1.1)
        XCTAssertEqual(HDRLevel.subtleHighlight.rawValue, 1.25)
        XCTAssertEqual(HDRLevel.visibleGlow.rawValue, 1.75)
        XCTAssertEqual(HDRLevel.strongGlow.rawValue, 2.25)
        XCTAssertEqual(HDRLevel.effect.rawValue, 3.0)
    }

    func testP3ColorWithRGBConstructsColor() {
        let color = Color.p3(0.5, 0.4, 0.3, 0.8, level: .visibleGlow)
        XCTAssertNotNil(color)

        let labeledColor = Color.p3(r: 0.5, g: 0.4, b: 0.3, a: 0.8, level: .strongGlow)
        XCTAssertNotNil(labeledColor)
    }

    func testP3ColorWithHSBConstructsColor() {
        // Red (h = 0)
        let redColor = Color.p3(h: 0.0, s: 1.0, b: 1.0, a: 1.0, level: .sdr)
        XCTAssertNotNil(redColor)

        // Green (h = 0.333 / 120 deg)
        let greenColor = Color.p3(h: 0.333, s: 1.0, b: 1.0, a: 1.0, level: .rimHighlight)
        XCTAssertNotNil(greenColor)

        // Blue (h = 0.666 / 240 deg)
        let blueColor = Color.p3(h: 0.666, s: 1.0, b: 1.0, a: 1.0, level: .subtleHighlight)
        XCTAssertNotNil(blueColor)

        // Achromatic / Gray (s = 0)
        let grayColor = Color.p3(h: 0.5, s: 0.0, b: 0.5, a: 1.0, level: .effect)
        XCTAssertNotNil(grayColor)

        // Wrapped hue (h = 1.2 / hue wrapping)
        let wrappedHueColor = Color.p3(h: 1.2, s: 0.8, b: 0.9, a: 1.0, level: .sdr)
        XCTAssertNotNil(wrappedHueColor)

        // Negative hue (abs(hue) handling)
        let negativeHueColor = Color.p3(h: -0.2, s: 0.8, b: 0.9, a: 1.0, level: .sdr)
        XCTAssertNotNil(negativeHueColor)
    }

    func testP3InterpolationWithHSBConstructsColor() {
        let interpolatedColor = Color.p3(
            h: 0.15,
            s: 0.9,
            b: 0.8,
            a: 1.0,
            headroomBetween: .subtleHighlight,
            and: .effect,
            phase: 0.5
        )
        XCTAssertNotNil(interpolatedColor)
    }
}
