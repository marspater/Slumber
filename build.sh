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
swiftc -O -parse-as-library -target $(uname -m)-apple-macos14.0 SlumberApp.swift SlumberTimer.swift SlumberView.swift -o "${MACOS_DIR}/${APP_NAME}"

# Build AppIcon.icns from New_Icon.icon artwork
echo "Building app icon from New_Icon.icon..."
ICON_SRC="Assets/New_Icon.icon/Assets/fullbleed_icon.png"
if [ ! -f "$ICON_SRC" ]; then
    ICON_SRC=$(ls Assets/New_Icon.icon/Assets/*.png 2>/dev/null | head -n 1)
fi
echo "Using icon source: ${ICON_SRC}"
mkdir -p _AppIcon.iconset
for size in 16 32 128 256 512; do
    sips -z $size $size "$ICON_SRC" --out "_AppIcon.iconset/icon_${size}x${size}.png" > /dev/null 2>&1
    double=$((size * 2))
    sips -z $double $double "$ICON_SRC" --out "_AppIcon.iconset/icon_${size}x${size}@2x.png" > /dev/null 2>&1
done
iconutil -c icns _AppIcon.iconset -o "${RESOURCES_DIR}/AppIcon.icns"
rm -rf _AppIcon.iconset

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
    <key>CFBundleShortVersionString</key>
    <string>2.7</string>
    <key>CFBundleVersion</key>
    <string>2.7</string>
    <key>MinimumOSVersion</key>
    <string>14.0</string>
    <key>LSUIElement</key>
    <true/>
</dict>
</plist>
EOF

# Copy sounds
echo "Copying assets..."
if ls Assets/*.wav 1> /dev/null 2>&1; then
    cp Assets/*.wav "${RESOURCES_DIR}/"
fi

echo "Signing binary..."
find "${APP_DIR}" -name '.DS_Store' -delete || true
xattr -cr "${APP_DIR}"
codesign --force --deep --sign - "${APP_DIR}"

touch "${APP_DIR}"

echo "Registering app bundle icon with macOS LaunchServices..."
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f -R "${APP_DIR}" || true
qlmanage -r cache > /dev/null 2>&1 || true
killall Dock 2>/dev/null || true
killall Finder 2>/dev/null || true

echo "Build complete. App is ready at ${APP_DIR}!"
