import XCTest
import SwiftUI
import SlumberCore
@testable import Slumber

final class ColorHDRTests: XCTestCase {

    // MARK: - Phase Clamping Edge Case Tests

    func testPhaseClampingBelowZeroClampsToZero() {
        // Below 0.0 phase (e.g. -0.5, -100.0) should clamp phase to 0.0,
        // resulting in the exact same color as phase = 0.0.
        let colorClampedMin = Color.p3(
            0.5, 0.5, 0.5, 1.0,
            headroomBetween: .subtleHighlight,
            and: .effect,
            phase: -0.5
        )
        let colorClampedFarMin = Color.p3(
            0.5, 0.5, 0.5, 1.0,
            headroomBetween: .subtleHighlight,
            and: .effect,
            phase: -100.0
        )
        let colorZero = Color.p3(
            0.5, 0.5, 0.5, 1.0,
            headroomBetween: .subtleHighlight,
            and: .effect,
            phase: 0.0
        )

        XCTAssertEqual(colorClampedMin, colorZero)
        XCTAssertEqual(colorClampedFarMin, colorZero)
    }

    func testPhaseClampingAboveOneClampsToOne() {
        // Above 1.0 phase (e.g. 1.5, 100.0) should clamp phase to 1.0,
        // resulting in the exact same color as phase = 1.0.
        let colorClampedMax = Color.p3(
            0.5, 0.5, 0.5, 1.0,
            headroomBetween: .subtleHighlight,
            and: .effect,
            phase: 1.5
        )
        let colorClampedFarMax = Color.p3(
            0.5, 0.5, 0.5, 1.0,
            headroomBetween: .subtleHighlight,
            and: .effect,
            phase: 100.0
        )
        let colorOne = Color.p3(
            0.5, 0.5, 0.5, 1.0,
            headroomBetween: .subtleHighlight,
            and: .effect,
            phase: 1.0
        )

        XCTAssertEqual(colorClampedMax, colorOne)
        XCTAssertEqual(colorClampedFarMax, colorOne)
    }

    func testPhaseClampingInBoundsPreservesInterpolation() {
        // Phase within 0.0...1.0 bounds should produce expected non-clamped values
        let colorMin = Color.p3(
            0.5, 0.5, 0.5, 1.0,
            headroomBetween: .subtleHighlight,
            and: .effect,
            phase: 0.0
        )
        let colorMid = Color.p3(
            0.5, 0.5, 0.5, 1.0,
            headroomBetween: .subtleHighlight,
            and: .effect,
            phase: 0.5
        )
        let colorMax = Color.p3(
            0.5, 0.5, 0.5, 1.0,
            headroomBetween: .subtleHighlight,
            and: .effect,
            phase: 1.0
        )

        // Verify distinct colors across phases
        XCTAssertNotEqual(colorMin, colorMid)
        XCTAssertNotEqual(colorMid, colorMax)
        XCTAssertNotEqual(colorMin, colorMax)
    }

    func testPhaseClampingLabeledRGBOverload() {
        // Verify phase clamping behavior in labeled RGB overload r:g:b:a:
        let negativePhase = Color.p3(
            r: 0.2, g: 0.4, b: 0.6, a: 0.8,
            headroomBetween: .rimHighlight,
            and: .visibleGlow,
            phase: -1.0
        )
        let zeroPhase = Color.p3(
            r: 0.2, g: 0.4, b: 0.6, a: 0.8,
            headroomBetween: .rimHighlight,
            and: .visibleGlow,
            phase: 0.0
        )
        let excessivePhase = Color.p3(
            r: 0.2, g: 0.4, b: 0.6, a: 0.8,
            headroomBetween: .rimHighlight,
            and: .visibleGlow,
            phase: 2.5
        )
        let onePhase = Color.p3(
            r: 0.2, g: 0.4, b: 0.6, a: 0.8,
            headroomBetween: .rimHighlight,
            and: .visibleGlow,
            phase: 1.0
        )

        XCTAssertEqual(negativePhase, zeroPhase)
        XCTAssertEqual(excessivePhase, onePhase)
    }

    func testPhaseClampingHSBOverload() {
        // Verify phase clamping behavior in HSB overload h:s:b:a:
        let negativePhase = Color.p3(
            h: 0.75, s: 0.5, b: 0.9, a: 1.0,
            headroomBetween: .sdr,
            and: .strongGlow,
            phase: -0.2
        )
        let zeroPhase = Color.p3(
            h: 0.75, s: 0.5, b: 0.9, a: 1.0,
            headroomBetween: .sdr,
            and: .strongGlow,
            phase: 0.0
        )
        let excessivePhase = Color.p3(
            h: 0.75, s: 0.5, b: 0.9, a: 1.0,
            headroomBetween: .sdr,
            and: .strongGlow,
            phase: 1.2
        )
        let onePhase = Color.p3(
            h: 0.75, s: 0.5, b: 0.9, a: 1.0,
            headroomBetween: .sdr,
            and: .strongGlow,
            phase: 1.0
        )

        XCTAssertEqual(negativePhase, zeroPhase)
        XCTAssertEqual(excessivePhase, onePhase)
    }

    func testPhaseInterpolationWhenBothLevelsAreSDRReturnsBaseColor() {
        // When both low and high levels are .sdr, phase interpolation should immediately return base
        let negativePhase = Color.p3(
            0.1, 0.2, 0.3, 1.0,
            headroomBetween: .sdr,
            and: .sdr,
            phase: -0.5
        )
        let excessivePhase = Color.p3(
            0.1, 0.2, 0.3, 1.0,
            headroomBetween: .sdr,
            and: .sdr,
            phase: 1.5
        )
        let standardColor = Color.p3(
            0.1, 0.2, 0.3, 1.0,
            level: .sdr
        )

        XCTAssertEqual(negativePhase, standardColor)
        XCTAssertEqual(excessivePhase, standardColor)
    }
}
