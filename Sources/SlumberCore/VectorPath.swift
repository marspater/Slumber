//
//  VectorPath.swift
//  SlumberCore
//
//  Minimal SVG path-data parser for Slumber's vector artwork.
//

import CoreGraphics

/// One absolute drawing command from SVG path data.
public enum VectorPathCommand: Equatable, Sendable {
    case move(CGPoint)
    case line(CGPoint)
    case quad(to: CGPoint, control: CGPoint)
    case curve(to: CGPoint, control1: CGPoint, control2: CGPoint)
    case close
}

public enum VectorPath {
    /// Parses whitespace/comma separated, absolute-only path data (`M`, `L`, `Q`, `C`, `Z`).
    /// Repeated coordinate groups after a command are accepted, as in SVG.
    /// Returns an empty array for anything else, so malformed art draws nothing rather than garbage.
    public static func parse(_ data: String) -> [VectorPathCommand] {
        var commands: [VectorPathCommand] = []
        var op: Character?
        var numbers: [CGFloat] = []

        func arity(_ op: Character) -> Int {
            switch op {
            case "M", "L": return 2
            case "Q": return 4
            case "C": return 6
            default: return 0
            }
        }

        for token in data.split(whereSeparator: { $0 == " " || $0 == "," || $0.isNewline }) {
            if token.count == 1, let c = token.first, c.isLetter {
                guard numbers.isEmpty, "MLQCZ".contains(c) else { return [] }
                op = c
                if c == "Z" { commands.append(.close) }
                continue
            }
            guard let current = op, current != "Z", let value = Double(token) else { return [] }
            numbers.append(CGFloat(value))
            guard numbers.count == arity(current) else { continue }

            let n = numbers
            numbers.removeAll(keepingCapacity: true)
            switch current {
            case "M":
                commands.append(.move(CGPoint(x: n[0], y: n[1])))
                op = "L" // SVG: extra pairs after a moveto are linetos
            case "L":
                commands.append(.line(CGPoint(x: n[0], y: n[1])))
            case "Q":
                commands.append(.quad(to: CGPoint(x: n[2], y: n[3]), control: CGPoint(x: n[0], y: n[1])))
            default:
                commands.append(.curve(
                    to: CGPoint(x: n[4], y: n[5]),
                    control1: CGPoint(x: n[0], y: n[1]),
                    control2: CGPoint(x: n[2], y: n[3])
                ))
            }
        }
        return numbers.isEmpty ? commands : []
    }
}
