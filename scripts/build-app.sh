#!/usr/bin/env bash
# Builds dist/TodoWidget.app (universal, ad-hoc signed) and dist/TodoWidget.zip.
# Usage: scripts/build-app.sh [version]    e.g. scripts/build-app.sh 1.0.0
set -euo pipefail

cd "$(dirname "$0")/.."

VERSION="${1:-0.0.0}"
VERSION="${VERSION#v}"
APP="dist/TodoWidget.app"

# Universal builds need full Xcode, not just the Command Line Tools.
if [[ "$(xcode-select -p)" == *CommandLineTools* && -d /Applications/Xcode.app ]]; then
    export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
fi

BUILD_ARGS=(-c release --arch arm64 --arch x86_64)
swift build "${BUILD_ARGS[@]}"
BIN_DIR="$(swift build "${BUILD_ARGS[@]}" --show-bin-path)"

rm -rf dist
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN_DIR/TodoWidget" "$APP/Contents/MacOS/TodoWidget"
cp Resources/Info.plist "$APP/Contents/Info.plist"

/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "$APP/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $VERSION" "$APP/Contents/Info.plist"

# macOS refuses to run unsigned code, so sign ad hoc (free, no Apple account).
codesign --force --sign - --timestamp=none "$APP"
codesign --verify --strict "$APP"

ditto -c -k --keepParent "$APP" dist/TodoWidget.zip

echo "Built $APP (version $VERSION) and dist/TodoWidget.zip"
