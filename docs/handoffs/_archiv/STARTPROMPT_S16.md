# Startprompt S16 — Lern-Loop sichtbar: Kalibrierungs-Kandidaten + Promote-Flow

```
Pfad:   /Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilOS Mac/
Branch: feat/kalkulation-record-adjustment (oder main nach Merge)
Build:  ✅ 197 Tests grün (178 swift-testing + 19 XCTest)
Datum:  2026-06-28
```

---

## Du bist Teil des mykilOS Dev Collective

**Lese zuerst:** `docs/TEAM_CHARTER.md`

Die wichtigsten Regeln für dich als aktive Build-Session:

1. **Du bist der aktive Chef** — S10 Learning (keen-williamson-ddb354) ist der Tisch. Alle anderen Sessions beobachten still.
2. **Kein Push ohne explizite Freigabe von Johannes** — auch wenn alles grün ist.
3. **`git add` immer mit expliziten Pfaden — nie `git add -A`** — Johannes hat uncommittete eigene Änderungen (z.B. `docs/IDEEN_UND_BACKLOG.md`). NIE anfassen.
4. **Handoff-Dreifach-Pflicht am Ende:** EREIGNISPROTOKOLL-Eintrag + CLAUDE.md aktualisiert + STARTPROMPT_S17.md geschrieben — alle drei, kein STOP ohne sie.
5. **Kanonischer Ordner:** `/Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilOS Mac/` — der einzige echte Arbeitsort. Desktop-Worktrees sind Wegwerfkopien.
6. **Wenn du merkst die Richtung ist grundsätzlich falsch** — stopp und melde es an Johannes/Tisch. Nicht weiterbauen auf falschen Fundamenten (Statut 14).
7. **Fehler werden berichtet, nicht verschwiegen** (Kulturregel des Collectives).

---

## Session-Schematik

S12 → S14 → S15 → **S16** → S17 → S18 → S19 → S20

Jede Session = ein abgeschlossener Schritt, sauberer Handoff, kein Bug offen,
Tests grün, Commit, Dokumentation aktuell. STOP wenn der Schritt fertig ist.

**Roadmap der nächsten 5 Sessions:** `docs/handoffs/ROADMAP_S16_S20.md`

---

## Was bisher gebaut wurde (Kalkulations-Port, Schritte 1–7)

| Schritt | Was | Status |
|---|---|---|
| 1 | `MykilosKalkulationsCore` (10 Dateien verbatim, Foundation-only) | ✅ |
| 2 | GRDB-Lernschicht + Cold-Start-Gate | ✅ |
| 3 | `KalkulationsEngineProviding` + `KalkulationsEngine` actor | ✅ |
| 4 | `DeviceCatalog` + `geraetepreis` live | ✅ |
| 5 | `BaselineAnchorProvider` + `AppState.kalkulationsEngine` live | ✅ |
| 6 | `KalkulationsWidget` + Sidebar-Tab + `WidgetKind.kalkulation` | ✅ |
| 7 | `recordAdjustment`-Flow + `KalkulationsActionCard` + Audit | ✅ |

**Offener Engine-Stub:** nur noch `importPDF` (braucht Drive-Download + PDF-Pipeline — eigene Spur, NICHT S16).

---

## Pflicht-Checks ZUERST

```bash
cd "/Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilOS Mac"
pwd
git status
git log --oneline -3
swift build && swift test 2>&1 | tail -5
```

Falls gemergt: `git checkout main && git pull`. Sonst auf
`feat/kalkulation-record-adjustment` bleiben und neuen Branch abzweigen:
```bash
git checkout -b feat/kalkulation-calibration-loop
```

---

## Johannes' Entscheidungen zu S15's offenen Fragen

| Frage | Antwort |
|---|---|
| `lernen: Bool`-Toggle an ActionCard oder separater Promote-Schritt? | **Toggle an ActionCard** — `lernen: true` beim recordAdjustment |
| S16 = Lern-Loop (nicht importPDF)? | **Ja** — importPDF ist eigene größere Spur |
| Eigener AuditEntry-Case `.calibrationPromoted`? | **Ja** — neuer Case, rawValue-persistiert |

---

## Dein Auftrag: Lern-Loop schließen (Schritt 8)

Schritt 7 schreibt jede bestätigte Anpassung append-only weg (`learn: false`).
Der Schätz-Brain *lernt* damit aber noch nicht sichtbar. Schritt 8 macht den
Loop sichtbar und steuerbar: aus wiederkehrenden Anpassungen entsteht ein
**Kalibrierungs-Kandidat**, den der Nutzer bewusst zu einem aktiven Faktor
**promoten** kann. Danach verschieben künftige Schätzungen sich tatsächlich.

Die gesamte Fachlogik existiert schon im `LearningStore`:
- `appendAdjustment(..., learn: true)` → `regenerateCandidate` (ab 3 ähnlichen
  Adjustments entsteht ein `CalibrationFactorCandidate`).
- `promoteCalibration(candidateID:)` → `ActiveCalibrationFactor`.
- `summary()` → `LearningSummary` (sessions, adjustments, candidates, activeFactors, outliers).
- `EvidenceBasedEstimator` liest aktive Faktoren bereits über `CalibrationFactorProviding`.

Es fehlt nur die **Verdrahtung über die Engine + die Sichtbarkeit im Widget**.

### A) Engine erweitern

In `KalkulationsEngineProviding` (MykilosKit) und `KalkulationsEngine` (Services):
- `recordAdjustment` einen `lernen: Bool`-Parameter geben (Default `false`,
  damit Schritt-7-Tests grün bleiben) → reicht `learn:` an `appendAdjustment` durch.
- Neue Methoden (Protokoll + Engine):
  ```swift
  func lernUebersicht() async throws -> KalkulationsLernStand
  func promote(candidateID: String) async throws
  ```
  `KalkulationsLernStand` ist ein neuer Sendable-Value-Type in MykilosKit
  (KEIN Core-Typ ins Widget leaken — `CalibrationFactorCandidate` lebt in
  MykilosKalkulationsCore, das MykilosWidgets NICHT importieren darf). Mappe
  `LearningSummary` → `KalkulationsLernStand` (Kandidaten/Faktoren als simple
  Value-Structs: id, reason-Label, target-Label, prozent, sampleCount, status).
- `promote` schreibt zusätzlich einen `AuditEntry` mit `action: .calibrationPromoted`
  (neuer rawValue-persistierter Case in `AuditEntry.Action`).

### B) Action-Card: „merken"-Toggle

In `KalkulationsActionCard` einen Toggle „Für künftige Schätzungen lernen"
ergänzen → setzt `lernen: true` beim `recordAdjustment`. Ohne Haken bleibt es
eine reine Einzelkorrektur (Status quo Schritt 7).

### C) Widget: „Gelernte Kalibrierung"-Sektion

Unter dem Ergebnis eine ausklappbare Sektion mit `engine.lernUebersicht()`:
- Aktive Faktoren (grün, z. B. „Marktpreis · Gesamtschätzung · +8 % · n=5").
- Kandidaten mit `promote`-Button → `engine.promote(candidateID:)` →
  Bestätigung sichtbar (gleiche Semantik wie Action-Card).
- Outlier-Zähler dezent anzeigen.
- Alle Renderstates: leer („Noch nichts gelernt"), Inhalt, Fehler.

### D) Cold-Start-Test (Merge-Gate — absolutes Projektgesetz)

In `KalkulationsLearningStoreTests`: Adjustment mit `learn: true` über die Engine
schreiben (×3, gleicher reason/target) → Kandidat entsteht → `promote` →
neuer `LearningStore` auf gleichem Verzeichnis → aktiver Faktor ist lesbar UND
`EvidenceBasedEstimator` nutzt ihn (mitteNetto verschiebt sich gegenüber Baseline).

**Hinweis von S15:** `schaetze` persistiert seit Schritt 7 jede Session. Tests müssen
**frische temp-Dirs** nutzen, damit die Kandidaten-Schwelle (≥3 ähnliche Adjustments)
deterministisch bleibt — sonst können Alt-Sessions aus vorherigen Läufen die Schwelle
verschieben.

---

## Relevante Dateipfade

| Was | Pfad |
|---|---|
| Engine | `Sources/MykilosServices/Kalkulation/KalkulationsEngine.swift` |
| Protokoll + Value-Types | `Sources/MykilosKit/Domain/KalkulationsEngineProviding.swift` |
| LearningStore | `Sources/MykilosServices/Kalkulation/LearningStore.swift` |
| LearningModels (Core) | `Sources/MykilosKalkulationsCore/LearningModels.swift` |
| AuditEntry | `Sources/MykilosKit/Domain/AuditEntry.swift` |
| Widget | `Sources/MykilosWidgets/Kinds/KalkulationsWidget.swift` |
| AppState | `Sources/MykilosApp/Data/AppState.swift` |
| LernTests | `Tests/MykilosServicesTests/KalkulationsLearningStoreTests.swift` |

---

## Spätere, größere Spur (NICHT S16): `importPDF`

Der letzte Engine-Stub. Reihenfolge wenn dran:
1. `GoogleDriveClient.downloadFile(fileID:) async throws -> Data` (read-only, erlaubt)
2. PDF-Textextraktion (PDFKit) + SHA256-Dedup (Infra in LearningDatabase existiert)
3. V2-Destillationspipeline → mehrere Sessions, kein One-Shot

---

## Absolute Regeln

- **Sevdesk: NIE lesen/schreiben**
- **Airtable-Base `appuVMh3KDfKw4OoQ`: nur lesen**
- **Airtable-Base `appkPzoEiI5eSMkNK`: NIE anfassen (stillgelegt)**
- **Drive: read-only — nie schreiben oder verschieben**
- Secrets nur Keychain, nie in Code/Commits/Logs
- `MykilosKit`: kein SwiftUI, kein GRDB
- `MykilosWidgets`: kein GRDB direkt, **kein `import MykilosKalkulationsCore`**
  (Core-Typen nur über MykilosKit-Value-Types ins Widget)
- Schreibvorgänge nie aus Views — nur über Stores/Engine
- **Neues persistierbares Feature → Cold-Start-Test ist Merge-Gate**
- `try?` nur mit erklärendem Kommentar
- **`git add` immer mit expliziten Pfaden — nie `git add -A`**
- **Kein Push ohne explizite Freigabe von Johannes**

---

## Handoff-Dreifach-Pflicht am Ende (Statut 13)

Kein STOP ohne alle drei:

1. `swift build && swift test` — grün, keine Regressions, mindestens 197 Tests
2. `git add <nur eigene Dateien>` — explizit, nie -A
3. `git commit -m "feat: surface calibration learning loop + promote flow (step 8)"`
4. `docs/handoffs/HANDOFF_KALKULATION_CORE_PORT.md` um Schritt 8 ergänzen
5. **`docs/EREIGNISPROTOKOLL.md`** — neuen Eintrag oben einfügen
6. **`CLAUDE.md`** — Fortschrittstabelle (Kalkulations-Port, Schritt 8 ✅)
7. **`docs/handoffs/STARTPROMPT_S17.md`** — für nächste Session schreiben
8. Erfahrungsbericht an S10 Learning senden (Tisch)
9. STOP — auf Johannes' Push-Freigabe warten

---

## Was S17 als nächstes macht

Security-Härtung + technische Schulden:
1. `AirtableSyncService.swift` löschen (3 Regelverstöße)
2. Google-Identität nach Login (`GoogleUserInfo` → Sidebar)
3. Airtable baseID-Validierung in Settings

Details: `docs/handoffs/ROADMAP_S16_S20.md`
