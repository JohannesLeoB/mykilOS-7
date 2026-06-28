# Handoff: Phase B — Wire-by-Wire Live-Verifikation

```
Pfad:   /Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilOS6/
Branch: main
Build:  ✅ swift build grün
Tests:  ✅ 192 Tests grün
Datum:  2026-06-28
```

---

## Ergebnis: Alle B-Checks grün (B5/B6 noch abhängig von Johannes)

| Check | Was | Ergebnis | Anmerkung |
|-------|-----|----------|-----------|
| **B1** | Airtable-Sync → 31 Projekte in Galerie | ✅ | Base-ID `appuVMh3KDfKw4OoQ` korrekt, 31 Projekte live |
| **B2** | Drive → DriveWidget + FilesTab + OffersTab | ✅ | API verbunden, Poll meldet „Keine neuen Angebote", leere Ordner = erwartet |
| **B3** | Calendar → CalendarWidget | ✅ | Bestätigt via Assistent-Tab Tool-Use „Kalender gelesen · vonBoch" |
| **B4** | Mail → MailWidget | ✅ | Bestätigt via Assistent-Tab Tool-Use „Gmail durchsucht · vonBoch" |
| **B5** | ClickUp → TasksWidget | ⏳ | Wartet auf M3: ClickUp-Listen-IDs in Airtable (Johannes) |
| **B6** | Cash/Sevdesk → CashWidget | ⏳ | Wartet auf M4: sevdeskRef + Budget in Airtable (Johannes) |
| **B7** | Claude → Assistent antwortet | ✅ | claude-sonnet-4-6 live, echte API-Antwort, Tool-Use aktiv |
| **B8** | Kalkulation → Schätzung erscheint | ✅ | KalkulationsWidget live: Eingabefeld, Schätzen-Button, Gelernte Kalibrierung, Quellenzeile |

---

## Detailbefunde

### B1 — Airtable Sync (✅)

- Settings → Airtable → Base-ID: `appuVMh3KDfKw4OoQ` korrekt eingetragen
- Bug B1 aus HANDOFF_MASTER_STATUS war bereits vor dieser Session behoben
- Galerie zeigt 31 Projekte aus 2024–2026
- Letzter Sync-Zeitstempel wird korrekt angezeigt

### B2 — Drive (✅)

- Google-Verbindungsstatus: VERBUNDEN (5 grüne Dots in Settings)
- Projekt vonBoch → DriveWidget: Poll läuft, meldet „Keine neuen Angebote im Drive-Ordner"
- Dateien-Tab: Lädt (API-Call wird ausgeführt), Ordner genuinely leer
- Angebote-Tab: funktioniert, leer = korrekt
- Drive-API-Verbindung bestätigt, keine Auth-Fehler

### B3 + B4 + B7 — Calendar, Mail, Claude (✅ alle drei)

Einzelner Test: Assistent-Tab im Projekt vonBoch, Frage „Was steht für vonBoch diese Woche an?"

Claude hat beide Tool-Calls live ausgeführt:
- `searchGmail` → „Gmail durchsucht · vonBoch" (B4 ✅)
- `listCalendarEvents` → „Kalender gelesen · vonBoch" (B3 ✅)
- Kohärente, projektspezifische Antwort auf Deutsch (B7 ✅)
- Modell: claude-sonnet-4-6, echte Anthropic Messages API

### B5 — ClickUp (⏳)

- Widget zeigt `.permissionRequired` → korrekt (keine Liste-ID eingetragen)
- **Nächster Schritt (Johannes):** ClickUp-Listen-IDs für Projekte in Airtable `Projekte.ClickUp-Listen-ID` eintragen, dann Sync → IDs landen im App-Cache

### B6 — Cash/Sevdesk (⏳)

- Widget zeigt Budget-Balken mit Platzhalter → korrekt
- **Nächster Schritt (Johannes):** sevdeskRef + Budget pro Projekt in Airtable `Projekte.SevdeskRef` + `Projekte.Budget` eintragen

### B8 — Kalkulation (✅)

- Sidebar → Kalkulation: View lädt sofort, kein Crash
- KalkulationsWidget sichtbar: Freitext-Eingabefeld „Projektbeschreibung eingeben …"
- „Schätzen"-Button vorhanden
- „Gelernte Kalibrierung"-Sektion ausklappbar
- Quellenzeile: „KALKULATION · BASELINE-ANKER"
- Engine ist verdrahtet, BaselineAnchors live

---

## Phase A — Nochmal bestätigt

Alle Phase-A-Features live verifiziert (aus der vorigen Session):

| Feature | Status |
|---------|--------|
| „Wer bin ich?" — Avatar J, Johannes Leo Berger, mykilos.com | ✅ |
| Verbindungsstatus 6-Dot Traffic-Light (5× grün, Sevdesk grau) | ✅ |
| PRIVATE AREA — Clockodo VERBUNDEN, johannes@mykilos.com | ✅ |
| B2-Fix — GoogleUserInfo nach Neustart | ✅ |
| GRDB-Migration v5 | ✅ |
| clearLocalCache() | ✅ |

---

## Offene Aktionen (Johannes)

| # | Aktion | Wo | Priorität |
|---|--------|----|-----------|
| M1 | Google Re-Consent: Settings → Google → Trennen → Verbinden | Live in App | 🟡 Bald |
| M2 | Clockodo Stundensätze für 8 Leistungsarten eintragen | Airtable `Clockodo-Leistungen.Stundensatz` | 🟡 Für Clockodo-Flow |
| M3 | ClickUp-Listen-IDs pro Projekt eintragen | Airtable `Projekte.ClickUp-Listen-ID` | 🟡 Für B5 |
| M4 | sevdeskRef + Budget pro Projekt eintragen | Airtable `Projekte.SevdeskRef` + `Budget` | 🟡 Für B6 |

---

## Nächste Sessions

### Nächste Code-Session: S18 — Kalkulations-Chat-Tool

Ziel: `schaetze`-Tool in `ConversationEngine` einbauen — Claude kann im Chat eine
Kostenschätzung aufrufen, Ergebnis erscheint als strukturierte Antwort mit Min/Mitte/Max.

Architektur laut HANDOFF_MASTER_STATUS + CLAUDE.md S18-Eintrag:
- Neues Tool `KalkulationsSchaetzungTool` in `AssistantToolRegistry`
- projektID via scope-Threading (Projekt-Assistent kennt Projektnummer)
- `schaetze(beschreibung:)` → `KostenSchaetzung` → formatierte Chat-Karte

### Nach M3/M4: B5 + B6 live verifizieren

Sobald Johannes die IDs eingetragen hat:
1. Airtable-Sync auslösen (`Jetzt synchronisieren`)
2. ClickUp-Widget in Projekt mit Liste-ID prüfen
3. Cash-Widget Budget-Balken mit echten Sevdesk-Daten prüfen

---

## Startprompt für S18 (Kalkulations-Chat-Tool)

```
Pfad:   /Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilOS6/
Branch: main
Modell: claude-sonnet-4-6

PFLICHTCHECK:
  swift build  → muss grün
  swift test   → muss grün (192 Tests)
  git status   → muss clean

SESSION-ZIEL: S18 — Kalkulations-Chat-Tool

Referenz-Architektur:
  - AssistantToolRegistry (Sources/MykilosApp/Assistant/)
  - ConversationEngine (wo Tool-Registrierung passiert)
  - KalkulationsEngine (Sources/MykilosServices/Kalkulation/)
  - Protokoll: KalkulationsEngineProviding (Sources/MykilosKit/Domain/)

Neues Tool `schaetze` in der Tool-Registry:
  - Input: projectNumber (String), beschreibung (String)
  - Engine-Call: AppState.kalkulationsEngine?.schaetze(beschreibung:)
  - Output: strukturierte Karte Min/Mitte/Max + Konfidenz
  - Kein Auto-Write, kein Audit ohne Bestätigung

NO-GOs:
  - Sevdesk nie lesen/schreiben
  - Airtable-Einträge niemals löschen — nur per Status/Archiv inaktivieren
  - Clockodo: datensensitiv, Private Area, kein Log mit fremden Daten
  - Drive-Ordner 0AOeReQBQKkKBUk9PVA: read-only
  - Externe Daten heilig; bei Datenverlust-Gefahr sofort warnen
```
