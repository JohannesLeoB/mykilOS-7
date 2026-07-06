# mykilOS Dev Collective — Team Briefing

**Stand:** 2026-06-28 · S10 Learning  
**Für:** Jede neue Session, jedes neue Kollektiv-Mitglied

---

## Wer wir sind

Ein Multi-Session-Entwicklungsteam, das mykilOS 6 baut — das persönliche Studio-Cockpit für Johannes. Jede Session hat einen klaren Scope, einen sauberen Handoff und ein kollektives Gedächtnis. Wir bauen nicht für uns, wir bauen für Johannes.

---

## Das Produkt

**mykilOS 6** — macOS 14+, SwiftUI, local-first, GRDB.  
Ein intelligentes Projektmanagement-Cockpit für ein Innenarchitektur-Studio.

**Kernfähigkeiten (alle live):**
- Projekt-Galerie + Widget-Boards (Kalender, Drive, Kontakte, Mail, Aufgaben, Notizen, Assistent)
- Google OAuth, Drive, Kalender, Kontakte, Gmail — alle live
- Clockodo-Zeiterfassung live
- Airtable-Sync (Mastermind-Base als System of Record)
- KalkulationsEngine — Tischler-Schätzungen mit Lern-Loop (S16 abgeschlossen)
- Claude-LLM-Integration im Assistenten
- AuditStore, About-Fenster, App-Icon

---

## Das Collective

| Rolle | Wer | Regel |
|---|---|---|
| **Gründer & Entscheider** | Johannes | Einzige Stimme für Scope, Architektur, Beschlüsse |
| **Tisch & Gedächtnis** | S10 Learning | Koordiniert, dokumentiert, leitet weiter — baut nicht |
| **Aktiver Chef** | Jeweils neueste Session (aktuell S17) | Baut, meldet Findings an Tisch |
| **Erfahrungsträger** | S8, S10 Build, S12, S14, S15, S16, mykilO$$$, Airtable Cleanup | Stille Zeugen, Wissensquelle |

**Vollständige Regeln:** `docs/TEAM_CHARTER.md` — immer zuerst lesen.

---

## Absolute NO-GOs (nicht verhandelbar, permanent)

| Was | Regel |
|---|---|
| **Sevdesk** | Nie lesen, nie schreiben |
| **Artikel-DB `appdxTeT6bhSBmwx5`** | READ ONLY — kein Schreiben, nie, weder App noch Sessions |
| **Stillgelegte Base `appkPzoEiI5eSMkNK`** | Kein Lesen, kein Schreiben |
| **Google Drive** | Read-only — nie schreiben oder verschieben |
| **Secrets** | Nur Keychain — nie in Code, Commits, Logs |
| **`git add -A`** | Verboten — immer explizite Pfade |
| **Push** | Nur mit expliziter Freigabe von Johannes |
| **Aktive Session stören** | Nie — Findings an Tisch, nicht direkt |
| **IdeenLog** | Muted — nur lesen wenn Johannes explizit verweist |

---

## Wo was liegt

| Was | Wo |
|---|---|
| Kanonischer Ordner | `/Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilOS Mac/` |
| Tisch-Session | `keen-williamson-ddb354` (S10 Learning) |
| Charter | `docs/TEAM_CHARTER.md` |
| Roadmap | `docs/handoffs/ROADMAP_S16_S20.md` |
| Ereignisprotokoll | `docs/EREIGNISPROTOKOLL.md` |
| Ideen & Backlog | `docs/IDEEN_UND_BACKLOG.md` (muted) |

---

## Airtable-Bases

| Base | ID | Zugriff |
|---|---|---|
| **Mastermind** | `appuVMh3KDfKw4OoQ` | Lesen + definierte Schreibtabellen |
| **Artikel- & Einkaufsdatenbank** | `appdxTeT6bhSBmwx5` | **READ ONLY** |
| Stillgelegt | `appkPzoEiI5eSMkNK` | Kein Zugriff |

Keychain PAT: `com.mykilos6.airtable` / `pat`

---

## Aktuelle Roadmap

| Session | Scope | Status |
|---|---|---|
| S17 | Security-Härtung + PAT-Cleanup + Google-Identität + baseID-Validierung | 🔄 Aktiv |
| S18 | Kalkulations-Chat-Tool im ConversationEngine (Tool-Use-Schleife, kein Intent-Switch) | Wartet |
| S19 | Artikel-Suche-Tool (Airtable `appdxTeT6bhSBmwx5`, read-only) | Wartet |
| S20 | Clockodo Zuhörer Phase 1 | Wartet |

---

## Architektur-Wissen das jede Session braucht

**Multi-Target:**
- `MykilosKit` → Foundation only, kein SwiftUI, kein GRDB
- `MykilosDesign` → Tokens, Farben, Typography
- `MykilosServices` → GRDB, Stores, alle Clients
- `MykilosWidgets` → Widget-UI, kein GRDB direkt, kein `import MykilosKalkulationsCore`
- `MykilosApp` → Shell, Navigation, AppState

**ConversationEngine:** Agentische Tool-Use-Schleife — Claude wählt Tools via `tool_use`, `AssistantToolRegistry.run(name:inputJSON:)` führt sie aus. KEIN Intent-Switch. Neue Features = neue `ClaudeToolDefinition` + `run`-Handler in der Registry.

**KalkulationsEngine:**
- Schätzt **nur Tischlerarbeiten** — Material + Erfahrungsanker + Lernfaktoren
- **Keine** Studio-Stundensätze (KO-DE+H, PRMG) — komplett getrennte Welten
- `schaetze(projektID:freitext:)` hat `EstimateRequestParser` eingebaut — Freitext direkt durchreichen, nicht vorab parsen
- `schaetze` schreibt `EstimateSession` → Referenz für `recordAdjustment` → Lern-Loop

**Drei getrennte Datenquellen — nie vermischen:**
1. DeviceCatalog-CSV → Tischler-Material für KalkulationsEngine
2. Artikel-DB Airtable → Studio-Produktkatalog (Leuchten, Armaturen, Geräte, Öfen)
3. KalkulationsEngine → Erfahrungsanker + Lernfaktoren (local GRDB)

---

## Handoff-Pflicht (Statut 13 — nicht verhandelbar)

Kein STOP ohne:
1. `swift build && swift test` — grün
2. `docs/EREIGNISPROTOKOLL.md` — neuer Eintrag oben
3. `CLAUDE.md` — Fortschrittstabelle aktualisiert
4. `STARTPROMPT_S{n+1}.md` — für nächste Session fertig
5. Erfahrungsbericht an S10 Learning

---

## Warum wir das tun

Johannes baut ein Cockpit, das ihm und seinem Studio echte Zeit spart. Jede Session die sauber liefert, bringt das Produkt einen Schritt näher an die Praxis. Das Collective ist das Gedächtnis, das das möglich macht — weil jede neue Session mit leerem Kontext startet und trotzdem nahtlos weiterbauen kann.

**Wir rocken das.**

---

*Aktualisiert von S10 Learning nach jeder abgeschlossenen Session.*
