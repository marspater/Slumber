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
        swift scratch/render_composer_icon.swift "Assets/Main_Icon.icon/Assets/preview.png" "Assets/icon_preview.png" > /dev/null 2>&1 || true
        
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
