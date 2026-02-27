#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DIST_DIR="${ROOT_DIR}/dist"
APP_PATH="${HOME}/Applications/TinyCEO.app"
VERSION="${1:-latest}"
ZIP_PATH="${DIST_DIR}/TinyCEO-${VERSION}.zip"
DMG_PATH="${DIST_DIR}/TinyCEO-${VERSION}.dmg"
SHA_PATH="${DIST_DIR}/TinyCEO-${VERSION}.sha256"
LATEST_ZIP_PATH="${DIST_DIR}/TinyCEO-latest.zip"
LATEST_DMG_PATH="${DIST_DIR}/TinyCEO-latest.dmg"
LATEST_SHA_PATH="${DIST_DIR}/TinyCEO-latest.sha256"

if [[ "${VERSION}" =~ [[:space:]] ]]; then
  echo "error: version must not contain whitespace" >&2
  exit 1
fi

echo "[1/5] Installing fresh app bundle..."
"${ROOT_DIR}/scripts/install_local_app.sh"

if [[ ! -d "${APP_PATH}" ]]; then
  echo "error: app bundle not found at ${APP_PATH}" >&2
  exit 1
fi

echo "[2/5] Preparing dist staging..."
mkdir -p "${DIST_DIR}"
STAGING_DIR="$(mktemp -d /tmp/tinyceo-dist.XXXXXX)"
cleanup() {
  rm -rf "${STAGING_DIR}"
}
trap cleanup EXIT

cp -R "${APP_PATH}" "${STAGING_DIR}/TinyCEO.app"
ln -s /Applications "${STAGING_DIR}/Applications"
cat > "${STAGING_DIR}/README.txt" <<'TXT'
TinyCEO local build

1. TinyCEO.app を Applications にドラッグ
2. 初回起動時に確認ダイアログが出たら開く
3. アップデート時は古い TinyCEO.app を置き換え
TXT

rm -f "${ZIP_PATH}" "${DMG_PATH}" "${SHA_PATH}"

echo "[3/5] Building ZIP..."
ditto -c -k --sequesterRsrc --keepParent "${STAGING_DIR}/TinyCEO.app" "${ZIP_PATH}"

echo "[4/5] Building DMG..."
hdiutil create \
  -volname "TinyCEO ${VERSION}" \
  -srcfolder "${STAGING_DIR}" \
  -ov \
  -format UDZO \
  "${DMG_PATH}" \
  >/dev/null

echo "[5/5] Writing checksums and latest aliases..."
shasum -a 256 "${ZIP_PATH}" "${DMG_PATH}" > "${SHA_PATH}"

cp -f "${ZIP_PATH}" "${LATEST_ZIP_PATH}"
cp -f "${DMG_PATH}" "${LATEST_DMG_PATH}"
cp -f "${SHA_PATH}" "${LATEST_SHA_PATH}"

echo
echo "Artifacts generated:"
echo "  ${ZIP_PATH}"
echo "  ${DMG_PATH}"
echo "  ${SHA_PATH}"
echo
echo "Latest aliases:"
echo "  ${LATEST_ZIP_PATH}"
echo "  ${LATEST_DMG_PATH}"
echo "  ${LATEST_SHA_PATH}"
