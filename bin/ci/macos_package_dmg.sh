#!/usr/bin/env bash
# Упаковка macOS .app в DMG + zip.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

LABEL="${APP_RELEASE_LABEL:-v$(grep '^version:' pubspec.yaml | awk '{print $2}' | cut -d'+' -f1)}"
VERSION="${LABEL#v}"
BUILD_DIR="${1:-build/macos/Build/Products/Release}"
DIST_DIR="${2:-dist/macos}"
VOLNAME="Repo Sync Hub"

# Имя .app берётся из PRODUCT_NAME (macos/Runner/Configs/AppInfo.xcconfig).
APP_NAME=""
for candidate in "repo_sync_hub.app" "Repo Sync Hub.app" "RepoSyncHub.app"; do
  if [[ -d "${BUILD_DIR}/${candidate}" ]]; then
    APP_NAME="${candidate}"
    break
  fi
done

if [[ -z "${APP_NAME}" ]]; then
  echo "ERROR: macOS .app не найден в ${BUILD_DIR}" >&2
  ls -la "${BUILD_DIR}" || true
  exit 1
fi

mkdir -p "${DIST_DIR}"
STAGING="${BUILD_DIR}/RepoSyncHub-dmg-staging"
rm -rf "${STAGING}"
mkdir -p "${STAGING}"
cp -R "${BUILD_DIR}/${APP_NAME}" "${STAGING}/"
ln -sf /Applications "${STAGING}/Applications"

DMG_NAME="RepoSyncHub-macos-v${VERSION}.dmg"
ZIP_NAME="RepoSyncHub-macos-v${VERSION}.zip"

hdiutil create \
  -volname "${VOLNAME}" \
  -srcfolder "${STAGING}" \
  -ov -format UDZO \
  "${BUILD_DIR}/${DMG_NAME}"

ditto -c -k --keepParent \
  "${BUILD_DIR}/${APP_NAME}" \
  "${BUILD_DIR}/${ZIP_NAME}"

mv "${BUILD_DIR}/${DMG_NAME}" "${BUILD_DIR}/${ZIP_NAME}" "${DIST_DIR}/"
rm -rf "${STAGING}"

echo "Wrote ${DIST_DIR}/${DMG_NAME}"
echo "Wrote ${DIST_DIR}/${ZIP_NAME}"
