# STARTPROMPT S20 — Drive Live, Board-Reset, Keychain, Airtable-Writes

```
Pfad:   /Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilOS Mac/
Branch: claude/elegant-nobel-ee5ece  (S17+S18+S19 fertig, 217 Tests)
Build:  swift build && swift test
Datum:  2026-06-28
Modell: claude-sonnet-4-6 · Effort: max
```

---

## 🚨 P0-HARD-GATE VOR JEGLICHER S20-AUFGABE

Der Projekt-Tab „Übersicht“ erzeugt weiterhin eine überbreite, unsichtbare
Hit-Test-Fläche über der Sidebar. Die Sidebar bleibt sichtbar, ist dann aber
nicht anklickbar; Hero und Tab-Leiste werden links abgeschnitten.

Das ist **kein Sidebar-Ausblendzustand** und durch `dd235ab` nicht live behoben.
Vor Keychain-, Board-, Drive- oder Timeline-Arbeit zuerst:

1. `docs/handoffs/HANDOFF_P0_OVERVIEW_SIDEBAR_HITTEST.md` lesen.
2. Grid-/Widget-Board-Breite wirklich auf das rechte Pane begrenzen.
3. Sidebar-Klicks bei aktiver Übersicht sofort und nach 300/800/1800 ms live prüfen.
4. Erst bei dokumentierter Live-Abnahme mit den S20-Aufgaben fortfahren.

---

## ⚠️ BEVOR DU ANFÄNGST — Johannes muss das MANUELL tun

Diese zwei Schritte kann kein Code lösen. Sag Johannes vor dem Build:

```
1. Einstellungen → Airtable
   → Base-ID Feld: alten Inhalt löschen
   → "appuVMh3KDfKw4OoQ" eintragen → Speichern
   → Sync-Button drücken
   Warum: Im Keychain steht ein PAT statt der Base-ID → Sync schlägt still fehl

2. Einstellungen → Google
   → Verbindung trennen → neu verbinden (Re-Consent erforderlich)
   Warum: S17 hat neue Scopes hinzugefügt (userinfo.email/profile) → altes
   Token kennt sie nicht → Drive, Mail, Kalender zeigen permissionRequired
```

Erst danach starten.

---

## AUFGABEN IN DIESER SESSION

### Aufgabe 0 — Pflichtcheck (erst dann weitermachen)

```bash
cd "/Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilOS Mac"
git checkout claude/elegant-nobel-ee5ece
swift build && swift test 2>&1 | tail -5
# Muss: 217 Tests grün
```

---

### Aufgabe 1 — Keychain: 18 Prompts auf 0 senken

**Root Cause:** Alte Keychain-Items wurden vor dem `makeAllowAllApplicationsAccess`-Fix
gespeichert und haben noch die alte ACL gebunden an den damaligen Binary-Hash.
Jeder `swift build` erzeugt einen neuen Hash → macOS sieht eine "neue App" → Dialog.

**Fix:** In `KeychainStore.load()` nach erfolgreichem Read sofort `store()` aufrufen.
Das migriert den ACL des bestehenden Items auf "allow all" — einmalig, nie wieder Dialog.

**Datei:** `Sources/MykilosServices/Google/KeychainStore.swift`

```swift
// In load(service:account:) — nach der erfolgreichen String-Extraktion:
// Jetzt statt:
return value

// So:
// ACL-Migration: re-store mit "allow all" damit kein Prompt beim nächsten Laden
try? store(value, service: service, account: account)
return value
```

Danach: App starten, alle Integrationen in Einstellungen einmal öffnen → kein einziger Keychain-Dialog mehr.

---

### Aufgabe 2 — Einheitliches Board-Layout (kein per-Kind-Unterschied mehr)

Johannes-Entscheid: ALLE Projekttypen bekommen dasselbe Layout. Keine Unterscheidung
nach kitchen/lighting/addendum/lead/studioInternal mehr.

**Schritt 2a — Layout vereinheitlichen:**

**Datei:** `Sources/MykilosKit/Domain/WidgetFoundation.swift`

Ersetze die gesamte `WidgetBoardDefault.layout(for kind:)` Funktion:

```swift
public enum WidgetBoardDefault {
    // Einheitliches Layout für alle Projekttypen.
    // Johannes-Entscheid 2026-06-28: kein per-Kind-Unterschied.
    public static var projectLayout: [WidgetInstance] {[
        WidgetInstance(kind: .drive,     size: .wide,   position: 0),
        WidgetInstance(kind: .contacts,  size: .medium, position: 1),
        WidgetInstance(kind: .tasks,     size: .medium, position: 2),
        WidgetInstance(kind: .cash,      size: .wide,   position: 3),
        WidgetInstance(kind: .calendar,  size: .medium, position: 4),
        WidgetInstance(kind: .notes,     size: .medium, position: 5),
        WidgetInstance(kind: .assistant, size: .full,   position: 6),
    ]}

    // Rückwärtskompatibilität — alte Aufrufer nicht brechen
    public static func layout(for kind: ProjectKind) -> [WidgetInstance] {
        projectLayout
    }
}
```

**Schritt 2b — GRDB-Migration: alte Boards zurücksetzen**

Alte Boards in GRDB haben AssistantWidget an Position 0 (alter Default).
Fix: GRDB-Migration die alle `widget_instances`-Zeilen löscht →
beim nächsten Öffnen greift das neue einheitliche Layout.

**Datei:** `Sources/MykilosServices/Database/GRDBDatabase.swift` (oder wo die Migrationskette liegt)

In der nächsten Migrationsnummer (nach der letzten bestehenden) hinzufügen:

```swift
migrator.registerMigration("v_board_layout_reset_2026_06_29") { db in
    try db.execute(sql: "DELETE FROM widget_instances")
}
```

Danach: alle Projekte beim Öffnen zeigen das neue einheitliche Layout.

---

### Aufgabe 3 — Zeichnungen-Tab (02 CAD Subfolder)

Alle anderen Tabs sind fertig. Nur der CAD-Tab fehlt noch.

**Schritt 3a — Tab-Enum erweitern:**

**Datei:** `Sources/MykilosApp/Detail/ProjectDetailView.swift`

In `enum ProjectTab`:
```swift
// Aktuell:
case overview = "Übersicht"; case chat = "Assistent"
case files = "Dateien"; case offers = "Angebote"
case timeline = "Timeline"; case material = "Material"

// Neu — Zeichnungen hinzufügen:
case overview = "Übersicht"; case chat = "Assistent"
case files = "Dateien"; case offers = "Angebote"
case drawings = "Zeichnungen"              // NEU
case material = "Material"; case timeline = "Timeline"
```

**Schritt 3b — TabContent-Switch ergänzen:**

In `tabContent`:
```swift
case .drawings:
    DrawingsTabView(
        projectID: project.projectNumber,
        driveFolderID: project.links.driveFolderID
    )
    .padding(.horizontal, MykSpace.s9)
    .padding(.top, MykSpace.s7)
    .padding(.bottom, 64)
```

**Schritt 3c — DrawingsTabView erstellen:**

**Neue Datei:** `Sources/MykilosApp/Detail/DrawingsTabView.swift`

Kopiere `MaterialTabView.swift` 1:1, ändere nur:
- `MaterialLoader` → `DrawingsLoader`
- Subfolder-Suche: statt `präsentation`/`presentation` suche nach `cad`
- Header-Text: `"Zeichnungen & CAD-Pläne"`
- Leer-Text: `"Keine Dateien im CAD-Ordner"`
- Icon für `.dwg`, `.dxf`: `"pencil.and.ruler"` — sonst gleich wie Material

Loader sucht (tolerant): Name enthält `"cad"` oder `"zeichnung"` (lowercase).

---

### Aufgabe 4 — Timeline-Tab: Google Kalender statt Platzhalter

**Datei:** `Sources/MykilosApp/Detail/ProjectDetailView.swift`

In `tabContent`, `case .timeline` austauschen:

```swift
case .timeline:
    TimelineTabView(
        projectID: project.projectNumber,
        calendarQuery: project.links.calendarQuery
    )
    .padding(.horizontal, MykSpace.s9)
    .padding(.top, MykSpace.s7)
    .padding(.bottom, 64)
```

**Neue Datei:** `Sources/MykilosApp/Detail/TimelineTabView.swift`

Nutze den bestehenden `GoogleCalendarClient` (identische Architektur wie CalendarWidget).
Zeige Events sortiert nach Datum, kompaktes Layout: Datum links, Titel rechts, Uhrzeit.
Alle WidgetRenderStates (loading, empty, permissionRequired, error, content).
Source-Label: `"GOOGLE KALENDER · N TERMINE"`.

---

### Aufgabe 5 — Airtable-Writes: createRecord hinzufügen

**Schritt 5a — AirtableClient um Write-Methode erweitern:**

**Datei:** `Sources/MykilosServices/Airtable/AirtableClient.swift`

Neue Methode hinzufügen (nach den bestehenden read-Methoden):

```swift
public func createRecord(
    baseID: String,
    tableIDOrName: String,
    fields: [String: AirtableFieldValue]
) async throws {
    guard let url = URL(string: "https://api.airtable.com/v0/\(baseID)/\(tableIDOrName)") else {
        throw AirtableError.invalidURL
    }
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("Bearer \(pat)", forHTTPHeaderField: "Authorization")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    let body: [String: Any] = ["fields": fields.mapValues(\.jsonValue)]
    request.httpBody = try JSONSerialization.data(withJSONObject: body)

    let (data, response) = try await session.data(for: request)
    guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
        throw AirtableError.httpError((response as? HTTPURLResponse)?.statusCode ?? -1)
    }
    // Record-ID aus Response ignorieren — nur Erfolg/Fehler relevant
    _ = data
}
```

`AirtableFieldValue` braucht `var jsonValue: Any` — ergänze die Extension.

**Schritt 5b — DriveOffer → Airtable "Eingehende-Angebote"**

Tabelle: `Eingehende-Angebote` in base `appuVMh3KDfKw4OoQ`
Felder: `SHA256` (Datei-ID als Proxy), `Datei-Name`, `Projekt-Nr`, `Richtung`, `Status`

Wo einhängen: In `AppState` oder `RegistryStore`, nach dem der `DriveOfferWatcher`
eine Signal `.offerDetected(projectID, label)` emittiert hat UND der User via
`CashWidget`-Action-Card bestätigt hat (im `AuditStore.append`-Pfad).

Konkret: In `CashWidget` oder `AuditStore.append(_:)`, wenn `AuditEntry.kind == .reviewAccepted`:
```swift
// Nach append in GRDB: auch nach Airtable schreiben
Task {
    try? await airtableClient.createRecord(
        baseID: "appuVMh3KDfKw4OoQ",
        tableIDOrName: "Eingehende-Angebote",
        fields: [
            "Datei-Name": .string(entry.label ?? ""),
            "Projekt-Nr": .string(entry.projectID ?? ""),
            "Richtung": .string("eingehend"),
            "Status": .string("Erkannt"),
        ]
    )
}
```

Fehler: still loggen (`print`) — nie UI-blockierend. Airtable ist Backup, nicht Haupt-DB.

**Schritt 5c — Kalkulation → Airtable "Kalkulations-Positionen"**

Tabelle: `Kalkulations-Positionen` in base `appuVMh3KDfKw4OoQ`
Felder: `Bezeichnung`, `Kategorie`, `Einzelpreis`, `Gesamt`, `Notiz`

Wo einhängen: In `KalkulationsWidget`, wenn User die ActionCard bestätigt
(gleicher Pfad wie `AuditEntry(.estimateAdjusted)`), schreibe zusätzlich:
```swift
Task {
    try? await airtableClient.createRecord(
        baseID: "appuVMh3KDfKw4OoQ",
        tableIDOrName: "Kalkulations-Positionen",
        fields: [
            "Bezeichnung": .string(schaetzung.beschreibung),
            "Kategorie": .string("Tischlerarbeit"),
            "Einzelpreis": .number(schaetzung.mittleresNetto),
            "Gesamt": .number(schaetzung.mittleresNetto),
            "Notiz": .string("mykilOS Schätzung · \(projektID)"),
        ]
    )
}
```

**WICHTIG:** NIEMALS in `appdxTeT6bhSBmwx5` (Artikel-DB) schreiben — READ ONLY.

---

### Aufgabe 6 — Airtable Base-ID: klare Fehlermeldung in Settings

Wenn `AirtableAuthService.connect()` `AirtableError.invalidBaseID` wirft,
muss die Settings-UI eine klare Fehlermeldung zeigen.

**Datei:** `Sources/MykilosApp/Shell/SettingsView.swift` (oder wo der Airtable-Abschnitt liegt)

Ergänze nach dem Base-ID-TextField:

```swift
if case .failed(let msg) = airtableAuth.status {
    Text("⚠️ " + msg)
        .font(.mykMono(10))
        .foregroundStyle(MykColor.critical.color)
    Text("Base-ID muss mit 'app' beginnen, z.B.: appuVMh3KDfKw4OoQ")
        .font(.mykMono(9.5))
        .foregroundStyle(MykColor.muted.color)
}
```

---

### Aufgabe 7 — Assistent-Ton (BEREITS ERLEDIGT von S10 Learning)

`Sources/MykilosServices/AssistantGrounding.swift` ist bereits gefixt:
- Keine Emojis
- Keine Floskeln
- Kein KI-Selbstbezug
- Ton: sachlicher Kollege

**Nichts tun — nur bestätigen dass die Änderung im Build grün ist.**

---

### Aufgabe 8 — Tests für neue Features

Für jeden neuen Code: mindestens 1 Test.

- `DrawingsTabView`: kein eigener Test nötig (UI-only, Loader folgt MaterialLoader-Muster)
- `AirtableClient.createRecord`: 1 Test mit FakeHTTPSession — prüft HTTP-Methode POST,
  URL-Aufbau, Authorization-Header, JSON-Body
- Board-Migration: 1 Cold-Start-Test — Board laden, Migration läuft, Board hat neues Layout

Ziel: ≥ 222 Tests grün.

---

## REIHENFOLGE

```
1. git checkout claude/elegant-nobel-ee5ece
2. swift build && swift test  → 217 grün
3. Aufgabe 1 (Keychain)       → sofort spürbar
4. Aufgabe 2 (Board-Layout)   → Migration + Layout
5. Aufgabe 3 (Zeichnungen)    → neuer Tab
6. Aufgabe 4 (Timeline)       → Calendar statt Platzhalter
7. Aufgabe 5 (Airtable-Write) → createRecord + 2 Write-Pfade
8. Aufgabe 6 (BaseID-Error)   → UI-Fehler
9. swift build && swift test  → alle grün
10. HANDOFF
```

---

## NICHT ANFASSEN

```
- appdxTeT6bhSBmwx5 (Artikel-DB): READ ONLY, nie schreiben
- appkPzoEiI5eSMkNK (stillgelegte Base): nie anfassen
- Sevdesk-API: nie lesen oder schreiben
- git add -A: verboten → immer explizite Dateipfade
- Push: nur nach Johannes' expliziter Freigabe
- try? ohne Kommentar
```

---

## HANDOFF-PFLICHT (Statut 13)

Kein STOP ohne:
1. `swift build && swift test` → grün
2. `git add <nur eigene Dateien>` — explizit
3. `git commit` mit aussagekräftiger Message
4. `docs/EREIGNISPROTOKOLL.md` — neuer Eintrag
5. `CLAUDE.md` — S20-Zeile in Tabelle
6. `docs/handoffs/STARTPROMPT_S21.md` — vollständig
7. Erfahrungsbericht an S10 Learning (keen-williamson-ddb354)
8. STOP — Push-Freigabe von Johannes abwarten

---

## MANUELLE SCHRITTE (nach dem Build — Johannes tut das)

```
Schritt A: App starten → Einstellungen → Airtable
  → Base-ID: "appuVMh3KDfKw4OoQ" eintragen → Speichern → Sync

Schritt B: Einstellungen → Google → trennen → neu verbinden
  → Re-Consent für neue Scopes aus S17

Schritt C: Einstellungen → Alle anderen Keys prüfen
  → Clockodo, sevdesk, Claude API, ClickUp
  → Nach Keychain-Fix: kein einziger Prompt mehr
```

---

*Erstellt: S10 Learning (mykilOS 6 Entwicklungsteam), 2026-06-28*
*Vorige Session: S19 (Artikel-Suche-Tool, 217 Tests, Branch claude/elegant-nobel-ee5ece)*
