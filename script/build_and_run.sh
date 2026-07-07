#!/usr/bin/env bash
set -euo pipefail

PRODUCT_NAME="mykilOS6"
EXECUTABLE_NAME="mykilOS6"
BUNDLE_ID="de.mykilos.mykilos6"
# Eindeutiger Versionsmarker pro Build (Johannes 2026-07-05: jede Build muss klar
# unterscheidbar sein — kein zweites „11.0.0" auf der Platte). Bewohner-Oberfläche =
# 11.1.0-alpha-Linie; bei jeder neuen Build die alpha-Nummer hochzählen.
# ⚠️ create_dmg.sh trägt DIESSELBE Zahl (Zeile ~18) — beide synchron halten!
APP_VERSION="11.1.0-alpha12"
# App-Bundle trägt die Versionsnummer im Namen, damit im Dock/Finder immer
# eindeutig ist, welche Version läuft. BUNDLE_ID bleibt KONSTANT (sonst neuer
# DB-/Keychain-Pfad → Datenverlust).
# 9.0.0 (2026-07-03): KONSOLIDIERUNG / Recovery-Safe-Punkt (Main Actor). Wirbelsäule C3
# integriert (WorkBasketStore — GRDB-Persistenz v21_workbasket + Sortieren/Filtern, 848 Tests).
# Master-Doku docs/VERSION_9_KONSOLIDIERUNG.md fasst alle Stränge verknüpft zusammen.
# 8.8.0-DMG bleibt als SAFETY-Rückfall (dist/mykilOS-8.8.0-SAFETY.dmg). Keine externen Writes.
# 8.8.0 (2026-07-03): Wirbelsäule C2 — drei native CheckoutPort-Ports (Dokument→PDF,
# Moodboard→PNG, Firefly-Prompt→Text-only). UNSICHTBARES Backend-Fundament, noch NICHT
# ins Checkout-UI verdrahtet. 835 Tests, keine externen Writes.
# 8.7.0 (2026-07-02, Schlusssprint): Dev-Checkout-Exporter — kreuz-und-quer Katalog-
# Picking (Artikel/Lager/Angebote ein+aus), Warenkorb-View mit Suche/Sortieren/Filtern/
# Gruppieren/Vorschau, wiederholbarer Checkout (Session-Korb + gespeicherte Warenkörbe),
# 3 lokale Exportwege (Copy/Notiz/ZIP), sevDesk-Postbox-Format als beschriftete Vorschau
# (noch keine Live-Anbindung). 822 Tests, keine externen Writes.
# 8.6.1 (2026-07-02, spät): Gute-Nacht-Checkpoint — keine neuen Features, nur der
# verifizierte Stand vor dem Nacht-Automode gesichert + frisch gestempelt (Git-Commit +
# Build-Zeitpunkt in Info.plist, siehe Diagnose-Injektion unten).
# 8.6.0 (2026-07-02): Hero-Bild-Tools — Upload skaliert (≤2400px, layout-sicher) +
# Fokus-Punkt-Picker (Fadenkreuz-Modus). Wirbelsäulen-Fundament (C1) reist separat mit.
# 8.5.0 (2026-07-02): Chip-Integration auf block-d — Warenkorb-Freeze-Fix,
# Angebote zweispaltig + Typ-Whitelist + Kategorie/Suche, Mail-Kopf-Feinschliff (CI-Toggle),
# Mail-Anhänge klickbar + Vorschau + bestätigte Drive-Ablage. Live-Abnahme (Hustadt-Gate,
# Block-D-Sandbox, M1-M7) steht weiterhin aus — siehe HYPERBUILD.md.
# 8.0.0 (2026-07-01): mykilOS-8-Rolling-Plan Block A-D + Fragebogen-Provisionierung,
# Konsolidierungs-Session (Doku-Wahrheit + toter Code + Prompt-Caching).
APP_NAME="mykilOS $APP_VERSION"
DISPLAY_NAME="mykilOS $APP_VERSION"
BUILD_VERSION="35"
MIN_SYSTEM_VERSION="14.0"
APP_ICON="AppIcon.icns"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Onboarding-Plan Ebene 1: Google-Client-ID/Secret als Build-Zeit-Inject (nie im Klartext-
# Repo). Lokale, git-ignorierte Datei mit GOOGLE_CLIENT_ID/GOOGLE_CLIENT_SECRET — fehlt sie,
# bleiben beide leer und alles verhaelt sich exakt wie vorher (manuelle Eingabe als Notausgang,
# siehe BundledGoogleOAuthConfig.swift).
GOOGLE_CLIENT_ID=""
GOOGLE_CLIENT_SECRET=""
GOOGLE_OAUTH_SECRETS_FILE="$ROOT_DIR/script/.google-oauth.local.sh"
if [ -f "$GOOGLE_OAUTH_SECRETS_FILE" ]; then
  # shellcheck source=/dev/null
  source "$GOOGLE_OAUTH_SECRETS_FILE"
fi

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
/usr/bin/plutil -insert NSCameraUsageDescription -string "mykilOS liest Artikel-Barcodes und QR-Codes über die Kamera ein (Barcode-Widget). Es werden keine Bilder gespeichert oder gesendet." "$INFO_PLIST"
/usr/bin/plutil -insert NSBluetoothAlwaysUsageDescription -string "mykilOS koppelt einen Bluetooth-Laser für Aufmaß-Messwerte (Aufmaß-Widget)." "$INFO_PLIST"
/usr/bin/plutil -insert LSMultipleInstancesProhibited -bool true "$INFO_PLIST"
/usr/bin/plutil -insert MykGitCommit -string "$GIT_COMMIT" "$INFO_PLIST"
/usr/bin/plutil -insert MykGitBranch -string "$GIT_BRANCH" "$INFO_PLIST"
/usr/bin/plutil -insert MykGoogleClientID -string "$GOOGLE_CLIENT_ID" "$INFO_PLIST"
/usr/bin/plutil -insert MykGoogleClientSecret -string "$GOOGLE_CLIENT_SECRET" "$INFO_PLIST"
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

ENTITLEMENTS="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/mykilOS.entitlements"
if [ -n "$SIGN_IDENTITY" ]; then
  /usr/bin/codesign --force --deep --options runtime --entitlements "$ENTITLEMENTS" --sign "$SIGN_IDENTITY" "$APP_BUNDLE" >/dev/null
  echo "Signiert mit stabiler Identität: $SIGN_IDENTITY." >&2
else
  /usr/bin/codesign --force --deep --entitlements "$ENTITLEMENTS" --sign - "$APP_BUNDLE" >/dev/null
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
