#!/bin/bash
set -e

REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "${REPO_ROOT}"
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

# Compile the Icon Composer .icon package into Assets.car + AppIcon.icns
echo "Compiling Icon Composer icon with actool..."
TMP_PLIST="$(mktemp)"
xcrun actool \
    --compile "${RESOURCES_DIR}" \
    --platform macosx \
    --minimum-deployment-target 26.0 \
    --app-icon AppIcon \
    --output-format human-readable-text --errors --warnings \
    --output-partial-info-plist "${TMP_PLIST}" \
    "Assets/AppIcon.icon"
rm -f "${TMP_PLIST}"
for f in Assets.car AppIcon.icns; do
    [[ -f "${RESOURCES_DIR}/${f}" ]] || { echo "error: actool did not produce ${f}" >&2; exit 1; }
done

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
    <string>26.0</string>
    <key>NSAppleEventsUsageDescription</key>
    <string>Slumber asks System Events to put your Mac to sleep when the timer ends.</string>
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

# Hardened runtime needs this entitlement for the AppleScript sleep fallback to reach System Events.
ENTITLEMENTS="$(mktemp)"
cat > "${ENTITLEMENTS}" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.automation.apple-events</key>
    <true/>
</dict>
</plist>
PLIST

SIGN_IDENTITY="$(security find-identity -v -p codesigning 2>/dev/null | grep -E 'Developer ID Application|Apple Development' | head -n 1 | awk -F '"' '{print $2}' || true)"
if [ -n "${SIGN_IDENTITY}" ]; then
    echo "Signing with Identity: ${SIGN_IDENTITY}"
    codesign --force --deep --options runtime --entitlements "${ENTITLEMENTS}" --sign "${SIGN_IDENTITY}" "${APP_DIR}"
else
    echo "Signing ad-hoc..."
    codesign --force --deep --options runtime --entitlements "${ENTITLEMENTS}" --sign - "${APP_DIR}"
fi
rm -f "${ENTITLEMENTS}"

touch "${APP_DIR}"

# Package Slumber.zip (tracked release artifact) only on request, so ordinary builds leave the tree clean
if [[ " $* " == *" --package "* ]]; then
    echo "Packaging Slumber.zip..."
    rm -f "${REPO_ROOT}/Slumber.zip"
    (cd "${ARTIFACTS_DIR}" && zip -r -y -q "${REPO_ROOT}/Slumber.zip" "${APP_NAME}.app")
fi

# Handle optional --install / -i flag
if [[ " $* " == *" --install "* || " $* " == *" -i "* ]]; then
    echo "Installing ${APP_NAME} to /Applications..."
    pkill -x "${APP_NAME}" 2>/dev/null || true
    rm -rf "/Applications/${APP_NAME}.app"
    cp -R "${APP_DIR}" /Applications/
    xattr -cr "/Applications/${APP_NAME}.app"
    /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "/Applications/${APP_NAME}.app" 2>/dev/null || true
    echo "Successfully installed to /Applications/${APP_NAME}.app!"
fi

echo "Build complete. App is ready at ${APP_DIR}!"
