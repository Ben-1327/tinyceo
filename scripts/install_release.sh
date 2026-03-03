#!/usr/bin/env bash
set -euo pipefail

REPO="Ben-1327/tinyceo"
VERSION="${1:-latest}"

if [[ "${VERSION}" == "latest" ]]; then
  RELEASE_API="https://api.github.com/repos/${REPO}/releases/latest"
else
  RELEASE_API="https://api.github.com/repos/${REPO}/releases/tags/${VERSION}"
fi

require_cmd() {
  local cmd="$1"
  if ! command -v "${cmd}" >/dev/null 2>&1; then
    echo "error: required command not found: ${cmd}" >&2
    exit 1
  fi
}

require_cmd curl
require_cmd hdiutil
require_cmd python3

echo "[1/6] Fetching release metadata..."
json="$(curl -fsSL "${RELEASE_API}")"

extract_with_python() {
  local code="$1"
  printf "%s" "${json}" | python3 -c "${code}"
}

tag_name="$(extract_with_python 'import json,sys; d=json.load(sys.stdin); print(d.get("tag_name",""))')"
dmg_url="$(extract_with_python '
import json,sys
d=json.load(sys.stdin)
for a in d.get("assets",[]):
    if a.get("name","").endswith(".dmg"):
        print(a.get("browser_download_url",""))
        break
')"
sha_url="$(extract_with_python '
import json,sys
d=json.load(sys.stdin)
for a in d.get("assets",[]):
    if a.get("name","").endswith(".sha256"):
        print(a.get("browser_download_url",""))
        break
')"

if [[ -z "${dmg_url}" ]]; then
  echo "error: DMG asset not found in release ${tag_name:-unknown}" >&2
  exit 1
fi

tmp_dir="$(mktemp -d /tmp/tinyceo-release-install.XXXXXX)"
cleanup() {
  if [[ -n "${mount_point:-}" && -d "${mount_point}" ]]; then
    hdiutil detach "${mount_point}" >/dev/null 2>&1 || true
  fi
  rm -rf "${tmp_dir}"
}
trap cleanup EXIT

dmg_path="${tmp_dir}/TinyCEO.dmg"
sha_path="${tmp_dir}/TinyCEO.sha256"

echo "[2/6] Downloading ${tag_name:-release}..."
curl -fL "${dmg_url}" -o "${dmg_path}"

if [[ -n "${sha_url}" ]]; then
  echo "[3/6] Verifying SHA256..."
  curl -fL "${sha_url}" -o "${sha_path}"
  expected_hash="$(awk '/\\.dmg$/ {print $1; exit}' "${sha_path}")"
  actual_hash="$(shasum -a 256 "${dmg_path}" | awk '{print $1}')"
  if [[ -n "${expected_hash}" && "${expected_hash}" != "${actual_hash}" ]]; then
    echo "error: checksum mismatch for DMG" >&2
    echo "expected: ${expected_hash}" >&2
    echo "actual:   ${actual_hash}" >&2
    exit 1
  fi
else
  echo "[3/6] SHA256 asset not found. Skipping checksum verification."
fi

echo "[4/6] Mounting disk image..."
attach_output="$(hdiutil attach "${dmg_path}" -nobrowse)"
mount_point="$(printf "%s\n" "${attach_output}" | tail -n 1 | awk '{$1=$2=""; sub(/^  */, ""); print}')"
app_src="${mount_point}/TinyCEO.app"
if [[ ! -d "${app_src}" ]]; then
  echo "error: TinyCEO.app not found in mounted DMG" >&2
  exit 1
fi

dest_dir="/Applications"
if [[ ! -w "${dest_dir}" ]]; then
  dest_dir="${HOME}/Applications"
  mkdir -p "${dest_dir}"
fi
app_dst="${dest_dir}/TinyCEO.app"

echo "[5/6] Installing to ${app_dst}..."
if pgrep -x "TinyCEO" >/dev/null 2>&1; then
  pkill -x "TinyCEO" || true
  sleep 1
fi
rm -rf "${app_dst}"
cp -R "${app_src}" "${app_dst}"
xattr -dr com.apple.quarantine "${app_dst}" || true

echo "[6/6] Launching TinyCEO..."
open "${app_dst}"

echo
echo "Installed ${tag_name:-TinyCEO} at: ${app_dst}"
echo "Done."
