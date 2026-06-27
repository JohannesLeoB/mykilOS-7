# Handoff — Live-Wiring Session 5 (2026-06-28)

**Thema:** mykilO$$ Vollintegration — Interface, Airtable-Schema, Write-Pfad.
**Status:** Fundament gelegt. Brain (Engine-Code) noch nicht portiert.
**Nächste Session:** `KalkulationsEngine` + `BottomUpCostEngine` aus mykilO$$ portieren.

---

## Entscheidung dieser Session

**mykilO$$ existiert nicht mehr als eigenständige App.**

Alle Kalkulations-Fähigkeiten kommen als Modul in mykilOS 6. Keine eigene
App-Shell, kein eigenes Fenster, kein eigener Airtable-PAT, kein eigenes
Drive-Scan, keine eigene SQLite-Datei. mykilOS 6 hat alle Schreibrechte.

---

## Was in dieser Session erledigt wurde

### 1. Protokoll + Domain-Typen ✅

**`Sources/MykilosKit/Domain/KalkulationsEngineProviding.swift`** (neu):

```swift
public protocol KalkulationsEngineProviding: AnyObject, Sendable {
    func schaetze(projektID: String, freitext: String) async throws -> KostenSchaetzung
    func geraetepreis(suchbegriff: String) async -> Double?
    func importPDF(driveFileID: String, projektID: String) async throws
    func recordAdjustment(schaetzungsID: UUID, faktor: Double, grund: String) async throws
}

public struct KostenSchaetzung: Sendable { projektID, minNetto, maxNetto, mitteNetto,
    confidence, evidenceCount, kostenboden, kostenbodenRatio, topEvidences }

public struct PriceEvidence: Sendable { lieferant, dokument, seite?, originalZitat, nettoPreis }
```

Mapping zu mykilO$$-Typen: `EstimateResult` → `KostenSchaetzung`, `PriceAnchor` → `PriceEvidence`.

### 2. AppState nil-Slot ✅

```swift
// Sources/MykilosApp/Data/AppState.swift
public var kalkulationsEngine: (any KalkulationsEngineProviding)?
```

Nil bis die Engine integriert ist — identisches Muster wie `assistantLLM`.

### 3. Airtable-Tabelle `Eingehende-Angebote` ✅

**ID: `tbliKfs5FnufjdB36`** in Base `appuVMh3KDfKw4OoQ`

| Feld | Typ | Zweck |
|------|-----|-------|
| SHA256 | singleLineText (Primary) | Dedup-Schlüssel |
| Datei-Name | singleLineText | Originalname |
| Projekt-Nr | singleLineText | Format YYYY-NR |
| Richtung | singleSelect | eingehend / ausgehend |
| Kategorie | singleSelect | Tischler / Stein / Elektro / Sanitaer / Gesamt / Sonstiges |
| Lieferant | singleLineText | |
| Netto-Summe | number (2 Stellen) | |
| Anker-Anzahl | number (0 Stellen) | Extrahierte Preis-Anker |
| Status | singleSelect | Neu / Verarbeitet / Archiviert |
| Lern-Gewicht | number (2 Stellen) | 0.0–1.0 für KalkulationsEngine |
| Importiert-am | dateTime | Europe/Berlin |

### 4. AirtableClient Write-Pfad ✅

```swift
// Sources/MykilosServices/Airtable/AirtableClient.swift
public protocol AirtableCreating: Sendable {
    func createRecord(baseID: String, tableID: String,
                      fields: [String: AirtableWriteValue]) async throws -> String
}
public enum AirtableWriteValue: Encodable, Sendable { case string, number, bool, null }
```

`AirtableClient` konformiert jetzt zu `AirtableFetching` + `AirtableCreating`.
Statische Bausteine `buildCreateRequest` / `parseCreateResponse` sind isoliert testbar.
**5 neue Tests. 97/97 grün.**

Unblockiert: Clockodo-Zuhörer (EW-Tabellen-Sync) + PDF-Import (Eingehende-Angebote).

### 5. Integrations-Plan-Dokument ✅

[`docs/KALKULATION_INTEGRATION.md`](../KALKULATION_INTEGRATION.md) — vollständiger 10-Schritte-Merge-Plan:
- Ziel-Modulstruktur in `MykilosServices/Kalkulation/`
- GRDB-Migrationsstufen (ab v3)
- Alle UI-Slots
- 59 Test-Migration-Plan
- Drive-Integration (PDF-Download-Pfad)

### 6. Airtable-Schema-Doku aktualisiert ✅

[`docs/PARTNER_APP_SCHEMA.md`](../PARTNER_APP_SCHEMA.md) — umbenannt von "Partner-App-Schema"
zur vollständigen Airtable-Gesamtdokumentation für mykilOS 6.

### 7. mykilO$$-Fragen beantwortet ✅

6 Integrationsfragen + 5 EK/VK-Fragen konkret beantwortet:
- Projektobjekt: `project.projectNumber` (YYYY-NR), `project.links.driveFolderID`, `project.phase`
- GRDB: `GRDBDatabase.runMigrations()`, neu ab `v3_kalkulation_*`
- Airtable: injizierter `AirtableClient`, kein eigener PAT
- Drive: `GoogleDriveClient.listFolder()`, kein eigener Scan
- Rückgabe: `KostenSchaetzung`-Struct direkt (in-process, kein JSON)
- Lern-Trigger: expliziter Aufruf aus `RegistryStore.syncFromAirtable()` bei Phase-Wechsel
- EK/VK: beide Tabellen via `Projekt-Nr` joinbar, Positionsebene outgoing ja / incoming nein (noch)

---

## Was NICHT hier ist — Brain noch in mykilO$$

**Diese Fähigkeiten sind noch NICHT in mykilOS 6:**

| Komponente | Status | Aufwand |
|-----------|--------|---------|
| `EvidenceBasedEstimator` | ❌ nicht portiert | hoch |
| `BottomUpCostEngine` | ❌ nicht portiert | mittel |
| `MaterialLexicon` (149 Einträge) | ❌ nicht portiert | gering |
| `LearningStore` (GRDB v3+) | ❌ nicht portiert | mittel + Cold-Start-Test |
| `DeviceCatalog` (13.419 Preise, SQLite-Bundle) | ❌ nicht portiert | gering (nur kopieren) |
| `ReviewCenter` (815 Positionen) | ❌ nicht portiert | mittel |
| `PDFImportPipeline` | ❌ nicht portiert | hoch |
| 201 Preis-Anker aus 146 Lieferanten-PDFs | ❌ Daten nicht migriert | separate Aufgabe |
| 59 Tests | ❌ nicht migriert | nach Code-Port |
| KalkulationsView (Projekt-Tab) | ❌ kein UI | nach Engine |
| KalkulationsWidget | ❌ kein Widget | nach Engine |
| KalkulationsActionCard | ❌ kein UI | nach Engine |
| ReviewCenterView | ❌ kein UI | zuletzt |

**Noch fehlende Infrastruktur:**
- `GoogleDriveClient.downloadFile()` — für PDF-Download (unblockiert Kalkulation + Clockodo)
- `AirtableClient.updateRecord()` — für Status-Updates (EW-Tabellen "Gebucht" etc.)

---

## Airtable-Gesamtstand (alle Tabellen in `appuVMh3KDfKw4OoQ`)

| Tabelle | ID | Session |
|---------|----|---------|
| Kunden | `tblsz4i1CqpBZUE0N` | Session 1 |
| Projekte | `tblGJR13OliFt6Ewi` | Session 1 |
| Externe Systeme | `tbl8aoORULVVtphE0` | Session 1 |
| Kontakte | `tblncfQzQa8TzCZQC` | Session 1 |
| Clockodo-Leistungen | `tblRtsegocdpM8CJd` | Session 1 (8 Services) |
| Clockodo-Nutzer | `tblPbly2br8mR2kaU` | Session 4 (4 Records + EW-Pointer) |
| Clockodo-Buchungen | `tblYQxlauwej7FD1w` | Session 4 |
| Clockodo-EW-Johannes | `tbl4vZ2UFyeTRD8hd` | Session 4 |
| Clockodo-EW-Jilliana | `tblXQIDrvPVN9ijI9` | Session 4 |
| Clockodo-EW-Daniel | `tblNDVve3jjJ9s8HB` | Session 4 |
| Clockodo-EW-Frauke | `tblRrqIQZmm2DosJT` | Session 4 |
| Kalkulationen | `tblO3y2jdmxDnuiZj` | Session 5 (Kalkulations-Modul) |
| Kalkulations-Positionen | `tblNamx3cHTus6gtk` | Session 5 |
| **Eingehende-Angebote** | **`tbliKfs5FnufjdB36`** | **Session 5 (neu)** |

---

## Git-Commits dieser Session

```
2bb14a9  feat: add AirtableClient write path (createRecord + AirtableWriteValue)
c4eef55  feat: add KalkulationsEngineProviding protocol and nil-slot for mykilO$$ integration
```

Branch: `claude/musing-sammet-3abd94` → PR → `main`

---

## Startprompt für nächste Implementierungs-Session

```
Wir portieren den mykilO$$-Kern in mykilOS 6.
Interface ist fertig: KalkulationsEngineProviding in MykilosKit/Domain.
AppState.kalkulationsEngine nil-Slot ist gesetzt.
AirtableClient hat Write-Pfad (createRecord). 97 Tests grün.

Vollständiger Merge-Plan: docs/KALKULATION_INTEGRATION.md

Nächste Schritte in Reihenfolge:
1. GoogleDriveClient.downloadFile(fileID:) -> Data (unblockiert PDF-Import)
2. AirtableClient.updateRecord(baseID:tableID:recordID:fields:) (für Status-Updates)
3. KalkulationsEngine.swift in MykilosServices/Kalkulation/ (aus EvidenceBasedEstimator)
4. BottomUpCostEngine.swift (Kostenboden-Logik)
5. KalkulationsLearningStore.swift (GRDB v3-Migration + Cold-Start-Test PFLICHT)
6. DeviceCatalog.swift (SQLite als Bundle-Resource, read-only)

Kernregel: Jeder Schreibvorgang throws. Cold-Start-Test für LearningStore nicht optional.
Airtable-Base: appuVMh3KDfKw4OoQ
GRDB-Migration ab: v3_kalkulation_learning
```

---

## Offene Datenfragen (nur Johannes kann bestätigen)

1. Stundensätze in `Clockodo-Leistungen.Stundensatz (€/h)` (`fld4NBokj4MoOy8Uq`) — noch leer
2. Kategorie-Unterordner unter `05 eingehende Angebote` (Tischler, Stein + was noch?)
3. Welche 59 Tests aus mykilO$$ werden direkt übernommen, welche passen nicht?

---

# Teil 2 — Architektur-Klärung im Austausch mit mykilO$$ (2026-06-28, Fortsetzung)

Nach dem ersten Handoff wurde der **echte mykilO$$-Code gelesen** (alle KalkulationsCore +
KalkulationsData Dateien) und über eine 8-Agent-Workflow-Analyse + direkte Verifikation zu
einem belastbaren Integrationsvertrag verdichtet. Quelle (read-only):
`/Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilO$$$/.../MYKILOSKalkulationslabor`.

## Verifizierte Befunde (am Code geprüft, nicht aus Selbstbeschreibung)

1. **`KalkulationsCore` importiert über alle 10 Dateien nur `Foundation`** — null GRDB/SwiftUI/Airtable.
   → Eigenes reines Target **`MykilosKalkulationsCore`** (Geschwister zu MykilosKit), Port verbatim.
   NICHT in `MykilosServices/Kalkulation/` (das importiert GRDB → würde Reinheit + 59 Tests verschmutzen).
2. **Einstieg ist zweistufig:** `Parsing.swift:43 parse(_:) -> EstimateRequest` (Semantik) DANN
   `Estimation.swift:18 estimate(_:) -> EstimateResult` (Preislogik). `estimate()` nimmt KEINEN
   Freitext. Das semantische Verständnis lebt in `parse()` + `MaterialLexicon`. Adapter
   `schaetze(freitext:)` = `parse → estimate`.
3. **`AirtableSyncService.swift` muss gelöscht werden** (3 verifizierte Verstöße):
   `:54` Secrets aus `ProcessInfo.environment["AIRTABLE_TOKEN"]`; `:39` fremde Base
   `appkPzoEiI5eSMkNK`; `:158` blockierender `DispatchSemaphore`. Upsert-Absicht → append-only
   `AirtableClient.createRecord` bei uns.
4. **`CostModel.stages` Stundensätze sind hardcoded** (`BottomUpCost.swift:44`, `ratePerHour: 104…`).
   → Leere `Clockodo-Leistungen`-Stundensatz-Spalte blockiert den Kostenboden NICHT.
5. **LearningStore bleibt in eigener `learning.sqlite`** (nicht in mykilOS-6-Hauptmigration) —
   verhindert Überfrachtung; `LearningDatabase` bringt eigenes Queue-Muster + `inMemory()` mit.
6. **`KostenSchaetzung` braucht additiv `id: UUID` + `erstelltAm: Date`.** `id` MUSS die
   persistierte `EstimateSession`-UUID sein (NIE `EstimateLine.id` — frisch pro Lauf), sonst hat
   `recordAdjustment(schaetzungsID:)` keinen Quellschlüssel.

## Korpus-Entscheidung: V4_MoneyObservations

Roh-Evidenz: **3.383 Beobachtungen, 145 Dokumente, 8 Lieferanten** (Bartels 1249, Weichsel78 963,
Jandali 610, HKT, Meylahn, …), **33 Projekte**; **1.104 Zeilen `total_or_carryforward_risk`**
(bestätigt die Existenz von `CarryforwardRule.isForbiddenContext`). Wird zu ~204 aktiven Ankern destilliert.

**Heimat = beides** (Johannes' Entscheidung):
1. **System-of-Record:** neue Tabelle `Preis-Beobachtungen` in Mastermind-Base `appuVMh3KDfKw4OoQ`.
   Alte Base `appkPzoEiI5eSMkNK` wird stillgelegt.
2. **Laufzeit:** destilliertes Seed-`sqlite` als read-only `activeAnchors()`-Pfad
   (Bundle/Application-Support); ~11MB JSONL + extracted_text werden NICHT mitgeshippt.

## HARTER BLOCKER (an mykilO$$ gestellt)

`Estimation.swift` referenziert Typen, die in den vier Core-Dateien NICHT enthalten sind und
ohne die nichts kompiliert: **`CarryforwardRule`** (`.isForbiddenContext`, ref. `:163`),
`CalibrationFactor`, `CalibrationTarget`, `AppliedCalibrationFactor`, `GermanNumberParser`.
→ Exakte Pfade + Foundation-only-Bestätigung von mykilO$$ ausstehend. Partielles Portieren =
#1-Fehlermodus.

## 5 offene Fragen an mykilO$$ (gesendet)

1. Pfade der Geschwister-Typen (Blocker, siehe oben).
2. Trägt `EvidenceCase` Provenienz (lieferant + Original-Zitat + Seite) für verlustfreies
   `PriceEvidence`-Mapping?
3. Ist `EstimateSession`-UUID in `saveSession()` erzeugt/persistiert und Key für `appendAdjustment`?
4. Liest `activeAnchors()` die ~204 destillierten Anker (nach Risk-Flag-Filter), nicht die 3.383
   Rohzeilen? Ist die Seed-`sqlite` self-sufficient ohne CSV-Geschwister? Destillation reproduzierbar?
5. PDF-Textextraktion hinter `importPDF` — wo, was hängt dran? Oder V1 = nur Drive-File + SHA256?
   Plus: ist `gen_lexicon.py` (MaterialLexicon-Generator) noch da?

## Port-Reihenfolge (sobald Blocker gelöst)

1. `MykilosKalkulationsCore`-Target anlegen, KalkulationsCore + Geschwister-Typen verbatim, 59 Tests grün.
2. `KostenSchaetzung` um `id` + `erstelltAm` erweitern (additiv).
3. LearningStore/LearningDatabase → `MykilosServices/Kalkulation/` (eigene `learning.sqlite`).
4. **LearningStore Cold-Start-Test (Merge-Gate).**
5. BrainSeedAnchorProvider + DeviceCatalog (Seed-sqlite read-only aus Application-Support).
6. `KalkulationsEngine`-Adapter (`schaetze`/`geraetepreis`/`importPDF`/`recordAdjustment`).
7. AppState-Slot verdrahten (eine Zeile in `bootstrap()`).
8. UI in BESTEHENDE Flächen: „Angebote"-Tab (`ProjectDetailView`) + `KalkulationsActionCard` im AssistantWidget.

## Korpus-Migration (unabhängig, parallel möglich)

- Tabelle `Preis-Beobachtungen` in `appuVMh3KDfKw4OoQ` anlegen (12 Spalten aus CSV).
- 3.383 Beobachtungen importieren (wartet auf Frage #4 — ob Roh oder nur destilliert nach Airtable).
- Alte Base `appkPzoEiI5eSMkNK` als stillgelegt dokumentieren.
