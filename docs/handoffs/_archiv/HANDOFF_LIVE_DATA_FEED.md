# Handoff: Live Data Feed — echte Daten in die App (2026-06-28)

```
Pfad:   /Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilOS Mac/
Branch: main
Build:  ✅ swift build grün
Tests:  ✅ 192 Tests grün
Datum:  2026-06-28
Fallback-Tag: ui/sidebar-ci-stable (git checkout ui/sidebar-ci-stable)
```

---

## Warum diese Session existiert

Die App ist feature-complete und UI-stabil. Alle Widgets sind live codiert.
Aber: die Daten kommen noch aus dem lokalen JSON-Seed (`InitialProjectSeed.swift`),
nicht aus den echten Quellen. Diese Session schließt die Lücke — Schritt für Schritt,
in der logisch richtigen Reihenfolge.

**Eiserne Regel:** Keine Schreibvorgänge in externe Systeme.
- Sevdesk: nie lesen/schreiben
- Airtable-Mastermind-Base `appuVMh3KDfKw4OoQ`: read-only aus Code, keine Record-Mutationen
- Google Drive `0AOeReQBQKkKBUk9PVA`: read-only

---

## Aktueller Stand der Datenquellen

| Feld im Projekt         | Befüllt (JSON) | Code-Seite fertig | Live verifiziert |
|-------------------------|---------------|-------------------|-----------------|
| `driveFolderID`         | 31/31 ✅      | ✅ DriveWidget    | ❌ ausstehend   |
| `calendarQuery`         | 30/31 ✅      | ✅ CalendarWidget | ❌ ausstehend   |
| `mailQuery`             | 30/31 ✅      | ✅ MailWidget     | ❌ ausstehend   |
| `clickUpListID`         | 0/31 ❌       | ✅ TasksWidget    | ❌ braucht IDs  |
| `sevdeskRef`            | 0/31 ❌       | ✅ CashWidget     | ❌ braucht IDs  |
| `budget`                | 0/31 ❌       | ✅ CashWidget     | ❌ braucht Wert |

**Airtable als Quelle der Wahrheit:** Die Mastermind-Base `appuVMh3KDfKw4OoQ`
hat 31 Projekte live. Ein einziger Sync füllt alle Link-Felder aus dem echten Schema.

---

## Schritt-für-Schritt-Plan (in dieser Reihenfolge)

### Schritt 0 — Manuell (Johannes, vor der Session): Airtable Base-ID fixen
**Bekannter Bug:** In den Settings → Airtable steht noch der PAT statt der Base-ID.
Feld „Airtable Base-ID" muss sein: `appuVMh3KDfKw4OoQ`
Erst wenn das korrekt ist, kann Schritt 2 (Airtable-Sync) funktionieren.

---

### Schritt 1 — Projektsortierung (Code, 10 min)

**Datei:** `Sources/MykilosApp/Data/RegistryStore.swift`, Zeile 37

```swift
// VORHER (alle updatedAt = 2026-06-27 → zufällige Reihenfolge):
projects = p.sorted { $0.updatedAt > $1.updatedAt }

// NACHHER (neueste Projektnummer oben, logisch + stabil):
projects = p.sorted { $0.projectNumber > $1.projectNumber }
```

Erwartetes Ergebnis: Galerie zeigt 2026-Projekte ganz oben (2026-026, 2026-025 ...).

---

### Schritt 2 — Airtable Live-Sync (Code + Live, 30 min)

**Ziel:** `syncFromAirtable` läuft durch, lokale GRDB-Registry wird mit echten
Daten aus der Mastermind-Base überschrieben.

**Was bereits fertig ist:**
- `AirtableRegistry.sync(baseID:into:)` in `Sources/MykilosServices/AirtableRegistry.swift`
- `AirtableClient.mapProjects` mapped alle Felder korrekt (Drive-Ordner-ID, ClickUp-Liste,
  Budget, sevdesk-Ref, Kalender-Suche, Mail-Suche) — Spaltenname ↔ App-Feld ist 1:1
- `RegistryStore.syncFromAirtable` löst den Sync aus und lädt danach neu

**Airtable-Schema (Mastermind-Base `appuVMh3KDfKw4OoQ`):**
```
Tabelle "Projekte":
  Projektnummer    → projectNumber
  Titel            → title
  Art              → kind (kitchen/lighting/addendum/lead/quote)
  Kundennummer     → customerNumber
  Phase            → phase
  Drive-Ordner-ID  → links.driveFolderID  ← PRIMÄRE LIVE-QUELLE
  ClickUp-Liste    → links.clickUpListID
  Kalender-Suche   → links.calendarQuery
  Kontakte-Suche   → links.contactsQuery
  Mail-Suche       → links.mailQuery
  sevdesk-Ref      → links.sevdeskRef
  Budget           → links.budget

Tabelle "Kunden":
  Kundennummer     → customerNumber
  Name             → name
```

**Live-Check:**
1. In der App: Settings → Airtable → Base-ID = `appuVMh3KDfKw4OoQ` → Sync-Button
2. Erwartung: Projekte-Galerie lädt neu, echte Projektnamen + Links erscheinen
3. Falls Fehler: `errorMessage` in RegistryStore prüfen (erscheint in der Galerie)

---

### Schritt 3 — Drive Live-Verifikation (Live, 30-60 min)

**Voraussetzung:** Google-Account in Settings → Google verbunden + Schritt 2 ✅

**Was zu tun ist:**
1. Projekt mit `driveFolderID` öffnen (alle 31 haben eine — z.B. vonBoch 2026-023)
2. Tab „Übersicht" → DriveWidget prüfen

**Mögliche Zustände und was sie bedeuten:**

| DriveWidget zeigt         | Ursache                                    | Fix                                    |
|---------------------------|---------------------------------------------|----------------------------------------|
| Dateien aus Drive ✅      | Alles korrekt                               | —                                      |
| „Verbindung nötig"        | Google nicht verbunden                      | Settings → Google → Verbinden          |
| „Noch leer"               | driveFolderID im Projekt falsch/leer        | Airtable-Spalte Drive-Ordner-ID prüfen |
| HTTP 403                  | OAuth-Scope `drive.readonly` fehlt          | Google re-consent: Trennen → Verbinden |
| HTTP 404                  | Ordner-ID existiert nicht / kein Zugriff    | Drive-Ordner-Link im Airtable prüfen   |

**Tab „Dateien" testen:** Projekt → Tab „Dateien" → FilesTabView zeigt alle Dateien
nach Änderungszeit sortiert.

**Tab „Angebote" testen:** Projekt → Tab „Angebote" → OffersTabView zeigt nur PDFs
mit Schlüsselwort (angebot/rechnung/kostenvoranschlag/offer/invoice).

---

### Schritt 4 — ClickUp Live (wenn IDs verfügbar, 30 min)

ClickUp-Listen-IDs sind noch nicht in Airtable eingetragen (`clickUpListID: 0/31`).

**Optionen:**
- A) Johannes trägt ClickUp-Listen-IDs manuell in Airtable ein → Sync → TasksWidget live
- B) Session zeigt nur „Noch leer" / „Verbindung nötig" — valider Zustand für jetzt

**Was schon fertig ist:** `TasksWidget` reagiert auf `clickUpListID == nil` mit
`.empty`-State (nicht Fehler), keine Crashes.

---

### Schritt 5 — Galerie-Filter (Code, 30 min)

Kleine UI-Verbesserung nach dem Live-Check: Projekte nach Jahr oder Phase filtern.

```swift
// ProjectGalleryView — Erweiterung des bestehenden Suche-Bars:
// Segmented Picker "Alle / 2026 / 2025 / Älter"
// Filtert filtered-Array nach Jahr aus projectNumber
```

Nur umsetzen wenn Schritte 1-3 grün sind.

---

## Datenpfad — wie Daten in die App kommen

```
Airtable Mastermind                    Google Drive
appuVMh3KDfKw4OoQ                      31 Projektordner
    │                                       │
    │  syncFromAirtable()                   │  DriveWidget.load()
    ▼                                       ▼
CachedProjectRegistry (GRDB)           GoogleDriveClient
    │  allProjects()                        │  files.list(folderID)
    ▼                                       ▼
RegistryStore.projects[]              WidgetContainer(loading/content/empty/error)
    │  ProjectGalleryView
    ▼
ProjectDetailView
    → project.links.driveFolderID ──────────────────────────▶ DriveWidget
    → project.links.clickUpListID ──────────────────────────▶ TasksWidget
    → project.links.calendarQuery ──────────────────────────▶ CalendarWidget
    → project.links.mailQuery ──────────────────────────────▶ MailWidget
    → project.links.sevdeskRef + budget ────────────────────▶ CashWidget
```

---

## Was NICHT in dieser Session

- Clockodo Zeitbuchungs-Flow (eigene Session, Architektur in HANDOFF_LIVE_WIRING_4.md)
- Kalkulations-Chat-Tool S18 (eigene Session)
- Neues Airtable-Schema schreiben oder Records anlegen
- Drive-Dateien herunterladen oder schreiben

---

## Startprompt für die Session

```
Pfad:   /Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilOS Mac/
Branch: main  (Fallback: git checkout ui/sidebar-ci-stable)
Build:  swift build && swift test → muss grün sein bevor irgendetwas passiert
Datum:  nach 2026-06-28

SESSION-ZIEL: Echte Daten live in allen Widgets

VORAUSSETZUNG (Johannes manuell):
  Settings → Airtable → Base-ID = appuVMh3KDfKw4OoQ (nicht der PAT)

SCHRITT 1: RegistryStore.swift Zeile 37 → projectNumber statt updatedAt
SCHRITT 2: Airtable-Sync live testen (Settings → Sync-Button), Fehler dokumentieren
SCHRITT 3: DriveWidget live testen (ein Projekt öffnen, alle Widget-States prüfen)
SCHRITT 4: ClickUp (nur wenn Johannes IDs in Airtable eingetragen hat)
SCHRITT 5: Galerie-Filter (nur wenn Schritte 1-3 grün)

Bei jedem Schritt: kurz dokumentieren was kam (State, Fehler, Screenshot-Beschreibung).
Handoff am Ende aktualisieren.

KEIN Schreiben in externe Systeme. Read-only überall.
```
