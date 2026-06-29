#!/usr/bin/env bash
set -euo pipefail

# Baut die App und verpackt sie in eine DMG für die Distribution.
# Voraussetzung: build_and_run.sh muss vorher gelaufen sein (oder die App
# liegt bereits unter dist/mykilOS 7.app).

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
APP_BUNDLE="$DIST_DIR/mykilOS 7.app"
DMG_NAME="mykilOS-6"
DMG_PATH="$DIST_DIR/$DMG_NAME.dmg"
VOLUME_NAME="mykilOS 7"

# Build falls nötig — ohne Start (Packaging-Lauf, kein Schlüsselbund-Prompt).
if [ ! -d "$APP_BUNDLE" ]; then
  echo "App-Bundle nicht gefunden, baue erst (ohne Start)…" >&2
  MYKILOS_NO_LAUNCH=1 "$ROOT_DIR/script/build_and_run.sh"
fi

if [ ! -d "$APP_BUNDLE" ]; then
  echo "Fehler: $APP_BUNDLE existiert nicht." >&2
  exit 1
fi

# Sauberes Drag-Install-Layout: Staging-Ordner mit App + Applications-Symlink.
STAGING="$DIST_DIR/dmg-staging"
rm -rf "$STAGING" "$DMG_PATH"
mkdir -p "$STAGING"
cp -R "$APP_BUNDLE" "$STAGING/"
ln -s /Applications "$STAGING/Applications"

# DMG aus dem Staging-Ordner erstellen (komprimiert).
echo "Erstelle DMG…" >&2
hdiutil create \
  -volname "$VOLUME_NAME" \
  -srcfolder "$STAGING" \
  -ov \
  -format UDZO \
  "$DMG_PATH"

rm -rf "$STAGING"

echo "DMG erstellt: $DMG_PATH" >&2
echo "Größe: $(du -h "$DMG_PATH" | cut -f1)" >&2
