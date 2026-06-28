# mykilOS 6 — Master Status & Startprompt (2026-06-28)

```
Pfad:    /Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilOS6/
Branch:  main
Commit:  9a3dbbf
Build:   ✅ swift build grün
Tests:   ✅ 192 Tests grün (30 Suites)
Modell:  claude-sonnet-4-6
Level:   Beta-bereit — UI stabil, Daten-Wiring offen
Fallback: git checkout ui/sidebar-ci-stable  (Tag, unveränderlich)
Datum:   2026-06-28
```

---

## Startprompt für die nächste Session

```
Pfad:   /Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilOS6/
Branch: main
Modell: claude-sonnet-4-6

PFLICHTCHECK VOR ALLEM:
  swift build   → muss grün
  swift test    → muss grün (192 Tests)
  git status    → muss clean
  Fallback-Tag: ui/sidebar-ci-stable

SESSION-ZIEL: Identitätsmodell härten + Wire-by-Wire Live-Bestätigung

PHASE A — Code (erst alleine, kein Johannes nötig):
  A1: UserProfile + clockodoUserID: String? + googleDomain: String? (MykilosKit)
  A2: IdentityView — „Wer bin ich?" oben in Settings (Google read-only + lokale Felder)
  A3: IntegrationStatusView — 6 Services Traffic-Light (Settings, nach A2)
  A4: GoogleUserInfo in UserDefaults persistieren (kein Flackern nach Neustart)
  → Build + Test nach jedem Schritt

PHASE B — Live mit Johannes (nacheinander, jeder Schritt bestätigt):
  Voraussetzung: Johannes setzt Base-ID = appuVMh3KDfKw4OoQ in Settings → Airtable
  B1: Airtable Sync → 31 Projekte in Galerie
  B2: Drive → vonBoch öffnen → DriveWidget lädt Dateien
  B3: Kalender → CalendarWidget → Termine
  B4: Mail → MailWidget → E-Mails
  B5: ClickUp → erst wenn Johannes IDs in Airtable einträgt
  B6: Cash → erst wenn sevdeskRef/Budget in Airtable
  B7: Claude → Assistent antwortet korrekt
  B8: Kalkulation → Schätzung erscheint

NICHT IN DIESER SESSION:
  - Clockodo Zeitbuchungs-Flow (eigene große Session)
  - S18 Kalkulations-Chat-Tool
  - Archiv-Projekte importieren
  - Schreiben in externe Systeme
```

---

## Modell & Level

| Feld          | Wert                                         |
|---------------|----------------------------------------------|
| **App-Modell** | claude-sonnet-4-6 (Anthropic Messages API)  |
| **App-Version** | 6.4.0 (Build 4)                             |
| **Level**      | Beta-bereit                                 |
| **UI-Status**  | Stabil + Fallback-Tag gesetzt               |
| **Daten**      | Seed-Daten (JSON) — Airtable-Sync ausstehend |
| **Identität**  | GoogleUserInfo vorhanden, nicht persistiert |
| **Team**       | Johannes Leo Berger (Studio Director)       |
| **Plattform**  | macOS 14+, SwiftUI, local-first             |

---

## Verzeichnis-Status — alle Daten festgeschrieben

### `docs/registry/projekte.json` — 31 Projekte

| Feld           | Status       | Anmerkung                               |
|----------------|--------------|-----------------------------------------|
| projectNumber  | ✅ 31/31     | Format JJJJ-NNN                         |
| title          | ✅ 31/31     |                                         |
| driveFolderID  | ✅ 31/31     | Direkte Ordner-IDs, verifiziert via Drive-Screenshot |
| calendarQuery  | ✅ 30/31     | 2026-001 MYKILOS fehlt (internes Projekt) |
| mailQuery      | ✅ 30/31     | 2026-001 MYKILOS fehlt                  |
| clickUpListID  | ❌ 0/31      | IDs müssen in Airtable eingetragen werden |
| sevdeskRef     | ❌ 0/31      | Refs müssen in Airtable eingetragen werden |
| budget         | ❌ 0/31      | Budgets müssen in Airtable eingetragen werden |

### `docs/registry/kunden.json` — 30 Kunden

✅ Vollständig. Alle Kunden mit customerNumber + name.

### Airtable Mastermind `appuVMh3KDfKw4OoQ`

| Tabelle                   | Records | Status          |
|---------------------------|---------|-----------------|
| Projekte                  | 31      | ✅ live          |
| Kunden                    | 30      | ✅ live          |
| Externe Systeme           | 8       | ✅ live          |
| Clockodo-Nutzer           | 4       | ✅ live          |
| Clockodo-EW-Johannes      | 0       | ✅ bereit        |
| Clockodo-Leistungen       | 8       | ⚠️ Stundensätze leer |
| Clockodo-Buchungen        | 0       | ✅ bereit (Audit-Log) |
| Kalkulationen             | 0       | ✅ bereit        |
| Kalkulations-Positionen   | 0       | ✅ bereit        |
| Eingehende-Angebote       | 0       | ✅ bereit        |

### Google Drive `1Q-H_3JsZfiXosFmxtNgoy0hI3cvZLgST`

✅ Verifiziert via Screenshot 2026-06-28. PROJEKTE-Root = korrekte ID.
31 Projektordner vorhanden (22 im Screenshot sichtbar, 9 abgeschnitten — alle im Ordner).

**Auffälligkeit:** `2026_20_Liebig_Quooker` → fehlende führende Null (sollte `2026_020`).
Kein App-Bug (direkte Folder-ID), aber Umbenennung in Drive empfohlen.

---

## Offene Bugs (bekannt, nicht kritisch)

| # | Bug | Schwere | Wo | Fix |
|---|-----|---------|-----|-----|
| B1 | Airtable Base-ID enthält PAT statt `appuVMh3KDfKw4OoQ` | 🔴 Blocker für Sync | Settings → Airtable | Johannes manuell |
| B2 | GoogleUserInfo nicht persistiert → Sidebar flackert nach Neustart | 🟡 UX | GoogleAuthService | A4 nächste Session |
| B3 | `2026_20_Liebig_Quooker` fehlende führende Null im Drive-Ordnernamen | 🟢 Kosmetisch | Google Drive | Johannes in Drive umbenennen |
| B4 | Projekt 2026-001 MYKILOS ohne calendarQuery/mailQuery | 🟢 Datenlücke | projekte.json | Eintragen oder bewusst leer lassen |
| B5 | Google Re-Consent nach S17 nicht verifiziert (neue Scopes: userinfo) | 🟡 Auth | GoogleAuthService | Live: Trennen → neu Verbinden |
| B6 | PAT-Cleanup ausstehend: alten PAT in Airtable revoken | 🟡 Security | Airtable PAT-Verwaltung | Johannes manuell |
| B7 | Clockodo-Stundensätze leer in Airtable | 🟡 Funktional | Airtable Clockodo-Leistungen | Johannes manuell eintragen |
| B8 | Tooltip Sidebar-Toggle sagt noch `⌘\` statt `⌘⇧S` | 🟢 Kosmetisch | MykilOS6App.swift:167 | 1-Zeilen-Fix |

---

## Offene Baustellen (mittel- bis langfristig)

### 🔴 Muss vor echtem Beta-Betrieb

| Baustelle | Was fehlt | Session |
|-----------|-----------|---------|
| Airtable Sync live | Base-ID-Fix + Live-Verifikation | Nächste Session B1 |
| Drive live | Google OAuth aktiv + 1 Projekt testen | Nächste Session B2 |
| Identitätsmodell | IdentityView + UserProfile-Erweiterung | Nächste Session A1-A4 |
| Google Re-Consent | Neue Scopes bestätigen | Nächste Session B2 |

### 🟡 Wichtig, aber nicht blockierend

| Baustelle | Was fehlt | Session |
|-----------|-----------|---------|
| ClickUp-IDs | 31 Listen-IDs in Airtable eintragen → Sync | Nach B1 |
| sevdeskRef + Budget | Refs + Budgets in Airtable eintragen → Sync | Nach B1 |
| Clockodo Zeitbuchungs-Flow | 6-Schichten-Architektur (HANDOFF_LIVE_WIRING_4.md) | Eigene Session |
| S18 Kalkulations-Chat-Tool | ConversationEngine + schaetze-Tool | Eigene Session |
| Galerie-Filter | Segmented Picker nach Jahr/Phase | ~30 min Sprint |
| Projektsortierung | `projectNumber` statt `updatedAt` (1 Zeile) | 5 min Fix |

### 🟢 Nice-to-have / Später

| Baustelle | Was fehlt |
|-----------|-----------|
| `importPDF` Stub in KalkulationsEngine | Drive-PDF-Import Pipeline |
| Archiv-Projekte (200+) | Eigener Parser für altes Namensschema |
| MaterialLexicon manuell | `gen_lexicon.py` fehlt, manuell pflegen |
| Tabs Timeline + Material | Keine Datenquelle vorhanden |
| Clockodo-Stundensätze | 8 Einträge in Airtable manuell |
| Drive-Ordner `2026_20` umbenennen | Konsistenz |

---

## Was diese Session (2026-06-28) gebaut hat

### Commits dieser Session (auf main)

| Commit | Was |
|--------|-----|
| `6aafa5e` | Option A: einheitlicher Widget-Satz für alle Projekttypen |
| `dd235ab` | Sidebar-Collapse Root Cause + einmalige Widget-Reconciliation |
| `5319d1e` | UI-Härtung: GeometryReader-Pane, stabile Row-IDs, Clipping |
| `ebb2e3b` | Sidebar-Toggle ⌘⇧S in Navigation-Menü |
| `70519cf` | MykColor.brand #EA5B25 + Sidebar-Footer (Settings-Icon + Toggle-Icon) |
| `c78b9ee` | CI-Brand-Logo solid Orange + Footer entclustered (eine Zeile) |
| `437af5e` | Handoff UI-Bootcamp + Drive-Wiring Startprompt |
| `dec64e4` | Handoff Live-Data-Feed |
| `9a3dbbf` | Handoff Identity + Wire-Checkliste |

### Fallback gesetzt

```bash
git tag ui/sidebar-ci-stable          # unveränderlicher Ankerpunkt
git branch fallback/ui-sidebar-ci-stable  # Branch zum Vergleich
```

### Drive-Verifikation

`1Q-H_3JsZfiXosFmxtNgoy0hI3cvZLgST` = PROJEKTE-Root ✅ (Screenshot bestätigt)
31 Projektordner vorhanden, alle driveFolderIDs in projekte.json korrekt.

---

## Eiserne Regeln (für jede Session gültig)

- **Kanonischer Pfad:** `/Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilOS6/`
- **Vor Handoff:** `swift build && swift test` — beides grün
- **Keine Schreibvorgänge** in Sevdesk, geteilte Airtable-Base, Drive-Root
- **Secrets nur Keychain** — nie in Code, Dateien, Logs
- **CI ist Merge-Gate** — roter Build = kein Commit
