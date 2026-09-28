import XCTest
import CoreGraphics
import SlumberCore

final class VectorPathTests: XCTestCase {
    func testParsesAllCommands() {
        let commands = VectorPath.parse("M 1 2 L 3 4 Q 5 6 7 8 C 9 10 11 12 13.5 -14 Z")
        XCTAssertEqual(commands, [
            .move(CGPoint(x: 1, y: 2)),
            .line(CGPoint(x: 3, y: 4)),
            .quad(to: CGPoint(x: 7, y: 8), control: CGPoint(x: 5, y: 6)),
            .curve(to: CGPoint(x: 13.5, y: -14), control1: CGPoint(x: 9, y: 10), control2: CGPoint(x: 11, y: 12)),
            .close
        ])
    }

    func testRepeatedCoordinateGroups() {
        XCTAssertEqual(VectorPath.parse("M 0 0 1 1 C 0 0 0 0 2 2 0 0 0 0 3 3"), [
            .move(CGPoint(x: 0, y: 0)),
            .line(CGPoint(x: 1, y: 1)),
            .curve(to: CGPoint(x: 2, y: 2), control1: .zero, control2: .zero),
            .curve(to: CGPoint(x: 3, y: 3), control1: .zero, control2: .zero)
        ])
    }

    func testRejectsMalformedData() {
        XCTAssertEqual(VectorPath.parse("M 1"), [])            // dangling coordinate
        XCTAssertEqual(VectorPath.parse("M 1 2 A 1 1 0 0 1 2 2"), []) // unsupported command
        XCTAssertEqual(VectorPath.parse("m 1 2"), [])          // relative commands unsupported
        XCTAssertEqual(VectorPath.parse("1 2"), [])            // numbers before a command
        XCTAssertEqual(VectorPath.parse("M 1 x"), [])          // not a number
    }
}
