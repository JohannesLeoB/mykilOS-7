# HANDOFF — Angebote: Beleg-Klassifikation per sicherem Zuordnungsweg

```
Pfad:   /Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilOS Mac/
Branch: polish/dampflok
Build:  ✅ swift build grün
Tests:  ✅ 270 Tests grün (43 Suites, swift test)
PR:     #3 → https://github.com/JohannesLeoB/mykilOS-6/pull/3 (gegen main)
Commit: ac1c914
Datum:  2026-06-28
```

## Worum es ging

P0-Reparatursession, Teilbereich **Angebote-Routing**. Ausgangslage: Der
Angebote-Tab fand nur direkte Dateien (keine Unterordner), klassifizierte nichts
und der Sidebar-Eintrag „Angebote" war unklar verdrahtet.

## Was umgesetzt wurde

### Kernarbeit — Beleg-Klassifikation
- **`OfferDocumentClassifier`** (neu, `Sources/MykilosServices/Google/`):
  klassifiziert Belege nach Typ — Angebot, Auftrag, Abschlagsrechnung,
  Schlussrechnung, eingehendes Angebot, Bestellung.
- **Sicherster Zuordnungsweg zuerst:** team-kontrollierter **Unterordner-Name**
  (`Angebot`/`Auftrag`/`Rechnung`/`Bestellungen`) hat Vorrang vor der
  Dateinamen-Präfix-Heuristik. Begründung in der Zuordnungswege-Analyse unten.
- Extraktion: Belegnummer (`JJJJ-NNNN`), Kundennummer (`Kdnr-…`), Version (`_vN`).
- **`OffersLoader`** (neu ausgelagert, `Sources/MykilosApp/Detail/`): rekursiv
  bis max. 3 Ebenen, trägt den unmittelbaren Eltern-Unterordnernamen mit →
  findet verschachtelte PDFs (`04/Rechnung/…`, `05/Bestellungen/…`).
- **`OffersTabView`**: Anzeige nach Dokumenttyp gruppiert, read-only.
- **Sidebar-Modul „Angebote" = gleiche Datenquelle:** `GlobalOffersView` rendert
  pro gewähltem Projekt dieselbe `OffersTabView`. Kein zweiter Datenpfad.
  Klassifikation erscheint dort automatisch.

### Zuordnungswege-Analyse (Verlässlichkeit)
| # | Signal | Sicherheit | Status |
|---|---|---|---|
| 1 | 04 vs 05 Top-Ordner | ✅ sicher | genutzt (`isIncoming`) |
| 2 | Unterordner-Name | ✅ sehr sicher (team-kontrolliert) | **jetzt Primärsignal** |
| 3 | MIME-Typ | ✅ sicher | Icon/Typlabel |
| 4 | Präfix `AN`/`SR` | ✅ bestätigt | genutzt |
| 4b | Präfix `TR`/`ARE`/`AB` | ⚠️ Annahme | nur Verfeinerung |
| 5 | Belegnummer `JJJJ-NNNN` | ✅ deterministisch | extrahiert |
| 6 | Kdnr ↔ Projekt-Kundennr. | ✅ wäre sicher | ❌ Registry hat keine Kdnr |

### Session-Härtung (begleitend)
- `GoogleDriveClient`: `nextPageToken`-Pagination (>100 Einträge).
- `GoogleOAuthModels`: `drive.readonly`-Scope.
- `BackupService` (neu): konsistente Snapshots inkl. WAL-Test.
- `LocalDriveRootResolver` (neu): Grundlage lokales Drive-/Finder-Routing.
- `GRDBDatabase` / `FilePreviewView` / `MykilOS6App`: Härtung & Diagnose.

## Verifiziert
- `swift build` grün, `swift test` → 270 Tests / 43 Suites grün.
- Hustadt-xattr `com.google.drivefs.item-id#S` = `13ITPqAMdz6JrS13u8y7JvkTVXAWznA_S`
  stimmt exakt mit der `driveFolderID` im Seed überein (Live-Routing möglich).
- Read-only gewahrt — keine Airtable-/Drive-/Gmail-Schreibzugriffe.

## OFFEN / nächste Session
1. **Live-Abnahme der Präfix-Annahmen** (Projekt Rodewyk/Hustadt):
   `TR-ARE`→Abschlagsrechnung, `AB`→Auftrag, `BE`/`BS`→Bestellung bestätigen.
   Korrektur = eine Zeile im `prefixLexicon` (`OfferDocumentClassifier.swift`).
2. **SwiftLint strict** lokal nicht geprüft (nicht installiert) — CI ist das Gate.
   CI-Status von PR #3 beobachten (SwiftLint bricht vor Build/Tests ab).
3. **Lokales Finder-Routing** (`LocalDriveRootResolver`): Grundlage liegt, aber
   „Im Finder zeigen" über Security-Scoped Bookmark + xattr-Auflösung ist noch
   nicht vollständig in der UI verdrahtet. Browseröffnung ist noch Standardweg.
4. **`AppDatabase.production`** nutzt weiter `try!` — sichtbarer, wiederher-
   stellbarer Fehlerpfad noch offen (P0-Punkt F).
5. **Kdnr im Project-Modell** ergänzen → ermöglicht Zuordnungsweg #6 (Misfiled-
   Warnung bei Kdnr-Mismatch).

## Kein Push/„fertig" ohne Live-Nachweis
PR #3 ist erstellt, aber die Live-Akzeptanz (Finder-Öffnung, PDF-Vorschau,
Bundle-Pfad-Anzeige, Präfix-Bestätigung) steht aus — Johannes prüft.
