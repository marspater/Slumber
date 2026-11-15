#!/bin/bash
# Builds Slumbr.app from Slumbr.xcodeproj with xcodebuild.
#   --package      also write Slumbr.zip (tracked release artifact) at the repo root
#   --install, -i  also copy the app to /Applications
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "${REPO_ROOT}"
APP_NAME="Slumbr"
DERIVED_DATA="${REPO_ROOT}/.build/DerivedData"
ARTIFACTS_DIR="${REPO_ROOT}/.build/artifacts"
APP_DIR="${ARTIFACTS_DIR}/${APP_NAME}.app"

# Prefer Developer ID (distributable) over Apple Development (runs only on this team's registered Macs);
# without either, the project's own ad-hoc ("Sign to Run Locally") setting applies.
SIGNING_ARGS=()
IDENTITIES="$(security find-identity -v -p codesigning 2>/dev/null || true)"
for KIND in "Developer ID Application" "Apple Development"; do
    SIGN_IDENTITY="$(printf '%s\n' "${IDENTITIES}" | grep "${KIND}" | head -n 1 | awk -F '"' '{print $2}' || true)"
    if [[ -n "${SIGN_IDENTITY}" ]]; then
        TEAM_ID="$(printf '%s' "${SIGN_IDENTITY}" | sed -E 's/.*\(([A-Z0-9]+)\)$/\1/')"
        SIGNING_ARGS=(CODE_SIGN_STYLE=Manual "CODE_SIGN_IDENTITY=${SIGN_IDENTITY}" "DEVELOPMENT_TEAM=${TEAM_ID}")
        echo "Signing with identity: ${SIGN_IDENTITY}"
        break
    fi
done
[[ ${#SIGNING_ARGS[@]} -gt 0 ]] || echo "Signing ad-hoc..."

echo "Building ${APP_NAME} (Release)..."
xcodebuild \
    -project "${APP_NAME}.xcodeproj" \
    -scheme "${APP_NAME}" \
    -configuration Release \
    -destination 'generic/platform=macOS' \
    -derivedDataPath "${DERIVED_DATA}" \
    -quiet \
    build ${SIGNING_ARGS[@]+"${SIGNING_ARGS[@]}"}

rm -rf "${APP_DIR}"
mkdir -p "${ARTIFACTS_DIR}"
ditto "${DERIVED_DATA}/Build/Products/Release/${APP_NAME}.app" "${APP_DIR}"
codesign --verify --deep --strict "${APP_DIR}"

# Package Slumbr.zip only on request, so ordinary builds leave the tree clean
if [[ " $* " == *" --package "* ]]; then
    echo "Packaging ${APP_NAME}.zip..."
    rm -f "${REPO_ROOT}/${APP_NAME}.zip"
    ditto -c -k --keepParent "${APP_DIR}" "${REPO_ROOT}/${APP_NAME}.zip"
fi

if [[ " $* " == *" --install "* || " $* " == *" -i "* ]]; then
    echo "Installing ${APP_NAME} to /Applications..."
    pkill -x "${APP_NAME}" 2>/dev/null || true
    rm -rf "/Applications/${APP_NAME}.app"
    ditto "${APP_DIR}" "/Applications/${APP_NAME}.app"
    xattr -cr "/Applications/${APP_NAME}.app"
    /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "/Applications/${APP_NAME}.app" 2>/dev/null || true
    echo "Installed to /Applications/${APP_NAME}.app"
fi

echo "Build complete. App is ready at ${APP_DIR}"
