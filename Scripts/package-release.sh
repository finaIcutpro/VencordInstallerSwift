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
  CODE_SIGN_IDENTITY="-" \
  ARCHS="$ARCHS" \
  ONLY_ACTIVE_ARCH=NO \
  build

rm -rf "$DIST"
mkdir -p "$DIST"

export COPYFILE_DISABLE=1
ditto --norsrc --noextattr "$APP_SRC" "$APP_DST"

(
  cd "$DIST"
  rm -f VencordInstaller.MacOS.zip
  zip -r -X VencordInstaller.MacOS.zip VencordInstaller.app >/dev/null
)

SIZE="$(du -h "$ZIP_PATH" | cut -f1 | xargs)"
echo "Packaged $ZIP_PATH ($SIZE)"
