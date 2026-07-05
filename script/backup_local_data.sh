#!/usr/bin/env bash
set -euo pipefail

# Nächtliches Backup der lokalen mykilOS-Datenbestände (Flanke #1, 2026-07-04).
# Local-first heißt: diese SQLites existieren NUR auf dieser Maschine — Git sichert
# Code, nicht Daten. Dieses Skript sichert konsistent (sqlite3 .backup, WAL-sicher)
# nach ~/mykilOS-App-Backups/auto/<Zeitstempel>/ und behält die letzten 14 Stände.
#
# Automatik (LaunchAgent, täglich 03:30):
#   cp script/com.mykilos.backup-local-data.plist ~/Library/LaunchAgents/
#   launchctl load ~/Library/LaunchAgents/com.mykilos.backup-local-data.plist
# Deaktivieren: launchctl unload ~/Library/LaunchAgents/com.mykilos.backup-local-data.plist

DEST_ROOT="$HOME/mykilOS-App-Backups/auto"
STAMP="$(date +%Y-%m-%d_%H%M)"
DEST="$DEST_ROOT/$STAMP"
KEEP=14

# Die Kronjuwelen (bei neuen persistenten Stores hier ergänzen):
SOURCES=(
  "$HOME/Library/Application Support/mykilOS6/db.sqlite"
  "$HOME/Library/Application Support/mykilOS/Kalkulationslabor/Learning/learning.sqlite"
)

mkdir -p "$DEST"
saved=0
for src in "${SOURCES[@]}"; do
  if [ -f "$src" ]; then
    name="$(basename "$(dirname "$src")")_$(basename "$src")"
    # sqlite3 .backup = konsistenter Online-Snapshot (inkl. WAL-Stand).
    sqlite3 "$src" ".backup '$DEST/$name'"
    saved=$((saved + 1))
  fi
done

echo "$(date -u +%FT%TZ) gesichert: $saved DB(s) -> $DEST" >> "$DEST_ROOT/backup.log"

# Retention: nur die letzten $KEEP Stände behalten (BSD-tauglich: neueste zuerst,
# alles ab Position KEEP+1 löschen).
cd "$DEST_ROOT"
ls -1d 20* 2>/dev/null | sort -r | tail -n +"$((KEEP + 1))" | while read -r old; do
  rm -rf "$DEST_ROOT/$old"
done

echo "OK: $saved DB(s) -> $DEST"
