//
//  ArtPaths.swift
//  Slumber
//
//  Path data for the moon, clouds and companions, authored as SVG in a fixed viewBox
//  (1 unit = 1pt) and parsed once on first use. Main-actor isolated: only view bodies read it.
//

import SwiftUI

@MainActor
enum FoxArt {
    static let box = CGSize(width: 64, height: 44)

    static let body = VectorShape("M 14 22 C 14 13 30 10 42 12 C 52 13.5 58 20 57 28 C 56 35 48 38 36 38 L 20 38 C 13 38 12 30 14 22 Z", viewBox: box)
    static let backRim = VectorShape("M 24 13.2 C 32 11.4 42 11.6 49 15", viewBox: box)
    static let tail = VectorShape("M 52 21 C 60 24 61 37 50 41.2 C 40 44.5 22 44 12.5 40.6 C 6.5 38.6 3.5 34.5 5 30.5 C 8 33.6 14 35.4 22 35.9 C 33 36.6 44 35.6 49.5 31.5 C 52.8 29 53.6 25.5 52 21 Z", viewBox: box)
    static let chest = VectorShape("M 18.5 28.8 C 21.5 29.3 25 29 27.6 27.6 C 28.9 29.6 28.4 31.6 27.4 32.6 C 28.1 33.6 27.3 35.2 26.2 36.2 C 23.4 36.4 20.8 36.2 18.8 35.8 C 18.9 34.7 18 34 18.2 33 C 17.6 31.6 17.7 30.1 18.5 28.8 Z", viewBox: box)
    static let tailRim = VectorShape("M 20 36.6 C 32 37.4 43 36.4 49 32.6", viewBox: box)
    static let tailTip = VectorShape("M 5 30.5 C 7.2 32.8 11.5 34.8 17.5 35.6 C 15.6 36.9 16.9 38.4 15.2 39.2 C 15.9 40.1 14.8 40.9 13.8 41.1 C 13.3 40.9 12.9 40.8 12.5 40.6 C 6.5 38.6 3.5 34.5 5 30.5 Z", viewBox: box)
    static let earBack = VectorShape("M 20 12.5 C 21 8.5 23.5 5 27 3.5 C 27.8 7 27.5 11 26 14.5 Z", viewBox: box)
    static let earBackTip = VectorShape("M 23.6 6.6 C 24.6 5.3 25.7 4.3 27 3.5 C 27.3 4.9 27.4 6.4 27.3 7.9 C 26.1 7.2 24.9 6.8 23.6 6.6 Z", viewBox: box)
    static let earFront = VectorShape("M 12 14.5 C 11 10 11 6 12 3.5 C 15 5 18 8.5 19.5 12 Z", viewBox: box)
    static let earFrontInner = VectorShape("M 13.2 12.8 C 12.8 10.2 12.9 8 13.4 6.4 C 15.2 7.8 16.8 9.8 17.8 12.2 Z", viewBox: box)
    static let earFrontTip = VectorShape("M 12 3.5 C 13.4 4.2 14.7 5.2 15.8 6.3 C 14.6 6.5 13.4 6.9 12.2 7.5 C 11.9 6.1 11.8 4.7 12 3.5 Z", viewBox: box)
    static let head = VectorShape("M 3.5 24 C 5 20 9 15.5 13 13 C 16 11 23 10.5 27 14 C 30 17 30 23 27 26.5 C 24 29.5 17 29.5 12 28 C 8 27 4.5 26 3.5 24 Z", viewBox: box)
    static let muzzle = VectorShape("M 3.5 24 C 6 23.2 10 23 13 22.6 C 16 22.2 19.5 23.6 21.5 26 C 22.4 27.4 21.2 28.9 18 29 C 14 29.2 9 28 6 26.6 C 4.8 26 3.8 25 3.5 24 Z", viewBox: box)
    static let eye = VectorShape("M 12.6 19.4 Q 15 21.4 17.4 19.6", viewBox: box)
    static let nose = VectorShape("M 5.9 23.9 C 5.9 24.59 5.18 25.15 4.3 25.15 C 3.42 25.15 2.7 24.59 2.7 23.9 C 2.7 23.21 3.42 22.65 4.3 22.65 C 5.18 22.65 5.9 23.21 5.9 23.9 Z", viewBox: box)
    static let blush = VectorShape("M 19 24.2 C 19 24.97 18.02 25.6 16.8 25.6 C 15.58 25.6 14.6 24.97 14.6 24.2 C 14.6 23.43 15.58 22.8 16.8 22.8 C 18.02 22.8 19 23.43 19 24.2 Z", viewBox: box)
}

@MainActor
enum CatArt {
    static let box = CGSize(width: 64, height: 44)

    static let body = VectorShape("M 16 26 C 15 16 28 11 40 12 C 51 13 57 21 56 29 C 55.5 35 50 38 40 38 L 22 38 C 16.5 38 16 32 16 26 Z", viewBox: box)
    static let stripes = VectorShape("M 36 12.6 C 37.4 14.6 37.6 16.6 36.8 18.4 M 42.5 13.2 C 44 15.2 44.2 17.4 43.2 19.4 M 48.6 15.4 C 50 17.2 50.2 19.4 49.2 21.2", viewBox: box)
    static let backRim = VectorShape("M 28 14.2 C 36 11.8 45 12.6 51 16.6", viewBox: box)
    static let tail = VectorShape("M 53 27 C 58.5 31 57 39.5 48 40.8 C 38 42.2 24 42 16 40.5 C 11 39.6 8.5 37 9.5 33.5 C 10.4 33.2 11.2 33.4 11.8 34 C 11.6 36 13.5 37.2 17 37.6 C 25 38.6 38 38.6 47 37.6 C 52 37 53.6 33 51.5 29.5 Z", viewBox: box)
    static let tailTip = VectorShape("M 9.5 33.5 C 10.4 33.2 11.2 33.4 11.8 34 C 11.6 36 12.8 37 14.6 37.4 C 14.2 38.6 14 39.6 14.2 40.2 C 10.6 39.2 8.7 36.8 9.5 33.5 Z", viewBox: box)
    static let pawFront = VectorShape("M 18.8 34.6 C 18.8 35.76 17.37 36.7 15.6 36.7 C 13.83 36.7 12.4 35.76 12.4 34.6 C 12.4 33.44 13.83 32.5 15.6 32.5 C 17.37 32.5 18.8 33.44 18.8 34.6 Z", viewBox: box)
    static let pawBack = VectorShape("M 25 35.2 C 25 36.36 23.57 37.3 21.8 37.3 C 20.03 37.3 18.6 36.36 18.6 35.2 C 18.6 34.04 20.03 33.1 21.8 33.1 C 23.57 33.1 25 34.04 25 35.2 Z", viewBox: box)
    static let earFront = VectorShape("M 11.6 18.6 C 10.8 15.4 10.6 12.2 11.2 9.2 C 14 10.2 16.4 12 18 14.4 Z", viewBox: box)
    static let earFrontInner = VectorShape("M 12.8 16.6 C 12.4 14.6 12.3 12.8 12.6 11.2 C 14.2 12 15.4 13.2 16.2 14.6 Z", viewBox: box)
    static let earBack = VectorShape("M 20.6 14.2 C 22.6 11.8 25 10.2 27.8 9.4 C 28.4 12.4 28.2 15.6 27.2 18.6 Z", viewBox: box)
    static let earBackInner = VectorShape("M 22.6 14 C 23.8 12.8 25.2 11.8 26.8 11.2 C 27 13 26.8 14.8 26.2 16.4 Z", viewBox: box)
    static let head = VectorShape("M 9 24 C 8.6 18 12.6 14 19 14 C 25.6 14 29.4 18.6 29 24 C 28.8 26.6 27.8 28.6 26 29.9 C 26.6 30.3 26.9 30.6 27 30.9 C 26 31.1 25 31 24 30.9 C 22.5 31.4 20.8 31.6 19 31.6 C 16.8 31.6 14.9 31.2 13.4 30.6 C 12.4 30.8 11.4 30.9 10.6 30.7 C 10.8 30.2 11.1 29.8 11.4 29.4 C 9.9 28 9.1 26.2 9 24 Z", viewBox: box)
    static let muzzle = VectorShape("M 23.2 27.4 C 23.2 29.11 21.14 30.5 18.6 30.5 C 16.06 30.5 14 29.11 14 27.4 C 14 25.69 16.06 24.3 18.6 24.3 C 21.14 24.3 23.2 25.69 23.2 27.4 Z", viewBox: box)
    static let nose = VectorShape("M 17.3 25.6 L 19.9 25.6 C 19.9 26.4 19.2 27 18.6 27.2 C 18 27 17.3 26.4 17.3 25.6 Z", viewBox: box)
    static let mouth = VectorShape("M 16.8 28.2 Q 17.7 29 18.6 28.1 Q 19.5 29 20.4 28.2", viewBox: box)
    static let eyes = VectorShape("M 12.8 22.6 Q 14.6 24.2 16.4 22.8 M 20.8 22.8 Q 22.6 24.2 24.4 22.6", viewBox: box)
    static let blush = VectorShape("M 14.5 26.4 C 14.5 27.06 13.65 27.6 12.6 27.6 C 11.55 27.6 10.7 27.06 10.7 26.4 C 10.7 25.74 11.55 25.2 12.6 25.2 C 13.65 25.2 14.5 25.74 14.5 26.4 Z M 26.7 26.4 C 26.7 27.06 25.85 27.6 24.8 27.6 C 23.75 27.6 22.9 27.06 22.9 26.4 C 22.9 25.74 23.75 25.2 24.8 25.2 C 25.85 25.2 26.7 25.74 26.7 26.4 Z", viewBox: box)
    static let whiskers = VectorShape("M 13.4 27.2 L 6.6 26.2 M 13.4 28.2 L 6.8 28.8 M 23.8 27.2 L 30.6 26.2 M 23.8 28.2 L 30.4 28.8", viewBox: box)
}

@MainActor
enum DodoArt {
    static let box = CGSize(width: 64, height: 44)

    static let plumeBack = VectorShape("M 61.35 21.16 C 61.95 22.83 60.67 24.81 58.49 25.61 C 56.31 26.4 54.06 25.7 53.45 24.04 C 52.85 22.37 54.13 20.39 56.31 19.59 C 58.49 18.8 60.74 19.5 61.35 21.16 Z", viewBox: box)
    static let plumeTop = VectorShape("M 60.12 12.84 C 61.33 14.28 60.73 16.77 58.79 18.4 C 56.84 20.04 54.28 20.2 53.08 18.76 C 51.87 17.32 52.47 14.83 54.41 13.2 C 56.36 11.56 58.92 11.4 60.12 12.84 Z", viewBox: box)
    static let plumeFront = VectorShape("M 53.81 10.36 C 55.21 11.01 55.63 13.08 54.74 14.98 C 53.85 16.89 52 17.9 50.59 17.24 C 49.19 16.59 48.77 14.52 49.66 12.62 C 50.55 10.71 52.4 9.7 53.81 10.36 Z", viewBox: box)
    static let body = VectorShape("M 18 27 C 17 17 27 11 39 11.5 C 51 12 58 20 57 29 C 56 36 49 39.5 38 39.5 L 26 39.5 C 20 39.5 18.4 34 18 27 Z", viewBox: box)
    static let backRim = VectorShape("M 29 12.8 C 37 10.8 46 12 52 16.8", viewBox: box)
    static let belly = VectorShape("M 20 30 C 22 26 28 25 33 27 C 37 29 38 34 36.4 39.5 L 26 39.5 C 22 39.5 20 36 20 30 Z", viewBox: box)
    static let wing = VectorShape("M 31 23 C 36 19.5 45 20 49 26 C 50.5 28.4 49 31 46 31.2 C 40 31.6 34 29 31 23 Z", viewBox: box)
    static let wingLines = VectorShape("M 38 26.6 C 41 27.8 44 28.4 46.6 28.2 M 36 24 C 39.4 24.2 42.6 25 45.4 26.2", viewBox: box)
    static let footBack = VectorShape("M 29.8 40.2 C 29.8 41.14 28.37 41.9 26.6 41.9 C 24.83 41.9 23.4 41.14 23.4 40.2 C 23.4 39.26 24.83 38.5 26.6 38.5 C 28.37 38.5 29.8 39.26 29.8 40.2 Z", viewBox: box)
    static let footFront = VectorShape("M 36.6 40.6 C 36.6 41.54 35.17 42.3 33.4 42.3 C 31.63 42.3 30.2 41.54 30.2 40.6 C 30.2 39.66 31.63 38.9 33.4 38.9 C 35.17 38.9 36.6 39.66 36.6 40.6 Z", viewBox: box)
    static let tufts = VectorShape("M 18 12.4 C 17.6 9.6 19 7.4 21.6 6.8 C 20.8 8.2 21 9.6 22 10.8 C 22.6 11.6 22.4 12.6 21.6 13 Z M 21 12.6 C 22.2 10.4 24.4 9.4 26.8 9.8 C 25.6 10.6 25 11.8 25.2 13.2 Z", viewBox: box)
    static let beak = VectorShape("M 16 16.8 C 11 16 5.4 17 3.2 19.2 C 1.4 21 1.2 23.8 2.6 25.4 C 3 24 4.2 23.2 5.8 23.2 L 16 23.4 Z", viewBox: box)
    static let beakHook = VectorShape("M 3.2 19.2 C 1.4 21 1.2 23.8 2.6 25.4 C 3 24 4.2 23.2 5.8 23.2 C 5.6 21.6 4.6 20 3.2 19.2 Z", viewBox: box)
    static let beakLower = VectorShape("M 5.8 23.2 L 15.6 23.3 C 15.4 25.2 12.6 26.4 9.8 26.2 C 7.8 26.1 6.2 25 5.8 23.2 Z", viewBox: box)
    static let beakLine = VectorShape("M 6.2 23.2 L 13.4 23.2", viewBox: box)
    static let nostril = VectorShape("M 9.3 19.4 C 9.3 19.7 8.81 19.95 8.2 19.95 C 7.59 19.95 7.1 19.7 7.1 19.4 C 7.1 19.1 7.59 18.85 8.2 18.85 C 8.81 18.85 9.3 19.1 9.3 19.4 Z", viewBox: box)
    static let head = VectorShape("M 10.5 20 C 10.5 14.8 14.4 11.5 19.4 11.5 C 24.4 11.5 28 15 28 20 C 28 25 24.4 28.4 19.4 28.4 C 14.4 28.4 10.5 25 10.5 20 Z", viewBox: box)
    static let eye = VectorShape("M 14.8 18.6 Q 16.8 20.4 18.8 18.8", viewBox: box)
    static let blush = VectorShape("M 20.8 23.6 C 20.8 24.32 19.9 24.9 18.8 24.9 C 17.7 24.9 16.8 24.32 16.8 23.6 C 16.8 22.88 17.7 22.3 18.8 22.3 C 19.9 22.3 20.8 22.88 20.8 23.6 Z", viewBox: box)
}

@MainActor
enum MoonArt {
    static let box = CGSize(width: 44, height: 44)

    static let crescent = VectorShape("M 19.92 2.11 C 10.1 3.14 2.5 11.18 2.02 21.04 C 1.55 30.9 8.34 39.63 18.02 41.6 C 27.69 43.57 37.35 38.18 40.77 28.91 C 33.35 34.12 23.15 32.59 17.58 25.44 C 12.02 18.28 13.04 8.02 19.92 2.11 Z", viewBox: box)
    static let rim = VectorShape("M 5.4 14.6 C 4.4 16.6 3.9 18.4 3.8 20.4", viewBox: box)
    static let craters = VectorShape("M 8.7 16.6 C 8.7 17.65 7.85 18.5 6.8 18.5 C 5.75 18.5 4.9 17.65 4.9 16.6 C 4.9 15.55 5.75 14.7 6.8 14.7 C 7.85 14.7 8.7 15.55 8.7 16.6 Z M 12 10.6 C 12 11.26 11.46 11.8 10.8 11.8 C 10.14 11.8 9.6 11.26 9.6 10.6 C 9.6 9.94 10.14 9.4 10.8 9.4 C 11.46 9.4 12 9.94 12 10.6 Z M 22.9 38.4 C 22.9 39.23 22.23 39.9 21.4 39.9 C 20.57 39.9 19.9 39.23 19.9 38.4 C 19.9 37.57 20.57 36.9 21.4 36.9 C 22.23 36.9 22.9 37.57 22.9 38.4 Z", viewBox: box)
    static let eyes = VectorShape("M 5.4 25.6 Q 7.2 27.4 9 25.8 M 11.8 25.8 Q 13.6 27.4 15.4 25.6", viewBox: box)
    static let mouth = VectorShape("M 9.2 29.6 Q 10.4 30.8 11.6 29.6", viewBox: box)
    static let blush = VectorShape("M 6.8 29.2 C 6.8 29.84 5.99 30.35 5 30.35 C 4.01 30.35 3.2 29.84 3.2 29.2 C 3.2 28.56 4.01 28.05 5 28.05 C 5.99 28.05 6.8 28.56 6.8 29.2 Z M 17.6 29.2 C 17.6 29.84 16.79 30.35 15.8 30.35 C 14.81 30.35 14 29.84 14 29.2 C 14 28.56 14.81 28.05 15.8 28.05 C 16.79 28.05 17.6 28.56 17.6 29.2 Z", viewBox: box)
    static let cap = VectorShape("M 5.6 10.4 C 6.6 3.6 12.6 -2.6 20.2 -3.2 C 26 -3.6 30.8 0.2 32.4 5.8 C 33.2 8.8 33 11.8 32.2 14.2 C 30 9.8 26.8 5.4 21.8 3 C 17.6 1.2 11 4.4 5.6 10.4 Z", viewBox: box)
    static let capFold = VectorShape("M 14 -0.6 C 20 -1.2 26 1.6 29.6 7", viewBox: box)
    static let capBand = VectorShape("M 6.2 8.2 C 10 3.6 16 0.8 21.8 1.2 C 22.6 1.3 22.9 2.2 22.6 3 C 22.2 3.8 21.4 4.2 20.4 4.2 C 15.4 4.4 11.4 7 8.6 11 C 8 11.8 6.8 11.8 6.2 11.2 C 5.6 10.4 5.6 9 6.2 8.2 Z", viewBox: box)
    static let pompom = VectorShape("M 35.2 15.6 C 35.2 17.04 34.04 18.2 32.6 18.2 C 31.16 18.2 30 17.04 30 15.6 C 30 14.16 31.16 13 32.6 13 C 34.04 13 35.2 14.16 35.2 15.6 Z", viewBox: box)
}

@MainActor
struct CloudArt {
    let box: CGSize
    let outline: VectorShape
    let eyes: VectorShape
    let mouth: VectorShape
    let blush: VectorShape

    init(box: CGSize, outline: String, eyes: String, mouth: String, blush: String) {
        self.box = box
        self.outline = VectorShape(outline, viewBox: box)
        self.eyes = VectorShape(eyes, viewBox: box)
        self.mouth = VectorShape(mouth, viewBox: box)
        self.blush = VectorShape(blush, viewBox: box)
    }

    static let large = CloudArt(
        box: CGSize(width: 64, height: 40),
        outline: "M 11 34 Q 6 34 7.48 28.74 C 6.47 25.94 7.08 22.82 9.08 20.62 C 11.08 18.42 14.13 17.51 17 18.25 C 16.89 12.76 20.52 7.88 25.82 6.43 C 31.13 4.97 36.74 7.31 39.45 12.1 C 42.56 10.5 46.28 10.65 49.25 12.49 C 52.23 14.33 54.03 17.59 54 21.08 C 55.76 21.38 57.29 22.44 58.19 23.98 C 59.08 25.52 59.25 27.38 58.64 29.05 Q 58 34 53 34 Z",
        eyes: "M 25.6 24 Q 27.4 25.8 29.2 24 M 32.8 24 Q 34.6 25.8 36.4 24",
        mouth: "M 29.8 27.4 Q 31 28.4 32.2 27.4",
        blush: "M 26.4 27 C 26.4 27.66 25.5 28.2 24.4 28.2 C 23.3 28.2 22.4 27.66 22.4 27 C 22.4 26.34 23.3 25.8 24.4 25.8 C 25.5 25.8 26.4 26.34 26.4 27 Z M 39.6 27 C 39.6 27.66 38.7 28.2 37.6 28.2 C 36.5 28.2 35.6 27.66 35.6 27 C 35.6 26.34 36.5 25.8 37.6 25.8 C 38.7 25.8 39.6 26.34 39.6 27 Z"
    )

    static let small = CloudArt(
        box: CGSize(width: 58, height: 34),
        outline: "M 11.5 29 Q 7 29 7.42 24.39 C 6.45 21.73 7.19 18.73 9.29 16.82 C 11.39 14.91 14.44 14.46 17 15.68 C 16.92 10.92 20.19 6.77 24.83 5.74 C 29.47 4.71 34.2 7.09 36.13 11.43 C 38.79 10.08 41.95 10.21 44.48 11.78 C 47.01 13.35 48.53 16.12 48.5 19.1 C 49.92 19.39 51.15 20.29 51.86 21.56 C 52.57 22.83 52.7 24.34 52.2 25.71 Q 52 29 47.5 29 Z",
        eyes: "M 22.6 20 Q 24.4 21.8 26.2 20 M 29.8 20 Q 31.6 21.8 33.4 20",
        mouth: "M 26.8 23.4 Q 28 24.4 29.2 23.4",
        blush: "M 23.4 23 C 23.4 23.66 22.5 24.2 21.4 24.2 C 20.3 24.2 19.4 23.66 19.4 23 C 19.4 22.34 20.3 21.8 21.4 21.8 C 22.5 21.8 23.4 22.34 23.4 23 Z M 36.6 23 C 36.6 23.66 35.7 24.2 34.6 24.2 C 33.5 24.2 32.6 23.66 32.6 23 C 32.6 22.34 33.5 21.8 34.6 21.8 C 35.7 21.8 36.6 22.34 36.6 23 Z"
    )
}
