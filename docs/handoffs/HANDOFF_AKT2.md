# Handoff — Akt 2: Die Werkbank lebt

**Datum:** 2026-06-25 · **Basis:** Akt-1 · **Status:** Vollständig geschrieben, Build auf Mac zu bestätigen.

## Was in diesem Commit liegt

### GRDB — Die Architektur-Stunde (das wichtigste)
- `Package.swift`: GRDB als SwiftPM-Dependency (`from: "6.0.0"`).
- `GRDBDatabase`: WAL-Mode, Foreign-Keys, `DatabaseMigrator`, versionierte Migrations.
- **Migration v1**: Tabellen `widgetInstances`, `notes`, `auditEntries` — jetzt in echtem SQLite.
- GRDB-Records (`WidgetInstanceRecord`, `NoteRecord`, `AuditRecord`) in `MykilosServices` —
  `MykilosKit` bleibt sauber ohne GRDB-Import.
- `AppDatabase`: einmalige Produktions-DB-Instanz in Application Support.

### WidgetBoardStore — Persistenz mit SaveState
- `@MainActor @Observable WidgetBoardStore`: GRDB-backed, alle Layouts persistent.
- Jeder Schreibvorgang `throws` — kein `try?`. SaveState `idle/saving/saved/failed` sichtbar.
- Cold-Start-Verhalten: beim ersten Öffnen seeded Default-Layout, ab dann lädt aus GRDB.
- Operationen: `load`, `save`, `move`, `add`, `remove`, `toggle`, `resize`.

### NoteStore — Echter Speichern-Vertrag
- `NoteStore`: GRDB-backed, debounced Autosave (0.8 s), SaveState in UI sichtbar.
- `NotesWidget` komplett überarbeitet: liest/schreibt via `NoteStore`, kein statischer `@State` mehr.

### AppState — Zentraler DI-Container
- `AppState(@Observable)`: hält `GRDBDatabase`, `homeBoard`, `homeNotes`, `RegistryStore`.
- `board(for:)` + `notes(for:)`: lazy Board-Stores je Projekt, gecached.
- `bootstrap()`: lädt alles async beim App-Start.
- Übergabe via `.environment(appState)` — kein Singleton-Wildwuchs.

### Heute-Board (TodayView) — Das neue Zuhause
- `TodayView`: Greeting, persistentes HomeBoardView, Signal-Demo-Knopf.
- `HomeBoardView`: Grid aus `WidgetBoardStore.instances`, Widget-Dispatch für alle Home-Arten.
- **5 Home-Widgets**:
  - `FocusWidget` (wide): "Heute zählt" — synthesiert aus StudioContext-Signalen.
    Keine Signale → Default-Demo. Signale vorhanden → konkrete Aufgaben.
  - `ProjectFavoritesWidget` (full): aktive Projekte als Mini-Karten aus `RegistryStore`.
  - `ClockodoWidget` (medium): 6,5 h Demo, Balken je Projekt, "nur Anzeige"-Hinweis.
  - `RecentActivityWidget` (wide): letzte Drive/ClickUp-Aktivitäten.
  - `NotesWidget` (medium): das globale Home-Post-It, jetzt mit echtem Autosave.

### SaveStateBar
- Wiederverwendbare Komponente für alle Boards und Stores.
- `idle` → unsichtbar. `saving` → Spinner. `saved` → grünes ✓ + Timestamp. `failed` → roter Hinweis + Retry.

### Tests (5 neue GRDB-Tests)
- Layout überlebt App-Neustart (Cold-Start, GRDB).
- SaveState ist `.saved` nach erfolgreichem Schreiben.
- Hinzufügen/Entfernen persistent.
- Notiz überlebt Neustart.
- Mehrere Projekt-Boards unabhängig.
- Nachtrag-Board unabhängig von Eltern-Board.

## Meilenstein erreicht
> *Tippe „Meyer" → `.projectFocused` → alle Widgets färben ihre Kante. Drive meldet Angebot → Cash fragt. FocusWidget ändert seinen Text. NotesWidget speichert nach 0.8 s Pause und zeigt „Gespeichert 14:32". App-Neustart → alles liegt genau so, wie du es verlassen hast.*

Das Cockpit lebt.

## Ehrlichkeits-Hinweise (vor dem Build)
1. **`SaveState` Equatable**: `SaveState.saved(Date)` hat einen assoziierten Wert.
   In `NotesWidget` (`noteStore.saveState != .idle`) prüft auf `Equatable` —
   `SaveState` braucht `Equatable`-Konformanz oder `if case`-Pattern statt `!=`.
   Fix: Entweder `SaveState: Equatable` (bedingt, da `Date` Equatable ist) oder `if case .idle = state {} else { ... }`.
2. **`WidgetKind`-Extension für `focus` etc.**: `SourceChip(kind: .focus)` ruft `kind.iconName` auf.
   In `SourceChip.swift` ist `iconName` nur für die Original-Cases. Die neuen static-lets
   (`focus`, `projectFaves` etc.) sind keine enum-Cases, daher greift das switch durch default.
   Die Erweiterung am Ende von `SourceChip.swift` (`homeIconName`) deckt das ab — SourceChip
   muss für Home-Kinds `homeIconName` statt `iconName` verwenden.
3. **`GRDBDatabase.inMemory()` in Tests**: die private `__inMemory()`-Methode ruft `runMigrations()`
   via `try!` — in Test-Isolation funktioniert das, aber der Stil ist nicht ideal.
   Kleaneres Muster für Akt 3: `throws` auch im Test-Factory-Method.
4. **`AppState` Zugriff in `RegistryStore`**: `RegistryStore.seedIfEmpty()` ruft `DemoSeed.inject(into:)`
   auf, das `CachedProjectRegistry` braucht — die ist in `MykilosServices`. `RegistryStore` liegt
   in `MykilosApp`. Kein circular dependency, aber `RegistryStore` muss `MykilosServices` importieren. ✓

## Nächster Schritt — Akt 3: Die Fenster öffnen sich
- Google OAuth/PKCE + Keychain (aus V5 portieren, Keychain-Prompt-Fix eingebaut).
- Drive-Ordner-Widget live (echte Drive-API, read-only).
- Kalender + Mail read-only.
- Clockodo-Widget live (ZEITEN-Regeln: nur Mapping, nie Wahrheitskopie).
- Drag-&-Drop im Widget-Board.
- Airtable-Sync (echte Implementierung von `AirtableRegistry`).
