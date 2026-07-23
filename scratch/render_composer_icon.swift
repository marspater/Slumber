import AppKit
import CoreGraphics

func superellipsePath(in rect: CGRect, n: Double = 5.0, numPoints: Int = 360) -> CGPath {
    let path = CGMutablePath()
    let cx = rect.midX
    let cy = rect.midY
    let a = rect.width / 2.0
    let b = rect.height / 2.0
    
    var points = [CGPoint]()
    for i in 0..<numPoints {
        let theta = (2.0 * .pi * Double(i)) / Double(numPoints)
        let cosT = cos(theta)
        let sinT = sin(theta)
        let sgnX: Double = cosT >= 0 ? 1.0 : -1.0
        let sgnY: Double = sinT >= 0 ? 1.0 : -1.0
        let x = cx + a * sgnX * pow(abs(cosT), 2.0 / n)
        let y = cy + b * sgnY * pow(abs(sinT), 2.0 / n)
        points.append(CGPoint(x: x, y: y))
    }
    
    if let first = points.first {
        path.move(to: first)
        for pt in points.dropFirst() {
            path.addLine(to: pt)
        }
        path.closeSubpath()
    }
    return path
}

func renderComposerIcon(inputPath: String, outputPath: String) {
    guard let inputImage = NSImage(contentsOfFile: inputPath) else {
        print("Error loading image")
        exit(1)
    }
    
    let size = CGSize(width: 1024, height: 1024)
    guard let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: 1024,
        pixelsHigh: 1024,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else {
        exit(1)
    }
    
    NSGraphicsContext.saveGraphicsState()
    guard let ctx = NSGraphicsContext(bitmapImageRep: rep)?.cgContext else {
        exit(1)
    }
    
    ctx.clear(CGRect(origin: .zero, size: size))
    
    // Squircle path for outer boundary
    let iconRect = CGRect(origin: .zero, size: size)
    let squirclePath = superellipsePath(in: iconRect, n: 5.0)
    
    ctx.saveGState()
    ctx.addPath(squirclePath)
    ctx.clip()
    
    // Background Gradient (Deep space violet -> purple -> magenta)
    let colors = [
        NSColor(red: 0.12, green: 0.08, blue: 0.32, alpha: 1.0).cgColor, // Top Left deep violet
        NSColor(red: 0.38, green: 0.22, blue: 0.65, alpha: 1.0).cgColor, // Center purple
        NSColor(red: 0.78, green: 0.25, blue: 0.85, alpha: 1.0).cgColor  // Bottom Right magenta
    ] as CFArray
    let locations: [CGFloat] = [0.0, 0.5, 1.0]
    if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: locations) {
        ctx.drawLinearGradient(gradient, start: CGPoint(x: 0, y: 1024), end: CGPoint(x: 1024, y: 0), options: [])
    }
    
    // Draw the raw artwork preview.png scaled to fit nicely inside squircle
    if let cgImage = inputImage.cgImage(forProposedRect: nil, context: nil, hints: nil) {
        // Apply 1.15 scale and offset matching Icon Composer json
        let artworkRect = CGRect(x: -30, y: -30, width: 1084, height: 1084)
        ctx.draw(cgImage, in: artworkRect)
    }
    
    // Overlay glass gloss / specular highlight overlay
    let glassColors = [
        NSColor.white.withAlphaComponent(0.35).cgColor,
        NSColor.white.withAlphaComponent(0.05).cgColor,
        NSColor.clear.cgColor
    ] as CFArray
    if let glassGrad = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: glassColors, locations: [0.0, 0.4, 1.0]) {
        ctx.drawLinearGradient(glassGrad, start: CGPoint(x: 0, y: 1024), end: CGPoint(x: 1024, y: 0), options: [])
    }
    
    ctx.restoreGState()
    
    // Outer glass specular rim stroke
    ctx.saveGState()
    ctx.addPath(squirclePath)
    ctx.setLineWidth(4.0)
    ctx.setStrokeColor(NSColor.white.withAlphaComponent(0.3).cgColor)
    ctx.strokePath()
    ctx.restoreGState()
    
    NSGraphicsContext.restoreGraphicsState()
    
    if let pngData = rep.representation(using: .png, properties: [:]) {
        try? pngData.write(to: URL(fileURLWithPath: outputPath))
        print("Rendered Composer icon successfully!")
    }
}

let args = CommandLine.arguments
let inPath = args.count > 1 ? args[1] : "Assets/Main_Icon.icon/Assets/preview.png"
let outPath = args.count > 2 ? args[2] : "Assets/icon_preview.png"
renderComposerIcon(inputPath: inPath, outputPath: outPath)
