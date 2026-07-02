# HANDOFF — Wirbelsäule C3: WorkBasket-Ausbau (für Codex)

**Für Codex-Sessions.** Folge zusätzlich `docs/codex/WORKFLOW.md` (verbindlich).
**Voraussetzung: C2 (`HANDOFF_WIRBELSAEULE_C2_CODEX.md`) muss abgeschlossen + integriert sein,
bevor diese Session startet** — C3 baut auf den C2-Ports auf (Tests referenzieren sie).

```
Pfad:   /Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilOS6/
Branch: feat/mykilos8-block-d-provisioning (oder wo C2 gelandet ist — prüfen!)
Datum:  2026-07-02 (Handoff geschrieben, vor C2-Ausführung)
```

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
