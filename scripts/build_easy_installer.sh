#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DIST_DIR="${ROOT_DIR}/dist"
APP_PATH="${HOME}/Applications/TinyCEO.app"
VERSION="${1:-latest}"
INSTALLER_DIR_NAME="TinyCEO-Installer-${VERSION}"
INSTALLER_ZIP_PATH="${DIST_DIR}/${INSTALLER_DIR_NAME}.zip"

if [[ "${VERSION}" =~ [[:space:]] ]]; then
  echo "error: version must not contain whitespace" >&2
  exit 1
fi

echo "[1/4] Installing fresh app bundle..."
"${ROOT_DIR}/scripts/install_local_app.sh"

if [[ ! -d "${APP_PATH}" ]]; then
  echo "error: app bundle not found at ${APP_PATH}" >&2
  exit 1
fi

echo "[2/4] Preparing installer staging..."
mkdir -p "${DIST_DIR}"
STAGING_DIR="$(mktemp -d /tmp/tinyceo-installer.XXXXXX)"
cleanup() {
  rm -rf "${STAGING_DIR}"
}
trap cleanup EXIT

INSTALLER_ROOT="${STAGING_DIR}/${INSTALLER_DIR_NAME}"
mkdir -p "${INSTALLER_ROOT}"
cp -R "${APP_PATH}" "${INSTALLER_ROOT}/TinyCEO.app"

cat > "${INSTALLER_ROOT}/Install TinyCEO.command" <<'SH'
#!/usr/bin/env bash
set -euo pipefail

SRC_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_SRC="${SRC_DIR}/TinyCEO.app"

if [[ ! -d "${APP_SRC}" ]]; then
  echo "TinyCEO.app が見つかりません。"
  exit 1
fi

DEST_DIR="/Applications"
if [[ ! -w "${DEST_DIR}" ]]; then
  DEST_DIR="${HOME}/Applications"
  mkdir -p "${DEST_DIR}"
fi
APP_DST="${DEST_DIR}/TinyCEO.app"

if pgrep -x "TinyCEO" >/dev/null 2>&1; then
  pkill -x "TinyCEO" || true
  sleep 1
fi

rm -rf "${APP_DST}"
cp -R "${APP_SRC}" "${APP_DST}"
xattr -dr com.apple.quarantine "${APP_DST}" || true

open "${APP_DST}"
echo
echo "インストール完了: ${APP_DST}"
SH
chmod +x "${INSTALLER_ROOT}/Install TinyCEO.command"

cat > "${INSTALLER_ROOT}/README.txt" <<'TXT'
TinyCEO インストーラー

1. 「Install TinyCEO.command」をダブルクリック
2. 警告が出たら「開く」を選択
3. インストール後、TinyCEO が自動起動します
TXT

echo "[3/4] Building installer ZIP..."
rm -f "${INSTALLER_ZIP_PATH}"
(
  cd "${STAGING_DIR}"
  /usr/bin/zip -r -q -X "${INSTALLER_ZIP_PATH}" "${INSTALLER_DIR_NAME}"
)

echo "[4/4] Done."
echo "Installer generated:"
echo "  ${INSTALLER_ZIP_PATH}"
