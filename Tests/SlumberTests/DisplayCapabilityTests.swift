import XCTest
@testable import Slumber

final class DisplayCapabilityTests: XCTestCase {
    func testDisplayCapabilityReturnsConsistentCachedValues() {
        // Querying DisplayCapability multiple times should return consistent values
        let edrFirst = DisplayCapability.supportsEDR()
        let edrSecond = DisplayCapability.supportsEDR()
        XCTAssertEqual(edrFirst, edrSecond)

        let p3First = DisplayCapability.supportsWideColorP3()
        let p3Second = DisplayCapability.supportsWideColorP3()
        XCTAssertEqual(p3First, p3Second)

        let headroomFirst = DisplayCapability.currentHeadroom()
        let headroomSecond = DisplayCapability.currentHeadroom()
        XCTAssertEqual(headroomFirst, headroomSecond)
    }

    func testInvalidateCacheResetsCapabilityCache() {
        let initialEdr = DisplayCapability.supportsEDR()
        DisplayCapability.invalidateCache()
        let postInvalidationEdr = DisplayCapability.supportsEDR()
        XCTAssertEqual(initialEdr, postInvalidationEdr)
    }
}
