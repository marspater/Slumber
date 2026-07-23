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
    <string>Main_Icon</string>
    <key>CFBundleIconName</key>
    <string>Main_Icon</string>
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

# Copy all assets as-is without any generation or processing
if [ -d "Assets" ]; then
    cp -R Assets/* "${RESOURCES_DIR}/" 2>/dev/null || true
fi

echo "Signing binary..."
find "${APP_DIR}" -name '.DS_Store' -delete || true
xattr -cr "${APP_DIR}"
codesign --force --deep --sign - "${APP_DIR}"

# Force Finder refresh
touch "${APP_DIR}"

echo "Build complete. App is ready at ${APP_DIR}!"
