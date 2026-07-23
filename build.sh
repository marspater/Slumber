#!/bin/bash
set -e

APP_NAME="Slumber"
APP_DIR="${APP_NAME}.app"
CONTENTS_DIR="${APP_DIR}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"

echo "Building ${APP_NAME}..."

# Clean old build
rm -rf "${APP_DIR}"

# Create directories
mkdir -p "${MACOS_DIR}"
mkdir -p "${RESOURCES_DIR}"

# Compile Swift files
swiftc -O -parse-as-library -target $(uname -m)-apple-macos26.0 SlumberApp.swift SlumberTimer.swift SlumberView.swift -o "${MACOS_DIR}/${APP_NAME}"

# Create Info.plist
cat > "${CONTENTS_DIR}/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIdentifier</key>
    <string>com.marspater.slumber2</string>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIconName</key>
    <string>AppIcon</string>
    <key>CFBundleShortVersionString</key>
    <string>2.6</string>
    <key>CFBundleVersion</key>
    <string>2.6</string>
    <key>MinimumOSVersion</key>
    <string>26.0</string>
    <key>LSUIElement</key>
    <true/>
</dict>
</plist>
EOF

echo "Copying & compiling assets..."
mkdir -p "${RESOURCES_DIR}"

# 1. Native macOS 26/27 actool compilation of Main_Icon.icon into Assets.car
if [ -d "Assets/Main_Icon.icon" ]; then
    echo "Compiling Main_Icon.icon into Assets.car..."
    mkdir -p TempCatalog.xcassets
    rm -rf TempCatalog.xcassets/AppIcon.appiconset
    cp -R "Assets/Main_Icon.icon" TempCatalog.xcassets/AppIcon.appiconset
    actool TempCatalog.xcassets \
        --compile "${RESOURCES_DIR}" \
        --minimum-deployment-target 26.0 \
        --platform macosx \
        --app-icon AppIcon \
        --output-partial-info-plist "${CONTENTS_DIR}/actool-info.plist" > /dev/null 2>&1 || true
    rm -rf TempCatalog.xcassets

    # Copy raw .icon bundle
    cp -R "Assets/Main_Icon.icon" "${RESOURCES_DIR}/"
    
    # 2. Render AppIcon.icns & icon_preview.png from Main_Icon.icon matching Icon Composer specification
    if [ -f "Assets/Main_Icon.icon/Assets/preview.png" ]; then
        swift - "Assets/Main_Icon.icon/Assets/preview.png" "Assets/icon_preview.png" << 'SWIFT_EOF' > /dev/null 2>&1 || true
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
        for pt in points.dropFirst() { path.addLine(to: pt) }
        path.closeSubpath()
    }
    return path
}

let args = CommandLine.arguments
let inputPath = args.count > 1 ? args[1] : "Assets/Main_Icon.icon/Assets/preview.png"
let outputPath = args.count > 2 ? args[2] : "Assets/icon_preview.png"

if let inputImage = NSImage(contentsOfFile: inputPath),
   let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: 1024, pixelsHigh: 1024, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0) {
    NSGraphicsContext.saveGraphicsState()
    if let ctx = NSGraphicsContext(bitmapImageRep: rep)?.cgContext {
        let size = CGSize(width: 1024, height: 1024)
        ctx.clear(CGRect(origin: .zero, size: size))
        let squirclePath = superellipsePath(in: CGRect(origin: .zero, size: size), n: 5.0)
        ctx.saveGState()
        ctx.addPath(squirclePath)
        ctx.clip()
        let colors = [
            NSColor(red: 0.12, green: 0.08, blue: 0.32, alpha: 1.0).cgColor,
            NSColor(red: 0.38, green: 0.22, blue: 0.65, alpha: 1.0).cgColor,
            NSColor(red: 0.78, green: 0.25, blue: 0.85, alpha: 1.0).cgColor
        ] as CFArray
        if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0.0, 0.5, 1.0]) {
            ctx.drawLinearGradient(gradient, start: CGPoint(x: 0, y: 1024), end: CGPoint(x: 1024, y: 0), options: [])
        }
        if let cgImage = inputImage.cgImage(forProposedRect: nil, context: nil, hints: nil) {
            ctx.draw(cgImage, in: CGRect(x: -30, y: -30, width: 1084, height: 1084))
        }
        let glassColors = [NSColor.white.withAlphaComponent(0.35).cgColor, NSColor.white.withAlphaComponent(0.05).cgColor, NSColor.clear.cgColor] as CFArray
        if let glassGrad = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: glassColors, locations: [0.0, 0.4, 1.0]) {
            ctx.drawLinearGradient(glassGrad, start: CGPoint(x: 0, y: 1024), end: CGPoint(x: 1024, y: 0), options: [])
        }
        ctx.restoreGState()
        ctx.saveGState()
        ctx.addPath(squirclePath)
        ctx.setLineWidth(4.0)
        ctx.setStrokeColor(NSColor.white.withAlphaComponent(0.3).cgColor)
        ctx.strokePath()
        ctx.restoreGState()
    }
    NSGraphicsContext.restoreGraphicsState()
    if let pngData = rep.representation(using: .png, properties: [:]) {
        try? pngData.write(to: URL(fileURLWithPath: outputPath))
    }
}
SWIFT_EOF

        mkdir -p MyIcon.iconset
        sips -s format png -z 16 16     "Assets/icon_preview.png" --out MyIcon.iconset/icon_16x16.png > /dev/null
        sips -s format png -z 32 32     "Assets/icon_preview.png" --out MyIcon.iconset/icon_16x16@2x.png > /dev/null
        sips -s format png -z 32 32     "Assets/icon_preview.png" --out MyIcon.iconset/icon_32x32.png > /dev/null
        sips -s format png -z 64 64     "Assets/icon_preview.png" --out MyIcon.iconset/icon_32x32@2x.png > /dev/null
        sips -s format png -z 128 128   "Assets/icon_preview.png" --out MyIcon.iconset/icon_128x128.png > /dev/null
        sips -s format png -z 256 256   "Assets/icon_preview.png" --out MyIcon.iconset/icon_128x128@2x.png > /dev/null
        sips -s format png -z 256 256   "Assets/icon_preview.png" --out MyIcon.iconset/icon_256x256.png > /dev/null
        sips -s format png -z 512 512   "Assets/icon_preview.png" --out MyIcon.iconset/icon_256x256@2x.png > /dev/null
        sips -s format png -z 512 512   "Assets/icon_preview.png" --out MyIcon.iconset/icon_512x512.png > /dev/null
        sips -s format png -z 1024 1024 "Assets/icon_preview.png" --out MyIcon.iconset/icon_512x512@2x.png > /dev/null
        iconutil -c icns MyIcon.iconset
        cp MyIcon.icns "${RESOURCES_DIR}/AppIcon.icns"
        rm -r MyIcon.iconset MyIcon.icns
    fi
fi

# 3. Preserve original companion artwork
if [ -f "Assets/glass_sleep_art.png" ]; then
    cp "Assets/glass_sleep_art.png" "${RESOURCES_DIR}/glass_sleep_art.png"
fi

# Copy generated/provided sounds
if ls Assets/*.wav 1> /dev/null 2>&1; then
    cp Assets/*.wav "${RESOURCES_DIR}/"
fi

echo "Signing binary..."
find "${APP_DIR}" -name '.DS_Store' -delete || true
xattr -cr "${APP_DIR}"
codesign --force --deep --sign - "${APP_DIR}"

# Force Finder to refresh the app icon cache
touch "${APP_DIR}"

echo "Build complete. App is ready at ${APP_DIR}!"
