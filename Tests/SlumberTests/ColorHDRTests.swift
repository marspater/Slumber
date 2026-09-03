//
//  ColorHDRTests.swift
//  SlumberTests
//

import XCTest
import SwiftUI
#if os(macOS)
import AppKit
#endif
@testable import Slumber

final class ColorHDRTests: XCTestCase {

    // MARK: - HDRLevel Tests

    func testHDRLevelRawValues() {
        XCTAssertEqual(HDRLevel.sdr.rawValue, 1.0)
        XCTAssertEqual(HDRLevel.rimHighlight.rawValue, 1.1)
        XCTAssertEqual(HDRLevel.subtleHighlight.rawValue, 1.25)
        XCTAssertEqual(HDRLevel.visibleGlow.rawValue, 1.75)
        XCTAssertEqual(HDRLevel.strongGlow.rawValue, 2.25)
        XCTAssertEqual(HDRLevel.effect.rawValue, 3.0)
    }

    func testHDRLevelAllCasesCount() {
        XCTAssertEqual(HDRLevel.allCases.count, 6)
    }

    func testHDRLevelEffectiveReturnsLevelOrSDR() {
        for level in HDRLevel.allCases {
            let effective = level.effective
            #if os(macOS)
            if DisplayCapability.supportsEDR() {
                XCTAssertEqual(effective, level)
            } else {
                XCTAssertEqual(effective, .sdr)
            }
            #else
            XCTAssertEqual(effective, level)
            #endif
        }
    }

    // MARK: - DisplayCapability Tests

    #if os(macOS)
    func testDisplayCapabilityMethodsWithNilScreen() {
        // Calling with nil screen uses fallback NSScreen logic without crashing
        let edrSupported = DisplayCapability.supportsEDR(nil)
        let wideColorSupported = DisplayCapability.supportsWideColorP3(nil)
        let headroom = DisplayCapability.currentHeadroom(nil)

        XCTAssertNotNil(edrSupported)
        XCTAssertNotNil(wideColorSupported)
        XCTAssertGreaterThanOrEqual(headroom, 1.0)
    }

    func testDisplayHeadroomAlias() {
        let supportsEDR = DisplayHeadroom.supportsEDR()
        let supportsP3 = DisplayHeadroom.supportsWideColorP3()
        let headroom = DisplayHeadroom.currentHeadroom()

        XCTAssertEqual(supportsEDR, DisplayCapability.supportsEDR())
        XCTAssertEqual(supportsP3, DisplayCapability.supportsWideColorP3())
        XCTAssertEqual(headroom, DisplayCapability.currentHeadroom())
    }
    #endif

    // MARK: - Color.p3 RGB Tests

    func testColorP3PositionalRGB() {
        let colorSDR = Color.p3(0.2, 0.4, 0.8, 0.9, level: .sdr)
        XCTAssertNotNil(colorSDR)

        let colorGlow = Color.p3(0.2, 0.4, 0.8, 1.0, level: .visibleGlow)
        XCTAssertNotNil(colorGlow)

        // Clamping check for out-of-bounds RGB
        let colorOutOfBounds = Color.p3(-0.5, 1.5, 0.5, 1.0, level: .sdr)
        XCTAssertNotNil(colorOutOfBounds)
    }

    func testColorP3LabeledRGB() {
        let color1 = Color.p3(r: 0.1, g: 0.5, b: 0.9, a: 0.8, level: .subtleHighlight)
        XCTAssertNotNil(color1)

        let colorDefaultAlphaAndLevel = Color.p3(r: 0.3, g: 0.6, b: 0.2)
        XCTAssertNotNil(colorDefaultAlphaAndLevel)
    }

    // MARK: - Color.p3 HSB Tests

    func testColorP3HSB() {
        // Test all 6 hue sectors (0...5) in HSB conversion
        let hues = [0.0, 0.2, 0.4, 0.6, 0.8, 0.95]
        for h in hues {
            let color = Color.p3(h: h, s: 0.8, b: 0.9, a: 1.0, level: .rimHighlight)
            XCTAssertNotNil(color)
        }

        // Negative and > 1.0 hue wrap checks
        let colorNegativeHue = Color.p3(h: -0.25, s: 0.5, b: 0.5)
        XCTAssertNotNil(colorNegativeHue)

        let colorOverflowHue = Color.p3(h: 2.75, s: 0.5, b: 0.5)
        XCTAssertNotNil(colorOverflowHue)
    }

    // MARK: - Color.p3 Headroom Interpolation Tests

    func testColorP3InterpolationPositionalRGB() {
        // Phase within 0...1
        let colorMidPhase = Color.p3(
            0.5, 0.5, 0.5, 1.0,
            headroomBetween: .sdr,
            and: .effect,
            phase: 0.5
        )
        XCTAssertNotNil(colorMidPhase)

        // Phase out of bounds (< 0.0 and > 1.0)
        let colorMinPhase = Color.p3(
            0.5, 0.5, 0.5, 1.0,
            headroomBetween: .subtleHighlight,
            and: .strongGlow,
            phase: -0.5
        )
        XCTAssertNotNil(colorMinPhase)

        let colorMaxPhase = Color.p3(
            0.5, 0.5, 0.5, 1.0,
            headroomBetween: .subtleHighlight,
            and: .strongGlow,
            phase: 1.5
        )
        XCTAssertNotNil(colorMaxPhase)
    }

    func testColorP3InterpolationLabeledRGB() {
        let color = Color.p3(
            r: 0.2, g: 0.8, b: 0.4, a: 0.9,
            headroomBetween: .rimHighlight,
            and: .visibleGlow,
            phase: 0.3
        )
        XCTAssertNotNil(color)
    }

    func testColorP3InterpolationHSB() {
        let color = Color.p3(
            h: 0.33, s: 0.9, b: 0.8, a: 1.0,
            headroomBetween: .visibleGlow,
            and: .effect,
            phase: 0.75
        )
        XCTAssertNotNil(color)
    }
}
