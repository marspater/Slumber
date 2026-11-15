import CoreGraphics
import Foundation
import Testing
import SlumbrCore
@testable import Slumbr

@Suite("Theme")
struct ThemeTests {
    /// Sunset Glow (1-20), Evening Twilight (21-38), Late Dusk (39-50), Midnight Blue (51-75), Deep Cosmic Space (76+).
    @Test(arguments: [
        (1, 0), (20, 0),
        (21, 1), (38, 1),
        (39, 2), (50, 2),
        (51, 3), (75, 3),
        (76, 4), (120, 4),
    ])
    func skyPhaseBoundaries(minutes: Int, phase: Int) {
        #expect(SlumbrTheme.Sky.phase(forMinutes: minutes) == phase)
    }

    /// The view indexes both gradients with the phase, so every phase needs a color in each.
    @Test func everySkyPhaseHasGradientColors() {
        let phases = SlumbrTheme.Sky.phaseUpperBounds.count + 1
        #expect(SlumbrTheme.Sky.top.count == phases)
        #expect(SlumbrTheme.Sky.bottom.count == phases)
        #expect(SlumbrTheme.Sky.phaseUpperBounds == SlumbrTheme.Sky.phaseUpperBounds.sorted())
    }

    @Test func contentGridFitsThePopover() {
        let m = SlumbrTheme.Metrics.self
        #expect(m.popoverWidth == 320)
        #expect(m.contentWidth == 272)
        #expect(m.contentWidth == m.popoverWidth - 2 * m.horizontalPadding)
    }
}

@Suite("Artwork")
struct ArtworkTests {
    /// Every path in ArtPaths.swift must parse: malformed data silently draws nothing.
    @Test func everyArtPathParses() throws {
        let source = URL(filePath: #filePath)
            .deletingLastPathComponent()
            .appending(path: "../../Sources/Slumbr/Art/ArtPaths.swift")
            .standardized
        let text = try String(contentsOf: source, encoding: .utf8)
        let paths = text.matches(of: /VectorShape\("([^"]*)"/).map { String($0.output.1) }
        #expect(paths.count > 40)
        for data in paths {
            #expect(!VectorPath.parse(data).isEmpty, "Unparseable path: \(data)")
        }
    }

    @MainActor
    @Test func vectorShapeScalesViewBoxToRect() {
        let shape = VectorShape("M 0 0 L 10 20", viewBox: CGSize(width: 10, height: 20))
        let bounds = shape.path(in: CGRect(x: 5, y: 5, width: 100, height: 40)).boundingRect
        #expect(bounds == CGRect(x: 5, y: 5, width: 100, height: 40))
    }
}
