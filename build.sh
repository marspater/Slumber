#!/bin/bash
set -e

REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"
APP_NAME="Slumber"
ARTIFACTS_DIR="${REPO_ROOT}/.build/artifacts"
APP_DIR="${ARTIFACTS_DIR}/${APP_NAME}.app"
CONTENTS_DIR="${APP_DIR}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"

echo "Building ${APP_NAME}..."

# Unregister and remove any legacy root app bundle to prevent LaunchServices duplicate indexing
if [ -d "${APP_NAME}.app" ]; then
    /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -u "${APP_NAME}.app" 2>/dev/null || true
    rm -rf "${APP_NAME}.app"
fi

# Clean old build
rm -rf "${APP_DIR}"

# Create directories
mkdir -p "${MACOS_DIR}"
mkdir -p "${RESOURCES_DIR}"

# Compile Swift release binary via Swift Package Manager
echo "Compiling Swift release binary with SwiftPM..."
swift build -c release
cp ".build/release/${APP_NAME}" "${MACOS_DIR}/${APP_NAME}"

# Build multi-resolution AppIcon.icns from Assets/app_icon.png
if [ -f "Assets/app_icon.png" ]; then
    echo "Building multi-resolution AppIcon.icns..."
    TMP_ICONSET="$(mktemp -d)/AppIcon.iconset"
    mkdir -p "${TMP_ICONSET}"
    for size in 16 32 128 256 512; do
        sips -z $size $size "Assets/app_icon.png" --out "${TMP_ICONSET}/icon_${size}x${size}.png" > /dev/null 2>&1 || true
        double=$((size * 2))
        sips -z $double $double "Assets/app_icon.png" --out "${TMP_ICONSET}/icon_${size}x${size}@2x.png" > /dev/null 2>&1 || true
    done
    iconutil -c icns "${TMP_ICONSET}" -o "${RESOURCES_DIR}/AppIcon.icns" > /dev/null 2>&1 || true
    rm -rf "$(dirname "${TMP_ICONSET}")"
fi

# Compile Apple Icon Composer .icon package into Assets.car via actool if supported
if [ -d "Assets/AppIcon.icon" ]; then
    echo "Compiling Icon Composer icon with actool..."
    TMP_PLIST="$(mktemp)"
    xcrun actool \
        --compile "${RESOURCES_DIR}" \
        --platform macosx \
        --minimum-deployment-target 14.0 \
        --app-icon AppIcon \
        --output-partial-info-plist "${TMP_PLIST}" \
        "Assets/AppIcon.icon" > /dev/null 2>&1 || true
    rm -f "${TMP_PLIST}"
fi

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
    <key>CFBundleDisplayName</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIconName</key>
    <string>AppIcon</string>
    <key>CFBundleShortVersionString</key>
    <string>3.2</string>
    <key>CFBundleVersion</key>
    <string>3.2</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>MinimumOSVersion</key>
    <string>14.0</string>
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
    echo "Signing ad-hoc..."
    codesign --force --deep --options runtime --sign - "${APP_DIR}" 2>/dev/null || codesign --force --deep --sign - "${APP_DIR}"
fi

touch "${APP_DIR}"

# Package Slumber.zip from hidden build artifacts directory
echo "Packaging Slumber.zip..."
rm -f "${REPO_ROOT}/Slumber.zip"
(cd "${ARTIFACTS_DIR}" && zip -r -y -q "${REPO_ROOT}/Slumber.zip" "${APP_NAME}.app")

# Handle optional --install / -i flag
if [ "$1" = "--install" ] || [ "$1" = "-i" ]; then
    echo "Installing ${APP_NAME} to /Applications..."
    pkill -x "${APP_NAME}" 2>/dev/null || true
    rm -rf "/Applications/${APP_NAME}.app"
    cp -R "${APP_DIR}" /Applications/
    xattr -cr "/Applications/${APP_NAME}.app"
    /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "/Applications/${APP_NAME}.app" 2>/dev/null || true
    echo "Successfully installed to /Applications/${APP_NAME}.app!"
fi

echo "Build complete. App is ready at ${APP_DIR}!"
