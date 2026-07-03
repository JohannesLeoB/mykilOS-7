# HANDOFF — Wirbelsäule C3: WorkBasket-Ausbau (für Codex)

**Für Codex-Sessions.** Folge zusätzlich `docs/codex/WORKFLOW.md` (verbindlich).

## 0. ⛔ REALITY CHECK — ZUERST, VOR JEDER ANDEREN AKTION

**Ignoriere jeden mykilOS-Kontext aus früheren Gesprächen in dieser Codex-Umgebung.** Nur was du
JETZT unten mit den Befehlen tatsächlich siehst, zählt.

```bash
pwd
git branch --show-current
git status --short
git log --oneline -5
```

**Prüfe in dieser Reihenfolge:**
1. **Pfad** muss enden mit `/Claude/Projects/mykilOS/MYKILOS 6/mykilOS6` — NICHT ein
   `~/Desktop/CLAUDE/...`-Worktree (das sind Wegwerfkopien anderer Sessions).
2. **Status** muss leer/clean sein.
3. **Voraussetzung C2:** in den letzten Commits (`git log --oneline -20`) muss ein Commit mit
   `HANDOFF_WIRBELSAEULE_C2_ERGEBNIS.md` ODER erkennbaren C2-Port-Dateien
   (`Sources/MykilosApp/Wirbelsaeule/Ports/...`) auftauchen. **Fehlt das: C2 ist noch nicht
   gelandet — STOPP, diese Session (C3) darf noch nicht starten.**
4. **Branch:** wo auch immer C2 tatsächlich gelandet ist (prüfe `git log`, nicht raten) — nicht
   zwingend `feat/mykilos8-block-d-provisioning`, falls Claude zwischenzeitlich umbenannt/
   gemergt hat.

**Bei jeder Abweichung: STOPP.** Abweichung in eigenen Worten benennen, nicht raten oder
improvisieren, auf Anweisung warten.

---

## 1. Pflichtlektüre

1. `docs/S10_WIRBELSAEULE.md` §3 „WorkBasket — der verallgemeinerte Warenkorb" — autoritativ.
2. `Sources/MykilosKit/Domain/Wirbelsaeule/WirbelsaeuleFoundation.swift` — C1-Fundament
   (`WorkBasket`, `WorkBasketStatus`, `WorkBasketID`, `InhaltsArt`, `Pick`).
3. `Sources/MykilosServices/.../CartStore.swift` (oder wo `CartStore` liegt — suchen mit
   `grep -r "class CartStore" Sources/`) — der heutige Artikel-only-Keim, den du verallgemeinerst.
4. `Sources/MykilosKit/Domain/WarenkorbEintrag.swift` — bestehender Eintrags-Typ mit `version:Int`.

## 2. Scope dieser Session (C3, NICHT mehr)

**Ziel:** `CartStore` von „nur Artikel-Positionen" auf **beliebige `Pick`-Inhalte** verallgemeinern,
ohne die bestehende Artikel-Funktionalität zu brechen (Abwärtskompatibilität zwingend — Warenkörbe
sind Kundendaten, siehe `CLAUDE.md` „Persistenz").

1. **`inhaltsArt`-Feld** auf dem persistierten Warenkorb-Typ ergänzen (GRDB-Migration NUR
   ANHÄNGEN, siehe `CLAUDE.md` „Absolute Regeln → Persistenz" — niemals bestehende Spalten ändern).
   Default für bestehende Zeilen: `.artikel` (Migrations-Rückwärtskompatibilität).
2. **Projekt-Zuordnung + Versionierung** — prüfen, ob `WarenkorbEintrag.version` bereits reicht
   oder ob eine explizite `WorkBasketStatus`-Spalte (aus C1: kalkulation/bestaetigt/nachtrag/
   gutschrift) ergänzt werden muss. **NICHT** die volle §5j-State-Machine bauen (das ist C4) —
   hier nur das Feld + einen Cold-Start-Test, dass es persistiert.
3. **Sortieren/Filtern** in der bestehenden Warenkorb-Liste (`Sources/MykilosApp/.../Warenkorb*`
   suchen) nach `inhaltsArt`, Datum, Projekt — reine UI-Ergänzung auf vorhandenen Daten.
4. **Kein Artikel-only-Hardwiring mehr einführen** — wo neuer Code entsteht, gegen `Pick`/
   `InhaltsArt` programmieren, nicht gegen einen konkreten Artikel-Typ.

## 3. Was NICHT in dieser Session passiert

- **Keine sevDesk-Postbox** (C4).
- **Keine neuen Ports** (C2 ist abgeschlossen, bevor C3 beginnt).
- **Keine volle Lebenszyklus-State-Machine** (§5j/§7) — nur das Status-Feld vorbereiten, die
  Übergangslogik (kalkulation→bestaetigt etc.) ist bereits in `WorkBasketStatus.darfWechselnZu`
  aus C1 vorhanden — hier nur **verwenden**, nicht neu bauen.
- **Keine GRDB-Spalten ändern/löschen** — nur anhängen. Migration-Nummer prüfen
  (`Sources/MykilosServices/.../GRDBDatabase*.swift`, aktuell bei welcher Version?).

## 4. Rails (unverändert)

- GRDB-Migration anhängen, nie ändern. Cold-Start-Test: schreiben → neue Instanz → lesen → identisch.
- Kein `try?` bei neuen Schreibvorgängen.
- Token-Disziplin (MykilosDesign) bei jeder UI-Ergänzung.
- `MykilosServices` darf GRDB, `MykilosWidgets`/Views schreiben nie direkt — nur über Stores.

## 5. Finish-Kriterium

`swift build` + `swift test` grün, neuer Cold-Start-Test für das `inhaltsArt`-Feld, bestehende
Warenkorb-Tests weiterhin grün (keine Regression an der Artikel-Funktionalität — das ist die
härteste Nagelprobe dieser Session). Handoff:
`docs/handoffs/HANDOFF_WIRBELSAEULE_C3_ERGEBNIS.md`. `CLAUDE.md` nicht selbst anfassen.
