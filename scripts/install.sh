#!/usr/bin/env bash
# Downloads the latest release of Todo Widget and opens it.
set -euo pipefail

URL="https://github.com/andrewcjh27/Todo-Widget/releases/latest/download/TodoWidget.zip"

if [[ -w /Applications ]]; then
    DEST=/Applications
else
    DEST="$HOME/Applications"
    mkdir -p "$DEST"
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "Downloading Todo Widget..."
curl -fsSL "$URL" -o "$TMP/TodoWidget.zip"
ditto -x -k "$TMP/TodoWidget.zip" "$TMP"

pkill -x TodoWidget 2>/dev/null || true
rm -rf "$DEST/TodoWidget.app"
mv "$TMP/TodoWidget.app" "$DEST/TodoWidget.app"

open "$DEST/TodoWidget.app"
echo "Installed to $DEST/TodoWidget.app. Look for the checklist icon in your menu bar."
