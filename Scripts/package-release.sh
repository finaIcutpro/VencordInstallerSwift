#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCHEME="VencordInstallerSwift"
CONFIGURATION="${CONFIGURATION:-Release}"
DERIVED_DATA="${DERIVED_DATA:-$ROOT/DerivedData}"
VERSION="${VERSION:-dev}"
BUILD_NUMBER="${BUILD_NUMBER:-0}"
ARCHS="${ARCHS:-arm64 x86_64}"

cd "$ROOT"

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

APP_SRC="$DERIVED_DATA/Build/Products/$CONFIGURATION/VencordInstallerSwift.app"
APP_DST="$ROOT/dist/VencordInstaller.app"
ZIP_PATH="$ROOT/dist/VencordInstaller.MacOS.zip"

rm -rf "$ROOT/dist"
mkdir -p "$ROOT/dist"
ditto "$APP_SRC" "$APP_DST"
ditto -c -k --sequesterRsrc --keepParent "$APP_DST" "$ZIP_PATH"

echo "Packaged $ZIP_PATH"
