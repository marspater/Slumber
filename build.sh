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

# Compile Swift release binary via Swift Package Manager
echo "Compiling Swift release binary with SwiftPM..."
swift build -c release
cp ".build/release/${APP_NAME}" "${MACOS_DIR}/${APP_NAME}"

# Compile Apple Icon Composer .icon package into Assets.car via actool
echo "Compiling Icon Composer icon with actool..."
TMP_PLIST="$(mktemp)"
xcrun actool \
    --compile "${RESOURCES_DIR}" \
    --platform macosx \
    --minimum-deployment-target 26.0 \
    --app-icon AppIcon \
    --output-partial-info-plist "${TMP_PLIST}" \
    "Assets/AppIcon.icon"
rm -f "${TMP_PLIST}"

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
    <key>CFBundleIconName</key>
    <string>AppIcon</string>
    <key>CFBundleShortVersionString</key>
    <string>3.0</string>
    <key>CFBundleVersion</key>
    <string>3.0</string>
    <key>LSMinimumSystemVersion</key>
    <string>26.0</string>
    <key>MinimumOSVersion</key>
    <string>26.0</string>
    <key>CFBundleSupportedPlatforms</key>
    <array>
        <string>MacOSX</string>
    </array>
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

SIGN_IDENTITY="$(security find-identity -v -p codesigning 2>/dev/null | grep -E 'Developer ID Application|Apple Development' | head -n 1 | awk -F '"' '{print $2}' || true)"
if [ -n "${SIGN_IDENTITY}" ]; then
    echo "Signing with Identity: ${SIGN_IDENTITY}"
    codesign --force --deep --options runtime --sign "${SIGN_IDENTITY}" "${APP_DIR}"
else
    echo "Signing ad-hoc with hardened runtime..."
    codesign --force --deep --options runtime --sign - "${APP_DIR}"
fi

touch "${APP_DIR}"

echo "Registering app bundle icon with macOS LaunchServices..."
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f -R "${APP_DIR}" || true
qlmanage -r cache > /dev/null 2>&1 || true
killall Dock 2>/dev/null || true
killall Finder 2>/dev/null || true

echo "Build complete. App is ready at ${APP_DIR}!"
