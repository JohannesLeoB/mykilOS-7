# mykilOS 6 — Claude Code Projektgedächtnis

**Smarte Projektplanung und Management mit intelligenten Automationen und Integrationen.**
Das Cockpit, das alles kann. macOS 14+, SwiftUI, local-first.

---

## Wo wir stehen

**Akt 2 abgeschlossen.** Die Werkbank lebt.

| Akt | Status | Inhalt |
|---|---|---|
| Akt 0 | ✅ | Fundament: GRDB, Repository, Cold-Start-Tests, Signal-Engine |
| Akt 1 | ✅ | App-Shell, Galerie, Projekt-Detailseite, 7 Widget-Arten |
| Akt 2 | ✅ | GRDB live, WidgetBoardStore, NoteStore, Heute-Board, SaveStateBar |
| Akt 3 | 🔜 | Google OAuth, Drive/Kalender/Mail live, Clockodo, Airtable-Sync |
| Akt 4 | 🔜 | Assistent live (Tool-Use, proaktiver ein-Satz-Dolmetscher) |
| Akt 5 | 🔜 | Politur, Dark Mode, DMG, Beta |

---

## Bekannte Build-Fixes (zuerst erledigen!)

Vier Stellen aus Akt 2 die beim ersten `swift build` auffallen können:

1. **`SaveState: Equatable`** fehlt — `NotesWidget` nutzt `!=` auf SaveState.
   Fix: `Sources/MykilosKit/Persistence/SaveState.swift` → `enum SaveState: Equatable`
   (Date ist Equatable, alle Cases sind vergleichbar ✓)

2. **`SourceChip` für Home-Widget-Kinds** — `SourceChip(kind: .focus)` ruft `kind.iconName` auf,
   das nur Original-Cases kennt.
   Fix: In `WidgetContainer.swift` + `SourceChip.swift` den switch-default auf `homeIconName` zeigen
   oder `iconName` mit Home-Cases ergänzen.

3. **`Color(hex:)` mehrfach definiert** — in `ProjectCard.swift`, `NotesWidget.swift`, `DriveWidget.swift`.
   Fix: Alle `private extension Color { init(hex:) }` löschen. Stattdessen `public` in
   `Sources/MykilosDesign/Tokens.swift` exportieren (ist dort bereits als `init(hex:)` vorhanden).

4. **`GridTexture` doppelt** — in `ProjectCard.swift` und `ProjectHeroView.swift`.
   Fix: Eine löschen, oder nach `Sources/MykilosDesign/` als `public struct GridTexture` auslagern.

---

## Absolute Regeln (nicht verhandelbar)

### Persistenz
- Jeder Schreibvorgang `throws`. Niemals `try?` außer in begründeten, kommentierten Ausnahmen.
- `SaveState` (.idle/.saving/.saved(Date)/.failed(String)) ist in der UI sichtbar.
- Cold-Start-Test für jedes neue persistierbare Feature: schreiben → neue Instanz → lesen → identisch.

### Token-Disziplin (SwiftLint erzwingt das)
- Keine `.font(.system(...))` in Feature-/Widget-Code → `Font.mykHero` etc. aus `MykilosDesign`.
- Keine `Color(red:...)` → `MykColor.drive.color` etc.
- Keine `Color(hex:)` in Widgets/Features → `public` in `MykilosDesign/Tokens.swift` nutzen.

### Secrets
- Tokens, API-Keys, PATs → nur Keychain. Nie in Code, Dateien, Repo, Logs.
- Externe IDs (Airtable-Record, Drive-Folder, ClickUp-Liste) = Referenzen, nie Primärschlüssel.

### Widgets
- Widgets reden NIE direkt miteinander → nur über `StudioContext.emit()`.
- Signale sind VORSCHLÄGE (laut für Einsicht). Schreiben nur über Action-Card → Bestätigung → Audit.
- Jedes Widget hat alle Renderstates: loading / content / empty / permissionRequired / offline / error.
- Quelle ist immer sichtbar (Quellenzeile unten).

### Architektur
- Multi-Target: `App → Widgets → Design`, `Services → Kit`, `Integrations → Kit`.
- `MykilosKit` importiert NIE SwiftUI oder GRDB.
- `MykilosWidgets` importiert NIE GRDB.
- Schreibvorgänge kommen NIE aus Views — nur über Stores.

### Prozess
- Eine Session = ein kleiner PR = ein Handoff (`docs/handoffs/HANDOFF_AKT{n}_S{m}.md`).
- CI ist Merge-Gate: roter Build/Test = kein Merge.
- Keine parallelen Worktrees.

---

## Target-Struktur

```
Sources/
  MykilosKit/          # Foundation ← importiert NICHTS von uns
    Domain/            # Customer, Project, WidgetFoundation, AuditEntry, WidgetBoard
    Persistence/       # Repository, FileBackedRepository, PersistenceError, SaveState
    Signals/           # WidgetSignal, Mediator, StudioContext (@Observable)
  MykilosDesign/       # Tokens (MykColor, MykSpace, MykRadius), Typography, SourceColor
  MykilosServices/     # CachedProjectRegistry, AirtableRegistry, GRDBDatabase,
                       # WidgetBoardStore, NoteStore, GRDB-Records
  MykilosWidgets/      # WidgetContainer, WidgetBoardView, SourceChip, SaveStateBar,
                       # Kinds/ (7 Widgets: drive, tasks, contacts, cash, calendar, notes, assistant)
  MykilosApp/          # Shell (Sidebar), Gallery, Detail, Today, Data (AppState, AppDatabase,
                       # RegistryStore, DemoSeed)

Tests/
  MykilosKitTests/     # Cold-Start-Tests (FileBackedRepository)
  MykilosServicesTests/# WidgetBoardStoreTests (GRDB Cold-Start, 5+ Tests)
```

---

## Die Palette (Tokens)

```
--paper    #FAF8F3   Grund
--ink      #1A1814   Tinte
--drive    #C26B4A   Terrakotta  → Dateien/Drive
--people   #6E8B6A   Salbei      → Menschen/Kalender
--tasks    #C99A3E   Ocker       → Aufgaben/ClickUp
--cash     #4C6280   Tiefblau    → Geld/Angebote
--personal #8A5B73   Pflaume     → Notizen
--positive #3E7A4E   --critical #B4503C
```
Farbe ist Sprache: man erkennt die Quelle, bevor man liest.

---

## Team-Modell

Persönliches Cockpit, geteilte Instrumente. Jeder hat sein eigenes mykilOS,
sieht durch seine eigene Identität auf die geteilten Drive-Ordner, ClickUp-Tasks, Kalender.
Projekt-Verdrahtung (boardID, Links) über Airtable als System-of-Record.
Kein Sync-Backend in V1.

---

## Nächste Schritte (Akt 3)

1. `swift test` — alle Tests müssen grün sein
2. Die 4 Build-Fixes oben erledigen
3. Google OAuth/PKCE + Keychain portieren (aus V5 `KeychainGoogleTokenStore`)
4. Drive-Ordner-Widget live verdrahten (read-only)
5. Kalender + Mail read-only
6. Clockodo-Widget live (ZEITEN-Regel: nur Mapping/Status, nie Buchung)
7. Airtable-Sync implementieren (`AirtableRegistry.sync(into:)`)

---

## Hilfreiche Kommandos

```bash
swift package resolve          # GRDB + Dependencies holen
swift build                    # Kompilieren
swift test                     # Tests (zuerst Cold-Start-Tests)
swift run                      # App starten
swiftlint --strict              # Token-Disziplin prüfen
```

---

## Doku

- `docs/handoffs/HANDOFF_AKT0.md` — Fundament
- `docs/handoffs/HANDOFF_AKT1.md` — App-Shell, Galerie, Widgets
- `docs/handoffs/HANDOFF_AKT2.md` — GRDB, Heute-Board, SaveState
- `docs/MYKILOS_6_TEAM_MODELL.md` — Team, Airtable, Identität
