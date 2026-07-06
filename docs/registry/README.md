# Registry-Redundanz

Drei Kopien der mykilOS-6-Projekt-/Kunden-Registry, bewusst getrennt, damit kein
einzelner Knoten zum Single Point of Failure wird:

1. **Airtable "mykilOS Mastermind"** (`appuVMh3KDfKw4OoQ`) — die kollaborative
   Arbeitsoberfläche. Tabellen `Kunden`, `Projekte`, `Externe Systeme`,
   `Archiv-Übersetzung`. Hier wird inhaltlich gepflegt.
2. **Lokaler Cache pro Nutzer** — existiert bereits strukturell seit Akt 0/3:
   `CachedProjectRegistry` (`Sources/MykilosServices/CachedProjectRegistry.swift`)
   schreibt `customers.json` + `projects.json` über `FileBackedRepository` nach
   `~/Library/Application Support/mykilOS Mac/`. Wird bei jedem erfolgreichen
   Airtable-Sync (`RegistryStore.syncFromAirtable`) aktualisiert, überlebt
   Neustarts, funktioniert offline. Kein zusätzlicher Code nötig — das ist
   schon "lokale Sicherheitskopie auf jedem Nutzer-Mac".
3. **Diese Dateien hier** (`docs/registry/*.json`) — eine dritte, portable
   Kopie im Git-Verlauf. Unabhängig von Airtable als Plattform: falls Airtable
   in Zukunft durch ein anderes System ersetzt wird, bleibt die Datenhistorie
   versioniert und lesbar erhalten.

## Wichtig: kein Drop-in-Ersatz für den lokalen Cache

`FileBackedRepository` kodiert Daten intern mit
`date.timeIntervalSinceReferenceDate` (ein Double) für bitgenaue
Round-Trip-Sicherheit — siehe Kommentar in
`Sources/MykilosKit/Persistence/FileBackedRepository.swift`. Das ist kein
für Menschen lesbares Format. Die JSON-Dateien hier nutzen bewusst normale
ISO-8601-Datumsstrings für Lesbarkeit/Diff-Fähigkeit in Git. Sie lassen sich
**nicht** 1:1 in den App-eigenen Cache-Ordner kopieren — für eine echte
Wiederherstellung müsste ein kleines Konvertierungsskript zwischen den beiden
Formaten vermitteln (existiert noch nicht).

## Stand

- `projekte.json` — 31 echte Projekte aus dem Drive-Ordner `PROJEKTE`,
  Stand 2026-06-27. `airtableRecordID` ist überall `null`, weil der Import in
  Airtable noch nicht erfolgt ist (siehe Live-Wiring-Session, CLAUDE.md).
- `kunden.json` — die zugehörigen 30 Kunden (gleicher Stand).
- Keine Automatisierung bisher: dieser Snapshot wurde von Claude manuell aus
  dem Drive-Scan erzeugt, nicht aus einem laufenden Sync-Job gezogen. Ein
  wiederholbarer Export (aus Airtable-REST oder aus dem lokalen
  `FileBackedRepository`) ist als Folgeaufgabe offen.
