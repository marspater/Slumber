//
//  VectorShape.swift
//  Slumber
//
//  Draws `VectorPath` data authored in a fixed viewBox, scaled to the frame it is given.
//

import SwiftUI
import SlumberCore

struct VectorShape: Shape {
    let commands: [VectorPathCommand]
    let viewBox: CGSize

    init(_ data: String, viewBox: CGSize) {
        self.commands = VectorPath.parse(data)
        self.viewBox = viewBox
    }

    func path(in rect: CGRect) -> Path {
        let sx = rect.width / viewBox.width
        let sy = rect.height / viewBox.height
        func map(_ p: CGPoint) -> CGPoint {
            CGPoint(x: rect.minX + p.x * sx, y: rect.minY + p.y * sy)
        }

        var path = Path()
        for command in commands {
            switch command {
            case .move(let p): path.move(to: map(p))
            case .line(let p): path.addLine(to: map(p))
            case .quad(let p, let c): path.addQuadCurve(to: map(p), control: map(c))
            case .curve(let p, let c1, let c2): path.addCurve(to: map(p), control1: map(c1), control2: map(c2))
            case .close: path.closeSubpath()
            }
        }
        return path
    }
}

extension LinearGradient {
    /// Gradient between two points given in art (viewBox) coordinates, like SVG's `userSpaceOnUse`.
    init(_ gradient: Gradient, from start: CGPoint, to end: CGPoint, in box: CGSize) {
        self.init(
            gradient: gradient,
            startPoint: UnitPoint(x: start.x / box.width, y: start.y / box.height),
            endPoint: UnitPoint(x: end.x / box.width, y: end.y / box.height)
        )
    }
}

extension UnitPoint {
    /// A point given in art (viewBox) coordinates, for rotation and scale anchors.
    init(_ x: CGFloat, _ y: CGFloat, in box: CGSize) {
        self.init(x: x / box.width, y: y / box.height)
    }
}

extension StrokeStyle {
    /// Round-capped line used by the vector art.
    static func round(_ width: CGFloat) -> StrokeStyle {
        StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round)
    }
}
