# Handoff: mykilO$ Kalkulations-Core Port (Schritte 1–5)

```
Pfad:   /Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilOS6/
Branch: feat/kalkulation-core-port
Build:  ✅ swift build grün
Tests:  ✅ 194 Tests grün (175 swift-testing + 19 XCTest)
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
| `recordAdjustment` | ActionCard → Bestätigungs-Flow fehlt | UI-Schritt Kalkulations-Widget |

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

## Nächste Schritte (nicht in diesem PR)

1. **Kalkulations-Widget / UI**: `KalkulationsView`-Tab + `KalkulationsActionCard`
   im AssistantWidget. Engine ist injiziert in `AppState`, Zugriff ist vorbereitet.
2. **Seed-Provider**: `BrainSeedRepository` mit destillierten Ankern aus SQLite +
   4 CSV-Dateien (aus mykilO$ Application-Support). Erfordert explizite Freigabe
   für Datei-Copy.
3. **`recordAdjustment` vervollständigen**: ActionCard → Bestätigung → `AuditEntry` →
   `LearningStore.appendAdjustment`.
4. **`importPDF`**: Erst nach `GoogleDriveClient.downloadFile()`.
5. **PREISLISTEN CSV**: `~/.../Devices/catalog.csv` aus mykilO$ Application-Support
   kopieren → `geraetepreis` liefert echte Preise. Explizite Freigabe erforderlich.
