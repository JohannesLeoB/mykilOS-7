# Handoff: mykilO$ Kalkulations-Core Port (Schritte 1–7)

```
Pfad:   /Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilOS Mac/
Branch: feat/kalkulation-record-adjustment (Schritt 7) / feat/kalkulation-core-port (1–6)
Build:  ✅ swift build grün
Tests:  ✅ 197 Tests grün (178 swift-testing + 19 XCTest)
Datum:  2026-06-28
```

---

## Ziel

Den Schätz-Brain aus der separaten mykilO$-App (Swift Package `KalkulationsCore`)
vollständig in mykilOS 6 portieren, so dass `AppState.kalkulationsEngine` live
Schätzungen liefert — Foundation-only-Kern, GRDB-Lernschicht, Actor-Adapter,
DeviceCatalog, Baseline-Anker — alles ohne externe Datei-Abhängigkeiten im
Normalfall.

---

## Schritte (chronologisch, alle ✅)

### Schritt 1 — KalkulationsCore: Foundation-only Target

**Commit:** `d1d8f4b`

Neues SPM-Target `MykilosKalkulationsCore`:
- 10 Dateien verbatim aus mykilO$ portiert
  (`AirtableOffer`, `BottomUpCost`, `ComponentResolver`, `Estimation`,
  `LearningModels`, `MaterialLexicon`, `Models`, `Parsing`, `Review`, `Version`)
- Alle nur `import Foundation` — kein GRDB, kein SwiftUI
- Package.swift: neues Target + `MykilosKalkulationsCoreTests`
- 16 portierte Tests (XCTest): `ParserTests` (4) + `MaterialLexiconTests` (12)
- Einzige Änderung in den portierten Dateien: `import KalkulationsCore` →
  `import MykilosKalkulationsCore`

**Ergebnis:** 175 Tests grün.

---

### Schritt 2 — GRDB-Lernschicht

**Commit:** `8d86405`

Neue Dateien in `Sources/MykilosServices/Kalkulation/`:
- `LearningDatabase.swift` — GRDB `DatabaseQueue`, WAL, FK ON, additive
  Migrator v1–v3 (Sessions, Komponenten, Adjustments, Imports-SHA256-Dedup,
  Airtable-Offer-Sync); `inMemory()` für Tests
- `LearningRecords.swift` — alle GRDB `FetchableRecord/PersistableRecord`-Structs;
  `AuditRecord` → **`LearningAuditRecord`** (Kollision mit bestehendem
  `AuditRecord` in MykilosServices)
- `LearningStore.swift` — High-Level-API, append-only (`saveSession`,
  `appendAdjustment`, `promoteCalibration`), `CalibrationFactorProviding`

**SwiftLint:** vendored Dateien (LearningDatabase, LearningRecords, LearningStore)
zu `.swiftlint.yml`-`excluded` hinzugefügt (Daten-Tabellen mit Zeilen bis 700 Zeichen).

**Tests:** `KalkulationsLearningStoreTests.swift` (swift-testing):
- `lernDatenUeberlebenNeustart` — **Cold-Start-Merge-Gate** ✅
- `appendOnlyBleibtNachNeustartErhalten` — 2 Adjustments überleben Neustart

**Ergebnis:** 187 Tests grün.

---

### Schritt 3 — KalkulationsEngineProviding + Engine-Adapter

**Commit:** `c64a404`

- `Sources/MykilosKit/Domain/KalkulationsEngineProviding.swift` (neues Public-Protokoll):
  - `schaetze(projektID:, freitext:) async throws -> KostenSchaetzung`
  - `geraetepreis(suchbegriff:) async -> Double?`
  - `importPDF(driveFileID:, projektID:) async throws` (Stub)
  - `recordAdjustment(schaetzungsID: String, faktor:, grund:) async throws` (Stub —
    **String, nicht UUID** — matcht `EstimateSession.id` in LearningDatabase)
  - `KostenSchaetzung` + `PriceEvidence` (Sendable Value-Types)
- `Sources/MykilosServices/Kalkulation/KalkulationsEngine.swift` (neuer `actor`):
  - Nimmt `PriceAnchorProviding` + `LearningStore` + optionalen `DeviceCatalog`
  - `schaetze`: `EstimateRequestParser.parse()` → `EvidenceBasedEstimator.estimate()`
    → `Self.map()` → `KostenSchaetzung`; div-by-zero-Guard (`kostenbodenRatio`)
  - `geraetepreis`: nil ohne Katalog, sonst `search().first?.sellNet`
  - `importPDF` / `recordAdjustment`: werfen `KalkulationsEngineError.notYetImplemented`

**Tests:** `KalkulationsEngineTests.swift` (swift-testing, 4 Tests):
- `schaetzeLiefertGemappteKostenSchaetzung` — StubProvider → Mapping korrekt, kein Crash
- `nochNichtVerdrahteteFaehigkeitenWerfenKlar` — Stubs werfen, nil-Katalog → nil
- `schaetzeMitBaselineAnkernLiefertEchteZahlen` — BaselineProvider → mitteNetto > 0
- `geraetepreisLiefertPreisAusInjiziertemKatalog` — synthetischer Katalog → 2190 / nil

**Ergebnis:** 189 Tests grün.

---

### Schritt 4 — DeviceCatalog + CSVParser

**Commit:** `e268f2d`

- `CSVParser.swift` + `DeviceCatalog.swift` verbatim nach `MykilosServices/Kalkulation/`
  portiert (Import: `MykilosKalkulationsCore`).
  - `DeviceCatalogEntry.sellNet`: bevorzugt `mykilosNet` vor Listenpreis
  - `DeviceCatalog.defaultURL()`: `~/Library/Application Support/MYKILOS/Kalkulationslabor/Devices/catalog.csv`
  - `DeviceCatalog.loadDefault()`: nil wenn CSV nicht vorhanden — kein Crash
- SwiftLint: `CSVParser.swift` + `DeviceCatalog.swift` zu `excluded` hinzugefügt.
- Tests: `DeviceCatalogTests.swift` (XCTest, 3 synthetische Tests) — **keine echten Preisdaten**;
  zusätzlicher Engine-Test `geraetepreisLiefertPreisAusInjiziertemKatalog`

**Ergebnis:** 193 Tests grün. `geraetepreis` live wenn `catalog.csv` in Application-Support.

---

### Schritt 5 — BaselineAnchorProvider + AppState live

**Commit:** `d465b49`

- `BaselineAnchors.swift` verbatim portiert (6 hartcodierte Regelanker, Foundation-only,
  keine externen Dateien): 60 cm Unterschrank Tür/Fachboden (820), Schubkasten (1250),
  Legrabox (180), Eiche-Aufpreis (140), Linoleum/lm (680), Edelstahl/m² (950)
- `BaselineAnchorProvider.swift` (eigener Code, gelintet):
  `struct BaselineAnchorProvider: PriceAnchorProviding`
- `AppState.kalkulationsEngine` live verdrahtet:
  ```swift
  self.kalkulationsEngine = KalkulationsEngine(
      provider: BaselineAnchorProvider(),
      learningStore: LearningStore(),
      deviceCatalog: DeviceCatalog.loadDefault()
  )
  ```
- SwiftLint: `BaselineAnchors.swift` zu `excluded` hinzugefügt.

**App-Preview (2026-06-28):**
Build via `./script/build_and_run.sh` → App gestartet → **Heute-Board, Projekte,
Navigation, Dark Mode — alles funktioniert**. Kein Crash durch die neu verdrahtete
Engine. `schaetze` liefert echte konservative Schätzungen bereits mit Baseline-Ankern.

**Ergebnis:** 194 Tests grün. Engine ist live in der App.

---

## Offene Stubs (bewusst, kein Blocker für diesen PR)

| Methode | Blocker | Nächster Schritt |
|---|---|---|
| `importPDF` | `GoogleDriveClient.downloadFile()` fehlt | Nach Drive-Ausbau |

`recordAdjustment` ist seit Schritt 7 vollständig implementiert (siehe unten).

---

## Neu hinzugefügte Dateien (Branch-Stand)

```
Sources/MykilosKalkulationsCore/          (10 verbatim)
Sources/MykilosServices/Kalkulation/
  LearningDatabase.swift                  (verbatim)
  LearningRecords.swift                   (verbatim + AuditRecord→LearningAuditRecord)
  LearningStore.swift                     (verbatim)
  KalkulationsEngine.swift                (neu, eigener Code)
  CSVParser.swift                         (verbatim)
  DeviceCatalog.swift                     (verbatim)
  BaselineAnchors.swift                   (verbatim)
  BaselineAnchorProvider.swift            (neu, eigener Code)
Sources/MykilosKit/Domain/KalkulationsEngineProviding.swift   (neu, eigener Code)
Tests/MykilosKalkulationsCoreTests/
  ParserTests.swift                       (portiert, import fix)
  MaterialLexiconTests.swift              (portiert, import fix)
Tests/MykilosServicesTests/
  KalkulationsLearningStoreTests.swift    (neu, swift-testing)
  DeviceCatalogTests.swift                (portiert, synthetisch)
  KalkulationsEngineTests.swift           (neu, swift-testing)
```

---

## Wichtige Invarianten

- **Verbatim-Prinzip**: Portierte mykilO$-Dateien wurden minimal geändert (nur Import-Namen,
  eine Kollision bei `AuditRecord`). Keine Logikänderungen.
- **Keine echten Preisdaten im Repo**: `catalog.csv` liegt in Application-Support, nie im Git.
- **Cold-Start-Test ist Merge-Gate**: `lernDatenUeberlebenNeustart` beweist GRDB-Persistenz
  für die Lernschicht.
- **DeviceCatalog optional**: `loadDefault()` → nil → `geraetepreis` → nil. Kein Crash
  ohne Preisbuch.
- **Engine funktioniert sofort**: Baseline-Anker (eingebaut) liefern echte konservative
  Schätzungen ohne externe Daten.

---

---

### Schritt 6 — KalkulationsWidget + KalkulationsView Tab (UI)

**Commit:** (aktueller Stand)

Neue und geänderte Dateien:

- `Sources/MykilosKit/Domain/WidgetFoundation.swift` — `.kalkulation` zu `WidgetKind` hinzugefügt
- `Sources/MykilosWidgets/SourceChip.swift` — `iconName` für `.kalkulation`: `"eurosign.square"`
- `Sources/MykilosWidgets/WidgetContainer.swift` — `.kalkulation` → `.tasks` (Ocker-Akzent)
- `Sources/MykilosWidgets/Kinds/KalkulationsWidget.swift` — **neu**:
  - Alle 6 Renderstates (empty / loading / content / error / permissionRequired/offline = empty)
  - Freitext-Eingabe + "Schätzen"-Button → `engine.schaetze(projektID:, freitext:)`
  - Ergebnis: Min/Mitte/Max-Netto als `PreisSaeule`, Konfidenz-Badge (grün ≥70%, Ocker ≥40%, rot)
  - Top-3-Evidenzen als `EvidenceRow` mit Lieferant, Dokument, Zitat, Preis
  - Kostenboden + Evidenz-Anzahl als Metazeile
  - Quellenzeile: `KALKULATION · BASELINE-ANKER`
  - Dependency nur über `KalkulationsEngineProviding`-Protokoll (kein GRDB, kein direkter Store)
- `Sources/MykilosApp/MykilOS6App.swift` — `AppModule.kalkulation` + `KalkulationsPageView`:
  - Neuer Sidebar-Tab "Kalkulation" (nach "Angebote", vor "Einstellungen")
  - `KalkulationsPageView` bettet `KalkulationsWidget(projektID: "global", engine: appState.kalkulationsEngine)` ein
  - Navigation-Menü: ⌘6 = Kalkulation, ⌘7 = Einstellungen

**Tests:** 175 Tests grün, keine Regressions (kein neues persistierbares Feature → kein neuer Cold-Start-Test nötig).

---

### Schritt 7 — recordAdjustment-Flow + KalkulationsActionCard

**Commit:** (dieser PR, Branch `feat/kalkulation-record-adjustment`)

`recordAdjustment` ist kein Stub mehr: eine bestätigte Anpassung wird append-only
im `LearningStore` abgelegt UND als `AuditEntry` protokolliert — gleiche Semantik
wie die Action-Cards im `AssistantWidget` (kein automatisches Schreiben).

Geänderte/neue Stellen:

- `Sources/MykilosKit/Domain/AuditEntry.swift` — neuer `Action.estimateAdjusted`
  (rawValue-basiert persistiert → migrationssicher, keine DB-Migration nötig).
- `Sources/MykilosKit/Domain/KalkulationsEngineProviding.swift` — `KostenSchaetzung`
  trägt jetzt `schaetzungsID` (stabile `EstimateSession.id`). Referenz, gegen die
  eine Anpassung gebucht wird.
- `Sources/MykilosServices/Kalkulation/KalkulationsEngine.swift`:
  - `schaetze` persistiert die Session via `learningStore.saveSession(from:)` und
    gibt deren `id` als `schaetzungsID` zurück (vorher wurde **gar keine** Session
    persistiert — ohne ID gäbe es nichts, wogegen man eine Anpassung buchen könnte).
  - In-Memory-Map `projektIDBySession` merkt sich je Schätzung das Projekt (das
    Protokoll `recordAdjustment(schaetzungsID:faktor:grund:)` führt kein `projektID`;
    schaetze → recordAdjustment läuft sequenziell in einer Sitzung).
  - `recordAdjustment`: `faktor → percentDelta = (faktor-1)*100`, `grund → note`,
    `reason: .gutFeeling` (niedriges Reliability-Gewicht), `target: .wholeEstimate`,
    `learn: false` (eine einzelne manuelle Anpassung verändert den Kalibrierungs-
    Kandidaten NICHT automatisch). Danach `AuditEntry(action: .estimateAdjusted)`
    über den injizierten `AuditStore`.
  - Neuer `init`-Parameter `auditStore: AuditStore? = nil` (optional → bestehende
    Engine-Unit-Tests laufen ohne Audit weiter; die Anpassung wird trotzdem persistiert).
- `Sources/MykilosApp/Data/AppState.swift` — `auditStore: audit` an die Engine übergeben.
- `Sources/MykilosWidgets/Kinds/KalkulationsWidget.swift` — `KalkulationsActionCard`:
  Faktor-Schieberegler (0.5…1.5, Prozent-Label), Freitext-Begründung,
  „Anpassung buchen"-Button (disabled bei leerem Grund/Saving), Statuszeile
  („Im Audit protokolliert" / Fehler). Erscheint erst nach einer Schätzung,
  Reset bei jeder neuen Schätzung. Schreibt nur über `engine.recordAdjustment`
  (Regel: keine Schreibvorgänge aus Views).

**Tests:**
- `KalkulationsEngineTests`: `nochNichtVerdrahteteFaehigkeitenWerfenKlar` deckt
  nur noch `importPDF` (echter Stub) ab. Neu:
  `recordAdjustmentBuchtAnpassungGegenSchaetzung` (schaetze → recordAdjustment →
  1 Adjustment mit korrektem percentDelta/note) und
  `recordAdjustmentMitUnbekannterSessionWirft`.
- `KalkulationsLearningStoreTests`: neuer Cold-Start-Test
  `recordAdjustmentUeberlebtNeustart` — Anpassung über den **echten Engine-Pfad**
  (nicht direkt über den Store) geschrieben, nach Neustart aus frischer
  Store-Instanz lesbar.

**Ergebnis:** 197 Tests grün (178 swift-testing + 19 XCTest), keine Regressions.

---

## Schritt 8 — Lern-Loop sichtbar: Kalibrierungs-Kandidaten + Promote-Flow (S16)

**Branch:** `feat/kalkulation-calibration-loop` (abgezweigt von `feat/kalkulation-record-adjustment`)

Schritt 7 schrieb jede bestätigte Anpassung append-only weg (`learn: false`) — der
Schätz-Brain lernte aber noch nicht sichtbar. Schritt 8 schließt den Loop: aus
wiederkehrenden Anpassungen entsteht ein **Kalibrierungs-Kandidat**, den der Nutzer
bewusst zu einem **aktiven Faktor** promotet. Danach verschieben sich künftige
Schätzungen real. Die gesamte Fachlogik lag bereits im `LearningStore` — es fehlte
nur die Verdrahtung über die Engine + die Sichtbarkeit im Widget.

Geänderte/neue Stellen:

- `Sources/MykilosKit/Domain/KalkulationsEngineProviding.swift`:
  - `recordAdjustment` bekommt `lernen: Bool`. **Kein Default am Protokoll-Requirement**
    (Swift erlaubt das nicht) — stattdessen eine `extension`-Convenience mit der alten
    3-Argument-Signatur (`lernen: false`). So bleiben alle Schritt-7-Aufrufer (Tests,
    Widget) quellkompatibel und unverändert grün. Bewusst NICHT zusätzlich ein Default
    am konkreten Engine-Impl, sonst wäre der 3-Arg-Aufruf mehrdeutig.
  - Neue Requirements `lernUebersicht() -> KalkulationsLernStand` + `promote(candidateID:)`.
  - Neue Sendable-Value-Types `KalkulationsLernStand` / `KalkulationsFaktor` /
    `KalkulationsKandidat` — bewusst in MykilosKit, damit das Widget **nie**
    `CalibrationFactorCandidate` & Co. aus `MykilosKalkulationsCore` sieht (das es nicht
    importieren darf).
- `Sources/MykilosKit/Domain/AuditEntry.swift` — neuer `Action.calibrationPromoted`
  (rawValue-persistiert → migrationssicher).
- `Sources/MykilosServices/Kalkulation/KalkulationsEngine.swift`:
  - `recordAdjustment` reicht `learn: lernen` an `appendAdjustment` durch.
  - `lernUebersicht`: `learningStore.summary()` → `mapLernStand` (Kern-`LearningSummary`
    → Kit-Value-Types; promotebare Kandidaten = Status `.candidate`/`.strongCandidate`,
    bereits promotete erscheinen als aktiver Faktor, nicht doppelt als Knopf).
  - `promote`: `learningStore.promoteCalibration` + `AuditEntry(.calibrationPromoted)`.
    Sentinel-`projectID` "kalkulation", weil Kalibrierung projektübergreifend ist
    (kein einzelnes Projekt).
- `Sources/MykilosWidgets/Kinds/KalkulationsWidget.swift`:
  - `KalkulationsActionCard`: Toggle „Für künftige Schätzungen lernen" → `lernen: true`.
    Ohne Haken bleibt es eine reine Einzelkorrektur (Status quo Schritt 7).
  - Neue ausklappbare Sektion „Gelernte Kalibrierung" mit allen Renderstates
    (loading / leer „Noch nichts gelernt" / Inhalt / Fehler): aktive Faktoren (grün,
    z. B. „Bauchgefühl · Gesamtschätzung · +10 % · n=3"), promotebare Kandidaten mit
    „Übernehmen"-Button → `engine.promote` → Bestätigung sichtbar, Outlier-Zähler dezent.
    Lädt via `.task`, refresht nach Lern-Anpassung und Promote. Schreibt nur über die
    Engine (Regel: keine Schreibvorgänge aus Views).

**Tests:** neuer Cold-Start-Test (Merge-Gate)
`lernLoopUeberlebtNeustartUndVerschiebtSchaetzung` in `KalkulationsLearningStoreTests` —
3× `recordAdjustment(lernen: true)` über die Engine (BaselineAnchorProvider liefert eine
echte, positive Baseline; der leere Stub-Provider hätte mitteNetto == 0 und Kalibrierung
könnte nicht greifen) → Kandidat → `promote` → **frische Store-Instanz** auf derselben
`learning.sqlite` → aktiver Faktor lesbar UND der `EvidenceBasedEstimator` nutzt ihn:
`mitteNetto` der neuen Schätzung liegt messbar über der unkalibrierten Baseline.

**Ergebnis:** 198 Tests grün (179 swift-testing + 19 XCTest), keine Regressions.

**Berührte Daten:** nur lokale temporäre `learning.sqlite` in `NSTemporaryDirectory()`
(Test-Verzeichnisse, im `defer` gelöscht). Keine externen Datenquellen berührt.

---

## Nächste Schritte (nicht in diesem PR)

1. **Seed-Provider**: `BrainSeedRepository` mit destillierten Ankern aus SQLite +
   4 CSV-Dateien (aus mykilO$ Application-Support). Erfordert explizite Freigabe
   für Datei-Copy.
2. **`importPDF`**: Erst nach `GoogleDriveClient.downloadFile()`. **Letzter Engine-Stub.**
3. **PREISLISTEN CSV**: `~/.../Devices/catalog.csv` aus mykilO$ Application-Support
   kopieren → `geraetepreis` liefert echte Preise. Explizite Freigabe erforderlich.
4. ~~**Kalibrierung sichtbar machen**~~ ✅ erledigt in Schritt 8 (S16).
