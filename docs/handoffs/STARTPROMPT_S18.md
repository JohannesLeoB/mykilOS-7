# Startprompt S18 — Kalkulations-Chat-Tool

```
Pfad:   /Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilOS6/
Branch: main (S17 muss noch gemergt werden — Johannes gibt die Freigabe)
Build:  ✅ 209 Tests grün (190 swift-testing + 19 XCTest)
Datum:  2026-06-28
```

---

## 🚨 P0-HARD-GATE VOR JEGLICHER S18-FEATURE-ARBEIT

Bevor das Kalkulations-Chat-Tool begonnen wird, muss der offene
Projektübersicht-/Sidebar-Bug behoben und **live** verifiziert werden:

- Nur im Tab „Übersicht“ wird der Detailinhalt horizontal übergroß und links
  abgeschnitten.
- Die Sidebar bleibt sichtbar, ist aber nicht anklickbar, weil eine unsichtbare
  Hit-Test-Fläche des Widget-Boards darüberliegt.
- `dd235ab`, `.clipped()`, WindowGuard und grüne Unit-Tests sind kein
  Abschlussbeweis; die Live-Screenshots 09:39 zeigen den Fehler weiterhin.

Pflichtlektüre:
`docs/handoffs/HANDOFF_P0_OVERVIEW_SIDEBAR_HITTEST.md`

S18 darf erst starten, wenn Übersicht, Hero und Tab-Leiste vollständig sichtbar
bleiben und alle Sidebar-Ziele unmittelbar sowie nach 300/800/1800 ms
anklickbar sind.

---

## Du bist Teil des mykilOS Dev Collective

**Lese zuerst:** `docs/TEAM_CHARTER.md`

Die wichtigsten Regeln:
1. **Du bist der aktive Chef** — alle anderen Sessions beobachten still.
2. **Kein Push ohne explizite Freigabe von Johannes.**
3. **`git add` immer mit expliziten Pfaden — nie `git add -A`** — Johannes hat uncommittete eigene Änderungen.
4. **Handoff-Dreifach-Pflicht am Ende:** EREIGNISPROTOKOLL + CLAUDE.md + STARTPROMPT_S19 — alle drei, kein STOP ohne sie.
5. **Kanonischer Ordner:** `/Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilOS6/`

---

## Pflicht-Checks ZUERST

```bash
cd "/Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilOS6"
pwd
git status
git log --oneline -3
swift build && swift test 2>&1 | tail -5
```

Starte von main (S17 muss gemergt sein — prüfe ob `feat/security-haertung` bereits in main ist):
```bash
git checkout main && git pull
git checkout -b feat/kalkulations-chat-tool
```

---

## Was S17 hinterlassen hat

| Feature | Status |
|---|---|
| `AirtableError.invalidBaseID` + Validierung in `connect` | ✅ |
| `GoogleUserInfo` in `MykilosKit/Domain/` | ✅ |
| `GoogleUserInfoClient` + `GoogleHTTPClient`-Protokoll | ✅ |
| Userinfo-Scopes (`email` + `profile`) in `readOnlyDefaults` | ✅ |
| `GoogleAuthService.currentUser` + nicht-fataler Hook | ✅ |
| `AppState.currentGoogleUser` | ✅ |
| `SidebarView` zeigt Google-Name + E-Mail | ✅ |
| PAT-Cleanup dokumentiert (`docs/PAT_CLEANUP_S17.md`) | ✅ |

**Noch ausstehend (Johannes, nicht S18):**
- Re-Consent live: Johannes muss sich einmal neu bei Google verbinden (neue Scopes)
- PAT-Cleanup manuell in Airtable-Settings (s. `docs/PAT_CLEANUP_S17.md`)
- Korrupter Keychain-Eintrag (baseID enthält PAT): manuell `appuVMh3KDfKw4OoQ` neu eintragen

---

## Dein Auftrag: Kalkulations-Chat-Tool

### Architektur-Kontext (aus S10 Learning bestätigt)

`ConversationEngine` ist eine Tool-Use-Schleife — kein Intent-Switch. Neue Fähigkeiten kommen als neue Tools in `AssistantToolRegistry`. Das ist S18s Muster.

**Wichtig:**
- Keine Clockodo-Stundensätze involviert — `KalkulationsEngine` schätzt ausschließlich Tischlerarbeiten aus Material + Erfahrungsankern + Lernfaktoren.
- `importPDF` bleibt Stub — nicht S18s Aufgabe.

### Neue Komponente: `KalkulationsTool`

**Tool-Name:** `"kalkulation"` (oder `"schaetze_kueche"` — entscheide nach Konvention der bestehenden Tools)

**Natürlichsprachliche Eingabe → `schaetze` → strukturierte Antwort:**
```
"6m Küchenzeile, 5 Körper, 6 Schubladen, Linoleum-Fronten, Taj-Mahal-Arbeitsplatte"
→ appState.kalkulationsEngine.schaetze(KüchenAnfrage {...})
→ KostenSchaetzung { minNetto, mitteNetto, maxNetto, konfidenz }
→ KalkulationsActionCard oder strukturierter Text im Chat
```

**Referenz-Tools lesen (Konvention verstehen):**
```
Sources/MykilosServices/Assistant/AssistantToolRegistry.swift
Sources/MykilosServices/Assistant/Tools/ (alle Tool-Dateien)
```

**projektID über scope-Threading:**
- `ConversationEngine` hat bereits ein `scope`-Konzept (oder `projectNumber` im Kontext)
- `schaetze(...)` braucht keine projektID — aber das Tool soll die Schätzung im Audit-Log an das aktuelle Projekt binden
- `AuditEntry.projectNumber` verwenden

**`schaetze` darf schreiben** (EstimateSession für Lern-Loop-Referenz — `schaetzungsID` wird persistent, damit `recordAdjustment` später darauf referenzieren kann)

### Minimaler Scope

1. Tool-Klasse `KalkulationsTool` in `AssistantToolRegistry`
2. Text-Extractor: Freitext → `KüchenAnfrage` (oder äquivalent, abhängig von `schaetze`-Signatur)
3. Response-Formatter: `KostenSchaetzung` → lesbarer Antworttext (Min/Mitte/Max, Konfidenz)
4. Optionale `KalkulationsActionCard` im Chat (analog zu `CalendarActionCard`)
5. Test: Extractor + Formatter ohne echte Engine (Fake-Provider)

---

## Absolute Regeln

- **Sevdesk: NIE lesen/schreiben**
- **Airtable-Base `appuVMh3KDfKw4OoQ`: nur lesen** (außer explizit vorgesehene Schreibtabellen)
- **Airtable-Base `appkPzoEiI5eSMkNK`: NIE anfassen (stillgelegt)**
- **Artikel-DB `appdxTeT6bhSBmwx5`: READ ONLY — absolut kein Schreiben**
- **Drive: read-only**
- Secrets nur Keychain
- `MykilosKit`: kein SwiftUI, kein GRDB
- `MykilosWidgets`: kein GRDB, **kein `import MykilosKalkulationsCore`**
- **`git add` immer explizit — nie -A**
- **Kein Push ohne Freigabe von Johannes**
- **Studio-Stundensätze sind KEINE Inputs für KalkulationsEngine**

---

## Handoff-Dreifach-Pflicht am Ende

Kein STOP ohne alle drei:
1. `swift build && swift test` — grün, mindestens 209 Tests
2. `git add <nur eigene Dateien>` — explizit
3. `git commit -m "feat: kalkulations-chat-tool (S18)"`
4. `docs/handoffs/HANDOFF_S18.md` schreiben
5. `docs/EREIGNISPROTOKOLL.md` — Eintrag oben einfügen
6. `CLAUDE.md` — S18-Zeile aktualisieren
7. `docs/handoffs/STARTPROMPT_S19.md` — für nächste Session

---

## Was S19 als nächstes macht

**Artikel-Suche-Tool** — neues Tool in `AssistantToolRegistry` das `appdxTeT6bhSBmwx5` (READ ONLY) abfragt: "Zeig mir Leuchten um 200€" → Airtable-Query → Ergebnisliste im Chat.

Details: `docs/handoffs/ROADMAP_S16_S20.md`
