# Handoff — Akt 0: Das Fundament

**Datum:** 2026-06-25 · **Status:** Gerüst geschrieben, Build auf Mac zu bestätigen.

## Was in diesem Commit liegt

**Persistenz, die hält** (heilt die V5-Speicherwunde)
- `Repository`-Protokoll — jeder Schreibvorgang `throws`.
- `FileBackedRepository` — atomare Datei-Persistenz, nie UserDefaults, nie `try?`.
- `SaveState` — der Speichern-Vertrag (idle/saving/saved/failed).
- **Cold-Start-Test** (`Tests/MykilosKitTests`) — beweist, dass Daten den Neustart überleben.

**Signal-Engine** (die Seele — Widgets reden über einen gemeinsamen Kontext)
- `WidgetSignal`, `Mediator` (azyklisch, testbar), `StudioContext` (`@Observable`).
- Regel im Code verankert: abgeleitete Signale sind VORSCHLÄGE, nie Aktionen.

**Datenmodell + Registry** (Airtable eingepflegt)
- `Customer`, `Project` (mit `projectNumber`/Kürzel, `customerNumber`, `links`, `airtableRecordID`).
- `parentProjectNumber` → Nachträge verweisen auf ihr Eltern-Projekt.
- `ProjectRegistry`-Protokoll; `CachedProjectRegistry` (lokaler Cache, erster echter
  Kunde der Persistenz); `AirtableRegistry` (ehrlicher Stub, wirft — kein Fake-Erfolg).
- Tests: Neustart-Überleben + Nachtrag-Beziehung + „Airtable noch nicht scharf".

**Design & Disziplin**
- `MykColor` — warme Palette + Quellen-Farben als Code.
- `.swiftlint.yml` — verbietet `.font(.system)` und `Color(red:)`, warnt bei `try?`.
- `.github/workflows/ci.yml` — Lint + Build + Test als Merge-Gate.

## Entscheidungen
- **Persistenz Akt 0 = datei-basiert, atomar, null Abhängigkeiten.** GRDB/SQLite tritt
  in Akt 1 hinter dieselbe `Repository`-Schnittstelle, sobald relationale Abfragen
  über den Cache hinaus nötig werden. Aufrufender Code bleibt gleich.
- **Airtable = System-of-Record für Kunden & Projekte.** Es ersetzt das frühere
  JSON-Manifest aus dem Team-Modell. Read-first; Writes später über Action-Card +
  Audit. PAT im Keychain.

## Ehrlichkeits-Hinweis
Das Gerüst entstand in einer Umgebung ohne Swift/macOS-Toolchain — es konnte hier
nicht kompiliert werden. Der grüne Build wird auf dem Mac bestätigt.
**Erster Schritt dort:** `swift test` (zuerst der Cold-Start-Test).

## Nächster Schritt — Akt 1: Das erste Zuhause
App-Shell in warmer CI (Rail, Command-Bar), Token-Schrift statt System-Font,
Projekte-Galerie aus `CachedProjectRegistry`, Projekt-Detailseite (Hero +
Widget-Grid, noch statische Quellen). GRDB-Migration einführen.
