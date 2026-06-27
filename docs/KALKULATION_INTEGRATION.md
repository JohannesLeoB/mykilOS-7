# mykilO$$ → mykilOS 6 — Vollintegrations-Plan

**Stand:** 2026-06-28
**Entscheidung:** mykilO$$ wird kein eigenständiges Fenster mehr. Alle Kalkulations-
fähigkeiten leben ab sofort als Modul innerhalb von mykilOS 6. Alle Schreibrechte
liegen bei mykilOS 6.

> ⚠️ **WICHTIG — präzisierte Architektur (2026-06-28, nach Code-Lesung):**
> Dieses Dokument ist der Grobplan. Die **am echten Code verifizierten** Entscheidungen
> stehen in **[HANDOFF_LIVE_WIRING_5.md → Teil 2](handoffs/HANDOFF_LIVE_WIRING_5.md)** und
> haben Vorrang. Wichtigste Korrekturen gegenüber den Abschnitten unten:
> - Der pure Kern kommt in ein **eigenes Foundation-only-Target `MykilosKalkulationsCore`**
>   (NICHT in `MykilosServices/Kalkulation/` — das importiert GRDB). Nur die GRDB-Adapter
>   landen in `MykilosServices/Kalkulation/`.
> - LearningStore bleibt in **eigener `learning.sqlite`**, nicht in der Haupt-GRDB-Migration.
> - `AirtableSyncService.swift` wird **gelöscht** (ENV-Secrets, fremde Base, Blocking).
> - Einstieg ist **zweistufig**: `parse(_:) -> EstimateRequest` dann `estimate(_:)`.
> - **Harter Blocker:** Geschwister-Typen (`CarryforwardRule` etc.) — Pfade ausstehend.

---

## 1. Was mykilO$$ mitbringt

| Komponente | Funktion | Datenmenge |
|-----------|----------|-----------|
| `EvidenceBasedEstimator` | Freitext → `KostenSchaetzung` + Evidence-Ankerpunkte | — |
| `BottomUpCostEngine` | Material + Arbeitszeit → harter Kostenboden | — |
| `LearningStore` (GRDB/SQLite) | Append-only: Anpassungen + Ergebnis-Korrekturen | wächst |
| `ReviewCenter` | 815 Positions-Kandidaten, manuell bewertet | 815 Records |
| `DeviceCatalog` | 13.419 Gerätepositionen mit Marktpreisen | 13.419 Records |
| `PDF Import Pipeline` | SHA256-Dedup, Text-Extraktion, Preis-Anker-Erkennung | wächst |

---

## 2. Ziel-Modulstruktur in mykilOS 6

```
Sources/
  MykilosKit/
    Domain/
      KalkulationsEngineProviding.swift   ← ✅ neu (2026-06-28)
      KalkulationsEngineProviding-types   (KostenSchaetzung, PriceEvidence)

  MykilosServices/
    Kalkulation/
      KalkulationsEngine.swift            ← adaptiert aus mykilO$$ EvidenceBasedEstimator
      BottomUpCostEngine.swift            ← adaptiert aus mykilO$$
      KalkulationsLearningStore.swift     ← append-only GRDB, Cold-Start-Test pflicht
      DeviceCatalog.swift                 ← Catalog + Suche
      ReviewCenterStore.swift             ← 815 Positionen laden/bewerten
      PDFImportPipeline.swift             ← SHA256-dedup, Drive-Integration
      KalkulationsAirtableSync.swift      ← schreibt Kalkulationen + Positionen in Airtable

  MykilosWidgets/
    Kinds/
      KalkulationsWidget.swift            ← kompakte Kalkulations-Übersicht im Projekt-Board
      (AssistantWidget erweitern)         ← KalkulationsActionCard im Chat

  MykilosApp/
    Kalkulation/
      KalkulationsView.swift              ← Vollansicht als Tab in der Projekt-Detailseite
      ReviewCenterView.swift              ← 815 Positionen, Admin-only
      KalkulationsActionCard.swift        ← Assistent schlägt Kalkulation vor → Bestätigung → Audit
    Data/
      AppState.swift                      ← var kalkulationsEngine: (any KalkulationsEngineProviding)?
                                             ← ✅ nil-Slot gesetzt (2026-06-28)
```

---

## 3. Airtable-Tabellen (mykilOS 6 schreibt alle)

| Tabelle | ID | Inhalt |
|---------|----|--------|
| `Kalkulationen` | `tblO3y2jdmxDnuiZj` | Gesamt-Kalkulationen je Projekt |
| `Kalkulations-Positionen` | `tblNamx3cHTus6gtk` | Zeilen-Positionen, linked zu Leistungen |
| `Eingehende-Angebote` | `tbliKfs5FnufjdB36` | PDF-Corpus, SHA256-dedup, Preis-Anker |

**Felder `Eingehende-Angebote`:**
| Feld | Typ | Details |
|------|-----|---------|
| SHA256 | singleLineText | Primärer Dedup-Schlüssel |
| Datei-Name | singleLineText | Originalname |
| Projekt-Nr | singleLineText | Format `YYYY-NR` |
| Richtung | singleSelect | eingehend / ausgehend |
| Kategorie | singleSelect | Tischler / Stein / Elektro / Sanitaer / Gesamt / Sonstiges |
| Lieferant | singleLineText | |
| Netto-Summe | number (2 Stellen) | Gesamtsumme des Angebots |
| Anker-Anzahl | number (0 Stellen) | Wie viele Preis-Anker extrahiert wurden |
| Status | singleSelect | Neu / Verarbeitet / Archiviert |
| Lern-Gewicht | number (2 Stellen) | Gewichtung für KalkulationsEngine (0.0–1.0) |
| Importiert-am | dateTime | Europe/Berlin |

---

## 4. GRDB-Migration (mykilO$$ → mykilOS 6)

mykilO$$ nutzt SQLite direkt (nicht via GRDB-Wrapper). Beim Merge:

1. **LearningStore** → neue GRDB-Migration in `MykilosServices`, Tabelle `kalkulations_adjustments`.
   Felder: `id UUID, schaetzungsID UUID, faktor REAL, grund TEXT, erstellt_at TEXT`.
   Cold-Start-Test Pflicht (schreiben → neue Store-Instanz → lesen → identisch).

2. **DeviceCatalog** → read-only SQLite-DB als Bundle-Resource bleibt unverändert.
   Kein GRDB-Wrapper nötig — direkte SQLite.swift oder FMDB-Abfragen.

3. **ReviewCenter (815 Records)** → einmalig in Airtable-Tabelle `Kalkulations-Positionen`
   importieren? Oder als lokale GRDB-Tabelle? Entscheidung offen — erstmal lokal in GRDB,
   da ReviewCenter-Prozess nicht cross-device geteilt werden muss.

---

## 5. UI-Slots

### 5a. KalkulationsView (Projekt-Detailseite)

Neuer Tab "Kalkulation" in `ProjectDetailView`, sichtbar wenn:
- `appState.kalkulationsEngine != nil`

Zeigt:
- Laufende Kalkulation des Projekts (aus `Kalkulationen`-Airtable)
- Freitext-Eingabe → `schaetze()` → KostenSchaetzung mit Evidence
- "Speichern als Kalkulation" → `KalkulationsActionCard` → Bestätigung → Airtable + AuditEntry

### 5b. KalkulationsWidget (Projekt-Board)

Kompaktes Widget im Projekt-Board:
- Budget-Balken (Soll vs. Ist aus Clockodo)
- Letzter Kosten-Schätzungs-Mitte-Wert
- Link zu KalkulationsView

### 5c. KalkulationsActionCard (Assistent)

Assistent erkennt im Chat Kalkulations-Intent:
- "Schätz mal was das Projekt Meyer kosten könnte"
- → Claude-Intent-Erkennung → `schaetze()` → ActionCard mit Spanne + Confidence
- → Bestätigung → `Kalkulationen`-Airtable-Record + `AuditEntry`

### 5d. ReviewCenterView (Admin-Tab)

Versteckter Admin-Tab, nur für interne Nutzung:
- 815 Positionen-Kandidaten durchgehen
- Bewerten (annehmen/ablehnen/anpassen)
- Anpassungen landen im `LearningStore` (GRDB)

---

## 6. Tests migrieren (59 aus mykilO$$)

mykilO$$ hat 59 Tests. Beim Merge in `Tests/MykilosServicesTests/Kalkulation/`:

| Testgruppe | Anzahl | Priorität |
|-----------|--------|-----------|
| EvidenceBasedEstimator (Unit) | ~15 | Hoch — Kernlogik |
| BottomUpCostEngine (Unit) | ~10 | Hoch — Kostenboden |
| PDFImportPipeline (Unit, Fake-HTTP) | ~12 | Hoch — SHA256-Dedup |
| DeviceCatalog (Read-only) | ~8 | Mittel |
| LearningStore (Cold-Start) | ~5 | **Pflicht** — laut absoluten Regeln |
| ReviewCenter | ~9 | Niedrig — UI-nah |

Cold-Start-Test für `LearningStore` ist nicht optional (absolutes Projektgesetz).

---

## 7. Drive-Integration

PDF Import Pipeline liest aus Drive-Ordner-Struktur:

```
PROJEKTE/{year}_{nr}_{kunde}/
  01 INFOS/
    05 eingehende Angebote/
      {Kategorie}/       ← Tischler / Stein / Elektro / Sanitaer / Gesamt / Sonstiges
        *.pdf
```

- Root Drive-Ordner-ID aus `Projekte.Drive-Ordner-ID` (Airtable)
- Navigation: Root → `01 INFOS` → `05 eingehende Angebote` → Kategorie-Ordner
- Dateien: Google Drive MimeType `application/pdf`
- Download → SHA256-Check gegen `Eingehende-Angebote.SHA256` → neu importieren oder überspringen
- Schreibrecht: KEIN Schreiben in Drive — nur lesen, lokal verarbeiten, in Airtable protokollieren

---

## 8. Merge-Reihenfolge (empfohlen)

1. **Protokoll fertig** ✅ — `KalkulationsEngineProviding` + `AppState.kalkulationsEngine`
2. **Airtable komplett** ✅ — alle 3 Kalk-Tabellen live
3. **Services portieren** — `KalkulationsEngine` + `BottomUpCostEngine` aus mykilO$$ adaptieren
4. **LearningStore GRDB-Migration** — Cold-Start-Test schreiben, dann Implementierung
5. **DeviceCatalog Bundle-Resource** — SQLite als Bundle-Asset integrieren
6. **PDFImportPipeline** — Drive-Download + SHA256-Dedup + Airtable-Sync
7. **KalkulationsView UI** — Projekt-Tab, Freitext-Eingabe, ActionCard
8. **KalkulationsWidget** — kompaktes Budget-Widget
9. **Tests migrieren** — 59 Tests, zuerst Unit-Tests, dann Cold-Start
10. **ReviewCenterView** — letzter Schritt, Admin-only

---

## 9. Nicht-Ziele (explizit ausgeschlossen)

- Kein separates Fenster, kein separater Prozess für Kalkulation
- Kein eigenes SQLite für mykilO$$ neben mykilOS GRDB (außer DeviceCatalog als Read-only Bundle)
- Keine Synchronisation von `DeviceCatalog` über Airtable — zu groß, bleibt Bundle
- Keine Schreibrechte für Eingehende-Angebote via Drive — nur lesen, dann lokal verarbeiten
- Sevdesk: NO-GO bleibt vollständig in Kraft
