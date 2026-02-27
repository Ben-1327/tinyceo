#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
VERSION="${1:-dev-$(date +%Y%m%d%H%M)}"
VERSION_SAFE="${VERSION//\//-}"

BUILD_PATH="${BUILD_PATH:-/tmp/tinyceo-build-release}"
STAGING_DIR="${STAGING_DIR:-/tmp/tinyceo-release}"
DIST_DIR="${ROOT_DIR}/dist"

APP_NAME="TinyCEO"
APP_DIR="${STAGING_DIR}/${APP_NAME}.app"
APP_CONTENTS="${APP_DIR}/Contents"
APP_MACOS="${APP_CONTENTS}/MacOS"
APP_RESOURCES="${APP_CONTENTS}/Resources"
INFO_PLIST="${APP_CONTENTS}/Info.plist"

BUNDLE_ID="${BUNDLE_ID:-com.ben1327.tinyceo}"
BUILD_NUMBER="${BUILD_NUMBER:-$(date +%Y%m%d%H%M%S)}"

ZIP_VERSIONED="${DIST_DIR}/TinyCEO-${VERSION_SAFE}.zip"
ZIP_LATEST="${DIST_DIR}/TinyCEO-latest.zip"
DMG_VERSIONED="${DIST_DIR}/TinyCEO-${VERSION_SAFE}.dmg"
DMG_LATEST="${DIST_DIR}/TinyCEO-latest.dmg"

echo "[1/6] Cleaning staging..."
rm -rf "${STAGING_DIR}"
mkdir -p "${APP_MACOS}" "${APP_RESOURCES}" "${DIST_DIR}"

echo "[2/6] Building release binary..."
cd "${ROOT_DIR}"
swift build -c release --build-path "${BUILD_PATH}" --product tinyceo-app

EXECUTABLE="${BUILD_PATH}/release/tinyceo-app"
if [[ ! -f "${EXECUTABLE}" ]]; then
  echo "error: executable not found at ${EXECUTABLE}" >&2
  exit 1
fi

echo "[3/6] Creating app bundle..."
cp "${EXECUTABLE}" "${APP_MACOS}/TinyCEO"
chmod +x "${APP_MACOS}/TinyCEO"

shopt -s nullglob
for bundle in "${BUILD_PATH}/release/"*.bundle; do
  cp -R "${bundle}" "${APP_RESOURCES}/"
done
shopt -u nullglob

cat > "${INFO_PLIST}" <<PLIST
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
  <string>${BUNDLE_ID}</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>TinyCEO</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>${VERSION}</string>
  <key>CFBundleVersion</key>
  <string>${BUILD_NUMBER}</string>
  <key>LSMinimumSystemVersion</key>
  <string>14.0</string>
  <key>LSUIElement</key>
  <true/>
  <key>NSHumanReadableCopyright</key>
  <string>© TinyCEO</string>
</dict>
</plist>
PLIST

if command -v codesign >/dev/null 2>&1; then
  echo "[4/6] Applying ad-hoc code signature..."
  codesign --force --deep --sign - "${APP_DIR}"
fi

echo "[5/6] Packaging ZIP..."
rm -f "${ZIP_VERSIONED}" "${ZIP_LATEST}"
ditto -c -k --sequesterRsrc --keepParent "${APP_DIR}" "${ZIP_VERSIONED}"
cp "${ZIP_VERSIONED}" "${ZIP_LATEST}"

echo "[6/6] Packaging DMG..."
DMG_ROOT="${STAGING_DIR}/dmg-root"
rm -rf "${DMG_ROOT}"
mkdir -p "${DMG_ROOT}"
cp -R "${APP_DIR}" "${DMG_ROOT}/"
ln -s /Applications "${DMG_ROOT}/Applications"

rm -f "${DMG_VERSIONED}" "${DMG_LATEST}"
hdiutil create -volname "TinyCEO" -srcfolder "${DMG_ROOT}" -ov -format UDZO "${DMG_VERSIONED}" >/dev/null
cp "${DMG_VERSIONED}" "${DMG_LATEST}"

echo
echo "Artifacts:"
echo "  ${ZIP_VERSIONED}"
echo "  ${DMG_VERSIONED}"
echo "  ${ZIP_LATEST}"
echo "  ${DMG_LATEST}"

