#!/usr/bin/env bash
set -euo pipefail

# ─────────────────────────────────────────────────────────────────────────────
# recall_safe_state.sh — den Goldstand mykilOS 7 (v7.0.0) frisch aufrufen.
#
# Holt den unantastbaren Safe-Stand (Tag v7.0.0) in einen SEPARATEN git-worktree
# und baut/startet ihn dort. Der aktuelle Arbeitsordner wird NICHT angefasst —
# du kannst also mitten in einem Experiment stehen und trotzdem jederzeit den
# sauberen mykilOS-7-Stand danebenlegen und starten.
#
#   ./script/recall_safe_state.sh          # Worktree anlegen + bauen + starten
#   ./script/recall_safe_state.sh --build  # nur bauen, nicht starten
#   ./script/recall_safe_state.sh --clean  # den Recall-Worktree wieder entfernen
#
# Der Worktree liegt unter ~/Desktop/CLAUDE/mykilOS-7-SAFE-v7.0.0 (Wegwerfkopie).
# ─────────────────────────────────────────────────────────────────────────────

SAFE_TAG="v7.0.0"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORKTREE_DIR="$HOME/Desktop/CLAUDE/mykilOS-7-SAFE-v7.0.0"

cd "$ROOT_DIR"

# Tag muss existieren (lokal oder remote).
if ! git rev-parse -q --verify "refs/tags/$SAFE_TAG" >/dev/null; then
  echo "→ Tag $SAFE_TAG nicht lokal — hole ihn aus origin (mykilOS-7) …"
  git fetch --tags origin 2>/dev/null || true
fi
if ! git rev-parse -q --verify "refs/tags/$SAFE_TAG" >/dev/null; then
  echo "✗ Safe-Tag $SAFE_TAG nicht gefunden. Abbruch." >&2
  exit 1
fi

if [[ "${1:-}" == "--clean" ]]; then
  echo "→ Entferne Recall-Worktree $WORKTREE_DIR …"
  git worktree remove --force "$WORKTREE_DIR" 2>/dev/null || rm -rf "$WORKTREE_DIR"
  git worktree prune
  echo "✓ Worktree entfernt. Der Safe-Stand selbst (Tag $SAFE_TAG) bleibt unberührt."
  exit 0
fi

# Frischen Worktree am Safe-Tag anlegen (detached — read-only Referenz).
if [[ -d "$WORKTREE_DIR" ]]; then
  echo "→ Recall-Worktree existiert bereits: $WORKTREE_DIR"
else
  echo "→ Lege frischen Worktree am Safe-Stand $SAFE_TAG an …"
  mkdir -p "$(dirname "$WORKTREE_DIR")"
  git worktree add --detach "$WORKTREE_DIR" "$SAFE_TAG"
fi

echo "✓ Safe-Stand liegt unter: $WORKTREE_DIR"
echo "  Commit: $(git -C "$WORKTREE_DIR" rev-parse --short HEAD) (Tag $SAFE_TAG)"

if [[ "${1:-}" == "--build" ]]; then
  echo "→ Baue (ohne Start) …"
  ( cd "$WORKTREE_DIR" && swift build )
  echo "✓ Fertig. Zum Starten: cd \"$WORKTREE_DIR\" && ./script/build_and_run.sh"
else
  echo "→ Baue + starte den Safe-Stand …"
  ( cd "$WORKTREE_DIR" && ./script/build_and_run.sh )
fi
