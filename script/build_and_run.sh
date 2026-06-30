#!/usr/bin/env bash
set -euo pipefail

PRODUCT_NAME="mykilOS6"
EXECUTABLE_NAME="mykilOS6"
APP_NAME="mykilOS 7.5"
DISPLAY_NAME="mykilOS 7.5"
BUNDLE_ID="de.mykilos.mykilos6"
APP_VERSION="7.6.3"
BUILD_VERSION="6"
MIN_SYSTEM_VERSION="14.0"
APP_ICON="AppIcon.icns"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Diagnose-Injektion (Mandate A): echter Git-Commit, Branch und Build-Zeitpunkt
# wandern in die Info.plist (Keys Myk…) und werden zur Laufzeit über
# Bundle.main.infoDictionary gelesen (AppIdentity). Kein zerbrechliches #if-Makro.
GIT_COMMIT="$(git -C "$ROOT_DIR" rev-parse --short HEAD 2>/dev/null || echo unbekannt)"
GIT_BRANCH="$(git -C "$ROOT_DIR" rev-parse --abbrev-ref HEAD 2>/dev/null || echo unbekannt)"
BUILD_DATE="$(date -u +%Y-%m-%dT%H:%MZ)"
DIST_DIR="$ROOT_DIR/dist"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
APP_CONTENTS="$APP_BUNDLE/Contents"
APP_MACOS="$APP_CONTENTS/MacOS"
APP_RESOURCES="$APP_CONTENTS/Resources"
APP_BINARY="$APP_MACOS/$EXECUTABLE_NAME"
INFO_PLIST="$APP_CONTENTS/Info.plist"
PKG_INFO="$APP_CONTENTS/PkgInfo"
APP_ICON_SOURCE="$ROOT_DIR/Sources/MykilosApp/Resources/$APP_ICON"

pkill -x "$EXECUTABLE_NAME" >/dev/null 2>&1 || true

cd "$ROOT_DIR"
swift build --disable-sandbox
BUILD_BINARY="$(swift build --disable-sandbox --show-bin-path)/$PRODUCT_NAME"

rm -rf "$APP_BUNDLE"
mkdir -p "$APP_MACOS" "$APP_RESOURCES"
cp "$BUILD_BINARY" "$APP_BINARY"
cp "$APP_ICON_SOURCE" "$APP_RESOURCES/$APP_ICON"
chmod +x "$APP_BINARY"

# SPM-Resource-Bundles (Bundle.module) mit ins App-Bundle nehmen. Ohne sie fehlen
# der ausgelieferten App zur Laufzeit u.a. DatastromManifest.json (Schaltzentrum →
# „0 Weichen") und studio_brain.json (Assistenten-Wissensbasis). swift build legt
# sie neben dem Binary unter <bin>/<Paket>_<Target>.bundle ab.
BUILD_BIN_DIR="$(dirname "$BUILD_BINARY")"
for bundle in "$BUILD_BIN_DIR"/*.bundle; do
  [ -e "$bundle" ] || continue
  cp -R "$bundle" "$APP_RESOURCES/"
done

/usr/bin/plutil -create xml1 "$INFO_PLIST"
/usr/bin/plutil -insert CFBundleExecutable -string "$EXECUTABLE_NAME" "$INFO_PLIST"
/usr/bin/plutil -insert CFBundleInfoDictionaryVersion -string "6.0" "$INFO_PLIST"
/usr/bin/plutil -insert CFBundleIdentifier -string "$BUNDLE_ID" "$INFO_PLIST"
/usr/bin/plutil -insert CFBundleName -string "$DISPLAY_NAME" "$INFO_PLIST"
/usr/bin/plutil -insert CFBundleDisplayName -string "$DISPLAY_NAME" "$INFO_PLIST"
/usr/bin/plutil -insert CFBundlePackageType -string "APPL" "$INFO_PLIST"
/usr/bin/plutil -insert CFBundleIconFile -string "$APP_ICON" "$INFO_PLIST"
/usr/bin/plutil -insert CFBundleShortVersionString -string "$APP_VERSION" "$INFO_PLIST"
/usr/bin/plutil -insert CFBundleVersion -string "$BUILD_VERSION" "$INFO_PLIST"
/usr/bin/plutil -insert LSMinimumSystemVersion -string "$MIN_SYSTEM_VERSION" "$INFO_PLIST"
/usr/bin/plutil -insert NSPrincipalClass -string "NSApplication" "$INFO_PLIST"
/usr/bin/plutil -insert NSHumanReadableCopyright -string "Copyright MYKILOS" "$INFO_PLIST"
/usr/bin/plutil -insert LSMultipleInstancesProhibited -bool true "$INFO_PLIST"
/usr/bin/plutil -insert MykGitCommit -string "$GIT_COMMIT" "$INFO_PLIST"
/usr/bin/plutil -insert MykGitBranch -string "$GIT_BRANCH" "$INFO_PLIST"
/usr/bin/plutil -insert MykBuildDate -string "$BUILD_DATE" "$INFO_PLIST"
printf "APPL????" > "$PKG_INFO"

/usr/bin/xattr -cr "$APP_BUNDLE" >/dev/null 2>&1 || true

# --- Stabile Code-Signatur ---------------------------------------------------
# Ad-hoc-Signierung (`--sign -`) erzeugt bei jedem Rebuild einen NEUEN
# Code-Hash. Die Keychain-ACL der Google-Tokens (Sources/MykilosServices/
# Google/KeychainStore.swift) ist bereits per "allow all applications" davon
# entkoppelt — aber eine stabile Identität ist trotzdem der sauberere Vollfix
# und vermeidet jeden Gatekeeper-Re-Prompt. Auflösung:
#   1) $MYKILOS_SIGN_IDENTITY (z. B. "Developer ID Application: ...")
#   2) lokale selbstsignierte Identität "mykilOS Local Signing"
#   3) Fallback: ad-hoc + einmaliger Hinweis
SIGN_IDENTITY="${MYKILOS_SIGN_IDENTITY:-}"
if [ -z "$SIGN_IDENTITY" ]; then
  if /usr/bin/security find-identity -v -p codesigning 2>/dev/null | /usr/bin/grep -q "mykilOS Local Signing"; then
    SIGN_IDENTITY="mykilOS Local Signing"
  else
    # M6-Fix: vorhandenes Apple-Development-Zertifikat als STABILE Identität nutzen, statt
    # ad-hoc (das bei jedem Build einen neuen Code-Hash erzeugt → wiederkehrende Schlüsselbund-
    # Prompts). Nach EINMALIGEM „Immer erlauben" bleibt der Zugriff bestehen.
    APPLE_DEV_ID="$(/usr/bin/security find-identity -v -p codesigning 2>/dev/null | /usr/bin/grep "Apple Development:" | /usr/bin/head -1 | /usr/bin/sed -E 's/.*"(.*)"$/\1/')"
    if [ -n "$APPLE_DEV_ID" ]; then
      SIGN_IDENTITY="$APPLE_DEV_ID"
    fi
  fi
fi

if [ -n "$SIGN_IDENTITY" ]; then
  /usr/bin/codesign --force --deep --options runtime --sign "$SIGN_IDENTITY" "$APP_BUNDLE" >/dev/null
  echo "Signiert mit stabiler Identität: $SIGN_IDENTITY." >&2
else
  /usr/bin/codesign --force --deep --sign - "$APP_BUNDLE" >/dev/null
  echo "Hinweis: Ad-hoc signiert. Für eine dauerhafte Keychain-Freigabe ohne erneute" >&2
  echo "  Prompts: Schlüsselbundverwaltung → Zertifikatsassistent → 'mykilOS Local" >&2
  echo "  Signing' (Codesignatur, selbstsigniert) anlegen, oder MYKILOS_SIGN_IDENTITY setzen." >&2
fi
/usr/bin/xattr -cr "$APP_BUNDLE" >/dev/null 2>&1 || true

# MYKILOS_NO_LAUNCH=1 → nur bauen+signieren (für Packaging/DMG/CI), nicht starten
# (vermeidet den Schlüsselbund-Prompt bei reinen Build-Läufen).
if [ "${MYKILOS_NO_LAUNCH:-0}" = "1" ]; then
  echo "Gebaut (ohne Start): $APP_BUNDLE" >&2
else
  /usr/bin/open -n "$APP_BUNDLE"
  echo "Gestartet: $APP_BUNDLE" >&2
fi
