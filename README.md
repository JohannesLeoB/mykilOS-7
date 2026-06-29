# mykilOS 7.5

**Das Cockpit, das alles kann.** Internes Studio-OS für MYKILOS — neuer, bewusster Start.

## Was hier liegt (Akt 0 — Fundament)

Dies ist das Akt-0-Gerüst aus dem Produktionsplan. Es baut auf einem Boden auf,
der die Lehren aus mykilOS 5 trägt:

- **Multi-Target-Package** — Schichtgrenzen vom Build-System erzwungen.
- **Persistenz, die hält** — `Repository`-Protokoll + atomare `FileBackedRepository`.
  Jeder Schreibvorgang `throws`. Kein `try?`-Schlucken.
- **Cold-Start-Test** — beweist, dass Daten den Neustart überleben. (`Tests/`)
- **Signal-Engine** — `StudioContext` + `Mediator`: Widgets reden über einen
  gemeinsamen Kontext, nie direkt. Laut für Einsicht, leise für Wirkung.
- **Warme Palette als Code** — `MykColor`, Quellen-Farben als Sprache.
- **Token-Disziplin** — SwiftLint verbietet `.font(.system)` und `Color(red:)`.
- **CI-Gate** — GitHub Actions: Lint + Build + Test als Merge-Voraussetzung.

## Bauen

```bash
swift build
swift test        # zuerst: der Cold-Start-Test
swift run         # zeigt das Fundament + die Quellen-Farben
```

> Hinweis: Das Gerüst wurde sorgfältig geschrieben, aber in der Build-Umgebung,
> in der es entstand, konnte kein Swift/macOS kompiliert werden. Der grüne Build
> wird auf deinem Mac (Xcode/Claude Code) bestätigt — `swift test` ist der erste
> Schritt.

## Persistenz-Entscheidung

Akt 0 nutzt eine **datei-basierte, atomare** Persistenz (null Abhängigkeiten,
sofort buildbar, Fehler werden geworfen). **GRDB/SQLite** tritt in Akt 1 hinter
dieselbe `Repository`-Schnittstelle, sobald relationale Daten kommen
(z. B. Nachträge, die auf ihr Eltern-Projekt verweisen). Der aufrufende Code
ändert sich dabei nicht.

## Nächster Schritt

Akt 1 — Das erste Zuhause: App-Shell in warmer CI, Core-Modelle (Project, Audit),
Projekte-Galerie aus der Persistenz, Projekt-Detailseite (Hero + Widget-Grid).
