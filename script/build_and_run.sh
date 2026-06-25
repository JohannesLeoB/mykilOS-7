#!/usr/bin/env bash
set -euo pipefail

PRODUCT_NAME="mykilOS6"
EXECUTABLE_NAME="mykilOS6"
APP_NAME="mykilOS 6"
DISPLAY_NAME="mykilOS 6"
BUNDLE_ID="de.mykilos.mykilos6"
APP_VERSION="6.0.0"
BUILD_VERSION="1"
MIN_SYSTEM_VERSION="14.0"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
APP_CONTENTS="$APP_BUNDLE/Contents"
APP_MACOS="$APP_CONTENTS/MacOS"
APP_RESOURCES="$APP_CONTENTS/Resources"
APP_BINARY="$APP_MACOS/$EXECUTABLE_NAME"
INFO_PLIST="$APP_CONTENTS/Info.plist"
PKG_INFO="$APP_CONTENTS/PkgInfo"

pkill -x "$EXECUTABLE_NAME" >/dev/null 2>&1 || true

cd "$ROOT_DIR"
swift build --disable-sandbox
BUILD_BINARY="$(swift build --disable-sandbox --show-bin-path)/$PRODUCT_NAME"

rm -rf "$APP_BUNDLE"
mkdir -p "$APP_MACOS" "$APP_RESOURCES"
cp "$BUILD_BINARY" "$APP_BINARY"
chmod +x "$APP_BINARY"

/usr/bin/plutil -create xml1 "$INFO_PLIST"
/usr/bin/plutil -insert CFBundleExecutable -string "$EXECUTABLE_NAME" "$INFO_PLIST"
/usr/bin/plutil -insert CFBundleInfoDictionaryVersion -string "6.0" "$INFO_PLIST"
/usr/bin/plutil -insert CFBundleIdentifier -string "$BUNDLE_ID" "$INFO_PLIST"
/usr/bin/plutil -insert CFBundleName -string "$DISPLAY_NAME" "$INFO_PLIST"
/usr/bin/plutil -insert CFBundleDisplayName -string "$DISPLAY_NAME" "$INFO_PLIST"
/usr/bin/plutil -insert CFBundlePackageType -string "APPL" "$INFO_PLIST"
/usr/bin/plutil -insert CFBundleShortVersionString -string "$APP_VERSION" "$INFO_PLIST"
/usr/bin/plutil -insert CFBundleVersion -string "$BUILD_VERSION" "$INFO_PLIST"
/usr/bin/plutil -insert LSMinimumSystemVersion -string "$MIN_SYSTEM_VERSION" "$INFO_PLIST"
/usr/bin/plutil -insert NSPrincipalClass -string "NSApplication" "$INFO_PLIST"
/usr/bin/plutil -insert NSHumanReadableCopyright -string "Copyright MYKILOS" "$INFO_PLIST"
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

/usr/bin/open -n "$APP_BUNDLE"
echo "Gestartet: $APP_BUNDLE" >&2
