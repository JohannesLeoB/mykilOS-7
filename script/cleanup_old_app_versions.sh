#!/usr/bin/env bash
set -euo pipefail

# Räumt /Applications auf: behält nur die N neuesten mykilOS-Installationen
# (Bundle-ID de.mykilos.mykilos6), alles Ältere wandert in den Papierkorb
# (Finder-delete, kein rm -rf — reversibel). Erkennung über Bundle-ID statt
# Namensmuster, weil Ordnernamen und interne Version schon mal auseinander-
# gelaufen sind (z. B. "mykilOS 7.5.app" enthielt intern Version 7.6.1).
#
# Hintergrund: script/create_dmg.sh baut nur eine DMG, das eigentliche
# Installieren ist ein manueller Drag-in-/Applications-Vorgang — jede DMG legt
# einen NEUEN, versionsnamigen Ordner an statt den alten zu ersetzen. Ohne
# dieses Skript sammeln sich beliebig viele alte Versionen an (siehe
# 2026-07-01: 5 parallele Installationen führten zu Verwechslungen beim
# Screenshotten/Testen).
#
# Nutzung:
#   ./script/cleanup_old_app_versions.sh          # behält die 2 neuesten
#   ./script/cleanup_old_app_versions.sh 1         # behält nur die 1 neueste
#   KEEP=3 ./script/cleanup_old_app_versions.sh    # alternative Übergabe

BUNDLE_ID="de.mykilos.mykilos6"
KEEP="${1:-${KEEP:-2}}"

if ! [[ "$KEEP" =~ ^[0-9]+$ ]] || [ "$KEEP" -lt 1 ]; then
  echo "Fehler: KEEP muss eine positive Zahl sein (bekommen: $KEEP)" >&2
  exit 1
fi

# Alle /Applications/*.app mit passender Bundle-ID einsammeln, samt
# Erstellungsdatum (Sekunden seit Epoch) für die Sortierung.
CANDIDATES=()
while IFS= read -r -d '' app; do
  id="$(/usr/bin/defaults read "$app/Contents/Info" CFBundleIdentifier 2>/dev/null || echo "")"
  if [ "$id" = "$BUNDLE_ID" ]; then
    created="$(/usr/bin/stat -f '%B' "$app")"
    CANDIDATES+=("$created|$app")
  fi
done < <(find /Applications -maxdepth 1 -iname "*.app" -print0)

COUNT=${#CANDIDATES[@]}
if [ "$COUNT" -le "$KEEP" ]; then
  echo "Nur $COUNT mykilOS-Installation(en) gefunden — nichts aufzuräumen (KEEP=$KEEP)." >&2
  exit 0
fi

# Neueste zuerst sortieren.
SORTED=$(printf '%s\n' "${CANDIDATES[@]}" | sort -t'|' -k1,1 -rn)

echo "Gefunden: $COUNT mykilOS-Installation(en), behalte die $KEEP neuesten." >&2

i=0
TO_TRASH=()
while IFS='|' read -r created app; do
  i=$((i + 1))
  if [ "$i" -le "$KEEP" ]; then
    echo "  behalten:    $app" >&2
  else
    echo "  Papierkorb:  $app" >&2
    TO_TRASH+=("$app")
  fi
done <<< "$SORTED"

if [ "${#TO_TRASH[@]}" -eq 0 ]; then
  exit 0
fi

# Finder-delete statt rm -rf: landet im Papierkorb, ist also reversibel.
{
  echo "tell application \"Finder\""
  for app in "${TO_TRASH[@]}"; do
    echo "  delete POSIX file \"$app\""
  done
  echo "end tell"
} | /usr/bin/osascript

echo "Fertig — ${#TO_TRASH[@]} alte Installation(en) in den Papierkorb verschoben." >&2
