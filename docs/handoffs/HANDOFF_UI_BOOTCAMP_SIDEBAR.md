# Handoff: UI Bootcamp + Sidebar CI-Sprint (2026-06-28)

```
Pfad:   /Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilOS6/
Branch: main
Build:  ✅ swift build grün
Tests:  ✅ 192 Tests grün
Datum:  2026-06-28
```

---

## Was diese Session gemacht hat

### Bootcamp-Phase (UI Bug Fixes)

**Commit `6aafa5e` — Option A: einheitlicher Widget-Satz für alle Projekttypen**
- Alle Projekttypen (kitchen, lighting, addendum, lead, quote) bekommen denselben
  6-Widget-Satz (drive/tasks/contacts/cash/calendar/notes/mail/assistant)
- `canonicalWidgetSet(for:)` in AppState — determiniertisch, keine Regressions-
  möglichkeit durch divergierende Sets

**Commit `dd235ab` — Sidebar-Collapse Root Cause + Widget-Reconciliation**
- Root Cause Sidebar-Collapse: `@AppStorage("ui.sidebarCollapsed")` fehlte in
  `ContentView` — Toggle-State war flüchtig (Session-Reset bei jedem Neustart)
- Einmalige Widget-Reconciliation via GRDB-Migration `v4_reconciledBoards`:
  Projektboards, die mit dem alten unvollständigen Set gespeichert waren,
  bekommen beim nächsten DB-Open automatisch die fehlenden Widgets nachgefüllt
  (append-only, bestehende Widgets und Positionen bleiben)

**Commit `5319d1e` — UI-Härtung Bootcamp**
- `GeometryReader`-Pane in ContentView: harte Layout-Grenze zwischen Sidebar und
  Detailpane — verhindert, dass Grid-Idealbreiten in den HStack zurückschlagen
- Stabile Row-IDs in `HomeBoardView.BoardRow`:
  `var id: UUID { items.first?.id ?? Self.emptyRowID }` statt `let id = UUID()`
  → Loader-Churn bei Home-Widgets behoben (Widgets wurden bei jedem Tick abgerissen)
- `.clipped()` auf TodayView-ScrollView und ProjectDetailView-ScrollView
- `AssistantGrounding`: Ton verschärft — kein "Gerne!", kein KI-Selbstbezug,
  direkt wie ein Kollege

### Sidebar CI-Sprint (diese Unterphase)

**Commit `ebb2e3b` — Sidebar-Toggle Keyboard Shortcut**
- `⌘⇧S` in `CommandMenu("Navigation")` als erste Aktion — zuverlässig (CommandMenu
  funktioniert, `CommandGroup(after: .toolbar)` und Overlay-`keyboardShortcut` tun es nicht)
- `@AppStorage("ui.sidebarCollapsed")` direkt in `AppCommands` — kein `@FocusedBinding`
  (das wurde nil wenn kein passendes Window im Fokus)

**Commit `70519cf` — MYKILOS Orange Brand Token + Sidebar-Footer**
- `MykColor.brand` (`#EA5B25`) als neuer Design-Token in `MykilosDesign/Tokens.swift`
- Settings aus Nav-Liste entfernt → kompakter Icon-Button im Footer
- Sidebar-Toggle als Orange-Icon im Footer (neben Settings)
- `SidebarIconButton` Komponente: Hover-Feedback, Tooltip, `.plain`

**Commit `c78b9ee` — CI-konformes Brand-Logo + entclusterter Footer**
- Brand-Square: solid `MykColor.brand` statt Gradient (CI: #EA5B25)
- "6"-Suffix im Header entfernt
- Footer: **eine Zeile** — Status-Dot + Name links, ⚙️ + ◫ rechts
- `onToggleSidebar`-Callback in SidebarView + ContentView verdrahtet

---

## Aktueller Sidebar-Aufbau (nach diesem Sprint)

```
┌────────────────────────────┐
│ [■] mykilOS                │  ← Brand: solid orange Square, kein Gradient
│                            │
│ ● Heute                    │
│ ● Projekte                 │
│ ● Assistent                │
│ ● Marken & Daten           │
│ ● Angebote                 │
│ ● Kalkulation              │  ← Settings fehlt hier (ist im Footer)
│                            │
│ ◉ Johannes Leo Berger  ⚙◫ │  ← Eine Zeile: Profil + Icons Orange
└────────────────────────────┘
```

Sidebar-Toggle-Quellen:
1. Footer-Icon `◫` (immer sichtbar wenn Sidebar offen)
2. `⌘⇧S` im Navigation-Menü (immer)
3. Overlay-Button `◫` oben links im Detailbereich (immer sichtbar, auch wenn Sidebar zu)

---

## Offene Punkte aus vorherigen Sessions (unverändert)

- Google Live-Verifikation (Re-Consent + aktiver OAuth-Refresh unter Last)
- PAT-Cleanup manuell (Johannes: alten PAT in Airtable revoken)
- Airtable Base-ID-Bug: Johannes muss in Einstellungen `appuVMh3KDfKw4OoQ`
  eintragen (steht noch fälschlich der PAT dort)

---

## Nächste Session: Drive Live-Wiring + Sortierung

### Was konkret zu tun ist

#### 1. Projektsortierung (schnell, 30 min)

Aktuelle Sortierung: `updatedAt` descending → alle Projekte haben `2026-06-27`
als `updatedAt` (Seed-Datum), Reihenfolge damit de-facto zufällig.

**Fix:** Sortierung auf `projectNumber` descending umstellen — neueste Projekte
oben, logisch und stabil:

```swift
// RegistryStore.swift, Zeile 37:
// VORHER:
projects = p.sorted { $0.updatedAt > $1.updatedAt }
// NACHHER:
projects = p.sorted { $0.projectNumber > $1.projectNumber }
```

Damit stehen 2026-Projekte oben, ältere unten — entspricht dem mentalen Modell.

#### 2. Drive Live-Wiring — was noch fehlt

Die 31 Projekte in `docs/registry/projekte.json` haben alle `driveFolderID`s gesetzt.
Der Code (DriveWidget, OffersTabView, DriveOfferWatcher) ist fertig.

**Was noch aussteht:**
- Live-Verifikation: Google-Account verbinden → ein Projekt öffnen → prüfen ob
  DriveWidget Dateien lädt (nicht "Noch leer")
- Falls "permissionRequired" erscheint: OAuth-Scopes prüfen (`drive.readonly`
  muss in den granted scopes sein — Settings → Google → Verbinden → Scopes)
- DriveOfferWatcher live testen: neues PDF in Drive-Ordner ablegen mit "Angebot"
  im Namen → nach ≤60s muss Signal im Today-Board erscheinen

**Projekte mit vollständigem Drive-Link (alle 31, Stichproben):**
```
2026-023  vonBoch       1Q-H_... (Drive-Ordner)
2026-016  Schmidt       ...
2025-018  Rodewyk       ...
```
Alle haben `driveFolderID` ≠ null in der JSON.

#### 3. Galerie-Sortierung in der UI

Nach Projekt-Nummer-Sortierung soll die Galerie optional nach Phasen gruppierbar sein.
Plan für die Session:

```swift
// ProjectGalleryView: Segmented Picker "Alle / Aktiv / Archiviert"
// + Optional: Gruppe nach Jahr (2026, 2025, 2024...)
```

Das ist ein kleiner UI-Sprint (~1h) der nach dem Drive-Check sinnvoll ist, weil man
dann weiß welche Projekte tatsächlich Drive-Daten liefern.

---

## Startprompt für die nächste Session

```
Pfad:   /Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilOS6/
Branch: main
Build:  ✅ swift build grün
Tests:  ✅ 192 Tests grün

SESSION-ZIEL: Drive Live-Wiring + Sortierung

SCHRITT 1 (10 min) — Projektsortierung:
  RegistryStore.swift Zeile 37: `updatedAt` → `projectNumber` (descending).
  Fertig wenn: Galerie zeigt 2026-Projekte oben.

SCHRITT 2 (1-2h) — Drive Live-Verifikation:
  Google-Account in der App verbinden (Settings → Google → Verbinden).
  Dann ein Projekt mit driveFolderID öffnen → DriveWidget muss Dateien zeigen.
  Falls "permissionRequired": OAuth-Scopes prüfen.
  Falls "Noch leer": driveFolderID im Projekt prüfen (projekte.json).
  Dokumentiere live: welches Projekt, welche Dateien, welche Fehler.

SCHRITT 3 (30 min) — Galerie-Filter:
  Segmented Picker in ProjectGalleryView: Alle / Aktiv.
  Sortierung: projectNumber descending.

SCHRITT 4 — Handoff aktualisieren.

KEIN SCHREIBEN in externe Systeme (Airtable, Drive, Sevdesk).
```
