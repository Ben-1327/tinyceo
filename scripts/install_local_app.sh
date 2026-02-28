#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_PATH="/tmp/tinyceo-build-release"
APP_DIR="${HOME}/Applications/TinyCEO.app"
APP_CONTENTS="${APP_DIR}/Contents"
APP_MACOS="${APP_CONTENTS}/MacOS"
APP_RESOURCES="${APP_CONTENTS}/Resources"
INFO_PLIST="${APP_CONTENTS}/Info.plist"

echo "[1/5] Building release binary..."
if pgrep -x "TinyCEO" >/dev/null 2>&1; then
  echo "Stopping running TinyCEO process..."
  pkill -x "TinyCEO" || true
fi

# Ensure newly added resources are always reflected in the app bundle.
rm -rf "${BUILD_PATH}"
swift build -c release --build-path "${BUILD_PATH}" --product tinyceo-app

EXECUTABLE="${BUILD_PATH}/release/tinyceo-app"
if [[ ! -f "${EXECUTABLE}" ]]; then
  echo "error: executable not found at ${EXECUTABLE}" >&2
  exit 1
fi

echo "[2/5] Creating app bundle at ${APP_DIR}..."
rm -rf "${APP_DIR}"
mkdir -p "${APP_MACOS}" "${APP_RESOURCES}"

echo "[3/5] Installing executable and SwiftPM resource bundles..."
cp "${EXECUTABLE}" "${APP_MACOS}/TinyCEO"
chmod +x "${APP_MACOS}/TinyCEO"

shopt -s nullglob
for bundle in "${BUILD_PATH}/release/"*.bundle; do
  cp -R "${bundle}" "${APP_RESOURCES}/"
done
shopt -u nullglob

ASSET_ROOT="${APP_RESOURCES}/tinyceo_TinyCEOApp.bundle/Assets.xcassets"
required_assets=(
  "office_backdrop_main_2dpig"
  "office_desk_01"
  "office_monitor_01"
  "char_founder_01"
)
for asset in "${required_assets[@]}"; do
  if [[ ! -f "${ASSET_ROOT}/${asset}.imageset/Contents.json" ]]; then
    echo "error: missing required asset in app bundle: ${asset}" >&2
    exit 1
  fi
done

cat > "${INFO_PLIST}" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>ja</string>
  <key>CFBundleDisplayName</key>
  <string>TinyCEO</string>
  <key>CFBundleExecutable</key>
  <string>TinyCEO</string>
  <key>CFBundleIdentifier</key>
  <string>com.ben1327.tinyceo</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>TinyCEO</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>0.1.0</string>
  <key>CFBundleVersion</key>
  <string>1</string>
  <key>LSMinimumSystemVersion</key>
  <string>14.0</string>
  <key>LSUIElement</key>
  <true/>
  <key>NSHumanReadableCopyright</key>
  <string>© TinyCEO</string>
</dict>
</plist>
PLIST

echo "[4/5] Ad-hoc signing app bundle..."
codesign --force --deep --sign - "${APP_DIR}"
codesign --verify --deep --strict --verbose=2 "${APP_DIR}" >/dev/null

echo "[5/5] Done."
echo "Installed: ${APP_DIR}"
echo "User data: ${HOME}/Library/Application Support/TinyCEO/tinyceo.sqlite"
echo
echo "You can launch it with:"
echo "  open \"${APP_DIR}\""
