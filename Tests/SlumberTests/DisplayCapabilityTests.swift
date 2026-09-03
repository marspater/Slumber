import XCTest
import AppKit
@testable import Slumber

#if os(macOS)
final class MockScreen: NSScreen {
    private let mockMaxPotentialEDR: CGFloat
    private let mockMaxEDR: CGFloat
    private let mockSupportsP3: Bool

    init(
        maxPotentialEDR: CGFloat = 1.0,
        maxEDR: CGFloat = 1.0,
        supportsP3: Bool = true
    ) {
        self.mockMaxPotentialEDR = maxPotentialEDR
        self.mockMaxEDR = maxEDR
        self.mockSupportsP3 = supportsP3
        super.init()
    }

    override var maximumPotentialExtendedDynamicRangeColorComponentValue: CGFloat {
        return mockMaxPotentialEDR
    }

    override var maximumExtendedDynamicRangeColorComponentValue: CGFloat {
        return mockMaxEDR
    }

    override func canRepresent(_ colorSpace: NSColorSpace) -> Bool {
        if colorSpace == .p3 {
            return mockSupportsP3
        }
        return super.canRepresent(colorSpace)
    }
}

final class DisplayCapabilityTests: XCTestCase {

    // MARK: - supportsEDR Tests

    func testSupportsEDRReturnsTrueWhenHeadroomGreaterThanOne() {
        let mockScreen = MockScreen(maxPotentialEDR: 2.0)
        XCTAssertTrue(DisplayCapability.supportsEDR(mockScreen))
    }

    func testSupportsEDRReturnsFalseWhenHeadroomEqualsOne() {
        let mockScreen = MockScreen(maxPotentialEDR: 1.0)
        XCTAssertFalse(DisplayCapability.supportsEDR(mockScreen))
    }

    func testSupportsEDRReturnsFalseWhenHeadroomLessThanOne() {
        let mockScreen = MockScreen(maxPotentialEDR: 0.8)
        XCTAssertFalse(DisplayCapability.supportsEDR(mockScreen))
    }

    func testSupportsEDRWithNilScreenDoesNotCrash() {
        // Passing nil will fallback to NSScreen.main / NSScreen.screens.first or default 1.0.
        // It shouldn't crash regardless of runtime environment.
        _ = DisplayCapability.supportsEDR(nil)
    }

    // MARK: - supportsWideColorP3 Tests

    func testSupportsWideColorP3ReturnsTrueWhenSupported() {
        let mockScreen = MockScreen(supportsP3: true)
        XCTAssertTrue(DisplayCapability.supportsWideColorP3(mockScreen))
    }

    func testSupportsWideColorP3ReturnsFalseWhenNotSupported() {
        let mockScreen = MockScreen(supportsP3: false)
        XCTAssertFalse(DisplayCapability.supportsWideColorP3(mockScreen))
    }

    func testSupportsWideColorP3WithNilScreenDoesNotCrash() {
        _ = DisplayCapability.supportsWideColorP3(nil)
    }

    // MARK: - currentHeadroom Tests

    func testCurrentHeadroomReturnsCorrectValue() {
        let mockScreen = MockScreen(maxEDR: 3.5)
        XCTAssertEqual(DisplayCapability.currentHeadroom(mockScreen), 3.5, accuracy: 0.001)
    }

    func testCurrentHeadroomWithNilScreenDoesNotCrash() {
        _ = DisplayCapability.currentHeadroom(nil)
    }

    // MARK: - HDRLevel Effective Test

    func testHDRLevelEffectiveWithEDRSupport() {
        let level = HDRLevel.effect
        XCTAssertEqual(level.rawValue, 3.0)
    }
}
#endif
