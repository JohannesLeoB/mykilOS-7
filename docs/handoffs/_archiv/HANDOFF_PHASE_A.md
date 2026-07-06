# Handoff: Phase A — Identity, Private Area, B2-Fix

```
Pfad:   /Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilOS Mac/
Branch: claude/nifty-goldwasser-af846a  (4 Commits vor main)
Build:  ✅ swift build grün
Tests:  ✅ 192 Tests grün (swift test)
Datum:  2026-06-28
```

Commit: `7783355` feat: Phase A — IdentityView, Private Area, clearLocalCache, B2-Fix

---

## Was wurde gebaut (9 geänderte Dateien)

### 1. „Wer bin ich?" — IdentityView in Settings

`SettingsView.swift` wurde vollständig neu strukturiert. Oberste Sektion:

- Avatar-Kreis mit Initiale (Brand-Orange) + Name + E-Mail + Domain (read-only aus Google)
- Darunter editierbare Felder Name + Rolle → `Speichern` → `saveProfile()`
- `saveProfile()` persistiert neu auch `clockodoUserID` und `googleDomain`
- Live verifiziert: „Johannes Leo Berger · johannes@mykilos.com · mykilos.com"

### 2. Verbindungsstatus — 6-Dot Traffic-Light

Kompakte Karte unter der Identität:

```
● Google  ● Airtable  ● ClickUp  ○ Sevdesk  ● Claude  ● Clockodo
```

- 5 grün, Sevdesk grau (nicht verbunden) — korrekt
- Einzelner `serviceStatusBadge(color:text:)` Helper, keine Duplikate

### 3. Private Area — Clockodo Zeiterfassung

Letzte Sektion in Settings, visuell abgegrenzt:
- Brand-Orange Border + `🔒 PRIVATE AREA` Label
- Clockodo-Credentials (Benutzername-Feld + SecureField Passwort)
- Clockodo-User-ID Feld (für Airtable-Mapping)
- Datenschutz-Hinweis: „Persönliche Credentials — nur du siehst deine Zeiteinträge."
- Live verifiziert: VERBUNDEN · johannes@mykilos.com

### 4. `clearLocalCache()` — Projekt-Cache leeren

In der Airtable-Sektion: Button „Projekt-Cache leeren" mit Erklärung.

Implementierung in zwei Schichten:
- `CachedProjectRegistry.clearCache()` → `saveAll([])` für projects + customers
- `RegistryStore.clearLocalCache()` → ruft `clearCache()`, räumt Published-Arrays,
  seeded neu

Ersetzt den früheren Shell-Workaround (`rm projects.json customers.json`).

### 5. B2-Fix — GoogleUserInfo nach Neustart

Problem: User die vor S17 (Security-Härtung) eingeloggt waren hatten kein
gecachtes `GoogleUserInfo` → `currentUser == nil` nach Neustart → kein Name in Sidebar.

Fix in `GoogleAuthService`:
```swift
public func refreshUserInfoIfNeeded() async {
    guard status == .connected, currentUser == nil else { return }
    do {
        let token = try await GoogleAccessTokenProvider(tokenStore: tokenStore).validAccessToken()
        let info  = try await userInfoClient.fetchUserInfo(accessToken: token)
        try tokenStore.storeUserInfo(info)
        currentUser = info
    } catch {}
}
```

Aufruf in `AppState.bootstrap()` einmalig im Hintergrund — non-fatal, kein
Flackern, kein Restart nötig.

### 6. GRDB-Migration v5 — `v5_profile_identity`

```swift
migrator.registerMigration("v5_profile_identity") { db in
    try db.alter(table: "userProfile") { t in
        t.add(column: "clockodoUserID", .text)
        t.add(column: "googleDomain",   .text)
    }
}
```

Nullable ALTER TABLE — kein Datenverlust, bestehende Profile bleiben erhalten.

### 7. UserProfile Erweiterung

`UserProfile.swift` (MykilosKit) + `ProfileRecord.swift` (MykilosServices):
- `clockodoUserID: String?` — für Airtable-Entwurfstabellen-Mapping
- `googleDomain: String?`   — read-only aus GoogleUserInfo, zeigt Domain in Sidebar
- Beides mit `nil`-Default → rückwärtskompatibel

---

## Live-Verifikation (Screenshots 2026-06-28, 12:56 Uhr)

| Bereich | Status |
|---|---|
| „Wer bin ich?" — Avatar J, Johannes Leo Berger, mykilos.com | ✅ live |
| Verbindungsstatus — 5× grün, Sevdesk grau | ✅ live |
| Google Workspace — VERBUNDEN, Client-ID sichtbar | ✅ live |
| Airtable — VERBUNDEN, `appuVMh3KDfKw4OoQ` korrekt (B1 bereits behoben) | ✅ live |
| ClickUp — VERBUNDEN | ✅ live |
| Claude — VERBUNDEN, `claude-sonnet-4-6` | ✅ live |
| PRIVATE AREA — Clockodo VERBUNDEN, johannes@mykilos.com | ✅ live |
| Projekt-Cache leeren — Button sichtbar + beschriftet | ✅ live |

---

## Neue Sicherheitsregeln (dauerhaft, in CLAUDE.md eingetragen)

1. **Airtable NO-DELETE:** Einträge dürfen NIEMALS gelöscht oder direkt
   überschrieben werden. Inaktivierung ausschließlich per Status-/Archiv-Feld
   (PATCH, nie DELETE).

2. **Clockodo Private Area:** Clockodo ist datensensitiv. Private Area in
   Settings (letzter Block, Orange-Border). Per-User Keychain-Slots
   (Suffix = User-ID). Kein Log, kein Audit mit fremden Clockodo-Daten.

---

## Offene Punkte (Johannes)

| # | Aktion | Wo |
|---|---|---|
| M1 | Google Re-Consent: Settings → Google → Trennen → Verbinden | Live in App |
| M2 | Clockodo Stundensätze für 8 Leistungsarten eintragen | Airtable `Clockodo-Leistungen.Stundensatz` |
| M3 | ClickUp-Listen-IDs pro Projekt eintragen | Airtable `Projekte.ClickUp-Listen-ID` |
| M4 | sevdeskRef + Budget pro Projekt eintragen | Airtable `Projekte.SevdeskRef` + `Budget` |

---

## Nächste Session — Phase B: Wire-by-Wire

Ziel: Jede Integration mit echten Live-Daten prüfen und ggf. verbinden.

**Reihenfolge:**
1. **B1** — Airtable-Sync → alle 31 Projekte in der Galerie
2. **B2** — Drive → DriveWidget + FilesTab + OffersTab live prüfen
3. **B3** — Calendar → CalendarWidget live prüfen
4. **B4** — Mail → MailWidget live prüfen
5. **B5** — ClickUp → TasksWidget (erst wenn M3 erledigt)
6. **B6** — Cash/Sevdesk → CashWidget (erst wenn M4 erledigt)

**Startprompt für Phase B:**

```
Kanonischer Ordner:
/Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilOS Mac/

Pflichtchecks:
  pwd
  git status && git branch
  swift build && swift test 2>&1 | tail -3

Wir starten Phase B (Wire-by-Wire) von Handoff HANDOFF_PHASE_A.md aus.
Phase A ist abgeschlossen: IdentityView, Private Area, clearLocalCache, B2-Fix,
GRDB-Migration v5 — 192 Tests grün, live verifiziert.

Phase B: Jede Integration live prüfen.
Zuerst B1 — Airtable „Jetzt synchronisieren" drücken und prüfen ob alle 31
Projekte in der Galerie erscheinen.

NO-GOs:
- Sevdesk nie lesen/schreiben
- Airtable-Einträge niemals löschen — nur per Status/Archiv inaktivieren
- Clockodo: datensensitiv, Private Area, kein Log mit fremden Daten
- Drive-Ordner 0AOeReQBQKkKBUk9PVA: read-only
- Externe Daten heilig; bei Datenverlust-Gefahr sofort warnen
```

---

## Branch-Status

```
Branch: claude/nifty-goldwasser-af846a  (4 Commits vor main)
7783355  feat: Phase A — IdentityView, Private Area, clearLocalCache, B2-Fix
bc0698c  docs: Private Area + User-Secrets-Regel
bbf82f7  docs: Airtable safety rule
27aaf05  docs: CLAUDE.md 6.4.0 + HANDOFF_SESSION_640
```

Merge in `main` sobald Phase-B-Session diesen Branch als Basis nutzt oder
Johannes explizit den Merge freigibt.
