# Handoff: Identitätsmodell härten + Wire-by-Wire Bestätigung

```
Pfad:   /Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilOS Mac/
Branch: main
Build:  ✅ swift build grün
Tests:  ✅ 192 Tests grün
Datum:  2026-06-28
Fallback: git checkout ui/sidebar-ci-stable
```

---

## Zwei Ziele dieser Session

### A — Identitätsmodell härten (Code, ~90 min)

Das aktuelle Modell ist zweigeteilt und unvollständig:
- `UserProfile` (lokal, manuell): displayName + role — kein Service-Bezug
- `GoogleUserInfo` (OAuth): email + displayName — kein Persistenz nach App-Neustart
- 6 Service-Verbindungen (Google/Clockodo/ClickUp/Sevdesk/Airtable/Claude) — je in eigener Sektion in Settings, kein Gesamtbild

**Ziel:** Eine unified „Wer bin ich?"-Ansicht + härteres Domain-Modell.

### B — Wire-by-Wire Bestätigung (Live, ~60 min)

Johannes bestätigt jeden Daten-Draht einzeln in der laufenden App.
Checkliste mit exakten Schritten und erwarteten Ergebnissen (siehe unten).

---

## TEIL A: Identitätsmodell — was zu bauen ist

### A1 — `UserProfile` um Integrations-IDs erweitern

**Datei:** `Sources/MykilosKit/Domain/UserProfile.swift`

```swift
public struct UserProfile: Equatable, Sendable, Codable {
    public var displayName: String
    public var role: String
    public var clockodoUserID: String?   // NEU: Clockodo-User-ID für Scoping
    public var googleDomain: String?     // NEU: Domain aus Google-Login (mykilos.com)
    public var updatedAt: Date
}
```

Warum: `ClockodoDraftEntry` filtert auf GRDB-Ebene per User. Ohne feste
`clockodoUserID` müsste die App nach Google-Login + Clockodo-Nutzertabelle
matchen — das ist fragil. Direkte Speicherung ist robuster.

### A2 — `IdentityView` in Settings (neue Sektion ganz oben)

**Neue Datei:** `Sources/MykilosApp/Settings/IdentityView.swift`

Einbetten als erste Sektion in `SettingsView`, vor allen Integrations-Sektionen.

Layout:
```
┌─────────────────────────────────────────────────────┐
│  WER BIN ICH                                        │
│  ┌─────────────────────────────────────────────┐   │
│  │ ● [Google] Johannes Leo Berger              │   │
│  │           johannes@mykilos.com              │   │
│  │           Verbunden seit 27. Juni 2026      │   │
│  └─────────────────────────────────────────────┘   │
│                                                     │
│  Anzeigename  [Johannes Leo Berger        ]         │
│  Rolle        [Studio Director            ]         │
│  Clockodo-ID  [123456                     ]   NEU  │
│                                                     │
│  Speichern                                          │
└─────────────────────────────────────────────────────┘
```

Regeln:
- Google-Block: read-only, zeigt was aus dem OAuth kommt (GoogleUserInfo)
- Anzeigename/Rolle: editierbar (überschreibt Displayname wenn ausgefüllt)
- Clockodo-ID: Freitext (aus Airtable-Tabelle `Clockodo-Nutzer` nachschlagen)
- Nur sichtbar wenn `googleAuth.status == .connected` → sonst nur lokales Profil

### A3 — `IntegrationStatusView` — alle Drähte auf einen Blick

**Neue Datei:** `Sources/MykilosApp/Settings/IntegrationStatusView.swift`

Einbetten nach IdentityView, vor den einzelnen Sektionen.

```
VERBINDUNGEN

● Google       johannes@mykilos.com    [Verbunden ✓]  [Trennen]
● Airtable     appuVMh3KDfKw4OoQ      [Verbunden ✓]  [Trennen]
● Claude       claude-sonnet-4-6       [Verbunden ✓]  [Trennen]
○ Clockodo     —                       [Nicht verbunden][Verbinden]
○ ClickUp      —                       [Nicht verbunden][Verbinden]
○ Sevdesk      —                       [Nicht verbunden][Verbinden]
```

Jede Zeile: Farbpunkt (grün/rot/gelb) + Service-Name + Konto-Info + Button.
Klick auf Zeile öffnet die Detail-Sektion (nicht navigiert, expandiert).

Dies ersetzt das Profil-Widget unten in der Sidebar NICHT — das bleibt.
Es ist die vollständige Übersicht in Settings für Onboarding + Debugging.

### A4 — `GoogleUserInfo` nach Neustart persistieren

**Problem:** `GoogleAuthService.currentUser` (`GoogleUserInfo`) ist nur im RAM.
Nach App-Neustart ist er nil bis zum ersten erfolgreichen Token-Refresh.
→ Sidebar zeigt kurz "Profil einrichten" statt den echten Namen.

**Fix:** `GoogleUserInfo` in UserDefaults o. Keychain persistieren.
Empfehlung: UserDefaults (kein Secret), Key `com.mykilos6.google.cachedUserInfo`.

```swift
// GoogleAuthService: nach fetchUserInfo() speichern
// GoogleAuthService.init(): aus UserDefaults laden als Startwert
// Wird bei disconnect() gelöscht
```

---

## TEIL B: Wire-by-Wire Bestätigung (Checkliste)

Für Johannes: jeden Schritt in der App live durchführen.
Bei jedem Schritt: Ergebnis notieren (✅ / ❌ + Fehlermeldung).

### Voraussetzung (manuell vor Session-Start)

```
□ Settings → Airtable → Base-ID = appuVMh3KDfKw4OoQ  (nicht der PAT!)
□ App neu starten
□ swift build && swift test → grün
```

---

### Wire 1: Airtable Sync

**Schritt:** Settings → Airtable → Button „Jetzt synchronisieren"

**Erwartung:**
- Spinner kurz sichtbar
- Galerie lädt neu → echte Projektnamen erscheinen (Schmidt, vonBoch, Rodewyk …)
- Keine Fehlermeldung in der Galerie

**Wenn Fehler:**
| Fehler                        | Ursache                         | Fix                                    |
|-------------------------------|----------------------------------|----------------------------------------|
| „Base-ID ungültig"            | Noch der PAT eingetragen         | Base-ID = appuVMh3KDfKw4OoQ            |
| HTTP 401                      | PAT abgelaufen / falsch          | Neuen PAT aus Airtable holen           |
| HTTP 403                      | PAT ohne Lese-Rechte             | PAT-Scope: `data.records:read`         |
| Galerie leer nach Sync        | Tabellen-Namen stimmen nicht     | AirtableRegistry.swift: Tabellennamen prüfen |

**Notieren:** Wieviele Projekte nach Sync? (Soll: 31) Wieviele Kunden? (Soll: 30)

---

### Wire 2: Google Drive

**Voraussetzung:** Settings → Google → Verbinden (OAuth-Flow abschließen)

**Schritt:** Ein Projekt öffnen (z.B. vonBoch 2026-023) → Tab Übersicht → DriveWidget

**Erwartung:**
- DriveWidget zeigt Dateiliste aus Drive-Ordner
- Quellenzeile unten: „GOOGLE DRIVE · N DATEIEN"

**Wenn „Verbindung nötig":**
→ Google Trennen → neu Verbinden → Scopes bestätigen (drive.readonly muss dabei sein)

**Wenn „Noch leer" (0 Dateien):**
→ driveFolderID des Projekts prüfen: `docs/registry/projekte.json` → `links.driveFolderID`
→ Direkt in Drive browser: https://drive.google.com/drive/folders/{driveFolderID}

**Zusatz-Check:** Tab „Dateien" → FilesTabView → alle Dateien chronologisch

**Zusatz-Check:** Tab „Angebote" → OffersTabView → nur PDFs mit angebot/rechnung im Namen

---

### Wire 3: Google Kalender

**Schritt:** Projekt öffnen → Tab Übersicht → CalendarWidget

**Erwartung:** Termine der nächsten 14 Tage mit `calendarQuery` als Suchbegriff

**Wenn leer:** calendarQuery des Projekts in projekte.json prüfen

---

### Wire 4: Gmail

**Schritt:** Projekt öffnen → Tab Übersicht → MailWidget

**Erwartung:** Letzte E-Mails gefiltert nach `mailQuery` des Projekts

---

### Wire 5: ClickUp

**Schritt:** Projekt öffnen → Tab Übersicht → TasksWidget

**Erwartung (aktuell):** „Noch leer" — keine `clickUpListID` eingetragen
**Was zu tun:** Liste in Airtable-Tabelle `Projekte`, Spalte `ClickUp-Liste` eintragen
  → Sync → TasksWidget zeigt offene Tasks

---

### Wire 6: Sevdesk / Cash

**Schritt:** Projekt öffnen → Tab Übersicht → CashWidget

**Erwartung (aktuell):** „Kein sevdesk-Kontakt verknüpft"
**Was zu tun:** `sevdeskRef` + `budget` in Airtable eintragen → Sync

---

### Wire 7: Assistent / Claude

**Schritt:** Tab Assistent (global oder in Projekt) → Nachricht schreiben

**Erwartung:** Antwort auf Deutsch, direkt, ohne Floskeln, mit Projektkontext

---

### Wire 8: Kalkulation

**Schritt:** Sidebar → Kalkulation → Beschreibung eingeben → „Schätzen"

**Erwartung:** Kosten-Schätzung mit Konfidenz-Badge + Evidenzen

---

## Bestätigungs-Tabelle (zum Ausfüllen)

```
Wire           Status    Notiz
─────────────────────────────────────────────────────────
Airtable Sync  □         Projekte: __  Kunden: __
Drive          □         Projekt: vonBoch  Dateien: __
Kalender       □         Termine sichtbar: ja/nein
Gmail          □         Mails sichtbar: ja/nein
ClickUp        □         IDs eingetragen: ja/nein
Cash/Sevdesk   □         Refs eingetragen: ja/nein
Claude         □         Antwort korrekt: ja/nein
Kalkulation    □         Schätzung erscheint: ja/nein
```

---

## Startprompt für die Session

```
Pfad:   /Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilOS Mac/
Branch: main
Fallback: git checkout ui/sidebar-ci-stable

SESSION-ZIEL A (Code): Identitätsmodell härten
  1. UserProfile + clockodoUserID + googleDomain
  2. IdentityView (Wer bin ich, ganz oben in Settings)
  3. IntegrationStatusView (alle 6 Drähte auf einen Blick)
  4. GoogleUserInfo persistieren (UserDefaults nach Login)

SESSION-ZIEL B (Live mit Johannes): Wire-by-Wire Bestätigung
  Checkliste in HANDOFF_IDENTITY_AND_WIRE_CHECK.md, Abschnitt "TEIL B"
  Jeden Wire einzeln bestätigen, Ergebnis notieren.
  Bei jedem Fehler: erst dokumentieren, dann fixen.

REIHENFOLGE:
  1. swift build && swift test (muss grün)
  2. Code A1-A4 umsetzen (Identity)
  3. Neu bauen + starten
  4. Wire B1 (Airtable) — braucht manuellen Base-ID-Fix von Johannes
  5. Wire B2 (Drive) — braucht Google OAuth
  6. Wire B3-B8 nacheinander
  7. Bestätigungs-Tabelle ausfüllen + in Handoff speichern
  8. Handoff aktualisieren

KEIN Schreiben in externe Systeme außer lesend.
```
