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

func clipIcon(inputPath: String, outputPath: String) {
    guard let inputImage = NSImage(contentsOfFile: inputPath) else {
        print("Error: Could not load \(inputPath)")
        exit(1)
    }
    
    let targetSize = CGSize(width: 1024, height: 1024)
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
        print("Error: Could not create bitmap context")
        exit(1)
    }
    
    NSGraphicsContext.saveGraphicsState()
    guard let context = NSGraphicsContext(bitmapImageRep: rep)?.cgContext else {
        print("Error: Could not create CGContext")
        exit(1)
    }
    
    // Transparent background
    context.clear(CGRect(origin: .zero, size: targetSize))
    
    // Apple continuous corner squircle bounds (1024x1024 with margin for HIG alignment)
    let inset: CGFloat = 40.0
    let iconRect = CGRect(x: inset, y: inset, width: 1024 - (inset * 2), height: 1024 - (inset * 2))
    let maskPath = superellipsePath(in: iconRect, n: 5.0)
    
    context.addPath(maskPath)
    context.clip()
    
    // Draw input image inside clipped path
    if let cgImage = inputImage.cgImage(forProposedRect: nil, context: nil, hints: nil) {
        context.draw(cgImage, in: CGRect(origin: .zero, size: targetSize))
    }
    
    NSGraphicsContext.restoreGraphicsState()
    
    guard let pngData = rep.representation(using: .png, properties: [:]) else {
        print("Error: Could not encode PNG")
        exit(1)
    }
    
    do {
        try pngData.write(to: URL(fileURLWithPath: outputPath))
        print("Successfully generated beautifully clipped icon: \(outputPath)")
    } catch {
        print("Error writing output: \(error)")
        exit(1)
    }
}

let args = CommandLine.arguments
if args.count >= 3 {
    clipIcon(inputPath: args[1], outputPath: args[2])
} else {
    clipIcon(inputPath: "Assets/Main_Icon.icon/Assets/preview.png", outputPath: "Assets/icon_preview.png")
}
