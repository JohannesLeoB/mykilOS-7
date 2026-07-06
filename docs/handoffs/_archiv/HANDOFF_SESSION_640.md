# HANDOFF — Version 6.4.0 festgeschrieben (2026-06-28)

```
Pfad:    /Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilOS Mac/
Branch:  main (13 Commits vor origin/main)
Build:   ✅ swift build grün
Tests:   ✅ 192 Tests, 30 Suites
Modell:  claude-sonnet-4-6
Level:   Beta-bereit — UI stabil, Live-Wiring ausstehend
Fallback: git checkout ui/sidebar-ci-stable   (unveränderlicher Tag)
Datum:   2026-06-28
```

---

## Was diese Session getan hat

**UI-Bootcamp: Sidebar-Collapse, MYKILOS Orange CI, App-Icon, Repo-Cleanup.**

### Commits auf main (diese Session)

| Commit    | Was                                                       |
|-----------|-----------------------------------------------------------|
| `6aafa5e` | Option A: einheitlicher Widget-Satz für alle Projekttypen |
| `dd235ab` | Sidebar-Collapse Root Cause + einmalige Widget-Reconciliation |
| `5319d1e` | UI-Härtung: GeometryReader-Pane, stabile Row-IDs, Clipping |
| `ebb2e3b` | Sidebar-Toggle ⌘⇧S via CommandMenu("Navigation")         |
| `70519cf` | `MykColor.brand` #EA5B25 + kompakter Sidebar-Footer       |
| `c78b9ee` | CI-Brand-Logo solid Orange + Footer entclustered (1 Zeile)|
| `437af5e` | Handoff UI-Bootcamp + Drive-Wiring-Startprompt            |
| `dec64e4` | Handoff Live-Data-Feed — Schema + Reihenfolge             |
| `9a3dbbf` | Handoff Identity + Wire-by-Wire-Checkliste                |
| `8a15377` | Master-Status-Handoff (Bugs, Verzeichnisse, Startprompt)  |
| `530e80f` | Version bump → 6.4.0 (script + AboutView)                 |
| `a1d448d` | App-Icon 6.4.0 — MY brand orange, alle 10 macOS-Größen    |

### Was konkret gebaut wurde

**⌘⇧S Sidebar-Toggle:**
- Zuverlässig via `CommandMenu("Navigation")` (nicht via Overlay-Button, das war B8-Bug)
- `@AppStorage("ui.sidebarCollapsed")` shared zwischen ContentView + AppCommands
- `onToggleSidebar`-Callback-Pattern in SidebarView (kein direktes State-Coupling)

**MYKILOS Orange Brand CI:**
- `MykColor.brand` = `#EA5B25` adaptive (light + dark identisch) in `MykilosDesign/Tokens.swift`
- `SidebarIconButton`: oranges Icon, Hover-Hintergrund, `.help()`, `.plain`-Style
- Brand-Logo: solid `MykColor.brand.color`, kein Gradient, kein „6"-Suffix
- Sidebar-Footer: 1 HStack (Profil links, Settings-Icon + Toggle-Icon rechts)

**UI-Stabilität:**
- `GeometryReader` als harte Layout-Grenze zwischen Sidebar und Detail-Pane
  → Widget-Grid kann Idealbreite nicht mehr zurück in äußeren HStack melden
- Stabile `id`-Keys in Projekt-Listen (verhindert Layout-Sprünge bei Scroll)
- `.clipped()` + `.contentShape(.interaction, Rectangle())` auf Detail-Pane

**Neues App-Icon (6.4.0):**
- Orange (#EA5B25) abgerundetes Quadrat + „MY" bold weiß
- Alle 10 macOS-Dock-Größen: 16, 32, 64, 128, 256, 512, 1024 @1x/@2x
- Generiert via Python PIL + `iconutil`
- `Sources/MykilosApp/Resources/AppIcon.icns` + `AppIconSource.png`

**Repo-Cleanup:**
- 8 stale Desktop-Worktrees entfernt
- 13 `claude/*`-Branches gelöscht
- 14 alte Feature-Branches gelöscht
- Verbleibend: `main`, `claude/adoring-ptolemy-cc4006` (aktuelle Session), `fallback/ui-sidebar-ci-stable`
- Tags: `ui/sidebar-ci-stable` (unveränderlich), `mykilos6-last-known-good-2026-06-28-013028`

---

## Verzeichnis-Status — alle Daten festgeschrieben

### `docs/registry/projekte.json` — 31 Projekte

| Feld          | Status   | Anmerkung                                             |
|---------------|----------|-------------------------------------------------------|
| projectNumber | ✅ 31/31 | Format JJJJ-NNN                                       |
| title         | ✅ 31/31 |                                                       |
| driveFolderID | ✅ 31/31 | Direkte Ordner-IDs, verifiziert via Drive-Screenshot  |
| calendarQuery | ✅ 30/31 | 2026-001 MYKILOS fehlt (internes Projekt)             |
| mailQuery     | ✅ 30/31 | 2026-001 MYKILOS fehlt                                |
| clickUpListID | ❌ 0/31  | IDs müssen in Airtable eingetragen werden             |
| sevdeskRef    | ❌ 0/31  | Refs müssen in Airtable eingetragen werden            |
| budget        | ❌ 0/31  | Budgets müssen in Airtable eingetragen werden         |

### `docs/registry/kunden.json` — 30 Kunden ✅ vollständig

### Airtable Mastermind `appuVMh3KDfKw4OoQ` — 69 Records live

### Google Drive `1Q-H_3JsZfiXosFmxtNgoy0hI3cvZLgST` — PROJEKTE-Root ✅ verifiziert
31 Projektordner, alle driveFolderIDs in projekte.json korrekt.
Auffälligkeit: `2026_20_Liebig_Quooker` (fehlende Null) — kosmetisch, kein App-Bug.

---

## Offene Bugs

| # | Bug                                                        | Schwere    | Fix                                     |
|---|-------------------------------------------------------------|------------|------------------------------------------|
| B1 | Airtable Base-ID im Settings enthält PAT statt `appuVMh3KDfKw4OoQ` | 🔴 Blocker für Sync | Johannes manuell korrigieren |
| B2 | GoogleUserInfo nicht persistiert → Sidebar flackert nach Neustart | 🟡 UX | Phase A4 nächste Session |
| B3 | `2026_20_Liebig_Quooker` fehlende führende Null im Drive-Ordnernamen | 🟢 Kosmetisch | Johannes in Drive umbenennen |
| B4 | Projekt 2026-001 MYKILOS ohne calendarQuery/mailQuery | 🟢 Datenlücke | Bewusst leer lassen |
| B5 | Google Re-Consent nach S17 (neue Scopes: userinfo) nicht verifiziert | 🟡 Auth | Live: Trennen → neu Verbinden |
| B6 | Alter PAT in Airtable noch aktiv | 🟡 Security | Johannes manuell revoken |
| B7 | Clockodo-Stundensätze leer in Airtable `Clockodo-Leistungen` | 🟡 Funktional | Johannes manuell eintragen |

---

## Offene Baustellen

### 🔴 Muss vor echtem Beta-Betrieb
- Airtable Base-ID korrekt (B1) + Live-Sync verifizieren
- Google OAuth Re-Consent (B5)
- IdentityView + GoogleUserInfo-Persistenz (Phase A)

### 🟡 Wichtig
- ClickUp-Listen-IDs (31 Einträge in Airtable)
- sevdeskRef + Budget (31 Einträge in Airtable)
- Clockodo Zeitbuchungs-Flow (eigene Session, Architektur fertig)
- S18 Kalkulations-Chat-Tool
- Galerie-Filter nach Jahr/Phase
- Projektsortierung: `RegistryStore.swift:37` → `projectNumber` statt `updatedAt`

### 🟢 Später
- `importPDF` Stub in KalkulationsEngine
- Archiv-Projekte (200+, eigener Parser)
- Tabs Timeline + Material (keine Datenquelle)

---

## Branch-Situation

```
Branches nach Cleanup:
  main                              ← kanonisch, 13 Commits ahead of origin
  claude/adoring-ptolemy-cc4006     ← diese Session (Worktree)
  fallback/ui-sidebar-ci-stable     ← UI-Fallback-Branch

Tags:
  ui/sidebar-ci-stable              ← unveränderlicher Ankerpunkt ⚠️
  mykilos6-last-known-good-2026-06-28-013028
```

**Fallback aktivieren (falls Session etwas bricht):**
```bash
cd "/Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilOS Mac"
git checkout ui/sidebar-ci-stable
```

---

## Startprompt für die nächste Session

```
Pfad:   /Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilOS Mac/
Branch: main
Modell: claude-sonnet-4-6

PFLICHTCHECK:
  swift build   → muss grün
  swift test    → muss grün (192 Tests)
  git status    → muss clean

FALLBACK-TAG: ui/sidebar-ci-stable (bei Notfall: git checkout ui/sidebar-ci-stable)

SESSION-ZIEL: Identitätsmodell härten + Wire-by-Wire Live-Bestätigung

MANUELL VON JOHANNES VOR SESSION-START:
  □ Settings → Airtable → Base-ID = appuVMh3KDfKw4OoQ  (NICHT der PAT!)
  □ App neu starten

PHASE A — Code (~90 min, ohne Johannes):
  A1: UserProfile + clockodoUserID: String? + googleDomain: String?
      Datei: Sources/MykilosKit/Domain/UserProfile.swift
  A2: IdentityView — "Wer bin ich?" ganz oben in SettingsView
      Neue Datei: Sources/MykilosApp/Settings/IdentityView.swift
      Google read-only Block + editierbare Felder + Clockodo-ID
  A3: IntegrationStatusView — alle 6 Dienste Traffic-Light
      Neue Datei: Sources/MykilosApp/Settings/IntegrationStatusView.swift
  A4: GoogleUserInfo in UserDefaults persistieren
      Key: com.mykilos6.google.cachedUserInfo
      In GoogleAuthService: nach fetchUserInfo() cachen, bei disconnect() löschen

PHASE B — Live mit Johannes (Wire-by-Wire):
  Checkliste: docs/handoffs/HANDOFF_IDENTITY_AND_WIRE_CHECK.md → TEIL B
  B1: Airtable-Sync (braucht Base-ID-Fix)
  B2: Drive (braucht Google OAuth + Re-Consent für neue Scopes)
  B3: Kalender
  B4: Mail
  B5: ClickUp (erst wenn Listen-IDs in Airtable)
  B6: Cash/Sevdesk (erst wenn sevdeskRef + Budget in Airtable)
  B7: Claude Assistent
  B8: Kalkulation

QUICK-FIX (5 min, Schritt 1 aus Live-Data-Feed-Plan):
  Sources/MykilosApp/Data/RegistryStore.swift Zeile 37:
  projects = p.sorted { $0.updatedAt > $1.updatedAt }   // VORHER
  projects = p.sorted { $0.projectNumber > $1.projectNumber }  // NACHHER

KEIN SCHREIBEN in Sevdesk, geteilte Airtable-Base, Drive-Root.
```
