import XCTest
#if os(macOS)
import AppKit
@testable import Slumber

final class MockScreen: NSScreen {
    var mockCanRepresentP3: Bool
    var mockMaxPotentialEDR: CGFloat
    var mockMaxEDR: CGFloat

    init(canRepresentP3: Bool = true, maxPotentialEDR: CGFloat = 1.0, maxEDR: CGFloat = 1.0) {
        self.mockCanRepresentP3 = canRepresentP3
        self.mockMaxPotentialEDR = maxPotentialEDR
        self.mockMaxEDR = maxEDR
        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func canRepresent(_ colorSpaceName: NSColorSpaceName) -> Bool {
        if colorSpaceName == .p3 {
            return mockCanRepresentP3
        }
        return super.canRepresent(colorSpaceName)
    }

    override var maximumPotentialExtendedDynamicRangeColorComponentValue: CGFloat {
        return mockMaxPotentialEDR
    }

    override var maximumExtendedDynamicRangeColorComponentValue: CGFloat {
        return mockMaxEDR
    }
}

final class DisplayCapabilityTests: XCTestCase {
    func testSupportsWideColorP3True() {
        let screen = MockScreen(canRepresentP3: true)
        XCTAssertTrue(DisplayCapability.supportsWideColorP3(screen))
    }

    func testSupportsWideColorP3False() {
        let screen = MockScreen(canRepresentP3: false)
        XCTAssertFalse(DisplayCapability.supportsWideColorP3(screen))
    }

    func testSupportsEDRTrue() {
        let screen = MockScreen(maxPotentialEDR: 2.0)
        XCTAssertTrue(DisplayCapability.supportsEDR(screen))
    }

    func testSupportsEDRFalseWhenHeadroomIsOne() {
        let screen = MockScreen(maxPotentialEDR: 1.0)
        XCTAssertFalse(DisplayCapability.supportsEDR(screen))
    }

    func testSupportsEDRFalseWhenHeadroomIsLessThanOne() {
        let screen = MockScreen(maxPotentialEDR: 0.8)
        XCTAssertFalse(DisplayCapability.supportsEDR(screen))
    }

    func testCurrentHeadroomReturnsCorrectValue() {
        let screen = MockScreen(maxEDR: 2.5)
        XCTAssertEqual(DisplayCapability.currentHeadroom(screen), 2.5, accuracy: 0.001)
    }

    func testNilScreenFallbackDoesNotCrash() {
        _ = DisplayCapability.supportsWideColorP3(nil)
        _ = DisplayCapability.supportsEDR(nil)
        _ = DisplayCapability.currentHeadroom(nil)
    }
}
#endif
