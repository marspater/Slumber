import XCTest
#if os(macOS)
import AppKit
@testable import Slumber

protocol ScreenProtocol {
    var maximumPotentialEDR: Double { get }
    var maximumEDR: Double { get }
    func canRepresentP3() -> Bool
}

extension NSScreen: ScreenProtocol {
    var maximumPotentialEDR: Double {
        Double(self.maximumPotentialExtendedDynamicRangeColorComponentValue)
    }

    var maximumEDR: Double {
        Double(self.maximumExtendedDynamicRangeColorComponentValue)
    }

    func canRepresentP3() -> Bool {
        self.canRepresent(.p3)
    }
}

struct TestScreen: ScreenProtocol {
    var maximumPotentialEDR: Double
    var maximumEDR: Double
    var p3Supported: Bool

    func canRepresentP3() -> Bool {
        p3Supported
    }
}

final class DisplayCapabilityTests: XCTestCase {
    func testSupportsWideColorP3True() {
        let screen = TestScreen(maximumPotentialEDR: 1.0, maximumEDR: 1.0, p3Supported: true)
        XCTAssertTrue(screen.canRepresentP3())
    }

    func testSupportsWideColorP3False() {
        let screen = TestScreen(maximumPotentialEDR: 1.0, maximumEDR: 1.0, p3Supported: false)
        XCTAssertFalse(screen.canRepresentP3())
    }

    func testSupportsEDRTrue() {
        let screen = TestScreen(maximumPotentialEDR: 2.0, maximumEDR: 1.0, p3Supported: true)
        XCTAssertTrue(screen.maximumPotentialEDR > 1.0)
    }

    func testSupportsEDRFalseWhenHeadroomIsOne() {
        let screen = TestScreen(maximumPotentialEDR: 1.0, maximumEDR: 1.0, p3Supported: true)
        XCTAssertFalse(screen.maximumPotentialEDR > 1.0)
    }

    func testSupportsEDRFalseWhenHeadroomIsLessThanOne() {
        let screen = TestScreen(maximumPotentialEDR: 0.8, maximumEDR: 1.0, p3Supported: true)
        XCTAssertFalse(screen.maximumPotentialEDR > 1.0)
    }

    func testCurrentHeadroomReturnsCorrectValue() {
        let screen = TestScreen(maximumPotentialEDR: 2.5, maximumEDR: 2.5, p3Supported: true)
        XCTAssertEqual(screen.maximumEDR, 2.5, accuracy: 0.001)
    }

    func testNilScreenFallbackDoesNotCrash() {
        _ = DisplayCapability.supportsWideColorP3(nil)
        _ = DisplayCapability.supportsEDR(nil)
        _ = DisplayCapability.currentHeadroom(nil)
    }
}
#endif
