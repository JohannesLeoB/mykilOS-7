# Handoff — Akt 1: Das erste Zuhause

**Datum:** 2026-06-25 · **Basis:** Akt-0-Fundament · **Status:** Vollständig geschrieben, Build auf Mac zu bestätigen.

## Was in diesem Commit liegt

### App-Shell (volle CI)
- `@main MykilOS6App` mit `StudioContext` + `RegistryStore` in der SwiftUI-Environment.
- `ContentView`: Custom `HStack`-Layout (kein `NavigationSplitView`) — 100 % Designkontrolle.
- `AppModule`-Enum: Heute · Projekte · Assistent · Marken & Daten · Angebote · Einstellungen.
- `SidebarView`: schlanker Rail, warme Palette, aktives Item Tinte auf Paper, Brand-Gradienten-Mark.

### Typografie-Token-System (`MykilosDesign/Typography.swift`)
- `Font.mykHero/Display/Title/Headline/Body/Small/Caption/mykMono(_:)`
- Kein `.font(.system(...))` mehr im Feature-Code — SwiftLint erzwingt das.

### Daten-Schicht
- `RegistryStore` (`@Observable`): lädt lokal aus `CachedProjectRegistry`, seeded Demo-Daten
  wenn leer (Cold-Start-safe), Fehler landen in `errorMessage` statt Crash.
- `DemoSeed`: 6 realistische Projekte (3 Küchenplanungen, 1 Lichtplanung, 2 Nachträge)
  für 4 Demo-Kunden — deckt alle `ProjectKind`-Archetypen ab.

### Projekte-Galerie (`ProjectGalleryView`)
- `LazyVGrid` mit `.adaptive(minimum: 260)` — skaliert von 2 bis n Spalten, lazy gerendert.
- Volltextsuche über Titel/Nummer/Kundennummer.
- Alle Zustände gestaltet: Loading · Inhalt · Leer/Keine Treffer.
- Smooth-Transition zur Detailseite (slide + opacity).

### ProjectCard
- Image-led: Hero-Gradient je `ProjectKind`, feines Raster-Overlay, Hover-Lift-Animation.
- Projekt-Kürzel (Mono), Kunden-Name, Phase, Kind-Chip in Quellen-Farbe.
- Nachtrag-Badge wenn `isAddendum`.

### Projekt-Detailseite (`ProjectDetailView` + `ProjectHeroView`)
- **Hero** (280 px): Gradient aus Archetyp, Versalschrift 42pt, Eckdaten, Budget-Strich + Donut.
- **Tabs**: Übersicht · Dateien · Angebote · Timeline · Material (Platzhalter-Tabs klar markiert).
- **SignalDemoView**: Sichtbarer Knopf, der `offerDetected` + `budgetThresholdCrossed` + `deadlineNear` feuert — macht die Widget-Kommunikation in Akt 1 erlebbar.
- `.onAppear`: sendet `.projectFocused` → alle projektbezogenen Widgets färben ihre Kante.

### Widget-System
- `WidgetContainer`: alle Renderstates (loading/content/empty/permission/offline/error) schön,
  Quellen-Zeile mit Status-LED, Hover-Lift, projektweite Mitfärbung (linke farbige Kante).
- `WidgetBoardView`: greedy Bin-Packing für 3-Spalten-Grid mit `gridCellColumns`.
- `WidgetBoardDefault.layout(for:)`: kuratiertes Default-Layout je Archetyp (Küche: 7 Widgets,
  Licht: 4, Nachtrag: 5, Lead/Angebot: 3).
- `SourceChip`: farbiges Quellen-Icon — Farbe ist Sprache, Herkunft sichtbar vor dem Lesen.

### 7 Widget-Implementierungen (alle Demo-Daten, Akt 3 → live)
| Widget | Besonderheit |
|---|---|
| `DriveWidget` | Mosaikvorschau mit „NEU"-Badge |
| `TasksWidget` | Fokus-Liste, kritische Tasks rötlich |
| `ContactsWidget` | farbige Avatar-Kacheln je Rolle |
| `CashWidget` | **Signal-reaktiv**: zeigt Review-Prompt wenn `reviewSuggested` empfangen |
| `CalendarWidget` | Terminliste, kritischer Termin farbig |
| `NotesWidget` | editierbares Post-It, warmes Gelb |
| `AssistantWidget` | dunkel, dominiert 3 Spalten, Summary-Text dynamisch aus aktiven Signalen |

### Das Herzstück sichtbar
`CashWidget` und `AssistantWidget` reagieren live auf Signale aus `StudioContext`. 
Knopf in `SignalDemoView` feuert die komplette Signal-Kaskade: `offerDetected → reviewSuggested` (Mediator), `budgetThresholdCrossed`, `deadlineNear`. 
Cash zeigt Review-Vorschlag, Assistent ändert seinen Text. **Tippe „Meyer" → alles leuchtet auf.**

## Neue Domänenmodelle
- `WidgetKind/Size/Instance` + `WidgetBoardDefault` in `MykilosKit/Domain/WidgetFoundation.swift`
- `AuditEntry` in `MykilosKit/Domain/AuditEntry.swift` (Modell da, Tabelle in Akt 2 via GRDB)

## Ehrlichkeits-Hinweise
- Build wurde geschrieben aber nicht kompiliert (kein Swift/macOS in dieser Umgebung).
- **`swift test` ist der erste Schritt** auf dem Mac — Cold-Start-Tests aus Akt 0 müssen grün bleiben.
- `GridTexture` ist in `ProjectCard.swift` und `ProjectHeroView.swift` jeweils definiert → 
  beim Build: eine der beiden in eine gemeinsame Datei verschieben oder einen Target-Export anlegen.
- `Color(hex:)` Extension ist in mehreren Dateien — vor dem Build zu `MykilosDesign/Tokens.swift` 
  zentralisieren und aus den Widgets entfernen.
- `ProjectKind.accentColor` und `.displayLabel` in `ProjectCard.swift` → bei Bedarf nach 
  `MykilosKit/Domain/Project.swift` verschieben (ohne SwiftUI-Import dort: als String/Int, Color im Design).

## Nächster Schritt — Akt 2: Die Werkbank lebt
- GRDB einführen (Migration, relationale Queries für Nachträge).
- Drag-&-Drop-Layout im Widget-Board.
- Heute-Board mit Home-Widgets (Fokus, Favoriten, Post-Its).
- Clockodo-Read-Integration (ZEITEN-Regeln).
- `SaveState` in NotesWidget: echtes Speichern mit sichtbarem Status.
