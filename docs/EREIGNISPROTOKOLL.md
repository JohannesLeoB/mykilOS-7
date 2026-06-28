# mykilOS 6 — Ereignisprotokoll

**Lebendes Dokument. Jede Session, jeder Agent, jedes Tool trägt hier ein.**
Ziel: lückenlose Nachverfolgung aller Entwicklungsschritte — was wurde gebaut,
was ist kaputt gegangen, was ist offen, wer hat was gemacht, auf welchem Branch.

---

## Pflicht-Header für jeden Eintrag

```
## [DATUM] [AGENT/TOOL] — [KURZTITEL]
Pfad:   /Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilOS6/
Branch: <branch>
Build:  ✅/❌
Tests:  N grün / M fehlgeschlagen
```

---

## Kanonischer Ordner (immer)

```
/Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilOS6/
GitHub: https://github.com/JohannesLeoB/mykilOS-6
```

Temporäre Worktrees liegen unter `~/Desktop/CLAUDE/` — das sind Wegwerfkopien,
nie dauerhafter Arbeitsort.

---

## Branch-Übersicht (Stand 2026-06-28)

| Branch | Basis | Tests | Zweck |
|---|---|---|---|
| `main` | — | **198** ✅ | **Aktueller Stand (S16-FF, 2026-06-28):** Live-Wiring + Assistent + Kalkulation 1–8. Subsumiert `stabilize` + die gesamte Kalkulations-Branch-Kette. |
| `stabilize/from-0b7c366-2026-06-28` | `0b7c366` | 169 | Codex Recovery — **jetzt in `main` enthalten** (Vorfahre der S16-Kette) |
| `sprint/shared-drive-widget-oauth` | `0b7c366` | 169 | Aktive Features (Wiring-Sessions 1–3) + Session-Docs |
| `feat/conversational-assistant` | älter | 163 | Konversationeller Assistent Phase 1–2 |
| `clickup-integration` | älter | 103 | ClickUp-Widget (gemergt in sprint?) |
| `drive-offer-watcher` | älter | 114 | DriveOfferWatcher (gemergt in sprint?) |
| `claude/musing-sammet-3abd94` | sehr alt | ~97 | Claude Code Desktop Worktree — VERALTET |
| `claude/hungry-ardinghelli-8e798a` | sehr alt | ? | Claude Code Desktop Worktree — VERALTET |
| `claude/loving-shamir-c7ff05` | sehr alt | ? | Claude Code Desktop Worktree — VERALTET |

**Aktiver Entwicklungs-Branch:** `main` (S16-Kette als Fast-Forward gemergt, 2026-06-28).
Verbleibende Abzweigungen, bewusst NICHT in `main` (eigene Entscheidung von Johannes):
`claude/musing-sammet-3abd94` (PR #1, läuft aktiv — Statut 2, nicht anfassen),
`sprint/shared-drive-widget-oauth` (+70, divergent). PR #2 `feat/kalkulation-core-port`
ist durch die S16-Kette subsumiert → geschlossen.

---

## Einträge (neueste zuerst)

---

### 2026-06-28 · Claude Code (Opus 4.8, S16) — Lern-Loop sichtbar: Kalibrierungs-Kandidaten + Promote-Flow (Schritt 8)

**Pfad:** `/Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilOS6/`
**Branch:** `feat/kalkulation-calibration-loop` (abgezweigt von `feat/kalkulation-record-adjustment`)
**Build:** ✅ | **Tests:** 198 grün (179 swift-testing + 19 XCTest)

**Was gemacht wurde:**
- `KalkulationsEngineProviding` (MykilosKit): `recordAdjustment` bekommt einen
  `lernen: Bool`-Parameter. Kein Default am Protokoll-Requirement (Swift erlaubt das
  nicht) — stattdessen eine `extension`-Convenience-Overload mit der alten 3-Argument-
  Signatur (`lernen: false`), damit alle Schritt-7-Aufrufer (Tests, Call-Sites)
  quellkompatibel bleiben und unverändert grün sind.
- Neue Protokoll-/Engine-Methoden `lernUebersicht() -> KalkulationsLernStand` und
  `promote(candidateID:)`. `KalkulationsLernStand`/`KalkulationsFaktor`/
  `KalkulationsKandidat` sind neue Sendable-Value-Types in MykilosKit — die Core-Typen
  (`CalibrationFactorCandidate` etc.) leaken NICHT ins Widget (das MykilosKalkulationsCore
  nicht importieren darf). `KalkulationsEngine.mapLernStand` mappt die Kern-`LearningSummary`.
- `KalkulationsEngine.recordAdjustment` reicht `learn: lernen` an `appendAdjustment`
  durch; `promote` ruft `LearningStore.promoteCalibration` und schreibt einen `AuditEntry`
  mit `action: .calibrationPromoted` (Sentinel-`projectID` "kalkulation", da Kalibrierung
  projektübergreifend ist).
- `AuditEntry.Action.calibrationPromoted` ergänzt (rawValue-persistiert → migrationssicher).
- `KalkulationsWidget`: „Für künftige Schätzungen lernen"-Toggle an der ActionCard
  (setzt `lernen: true`) + neue ausklappbare Sektion „Gelernte Kalibrierung" mit allen
  Renderstates (loading / leer / Inhalt / Fehler): aktive Faktoren (grün), promotebare
  Kandidaten mit „Übernehmen"-Button → `engine.promote` → Bestätigung sichtbar,
  Outlier-Zähler dezent. Schreiben weiterhin nur bestätigungspflichtig über die Engine.

**Neuer Cold-Start-Test (Merge-Gate):** `lernLoopUeberlebtNeustartUndVerschiebtSchaetzung`
— 3× `recordAdjustment(lernen: true)` über die Engine (BaselineAnchorProvider für eine
echte, positive Baseline) → Kandidat → `promote` → frische Store-Instanz auf derselben
`learning.sqlite` → aktiver Faktor lesbar UND der `EvidenceBasedEstimator` nutzt ihn:
`mitteNetto` verschiebt sich messbar (+10 %) gegenüber der unkalibrierten Baseline.

**Berührte Daten:** nur lokale temporäre `learning.sqlite` in `NSTemporaryDirectory()`
(Test-Verzeichnisse, im `defer` gelöscht). Keine externen Daten (Airtable/Drive/Sevdesk)
gelesen oder geschrieben.

**Status:** Branch sauber, 198 Tests grün, keine Regressions, Token-Disziplin geprüft
(kein `.font(.system)`/`Color(red:)` im Widget). Kein Push ohne Freigabe von Johannes.

---

### 2026-06-28 · Claude Code (Opus 4.8, S15) — recordAdjustment-Flow + KalkulationsActionCard (Schritt 7)

**Pfad:** `/Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilOS6/`
**Branch:** `feat/kalkulation-record-adjustment` (abgezweigt von `feat/kalkulation-core-port`)
**Build:** ✅ | **Tests:** 197 grün (178 swift-testing + 19 XCTest)

**Was gemacht wurde:**
- `KalkulationsEngine.recordAdjustment` implementiert (vorher Stub): bestätigte
  Anpassung → `LearningStore.appendAdjustment` (append-only) + `AuditEntry`
  (`action: .estimateAdjusted`). `faktor → percentDelta = (faktor-1)*100`,
  `reason: .gutFeeling`, `target: .wholeEstimate`, `learn: false`, `grund → note`.
- `schaetze` persistiert jetzt die `EstimateSession` (`saveSession`) und gibt deren
  ID als neues Feld `KostenSchaetzung.schaetzungsID` zurück — vorher wurde keine
  Session persistiert, es gäbe keine ID, gegen die man eine Anpassung buchen kann.
- `AuditEntry.Action.estimateAdjusted` ergänzt (rawValue-persistiert → migrationssicher).
- `KalkulationsEngine.init` nimmt optionalen `auditStore`; `AppState` übergibt `audit`.
  In-Memory-Map `projektIDBySession` liefert das `projectID` für den Audit-Eintrag.
- `KalkulationsActionCard` im `KalkulationsWidget`: Faktor-Schieberegler + Freitext-
  Begründung + „Anpassung buchen"-Button + Statuszeile. Erscheint erst nach einer
  Schätzung, Bestätigungspflicht (kein Auto-Write), schreibt nur über die Engine.
- **Vorab-Commit** (eigener Commit): `WindowGuard.guardWindowPositionOnAppear()` +
  Verdrahtung in `ProjectDetailView` gegen Fenster-Drift durch async Widget-Loads
  (lag uncommitted im Worktree).

**Neuer Cold-Start-Test:** `recordAdjustmentUeberlebtNeustart` — Anpassung über den
echten Engine-Pfad geschrieben, nach Neustart aus frischer Store-Instanz lesbar.
Plus `recordAdjustmentBuchtAnpassungGegenSchaetzung` und
`recordAdjustmentMitUnbekannterSessionWirft` (Engine-Tests).

**Status:** Branch sauber, 197 Tests grün, keine Regressions. Kein Push ohne Freigabe.

---

### 2026-06-28 · Claude Code (Sonnet 4.6, S14) — KalkulationsWidget + Kalkulations-Tab (Schritt 6)

**Pfad:** `/Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilOS6/`
**Branch:** `feat/kalkulation-core-port`
**Build:** ✅ | **Tests:** 175 grün

**Was gemacht wurde:**
- `WidgetKind.kalkulation` in `WidgetFoundation.swift` ergänzt
- `SourceChip.swift` um `.kalkulation` → `"eurosign.square"` erweitert
- `WidgetContainer.swift` um `.kalkulation` → `.tasks` (Ocker-Akzent) erweitert
- `KalkulationsWidget.swift` neu: alle 6 Renderstates, Freitext-Eingabe, Schätz-Button,
  Min/Mitte/Max-Netto, Konfidenz-Badge, Top-3-Evidenzen, Kostenboden, Quellenzeile
- `AppModule.kalkulation` + `KalkulationsPageView` in `MykilOS6App.swift` (Sidebar-Tab
  nach "Angebote", ⌘6, reicht `appState.kalkulationsEngine` durch)
- `HANDOFF_KALKULATION_CORE_PORT.md` um Schritt 6 ergänzt

**Kein neues persistierbares Feature → kein neuer Cold-Start-Test nötig.**

---

### 2026-06-28 · Claude Code (Sonnet 4.6) — Session-Abschluss Kalkulations-Port + App-Preview

**Pfad:** `/Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilOS6/`
**Branch:** `feat/kalkulation-core-port`
**Build:** ✅ | **Tests:** 194 grün

**Was gemacht wurde:**
- **App-Preview** via `./script/build_and_run.sh` — App gestartet, Heute-Board mit
  personalisierten Begrüßung + Projekten + Navigation + Dark Mode vollständig funktionsfähig.
  Kein Crash durch die neu verdrahtete `KalkulationsEngine` in `AppState`. ✅
- **Handoff-Dokument** `docs/handoffs/HANDOFF_KALKULATION_CORE_PORT.md` erstellt:
  vollständige Dokumentation aller 5 Schritte (Verbatim-Prinzip, Cold-Start-Gate,
  Architektur-Entscheidungen, offene Stubs, Nächste Schritte).
- **CLAUDE.md** aktualisiert: Kalkulations-Port Schritt 5 in die Fortschritts-Tabelle
  eingetragen, Link auf Handoff gesetzt.
- **Session-Modus geändert:** Modell auf `claude-sonnet-4-6` für Abschluss-Session.

**Status:** Branch `feat/kalkulation-core-port` ist sauber, 194 Tests grün,
kein Push ohne Johannes' Freigabe.

**Offene Stubs (bewusst, kein Merge-Blocker):**
- `importPDF` → braucht `GoogleDriveClient.downloadFile()`
- `recordAdjustment` → braucht ActionCard → Bestätigungs-Flow (UI-Schritt)

**Nächste natürliche Schritte (nach Freigabe):**
1. Kalkulations-Widget / UI (`KalkulationsView`-Tab, `KalkulationsActionCard`)
2. Seed-Provider mit destillierten Ankern (SQLite + CSVs aus mykilO$ App-Support)
3. PREISLISTEN CSV nach Application-Support kopieren (explizite Freigabe)

---

### 2026-06-28 · Claude Code (Opus 4.8) — Engine in AppState verdrahtet + Baseline-Anker (Schritt 5)

**Pfad:** `/Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilOS6/`
**Branch:** `feat/kalkulation-core-port`
**Build:** ✅ | **Tests:** 194 grün (175 swift-testing + 19 XCTest)

**Was gemacht wurde:**
- `BaselineAnchors.swift` verbatim portiert (6 hartcodierte Regelanker, Foundation-only,
  KEINE externen Daten) + eigener `BaselineAnchorProvider: PriceAnchorProviding`.
- **`AppState.kalkulationsEngine` live verdrahtet** (konstruiertes `let`, Muster wie
  `assistantLLM`): `KalkulationsEngine(provider: BaselineAnchorProvider(),
  learningStore: LearningStore(), deviceCatalog: DeviceCatalog.loadDefault())`.
  → Die Engine ist jetzt Teil der laufenden App und liefert echte konservative
  Schätzungen ohne externe Datei; `geraetepreis` wird real, sobald die Preisbuch-CSV
  in Application-Support liegt.
- Test `schaetzeMitBaselineAnkernLiefertEchteZahlen`: mitteNetto > 0, evidenceCount > 0,
  min ≤ mitte ≤ max — beweist den nicht-leeren Pfad.
- SwiftLint-Ausnahme um `BaselineAnchors.swift` erweitert (vendored); `BaselineAnchorProvider`
  ist eigener Code, voll gelintet.

**Doku-Hinweis:** Johannes' Airtable-Entscheidung (1 Base bleibt, Airtable=Master/GRDB=Cache)
in CLAUDE.md + IDEEN_UND_BACKLOG.md bleibt seine uncommittete Änderung — bewusst nicht in
diesem Commit gemischt.

**Adapter-Stand:** `schaetze` ✅ + `geraetepreis` ✅ live in der App. Stubs: `importPDF` (Drive),
`recordAdjustment` (Bestätigungs-Flow). Kein Push ohne Freigabe.

---

### 2026-06-28 · Claude Code (Opus 4.8) — DeviceCatalog + `geraetepreis` live (Schritt 4)

**Pfad:** `/Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilOS6/`
**Branch:** `feat/kalkulation-core-port`
**Build:** ✅ | **Tests:** 193 grün (174 swift-testing + 19 XCTest)

**Was gemacht wurde:**
- `DeviceCatalog.swift` + `CSVParser.swift` verbatim aus mykilO$$ `KalkulationsData` nach
  `MykilosServices/Kalkulation/` portiert (Import → `MykilosKalkulationsCore`). CSV-backed,
  tolerante Spaltenerkennung, Token-Score-Suche, Daten liegen in Application-Support (nie im Repo).
- **`geraetepreis(suchbegriff:)` scharf geschaltet:** `KalkulationsEngine` nimmt optional einen
  injizierten `DeviceCatalog`; `geraetepreis` → `search().first?.sellNet` (MYKILOS-VK vor Liste) →
  Double. Ohne Katalog weiterhin nil (optionaler Lookup, kein Crash).
- **Tests:** 3 synthetische DeviceCatalog-Port-Tests (parse/BOM/Suche, in-memory) + 1 Engine-Test
  (`geraetepreis` mit injiziertem Katalog → 2190; Fehlsuche → nil). Der mykilO$$-Import-Test
  (`importCatalog`→defaultURL) bewusst NICHT übernommen — würde an den echten App-Support-Pfad
  schreiben und reale Daten berühren.
- SwiftLint-Ausnahme um die 2 neuen vendored Dateien erweitert.

**Datensicherheit:** Das echte Preisbuch (PREISLISTEN-CSV, 13.419 Artikel mit EK-Preisen) bleibt
extern (`~/Library/Application Support/MYKILOS/Kalkulationslabor/Devices/catalog.csv`), nie im Repo.
Das tatsächliche Laden der echten CSV ist ein separater Daten-Schritt (Johannes' Freigabe).

**Adapter-Stand:** `schaetze` ✅ + `geraetepreis` ✅ | Stubs: `importPDF` (Drive-Download),
`recordAdjustment` (Persistenz/Bestätigungs-Flow). Kein Push ohne Freigabe.

---

### 2026-06-28 · Claude Code (Opus 4.8) — Contract + Engine-Adapter (Schritt 3)

**Pfad:** `/Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilOS6/`
**Branch:** `feat/kalkulation-core-port`
**Build:** ✅ | **Tests:** 189 grün (173 swift-testing + 16 XCTest)

**Team-Abstimmung (S10-Kanal):** niemand konsolidiert die Basis; ich cherry-picke nur was ich
brauche; kanonische Basis = `stabilize`/mein Branch; `recordAdjustment` = **String**; ich besitze
den Engine-Port allein.

**Was gemacht wurde:**
- **Contract übernommen:** `Sources/MykilosKit/Domain/KalkulationsEngineProviding.swift` aus PR #1
  (`claude/musing-sammet`) auf die kanonische Basis geholt. Einzige Änderung: `recordAdjustment(
  schaetzungsID:)` von `UUID` → **`String`** (stabiler Schlüssel = `EstimateSession.id`). Nur die
  Datei übernommen (nicht der ganze Commit — der AppState-Slot würde auf `stabilize` kollidieren).
- **Engine-Adapter:** `Sources/MykilosServices/Kalkulation/KalkulationsEngine.swift` (`actor`,
  conformt `KalkulationsEngineProviding`). `schaetze` voll implementiert: `parse → estimate →
  Mapping EstimateResult→KostenSchaetzung` (inkl. Kostenboden aus `bottomUpCost.total`,
  Div-by-Zero-Guard für `kostenbodenRatio`, EvidenceCase→PriceEvidence).
- **Bewusste Stubs (eigene Folgeschritte, werfen klar `KalkulationsEngineError.notYetImplemented`):**
  `geraetepreis` (DeviceCatalog fehlt), `importPDF` (Drive-Download fehlt), `recordAdjustment`
  (braucht persistierte Session + Reason/Target-Mapping + Bestätigungs-Flow).
- **Tests:** `KalkulationsEngineTests` (Stub-Anker, seed-frei): Mapping-Verdrahtung + Guard +
  dass die Stubs sauber werfen.
- SwiftLint: Lern-Schicht-Ausnahme auf die **3 vendored Dateien** verengt — eigener Adapter-Code
  in `Kalkulation/` ist voll gelintet.

**Nächste Schritte:** (5) Seed-Provider `BrainSeedRepository`/`DeviceCatalog` — braucht Seed-`sqlite`
+ CSVs nach Application-Support (externe Daten, Johannes' Freigabe). (4b) `recordAdjustment`
vervollständigen, wenn Persistenz-/Bestätigungs-Flow steht. Kein Push ohne Freigabe.

---

### 2026-06-28 · Claude Code (Opus 4.8) — Kalkulations-Lern-Schicht portiert (Schritt 2)

**Pfad:** `/Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilOS6/`
**Branch:** `feat/kalkulation-core-port`
**Build:** ✅ | **Tests:** 187 grün (171 swift-testing inkl. 2 Cold-Start + 16 XCTest)

**Was gemacht wurde — Port-Reihenfolge Schritt 2 (GRDB-Lern-Schicht):**
- `Sources/MykilosServices/Kalkulation/` mit 3 verbatim portierten Dateien aus mykilO$$
  `KalkulationsData`: `LearningDatabase.swift` (GRDB-Queue, WAL, additiver Migrator v1–v3,
  `inMemory()`), `LearningRecords.swift` (GRDB-Records + `LearningCodec` + DB-Extensions +
  JSONL-Import), `LearningStore.swift` (append-only High-Level-API, `CalibrationFactorProviding`).
- Einzige Änderungen am verbatim-Port: `import KalkulationsCore` → `import MykilosKalkulationsCore`;
  modul-internes `AuditRecord` → `LearningAuditRecord` umbenannt (Kollision mit bestehendem
  `AuditRecord` in MykilosServices).
- **Cold-Start-Test = Merge-Gate erfüllt:** neue `KalkulationsLearningStoreTests` —
  `lernDatenUeberlebenNeustart` (schreiben → zweite Store-Instanz öffnet dieselbe
  `learning.sqlite` von Platte → identisch) + `appendOnlyBleibtNachNeustartErhalten`.
  `MykilosKalkulationsCore` an die Test-Target-Deps gehängt.
- SwiftLint: `Sources/MykilosServices/Kalkulation` als vendored ausgenommen (3 Zeilen > 200);
  Rest von MykilosServices bleibt voll gelintet.

**Bewusst NICHT in diesem Schritt:** `BrainSeedRepository`/`DeviceCatalog`/CSV/`ImportService`
(brauchen externe Seed-Dateien) und `AirtableSyncService` (wird gelöscht, 3 Regelverstöße).
Engine-Adapter (`KalkulationsEngine: KalkulationsEngineProviding`, `parse → estimate`, id als
String), AppState-Verdrahtung, UI → Schritt 4+.

**Basis-Konflikt bleibt offen (siehe Schritt-1-Eintrag):** PR #1 (`claude/musing-sammet`,
~97-Test-Basis) hält das Contract/Protokoll, mein `stabilize`-Stand nicht. Schritt 2 brauchte
das Protokoll NICHT (reine Persistenz). Vor Schritt 4 (Engine-Adapter conformt das Protokoll)
muss EINE kanonische Basis hergestellt werden. Kein Push ohne Johannes' Freigabe.

---

### 2026-06-28 · Claude Code (Opus 4.8) — mykilO$$ Kalkulations-Core portiert (Schritt 1)

**Pfad:** `/Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilOS6/`
**Branch:** `feat/kalkulation-core-port` (aus `stabilize/from-0b7c366-2026-06-28`)
**Build:** ✅ | **Tests:** 185 grün (169 swift-testing + 16 portierte XCTest)

**Was gemacht wurde — Port-Reihenfolge Schritt 1 (HANDOFF_LIVE_WIRING_5.md Teil 3):**
- Neues Foundation-only-Target **`MykilosKalkulationsCore`** (Geschwister zu `MykilosKit`).
- **10 Dateien verbatim** aus mykilO$$ `KalkulationsCore` portiert: AirtableOffer,
  BottomUpCost, ComponentResolver, Estimation, LearningModels, MaterialLexicon,
  Models, Parsing, Review, Version. Foundation-only am Code verifiziert (nur `import Foundation`).
- `MykilosServices` hängt jetzt von `MykilosKalkulationsCore` ab (Zielzustand für die GRDB-Adapter).
- **16 reine Core-Tests portiert** (ParserTests 4 + MaterialLexiconTests 12) als neues
  Test-Target `MykilosKalkulationsCoreTests`. Einzige Änderung: Modulname im `@testable import`.
- SwiftLint: `Sources/MykilosKalkulationsCore` als vendored ausgenommen (verbatim-Tabellen
  sprengen `line_length` absichtlich; kein SwiftUI → Token-Custom-Rules n/a).

**Bewusst NICHT in diesem Schritt (= eigene PRs danach):**
- KalkulationsData/GRDB-Schicht: `LearningStore`/`LearningDatabase` (eigene `learning.sqlite`),
  `BrainSeedAnchorProvider`, `DeviceCatalog` → Schritt 2 + **Cold-Start-Test (Merge-Gate)**.
- 14 Integrations-Tests (Estimator/Calibration) — brauchen die Data-Schicht + Seed-Dateien.
- `KalkulationsEngine`-Adapter (`parse → estimate`, id als String), AppState-Verdrahtung, UI.
- Seed-`sqlite` (11 MB) + 4 CSVs aus dem mykilO$$-Tree nach Application-Support (externe Daten).

**Offen / Übergabe:** Reconciliation `recordAdjustment(schaetzungsID:)` UUID→String steht noch aus
(Teil 3); Destillation V2-Swift-Pipeline ist entschieden, aber noch nicht gebaut.
Kein Push ohne Johannes' Freigabe.

---

### 2026-06-28 · Claude Code Desktop — Verbindungscheck + Session-Abschluss

**Pfad:** `/Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilOS6/`
**Branch:** `stabilize/from-0b7c366-2026-06-28`
**Build:** ✅ | **Tests:** 169 grün

**Verbindungscheck (alle Keychain-Einträge geprüft):**

| Service | Keychain | Live-API |
|---|---|---|
| Airtable | ✅ PAT + baseID = `appuVMh3KDfKw4OoQ` | ✅ Kunden, Projekte, Clockodo-Nutzer, Clockodo-Leistungen |
| Claude | ✅ API-Key + Modell `claude-sonnet-4-6` | ✅ |
| Google | ✅ OAuth-Token vorhanden | in App prüfen |
| Clockodo | ✅ `johannes@mykilos.com` | in App prüfen |
| ClickUp | ✅ API-Key vorhanden | in App prüfen |
| Sevdesk | ✅ (NO-GO — nicht live geprüft) | — |

**Airtable-Bug behoben:** `baseID` im Keychain enthält jetzt korrekt `appuVMh3KDfKw4OoQ`
(zuvor fälschlich zweiten PAT-Token — von Johannes manuell in App → Einstellungen korrigiert).

**Abgeschlossen diese Session:**
- Eiserne Regel in CLAUDE.md
- EREIGNISPROTOKOLL.md angelegt (dieses Dokument)
- Alle Memories aktualisiert (canonical-folder-rule, project-current-state, airtable-keychain-bug)
- Startprompt + Modell-Empfehlung für nächste Session geschrieben

**Finaler Handoff:** `docs/handoffs/HANDOFF_SESSION_ABSCHLUSS_2026-06-28.md`

---

### 2026-06-28 · Claude Code Desktop — Eiserne Regel + Ereignisprotokoll

**Pfad:** `/Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilOS6/`
**Branch:** `stabilize/from-0b7c366-2026-06-28`
**Build:** ✅ (Build complete)
**Tests:** 169 grün

**Was passiert ist:**
- Neue EISERNE REGEL in `CLAUDE.md` eingetragen: kanonischer Pfad, Branch-Pflichtcheck,
  Handoff-Header-Pflicht. Verhindert künftig die Ordner-/Branch-Konfusion.
- Dieses `EREIGNISPROTOKOLL.md` angelegt als dauerhaftes Nachverfolgungsdokument.

**Offene Punkte aus dieser Session:**
- `sprint/shared-drive-widget-oauth` hat Session-Docs-Commits (4b3df08, 8c28443) die noch
  nicht auf `stabilize/` sind. Inhalt: Codex-Handoffs, Drive-Tab-Docs, Orientierungs-Docs.
  → Codex oder Johannes: prüfen ob diese Docs nach `stabilize/` oder `main` gemergt werden.
- `ProjectFilesTabView.swift` aus Worktree wurde in `sprint/shared-drive-widget-oauth` committed.
  Aber der Hauptordner hat bereits `FilesTabView.swift` (fortgeschrittener). Duplikat aufräumen.

---

### 2026-06-28 · Codex — Forensic Recovery Point

**Pfad:** `/Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilOS6/`
**Branch:** `stabilize/from-0b7c366-2026-06-28` (neu erstellt von Codex)
**Build:** ✅
**Tests:** 169 grün
**Commit:** `130e6c0 docs: mark forensic recovery point from 0b7c366`

**Was passiert ist:**
- Codex hat den Branch `stabilize/from-0b7c366-2026-06-28` von `0b7c366` aus erstellt.
- Keine Code-Änderungen. Nur forensische Dokumentation des letzten bekannten guten Stands.
- Ergebnis: 169 Tests grün, Build grün, stabiler Ausgangspunkt gesichert.

---

### 2026-06-27/28 · Claude Code Desktop (Session musing-sammet-3abd94) — Worktree-Ordner-Konfusion

**Pfad (Worktree):** `~/Desktop/CLAUDE/_mykilOS/mykilOS6/musing-sammet-3abd94/`
**Pfad (Ziel):** `/Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilOS6/`
**Branch Worktree:** `claude/musing-sammet-3abd94`
**Branch Hauptordner:** `sprint/shared-drive-widget-oauth`

**Was passiert ist (Problem):**
- Claude Code Desktop-Session arbeitete im temporären Worktree unter Desktop/CLAUDE/.
- Der Worktree war auf einem ÄLTEREN Commit-Stand basierend auf `main` (~97 Tests, Version 6.0.x).
- Der Hauptordner (gelber MYKILOS-6-Ordner) war bereits auf `sprint/shared-drive-widget-oauth`
  mit Version 6.3.0 und 169 Tests.
- Dateien wurden vom Worktree in den Hauptordner kopiert (`feat: sync all session work`).
- Dabei wurden ÄLTERE Dateien auf neuere Versionen kopiert — potenzielle Regression.

**Betroffene Dateien (kopiert von alt → neu, Risiko):**
- `AppState.swift` — Worktree-Version OHNE `chat`, `conversation`, `profile`, `pendingProjectSelection`
  wurde auf die Hauptordner-Version MIT diesen Feldern kopiert. Hätte Build brechen können.
  **Stand nach Analyse:** Build war zu diesem Zeitpunkt auf `stabilize/` bereits 169-Test-grün.
  Die Kopier-Commits landeten nur auf `sprint/shared-drive-widget-oauth`, nicht auf `stabilize/`.
- `DriveWidget.swift` — Ältere Worktree-Version, fehlte Signal-Emission. Neu hinzugefügt.
- `ProjectDetailView.swift` — Ältere Version. Überschrieben.

**Ergebnis:**
- Auf `sprint/shared-drive-widget-oauth`: mögliche Regression durch ältere Datei-Kopien.
- Auf `stabilize/from-0b7c366-2026-06-28`: UNBESCHÄDIGT, weil Kopier-Commits nur auf `sprint/` gingen.
- **Empfehlung:** `sprint/shared-drive-widget-oauth` vor weiterem Merge gründlich `swift build + swift test` prüfen.

**Neu erstellt in dieser Session (im Worktree, danach auf sprint/ committet):**
- `Sources/MykilosApp/Detail/ProjectFilesTabView.swift` — Drive-Browser (ABER: Hauptordner hat bereits `FilesTabView.swift` mit gleicher Funktion + mehr Features)
- `script/airtable_verify.sh` — Prüfskript für alle Airtable-Tabellen
- `docs/handoffs/MASTER_HANDOFF_CODEX.md` — Codex-Gesamtbauplan
- `docs/handoffs/CODEX_ORIENTATION.md` — Wer ist Johannes, Tools, Konnektoren
- `docs/handoffs/CODEX_START_PROMPT.md` — Copy-paste Startprompt
- `docs/handoffs/CODEX_SESSIONS.md` — Session-Übersicht A–F
- `docs/handoffs/CODEX_HANDOFF_KALKULATION.md` — Kalkulations-Port-Anleitung

**Bekanntes Problem identifiziert:**
- Keychain-Feld `baseID` enthält fälschlich einen zweiten PAT-Token statt der echten Base-ID.
- Fix: App öffnen → Einstellungen → Airtable → Base-ID = `appuVMh3KDfKw4OoQ` eintragen.
- **Johannes muss das manuell korrigieren.**

---

### 2026-06-27 · Claude Code Desktop — Live-Wiring Session 3 (BrandsView-Fix)

**Pfad:** `/Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilOS6/`
**Branch:** `sprint/shared-drive-widget-oauth`
**Build:** ✅ | **Tests:** 169 grün
**Handoff:** [HANDOFF_LIVE_WIRING_3.md](handoffs/HANDOFF_LIVE_WIRING_3.md)

**Was passiert ist:**
- `BrandsView`-Navigationsbug behoben: `@FocusedBinding` war `nil` bei inaktivem Fenster →
  Klick auf "Einstellungen" in BrandsView tat nichts. Fix: `onNavigateToSettings`-Callback.
- Version `6.3.0` · 169 Tests grün.
- Live-App-Tour: OAuth-Handshake dokumentiert, erster echter Google-Login-Flow beobachtet.

**Offene Punkte:**
- Google OAuth live noch nicht mit echtem Account vollständig durchlaufen (nur Token-Exchange beobachtet)
- Streaming bei toolsEnabled=true: nicht-streaming wenn Claude keine Tools aufruft (V1 ok)
- CalendarActionCard-Persistenz: korrekt und gewollt, aber noch nicht live-getestet

---

### 2026-06-27 · Claude Code Desktop — Post-Akt-5 Aufgaben 15–21 (Release 6.3.0)

**Pfad:** `/Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilOS6/`
**Branch:** `sprint/shared-drive-widget-oauth` (und Vorgänger-Branches)
**Build:** ✅ | **Tests:** 169 grün
**Handoff:** [HANDOFF_POST_AKT5_15_SURFACE_COMPLETION.md](handoffs/HANDOFF_POST_AKT5_15_SURFACE_COMPLETION.md)

**Was diese Aufgaben gebracht haben:**
- **Aufg. 15** — Projekt-Assistent-Tab: `AssistantChatView` scoped auf `project.projectNumber`
- **Aufg. 16** — Profil-Sektion in Settings: Name + Rolle direkt editierbar
- **Aufg. 17** — `GlobalOffersView`: Angebote als globales Sidebar-Modul
- **Aufg. 18** — `FilesTabView` (Drive-Dateien-Browser) + `BrandsView` (Integrations-Dashboard)
- **Aufg. 19** — UX-Polishing: Begrüßung, Cmd+1..6, Signal-Strip, Sidebar-Profil
- **Aufg. 20** — Phase 3: `SuggestCalendarEventTool` + `CalendarActionCard` (URL → Browser)
- **Aufg. 21** — Signal-Badges in Galerie, projektspezifische Beispielfragen

---

### 2026-06-27 · Claude Code Desktop — Post-Akt-5 Aufgaben 12–14 (Release 6.1–6.2)

**Handoff:** [HANDOFF_POST_AKT5_12_ASSISTANT_PLAN.md](handoffs/HANDOFF_POST_AKT5_12_ASSISTANT_PLAN.md) /
[HANDOFF_POST_AKT5_13_ASSISTANT_RELEASE.md](handoffs/HANDOFF_POST_AKT5_13_ASSISTANT_RELEASE.md) /
[HANDOFF_POST_AKT5_14_BUGFIXES.md](handoffs/HANDOFF_POST_AKT5_14_BUGFIXES.md)

- **Aufg. 12** — Konversationeller Assistent: `ChatStore`, `ConversationEngine`, Multi-Turn-Chat,
  Tool-Use mit Gmail-Labels und Kalender (read-only, Opt-in). 155 Tests, Version 6.1.0.
- **Aufg. 13** — First-Run-Onboarding-Wizard + `UserProfile`/`ProfileStore`. 158 Tests.
- **Aufg. 14** — SSE-Streaming live-tippend, UserProfile im System-Prompt, 2 Bugfixes:
  Integer-Decode-Bug in Tool-Inputs, Wizard ohne Schließen-Button. 163 Tests, Version 6.2.0.

---

### 2026-06-26/27 · Codex — Post-Akt-5 Aufgaben 9–11 (Stabilisierung)

**Handoff:** [HANDOFF_POST_AKT5_11.md](handoffs/HANDOFF_POST_AKT5_11.md)

- **Aufg. 9** — `DriveOfferWatcher`: Polling auf Drive → `offerDetected`-Signal, Baseline-Semantik
- **Aufg. 10** — Angebote-Tab live: Belege aus Drive via `DriveOfferWatcher.detectOffers`
- **Aufg. 11** — Kritische Crash-Fixes:
  - Projektdetail-Crash (100% reproduzierbar auf macOS 26): content-dimensioniertes Fenster +
    `.move`-Transition → `Update-Constraints`-Endlosschleife. Fix: `.opacity`-Transition +
    `WindowGuard` + feste Mindestrahmen an ContentView.
  - Galerie-Hang ("Lade Projekte…"): `RegistryStore` lief nicht auf `@MainActor`. Fix: `@MainActor`.
  - Multi-Agent-Bug-Audit: Notiz-Datenverlust, Signal-Leck, Loader-Races u.a. behoben.
  - 118 Tests, live verifiziert.

---

### 2026-06-26 · Codex — Live-Wiring Sessions 1–2

**Handoffs:** [HANDOFF_LIVE_WIRING_1.md](handoffs/HANDOFF_LIVE_WIRING_1.md) /
[HANDOFF_LIVE_WIRING_2.md](handoffs/HANDOFF_LIVE_WIRING_2.md)

- **Wiring 1**: Airtable "mykilOS Mastermind" (Schema + 69 Records live), 31 echte Projekte
  statt DemoSeed, Force-Poll-Buttons, Angebote-Tab-Bugfix.
- **Wiring 2**: Google-Login client_secret-Fix, Fenster-Drift-Guard (WindowGuard.swift),
  Projekt-Favoriten klickbar (heute → projektdetail), Drive-Routing über alle 31 Projekte.
  **Status: Alle code-fertig, Live-Verifikation mit echtem Account ausstehend.**

---

## Bekannte offene Punkte (Stand 2026-06-28)

### Sofort — erfordert Johannes' Aktion

| # | Was | Warum dringend |
|---|---|---|
| 1 | Airtable-Keychain-Bug: App → Einstellungen → Airtable → Base-ID = `appuVMh3KDfKw4OoQ` | Alle Airtable-Checks scheitern (404). `baseID` im Keychain enthält fälschlich PAT. |
| 2 | Google OAuth vollständig live testen (Drive, Kalender, Mail) | Noch nicht mit echtem Account end-to-end durchlaufen |
| 3 | Branch-Merge: `sprint/shared-drive-widget-oauth` → `main` beschließen | Drei Feature-Branches divergieren |

### Technisch offen (kein Blocker für Beta)

| # | Was | Details |
|---|---|---|
| 4 | `ProjectFilesTabView.swift` auf `sprint/` ist Duplikat von `FilesTabView.swift` | Aufräumen nach Merge |
| 5 | Clockodo-Widget zeigt Demo-Daten, keine echten Zeiten | `ClockodoClient` implementiert, aber nicht mit echtem User-Token live |
| 6 | `ProjectFilesTabView.swift` nutzt älteres Render-Pattern | `FilesTabView.swift` hat Generation-Token für Race-Freiheit — Pattern angleichen |
| 7 | `airtable_verify.sh` warnt bei falscher Base-ID, gibt aber nur Fallback-ID | Muss nach Keychain-Fix (Punkt 1) erneut getestet werden |
| 8 | Streaming bei toolsEnabled=true ist non-streaming wenn Claude keine Tools nutzt | V1 akzeptabel, aber sichtbar für den Nutzer |
| 9 | mykilO$$ Kalkulations-Core-Target (MykilosKalkulationsCore) noch nicht portiert | `KalkulationsEngineProviding`-Protokoll + nil-Slot existieren, aber 10 Dateien fehlen noch |
| 10 | Clockodo Zuhörer (Chat → Zeitbuchung → Draft → Wochenabschluss → POST) | Live-Wiring Session 4, noch nicht begonnen |

### Architektur-Hinweise für nächste Session

- `MykilosKit` darf NIE SwiftUI oder GRDB importieren
- `MykilosWidgets` darf NIE GRDB importieren
- Sevdesk: vollständiger NO-GO (nicht in Tool-Whitelist, nicht lesen, nicht schreiben)
- Signale sind VORSCHLÄGE — Schreiben immer nur über ActionCard → Bestätigung → AuditEntry
- Jede neue Persistenz: Cold-Start-Test ist Merge-Gate

---

## Airtable-Mastermind-Base (appuVMh3KDfKw4OoQ) — Live-Tabellen

| Tabelle | ID | Status |
|---|---|---|
| Kunden | `tblXXX` (→ per Verify ermitteln) | Live, 69 Records |
| Projekte | `tblYYY` | Live, 31 Projekte |
| Clockodo-Nutzer | `tblPbly2br8mR2kaU` | Live, 4 Team-Mitglieder |
| Clockodo-Buchungen | `tblYQxlauwej7FD1w` | Live |
| Clockodo-Leistungen | `tblRtsegocdpM8CJd` | Live, 8 Services |
| Kalkulationen | `tblO3y2jdmxDnuiZj` | Live |
| Kalkulations-Positionen | `tblNamx3cHTus6gtk` | Live |
| Eingehende-Angebote | `tbliKfs5FnufjdB36` | Live |
| Preis-Beobachtungen | (noch nicht angelegt) | Geplant für mykilO$$-Destillation |

**PAT im Keychain:** `security find-generic-password -s "com.mykilos6.airtable" -a "pat" -w`

---

## Keychain-Service-Namen (vollständig)

| Service | Account | Inhalt |
|---|---|---|
| `com.mykilos6.airtable` | `pat` | Airtable PAT |
| `com.mykilos6.airtable` | `baseID` | ⚠️ enthält fälschlich zweiten PAT — muss `appuVMh3KDfKw4OoQ` sein |
| `com.mykilos6.google` | — | Google OAuth Tokens |
| `com.mykilos6.clockodo` | — | Clockodo API-Key |
| `com.mykilos6.claude` | `apiKey` | Anthropic API-Key |
| `com.mykilos6.claude` | `model` | Default: `claude-sonnet-4-6` |
| `com.mykilos6.clickup` | — | ClickUp API-Key |

---

_Letzter Eintrag: 2026-06-28 · Claude Code Desktop_
_Nächster Eintrag bitte am Anfang der Einträge-Liste hinzufügen (neueste zuerst)._
