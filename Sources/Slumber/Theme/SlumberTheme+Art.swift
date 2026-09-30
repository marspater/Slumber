//
//  SlumberTheme+Art.swift
//  Slumber
//
//  Artwork tokens: the palettes, glow levels, loop timings and scene layout of the moon, clouds,
//  companions, stars, fireflies, constellations and aurora. Path data stays in Art/ArtPaths.swift,
//  and per-shape geometry (gradient endpoints and anchors in viewBox coordinates, particle drift,
//  fidget angles) stays next to the shape it belongs to.
//
//  Gradients are `static var` so each use builds a fresh value.
//

import SwiftUI

extension SlumberTheme {
    public enum Art {
        // MARK: - Scene layout
        /// Positions are offsets from the popover's center, in points.
        public enum Scene {
            public static let moon = CGPoint(x: 95, y: -135)
            /// Where the companion naps while the timer is idle.
            public static let companionCloud = CGPoint(x: -95, y: 146)
            public static let largeCloud = CGPoint(x: -95, y: 170)
            public static let smallCloud = CGPoint(x: 105, y: -30)
            public static let largeCloudScale: CGFloat = 1.0
            public static let smallCloudScale: CGFloat = 0.75

            public static let starCount = 45
            public static let fireflyCount = 8

            /// Shooting stars: angle in degrees, cycle and delay in seconds, length and start in points.
            public static let shootingStars: [(angle: Double, cycle: Double, delay: Double, length: CGFloat, start: CGPoint)] = [
                (32, 4.0, 1.0, 50, CGPoint(x: -60, y: 20)),
                (45, 5.5, 4.0, 35, CGPoint(x: 80, y: -30)),
                (25, 3.8, 7.0, 45, CGPoint(x: -20, y: -50)),
                (38, 6.0, 10.5, 40, CGPoint(x: 40, y: 60)),
                (18, 4.5, 14.0, 55, CGPoint(x: -90, y: 90))
            ]
        }

        // MARK: - Companion orbit
        public enum Orbit {
            /// One lap around the moon, in seconds.
            public static let period: Double = 90.0
            public static let launchDuration: Double = 2.2
            public static let returnDuration: Double = 1.6
            public static let radiusX: CGFloat = 56
            public static let radiusY: CGFloat = 28
            /// Control point of the quadratic cloud-to-orbit arc.
            public static let arcControl = CGPoint(x: -132, y: -8)
            /// One full zero-g somersault, in seconds.
            public static let tumblePeriod: Double = 6.5

            /// Companion scale on the cloud, and how much it shrinks in orbit: fox, cat, dodo.
            public static let companionScale: [(rest: CGFloat, orbitShrink: CGFloat)] = [
                (0.65, 0.15),
                (0.82, 0.12),
                (0.75, 0.14)
            ]

            /// Comet trail dot: head color fades to a transparent cyan tail.
            public static func trailHead(alpha: Double) -> Color {
                .p3(h: 0.78, s: 0.6, b: 1.0, a: alpha, level: .rimHighlight)
            }
            public static let trailTail = Color.p3(h: 0.55, s: 0.5, b: 0.9, a: 0.0, level: .subtleHighlight)
        }

        // MARK: - Stars
        public enum Stars {
            /// Lavender halo around a lit star; sparkles glow at `.rimHighlight`.
            public static func glow(alpha: Double, level: HDRLevel) -> Color {
                .p3(h: 0.75, s: 0.25, b: 1.0, a: alpha, level: level)
            }
            public static let glowOpacity: Double = 0.35
            public static let glowRadius: CGFloat = 2
            public static let sparkleGlowRadius: CGFloat = 4
            public static let sparkleScale: CGFloat = 2.2
            public static let litOpacity: Double = 0.75
            public static let restOpacity: Double = 0.12
            /// Each star picks a twinkle period from this range, in seconds.
            public static let twinkleDuration: ClosedRange<Double> = 1.8...3.8
        }

        // MARK: - Shooting star
        public enum ShootingStar {
            /// Transparent end of the streak.
            public static let tail = Color.p3(h: 0.75, s: 0.25, b: 0.95, a: 0, level: .subtleHighlight)
            /// Bright head, flaring toward `.effect` as the streak starts (`phase` 1 → 0).
            public static func head(alpha: Double, phase: Double) -> Color {
                .p3(h: 0.72, s: 0.15, b: 1.0, a: alpha, headroomBetween: .subtleHighlight, and: .effect, phase: phase)
            }
            public static let headOpacity: Double = 0.85
            public static let glowOpacity: Double = 0.45
            public static let glowRadius: CGFloat = 3.5
            public static let thickness: CGFloat = 1.0
            public static let blur: CGFloat = 0.3
            /// Drawn length as a fraction of the star's `length`.
            public static let lengthRatio: CGFloat = 0.85
            /// Distance covered per cycle, in points.
            public static let travel: CGFloat = 280
            /// 60 fps: at 30 a streak crossing a 60 Hz panel holds every position for two frames and judders.
            public static let frameRate: Double = 60
        }

        // MARK: - Fireflies
        public enum Firefly {
            /// Warm amber, violet and cyan, assigned by `seed % 3`.
            public static let tones: [(hue: Double, glow: (r: Double, g: Double, b: Double))] = [
                (0.08, (1.0, 0.85, 0.25)),
                (0.75, (0.85, 0.55, 0.95)),
                (0.52, (0.35, 0.85, 0.95))
            ]
            public static func core(hue: Double) -> Color {
                .p3(h: hue, s: 0.5, b: 1.0, level: .rimHighlight)
            }
            /// Glow twinkles between `.visibleGlow` and `.effect`.
            public static func glow(_ rgb: (r: Double, g: Double, b: Double), phase: Double) -> Color {
                .p3(r: rgb.r, g: rgb.g, b: rgb.b, a: 0.85, headroomBetween: .visibleGlow, and: .effect, phase: phase)
            }
            public static let size: CGFloat = 2.5
            /// Glow radius and opacity at rest, plus what the twinkle adds at its peak.
            public static let glowRadius = (rest: CGFloat(2.0), peak: CGFloat(6.0))
            public static let opacity = (rest: 0.15, peak: 0.55)
            /// Fireflies drift slowly enough to stay at 30 fps.
            public static let frameRate: Double = 30
        }

        // MARK: - Constellations
        public enum Constellation {
            public static let layerOpacity: Double = 0.3
            /// One full rotation of the constellation layer, in seconds.
            public static let rotationPeriod: Double = 180
            public static let pulseDuration: Double = 4.0
            public static let lineOpacity = (dim: 0.04, lit: 0.09)
            public static let lineWidth: CGFloat = 0.6
            public static let starOpacity = (dim: 0.15, lit: 0.30)
            public static let starSize: CGFloat = 2.5
            public static func glow(alpha: Double) -> Color {
                .p3(h: 0.75, s: 0.3, b: 1.0, a: alpha, level: .subtleHighlight)
            }
            public static let glowOpacity = (dim: 0.1, lit: 0.35)
            public static let glowRadius = (dim: CGFloat(1), lit: CGFloat(3))
        }

        // MARK: - Aurora
        public enum Aurora {
            /// Four drifting washes: violet, cyan, magenta, rose. Each band is a gradient pair.
            public static let bands: [[Color]] = [
                [.p3(h: 0.75, s: 0.65, b: 0.7, a: 0.08, level: .subtleHighlight), .p3(h: 0.72, s: 0.5, b: 0.7, a: 0.03, level: .subtleHighlight)],
                [.p3(h: 0.55, s: 0.55, b: 0.7, a: 0.07, level: .subtleHighlight), .p3(h: 0.60, s: 0.4, b: 0.7, a: 0.02, level: .subtleHighlight)],
                [.p3(h: 0.82, s: 0.55, b: 0.65, a: 0.05, level: .subtleHighlight)],
                [.p3(h: 0.93, s: 0.50, b: 0.7, a: 0.05, level: .subtleHighlight), .p3(h: 0.88, s: 0.40, b: 0.7, a: 0.02, level: .subtleHighlight)]
            ]
            /// Drift half-period of each band, in seconds.
            public static let driftDurations: [Double] = [6, 8, 10, 12]
        }

        // MARK: - Moon
        public enum Moon {
            public static let face = Color.p3(0.36, 0.26, 0.58)
            /// Nightcap band and pompom.
            public static let cloth = Color.p3(0.98, 0.97, 1.0, level: .subtleHighlight)
            public static let halo = Color.p3(h: 0.75, s: 0.4, b: 1.0, a: 0.3, level: .visibleGlow)
            public static let haloRadii = (start: CGFloat(10), end: CGFloat(40))
            public static let haloSize: CGFloat = 80
            public static let haloPulseScale: CGFloat = 1.15
            public static var crescent: Gradient {
                Gradient(stops: [
                    .init(color: .p3(0.88, 0.82, 1.0, level: .strongGlow), location: 0),
                    .init(color: .p3(0.74, 0.62, 0.95, level: .strongGlow), location: 0.55),
                    .init(color: .p3(0.60, 0.48, 0.88, level: .strongGlow), location: 1)
                ])
            }
            public static let rim = Color.p3(1, 1, 1, 0.55, level: .strongGlow)
            public static let craters = Color.p3(0.62, 0.50, 0.90, 0.18)
            public static let blush = Color.p3(1, 0.50, 0.70, 0.5)
            public static var cap: Gradient {
                Gradient(colors: [.p3(0.46, 0.74, 1.0, level: .rimHighlight), .p3(0.30, 0.46, 0.92, level: .rimHighlight)])
            }
            public static let capFold = Color.p3(0.20, 0.30, 0.78, 0.35)

            /// Bob distance (points) and tilt (degrees) each way.
            public static let bob: CGFloat = 5
            public static let tilt: Double = 3
            public static let bobDuration: Double = 3.5
            public static let haloPulseDuration: Double = 2.5
        }

        // MARK: - Clouds
        public enum Cloud {
            public static let face = Color.p3(0.40, 0.32, 0.62)
            public static let blush = Color.p3(1, 0.50, 0.70, 0.45)
            public static let shadow = Color.p3(0.10, 0.06, 0.24, 0.22)
            public static let shadowOffsetY: CGFloat = 2.5
            public static let shadowBlur: CGFloat = 3
            /// Lilac-to-white body, faded by the cloud's opacity.
            public static func body(opacity: Double) -> Gradient {
                Gradient(stops: [
                    .init(color: .p3(0.99, 0.98, 1.0, opacity), location: 0),
                    .init(color: .p3(0.88, 0.85, 0.97, opacity), location: 0.6),
                    .init(color: .p3(0.70, 0.64, 0.90, opacity), location: 1)
                ])
            }
            /// EDR top rim fading out down the cloud.
            public static func rim(opacity: Double) -> Gradient {
                Gradient(colors: [.p3(1, 1, 1, 0.9 * opacity, level: .rimHighlight), .p3(1, 1, 1, 0)])
            }
            public static let rimWidth: CGFloat = 1
            public static let largeOpacity: Double = 0.95
            public static let smallOpacity: Double = 0.6
            public static let largeBobDuration: Double = 4.5
            public static let smallBobDuration: Double = 5.5
            public static let smallBobDelay: Double = 0.5
        }

        // MARK: - Companions (shared)
        public enum Companion {
            /// Bold rounded face for the "z" particles and the last-minute "?".
            public static func letterFont(size: CGFloat) -> Font {
                .system(size: size, weight: .bold, design: .rounded)
            }
            /// Leading and trailing "z" particle color.
            public static let z1 = Color.white.opacity(0.4)
            public static let z2 = Color.white.opacity(0.3)
            /// EDR glint in an open (last-minute) eye.
            public static let glint = Color.p3(1, 1, 1, level: .visibleGlow)
            public static let zzzDuration: Double = 2.5
            /// Cross-fade between sleeping and last-minute faces.
            public static let nearEndFade: Double = 0.6
            public static let fidgetDuration: Double = 0.5
            public static let fidgetSettleDuration: Double = 0.3
        }

        // MARK: - Fox
        public enum Fox {
            public static let cream = Color.p3(0.99, 0.95, 0.89)
            public static let ink = Color.p3(0.22, 0.12, 0.10)
            public static var headFur: Gradient { Gradient(colors: [.p3(1.0, 0.62, 0.24), .p3(0.86, 0.40, 0.10)]) }
            public static var bodyFur: Gradient { Gradient(colors: [.p3(0.98, 0.58, 0.20), .p3(0.78, 0.32, 0.08)]) }
            public static var tailFur: Gradient { Gradient(colors: [.p3(1.0, 0.60, 0.22), .p3(0.80, 0.33, 0.08)]) }
            public static let backRim = Color.p3(1, 0.80, 0.55, 0.35)
            public static let tailShadow = Color.p3(0.45, 0.14, 0.04, 0.35)
            public static let tailRim = Color.p3(1, 0.78, 0.5, 0.3)
            public static let earBack = Color.p3(0.86, 0.40, 0.10)
            public static let earInner = Color.p3(0.99, 0.90, 0.84)
            public static let nose = Color.p3(0.16, 0.09, 0.08)
            public static let sleepingEye = Color.p3(0.22, 0.11, 0.08)
            public static let blush = Color.p3(1, 0.45, 0.55, 0.45)
            public static let question = Color.p3(h: 0.08, s: 0.6, b: 1.0, a: 0.75, level: .rimHighlight)
            public static let zSizes: (CGFloat, CGFloat) = (7, 5)
            public static let questionSize: CGFloat = 8
            public static let breatheDuration: Double = 3
            public static let tailSwayDuration: Double = 4.0
        }

        // MARK: - Cat
        public enum Cat {
            public static let stripe = Color.p3(0.36, 0.29, 0.52)
            public static let innerEar = Color.p3(1, 0.66, 0.80)
            public static var headFur: Gradient { Gradient(colors: [.p3(0.74, 0.67, 0.90), .p3(0.50, 0.43, 0.68)]) }
            public static var bodyFur: Gradient { Gradient(colors: [.p3(0.68, 0.61, 0.86), .p3(0.42, 0.35, 0.60)]) }
            public static var tailFur: Gradient { Gradient(colors: [.p3(0.66, 0.59, 0.84), .p3(0.42, 0.35, 0.60)]) }
            public static let backRim = Color.p3(0.86, 0.82, 0.98, 0.35)
            public static let tailShadow = Color.p3(0.20, 0.14, 0.34, 0.25)
            public static let pawFront = Color.p3(0.80, 0.75, 0.93)
            public static let pawBack = Color.p3(0.76, 0.70, 0.90)
            public static let earBack = Color.p3(0.50, 0.43, 0.68)
            public static let muzzle = Color.p3(0.86, 0.82, 0.96)
            public static let nose = Color.p3(1, 0.55, 0.70)
            public static let mouth = Color.p3(0.32, 0.24, 0.44)
            public static let sleepingEyes = Color.p3(0.26, 0.19, 0.38)
            /// Green open eyes in the last minute.
            public static let awakeEye = Color.p3(h: 0.35, s: 0.65, b: 0.85, level: .rimHighlight)
            public static let blush = Color.p3(1, 0.50, 0.65, 0.45)
            public static let whiskers = Color.white.opacity(0.55)
            public static let question = Color.p3(h: 0.72, s: 0.45, b: 1.0, a: 0.7, level: .rimHighlight)
            public static let zSizes: (CGFloat, CGFloat) = (6, 5)
            public static let questionSize: CGFloat = 7
            public static let breatheDuration: Double = 2.8
            public static let purrDuration: Double = 0.8
            public static let tailSwayDuration: Double = 3.5
        }

        // MARK: - Dodo
        public enum Dodo {
            public static let cream = Color.p3(0.97, 0.95, 0.89)
            public static let ink = Color.p3(0.14, 0.14, 0.20)
            public static var headFeather: Gradient { Gradient(colors: [.p3(0.56, 0.84, 0.87), .p3(0.30, 0.58, 0.65)]) }
            public static var bodyFeather: Gradient { Gradient(colors: [.p3(0.50, 0.80, 0.84), .p3(0.24, 0.50, 0.58)]) }
            public static var wing: Gradient { Gradient(colors: [.p3(0.34, 0.62, 0.70), .p3(0.20, 0.44, 0.52)]) }
            public static var beak: Gradient { Gradient(colors: [.p3(1.0, 0.84, 0.46), .p3(0.92, 0.64, 0.28)]) }
            public static let plumeBack = Color.p3(0.88, 0.86, 0.80)
            public static let plumeFront = Color.p3(0.94, 0.92, 0.86)
            public static let backRim = Color.p3(0.80, 0.96, 0.98, 0.35)
            public static let bellyOpacity: Double = 0.92
            public static let wingLines = Color.p3(0.70, 0.90, 0.93, 0.45)
            public static let footBack = Color.p3(0.95, 0.70, 0.32)
            public static let footFront = Color.p3(0.98, 0.76, 0.38)
            public static let beakHook = Color.p3(0.40, 0.66, 0.60)
            public static let beakLower = Color.p3(0.99, 0.86, 0.56)
            public static let beakLine = Color.p3(0.70, 0.46, 0.18, 0.5)
            public static let nostril = Color.p3(0.55, 0.36, 0.16, 0.7)
            public static let blush = Color.p3(1, 0.50, 0.62, 0.45)
            public static let question = Color.p3(h: 0.50, s: 0.7, b: 1.0, a: 0.8, level: .rimHighlight)
            public static let zSizes: (CGFloat, CGFloat) = (7, 5)
            public static let questionSize: CGFloat = 8
            public static let breatheDuration: Double = 2.9
        }
    }
}
