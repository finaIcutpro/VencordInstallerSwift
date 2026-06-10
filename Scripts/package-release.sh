#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCHEME="VencordInstallerSwift"
CONFIGURATION="${CONFIGURATION:-Release}"
DERIVED_DATA="${DERIVED_DATA:-$ROOT/DerivedData}"
VERSION="${VERSION:-dev}"
BUILD_NUMBER="${BUILD_NUMBER:-0}"
ARCHS="${ARCHS:-arm64 x86_64}"

DIST="$ROOT/dist"
APP_SRC="$DERIVED_DATA/Build/Products/$CONFIGURATION/VencordInstallerSwift.app"
APP_DST="$DIST/VencordInstaller.app"
ZIP_PATH="$DIST/VencordInstaller.MacOS.zip"
DMG_PATH="$DIST/VencordInstaller.MacOS.dmg"
DMG_STAGING="$DIST/dmg-staging"

cd "$ROOT"

echo "Building ${SCHEME} ${VERSION} (${BUILD_NUMBER}) for ${ARCHS}..."
xcodebuild \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -destination 'generic/platform=macOS' \
  -derivedDataPath "$DERIVED_DATA" \
  MARKETING_VERSION="$VERSION" \
  CURRENT_PROJECT_VERSION="$BUILD_NUMBER" \
  CODE_SIGNING_ALLOWED=NO \
  ENABLE_HARDENED_RUNTIME=NO \
  ARCHS="$ARCHS" \
  ONLY_ACTIVE_ARCH=NO \
  build

rm -rf "$DIST"
mkdir -p "$DIST"

export COPYFILE_DISABLE=1
ditto --norsrc --noextattr "$APP_SRC" "$APP_DST"
codesign --force --deep --entitlements "$ROOT/VencordInstallerSwift/VencordInstallerSwift.entitlements" --sign - "$APP_DST"

(
  cd "$DIST"
  rm -f VencordInstaller.MacOS.zip
  zip -r -X VencordInstaller.MacOS.zip VencordInstaller.app >/dev/null
)

rm -rf "$DMG_STAGING"
mkdir -p "$DMG_STAGING"
ditto --norsrc --noextattr "$APP_DST" "$DMG_STAGING/VencordInstaller.app"
ln -s /Applications "$DMG_STAGING/Applications"

rm -f "$DMG_PATH"
hdiutil create \
  -volname "Vencord Installer" \
  -srcfolder "$DMG_STAGING" \
  -ov \
  -format UDZO \
  "$DMG_PATH" >/dev/null

rm -rf "$DMG_STAGING"

ZIP_SIZE="$(du -h "$ZIP_PATH" | cut -f1 | xargs)"
DMG_SIZE="$(du -h "$DMG_PATH" | cut -f1 | xargs)"
echo "Packaged $ZIP_PATH ($ZIP_SIZE)"
echo "Packaged $DMG_PATH ($DMG_SIZE)"
