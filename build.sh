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

echo "Copying assets..."
mkdir -p "${RESOURCES_DIR}"

# Copy Main_Icon.icon bundle for macOS 26/27 native icon renderer
if [ -d "Assets/Main_Icon.icon" ]; then
    cp -R "Assets/Main_Icon.icon" "${RESOURCES_DIR}/"
fi

# Copy glass art icon & generate icns from Main_Icon.icon preview or glass_sleep_art
MAIN_ICON_PREVIEW="Assets/Main_Icon.icon/Assets/preview.png"
FALLBACK_ICON="Assets/glass_sleep_art.png"
SOURCE_ICON=""

if [ -f "$MAIN_ICON_PREVIEW" ]; then
    SOURCE_ICON="$MAIN_ICON_PREVIEW"
elif [ -f "$FALLBACK_ICON" ]; then
    SOURCE_ICON="$FALLBACK_ICON"
fi

if [ -n "$SOURCE_ICON" ]; then
    cp "$SOURCE_ICON" "${RESOURCES_DIR}/glass_sleep_art.png"
    
    # Create iconset for dock without white borders
    mkdir -p MyIcon.iconset
    sips -s format png -z 16 16     "$SOURCE_ICON" --out MyIcon.iconset/icon_16x16.png > /dev/null
    sips -s format png -z 32 32     "$SOURCE_ICON" --out MyIcon.iconset/icon_16x16@2x.png > /dev/null
    sips -s format png -z 32 32     "$SOURCE_ICON" --out MyIcon.iconset/icon_32x32.png > /dev/null
    sips -s format png -z 64 64     "$SOURCE_ICON" --out MyIcon.iconset/icon_32x32@2x.png > /dev/null
    sips -s format png -z 128 128   "$SOURCE_ICON" --out MyIcon.iconset/icon_128x128.png > /dev/null
    sips -s format png -z 256 256   "$SOURCE_ICON" --out MyIcon.iconset/icon_128x128@2x.png > /dev/null
    sips -s format png -z 256 256   "$SOURCE_ICON" --out MyIcon.iconset/icon_256x256.png > /dev/null
    sips -s format png -z 512 512   "$SOURCE_ICON" --out MyIcon.iconset/icon_256x256@2x.png > /dev/null
    sips -s format png -z 512 512   "$SOURCE_ICON" --out MyIcon.iconset/icon_512x512.png > /dev/null
    sips -s format png -z 1024 1024 "$SOURCE_ICON" --out MyIcon.iconset/icon_512x512@2x.png > /dev/null
    iconutil -c icns MyIcon.iconset
    cp MyIcon.icns "${RESOURCES_DIR}/AppIcon.icns"
    rm -r MyIcon.iconset MyIcon.icns
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
