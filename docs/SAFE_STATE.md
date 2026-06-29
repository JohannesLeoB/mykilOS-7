# 🔒 Safe State — mykilOS 7 (v7.0.0)

**mykilOS 7 ist der unantastbare Goldstand.** Er ist die Basis, auf die wir jederzeit
frisch zurückfallen können. Alles, was wir danach entwickeln (7.5, Mail-Client, neue
Experimente), läuft *daneben* und darf diesen Stand **niemals** zerstören.

Manche der kommenden Versuche werden im Sande verlaufen — das ist eingeplant und
genau deshalb gibt es diesen Safe State.

---

## Was genau ist gesichert

| Artefakt | Wo | Zweck |
|---|---|---|
| **Git-Tag `v7.0.0`** | mykilOS-7 **und** mykilOS-6 (beide Remotes) | unveränderlicher Anker auf Commit `e629e84` |
| **GitHub Release `v7.0.0`** | github.com/JohannesLeoB/mykilOS-7/releases/tag/v7.0.0 | dauerhaft abrufbare DMG + Release-Notes |
| **Safe-DMG** | `dist/safe/mykilOS-7-v7.0.0-SAFE.dmg` (+ `.sha256`) | lauffähiges Bundle, lokal |
| **Snapshot-Branch** | mykilOS-7 `main` = `2e0f773` (Snapshot @ e629e84) | redundante Kopie desselben Standes |

**Inhalt v7.0.0:** 409 Tests grün · S22 (klickbare Vorschau) · S23 (Alle Angebote) ·
S24 (Fehler-400-Fix) · Version 7.0.0.

---

## Den Safe-Stand frisch aufrufen

**Variante A — bauen & starten, ohne die laufende Arbeit zu stören** (empfohlen):

```bash
./script/recall_safe_state.sh
```

Legt den Stand in einem **separaten Worktree** an (`~/Desktop/CLAUDE/mykilOS-7-SAFE-v7.0.0`),
baut und startet ihn dort. Dein aktueller Arbeitsordner bleibt unberührt.
Aufräumen: `./script/recall_safe_state.sh --clean`.

**Variante B — direkt aus Git:**

```bash
git checkout v7.0.0      # exakt der Safe-Stand (detached HEAD)
swift build && swift test
```

**Variante C — einfach die DMG:** `dist/safe/mykilOS-7-v7.0.0-SAFE.dmg` öffnen,
oder vom GitHub-Release herunterladen.

---

## ⛔ Eiserne Schutzregeln

1. **Tag `v7.0.0` wird NIE verschoben, NIE überschrieben, NIE gelöscht.**
2. **mykilOS-7 `main` wird NIE force-gepusht.** Kein `git push --force` auf `main`.
3. **Neue Entwicklung läuft AUSSCHLIESSLICH auf Branches** (`release/7.5`,
   `feat/…`, `experiment/…`). Branches dürfen jederzeit sterben — der Safe-Stand nie.
4. **Vor jedem Experiment-Branch:** vom Safe-Stand oder einem grünen Branch ausgehen,
   nicht von ungetestetem Zwischenstand.
5. **Ein Stand wird erst „grün" genannt, wenn `swift build` UND `swift test` grün sind.**
   Nur grüne Stände werden zu neuen Tags/Releases erhoben.
6. Gerät irgendetwas durcheinander: **`git checkout v7.0.0` bringt immer den
   sauberen mykilOS 7 zurück.** Es gibt keinen Weg, ihn versehentlich zu verlieren.

---

## Branch-Modell (ab 7.5)

```
v7.0.0  ──🔒 (Tag, Goldstand, unantastbar)
   │
   └── release/7.5 ──────── aktive Weiterentwicklung (S25: Vorschau + Assistent-Widget)
         │
         ├── feat/mail-client ───── großer Mail-Strang (C), eigener Branch
         ├── experiment/… ───────── Versuche, die auch im Sande verlaufen dürfen
         └── …
```

Stabilisiert sich ein Branch zu einem neuen Goldstand, bekommt **er** ein neues Tag
(z. B. `v7.5.0`) — `v7.0.0` bleibt als Rückfallebene für immer bestehen.
