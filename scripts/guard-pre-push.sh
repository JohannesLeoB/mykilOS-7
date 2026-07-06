#!/bin/sh
# Maxime #1 — nur nach mykilOS-macOS pushen.
# Install: cp scripts/guard-pre-push.sh .git/hooks/pre-push && chmod +x .git/hooks/pre-push
remote_url="$2"
case "$remote_url" in
  *mykilOS-macOS*) exit 0 ;;
  *) echo "PRE-PUSH BLOCKIERT: Ziel ist NICHT mykilOS-macOS ($remote_url). Maxime #1 - siehe KOORDINATEN.md." >&2; exit 1 ;;
esac
