#!/bin/bash
# Rendert die Systemarchitektur-HTML zu PDF via Chrome headless.
# Reproduzierbar & repo-relativ — funktioniert aus jedem Arbeitsverzeichnis.
#
#   ./docs/architecture/build_pdf.sh
#
# Voraussetzung: Google Chrome installiert (headless --print-to-pdf).
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HTML="$DIR/mykilOS6_Systemarchitektur.html"
PDF="$DIR/mykilOS6_Systemarchitektur.pdf"
CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

if [ ! -x "$CHROME" ]; then
  echo "✗ Google Chrome nicht gefunden unter: $CHROME" >&2
  echo "  Installieren oder CHROME-Pfad im Skript anpassen." >&2
  exit 1
fi

"$CHROME" --headless --disable-gpu --no-pdf-header-footer \
  --print-to-pdf="$PDF" "$HTML" 2>&1 | tail -1

echo "✓ PDF: $PDF"
ls -la "$PDF"
