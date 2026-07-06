# Codex-Setup für mykilOS 6

## Voraussetzungen

- OpenAI Codex-Zugang (codex.openai.com oder CLI)
- Das Repo ist auf GitHub: https://github.com/JohannesLeoB/mykilOS-6 (privat)
- Lokaler Klon unter: `/Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilOS Mac`

## Schritt 1: Repo-Stand pushen

Bevor Codex starten kann, muss der aktuelle Stand auf GitHub sein:

```bash
cd "/Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilOS Mac"
git push origin main
```

## Schritt 2: Codex-Session starten

In Codex (Web oder CLI):

1. Repository auswählen: `JohannesLeoB/mykilOS-6`
2. Branch: `main`
3. Den Prompt aus `docs/codex/CODEX_AUFGABEN.md` kopieren (Aufgabe 1 zuerst)
4. Einfügen und starten

## Schritt 3: Codex-Ergebnis prüfen

Nach jeder Codex-Session diese Checkliste durchgehen:

### Pflicht-Checks

```bash
cd "/Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilOS Mac"
git pull origin main

# 1. Tests grün?
swift test

# 2. Build sauber?
swift build

# 3. Was hat Codex geändert?
git log --oneline -5

# 4. Handoff geschrieben?
ls docs/handoffs/ | tail -3

# 5. CLAUDE.md aktualisiert?
head -30 CLAUDE.md

# 6. App startet ohne Crash?
./script/build_and_run.sh
```

### Architektur-Schnellcheck

```bash
# MykilosKit darf KEIN SwiftUI/GRDB importieren
grep -r "import SwiftUI\|import GRDB" Sources/MykilosKit/ && echo "FEHLER!" || echo "OK"

# MykilosWidgets darf KEIN GRDB importieren
grep -r "import GRDB" Sources/MykilosWidgets/ && echo "FEHLER!" || echo "OK"

# Keine try? in neuen Dateien (außer dokumentiert)
git diff HEAD~1 --diff-filter=A -- '*.swift' | grep "try?" && echo "PRÜFEN!" || echo "OK"

# Keine Secrets im Code
git diff HEAD~1 -- '*.swift' | grep -i "password\|secret\|token.*=" | grep -v "//\|test\|mock\|fake\|protocol" && echo "PRÜFEN!" || echo "OK"
```

### Falls etwas rot ist

- **Tests rot:** Codex-Änderung revertieren (`git revert HEAD`), Problem in nächster Claude-Code-Session fixen lassen
- **Schichtgrenzen verletzt:** Nicht mergen, in Claude Code fixen lassen
- **Kein Handoff:** Kein Blocker, aber nachholen lassen
- **App crasht:** Crash-Log prüfen, in Claude Code debuggen lassen

## Schritt 4: Weiter zu Claude Code

Wenn du zurück zu Claude Code wechselst, nutze diesen Sessionstart-Prompt:

```
Du arbeitest am Projekt mykilOS 6 — ein macOS 14+ SwiftUI-Cockpit für Projektplanung.
Repo: /Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilOS Mac
Lies zuerst CLAUDE.md — das ist das vollständige Projektgedächtnis.
Dann git log --oneline -10 für den aktuellen Stand.
Dann swift test um zu prüfen ob alles grün ist.
```

Claude Code liest CLAUDE.md, sieht was Codex gemacht hat (über Handoffs + Git-Log), und macht nahtlos weiter.
