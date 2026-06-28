# mykilOS 6 — Claude Code Projektgedächtnis

**Smarte Projektplanung und Management mit intelligenten Automationen und Integrationen.**
Das Cockpit, das alles kann. macOS 14+, SwiftUI, local-first.

---

## ⛔ EISERNE REGEL: Kanonischer Ordner + Branch-Verifikation

**Diese Regel gilt für JEDEN Agenten, jede Session, jedes Tool — Claude, Codex, GitHub Actions, alles.**

### Kanonischer Arbeitsordner (nicht verhandelbar)

```
/Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilOS6/
```

**GitHub:** https://github.com/JohannesLeoB/mykilOS-6 (privat)

Der Desktop-Ordner `~/Desktop/CLAUDE/` enthält NUR temporäre Worktrees von Claude Code-Sessions.
Diese sind WEGWERFKOPIEN. Nie dauerhaft darin arbeiten. Immer in den gelben MYKILOS-6-Ordner.

### Pflichtprüfung vor JEDER Handoff / Startprompt / Anweisung

```bash
# Schritt 1: Bin ich im richtigen Ordner?
pwd
# Muss enden mit: /Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilOS6

# Schritt 2: Welcher Branch ist aktiv? Ist er sauber?
git status
git branch

# Schritt 3: Build und Tests grün?
swift build && swift test 2>&1 | tail -3
```

Erst wenn alle drei Checks bestanden sind, darf ein Handoff / Startprompt / eine Anweisung
geschrieben werden. Andernfalls: zuerst den Fehler beheben, dann dokumentieren.

### Jeder Handoff MUSS im Header enthalten

```
Pfad:   /Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilOS6/
Branch: <aktueller branch-name>
Build:  ✅ swift build grün
Tests:  ✅ N Tests grün (swift test)
Datum:  YYYY-MM-DD
```

### Warum diese Regel existiert

Am 2026-06-27/28 gab es parallel laufende Entwicklung in:
- Desktop/CLAUDE/ Worktrees (Claude Code Desktop Sessions) — VERALTET
- Sprint-Branches (sprint/shared-drive-widget-oauth) — aktive Features
- Stabilisierungs-Branches (stabilize/from-0b7c366-2026-06-28) — Codex Recovery

Dateien wurden zwischen diesen Orten kopiert und dabei teilweise neuere Versionen
durch ältere überschrieben. Das Ereignisprotokoll dokumentiert den genauen Hergang:
[docs/EREIGNISPROTOKOLL.md](docs/EREIGNISPROTOKOLL.md)

---

## Ideen & Backlog

**Vor jeder Session lesen, am Ende aktualisieren:**
[docs/IDEEN_UND_BACKLOG.md](docs/IDEEN_UND_BACKLOG.md) — lebendes Dokument
für alles, was angedacht aber noch nicht entschieden/umgesetzt ist. Anders
als die Handoffs unten (die sind abgeschlossene Session-Protokolle) ist das
hier der dauerhafte Sammelort für offene Ideen, egal in welcher Session sie
entstanden sind. Zwei thematische Vertiefungen liegen daneben:
[docs/IDENTITY_LOGIN_PLAN.md](docs/IDENTITY_LOGIN_PLAN.md) (Keychain-Prompts,
Single-Login-Frage) und
[docs/ASSISTANT_CAPABILITIES_PLAN.md](docs/ASSISTANT_CAPABILITIES_PLAN.md)
(voller Such-/Schreib-Ausbau des Assistenten — Mail, Kalender, Drive,
Notizen, Clockodo, Kontakte, Bilder, Angebote).

---

## Wo wir stehen

**🟢 Release 6.3.0 — App-Vollständigkeit + Phase 3 CalendarActionCard + BrandsView-Fix (Branch `sprint/shared-drive-widget-oauth`).**
Alle ursprünglichen „in Vorbereitung"-Oberflächen sind live. **Sidebar:** Angebote
(`GlobalOffersView`) und Marken & Daten (`BrandsView`, Integrations-Dashboard).
**Projekt-Tabs:** Assistent (Chat scoped auf Projektnummer) und Dateien (`FilesTabView`).
**Phase 3 (Aufgabe 20):** `SuggestCalendarEventTool` + `CalendarActionCard` — wenn
Claude einen Termin empfiehlt, erscheint eine klickbare Karte die Google Kalender im
Browser öffnet (kein API-Write, nur URL). `.calendarAction`-Block in `ChatContentBlock`,
nie an die API gesendet. **169 Tests grün.** Offen: Google live verifizieren.
**Session 3 (Bugfix):** `BrandsView`-Navigationsbug behoben — `@FocusedBinding` → Callback.
**Aufgabe 14 (Bugfixes + Streaming):** SSE-Streaming live tippend, UserProfile im Prompt,
dynamische Beispielfragen, Chat-Verlauf-Löschen, 2 Bugfixes (Integer-Decode, Wizard-X).

**Akt 5 abgeschlossen.** Politur, Dark Mode, DMG. Aufgabe 9/10: `DriveOfferWatcher`
als Live-Quelle für `offerDetected` + Angebote-Tab. **Aufgabe 11 (Stabilisierung)**
ist abgeschlossen: ein zuvor 100%iger Crash beim Öffnen jeder Projektseite
(content-dimensioniertes Fenster + `.move`-Transition → Update-Constraints-
Endlosschleife auf macOS 26) und der sporadische Galerie-Hang („Lade Projekte…",
Ursache: `RegistryStore` lief nicht auf dem MainActor) sind behoben und **live
verifiziert**. Dazu kam ein Multi-Agent-Bug-Audit mit Fixes (Notiz-Datenverlust,
Signal-Leck, Loader-Races u. a.). **118 Tests grün.** Details in
[HANDOFF_POST_AKT5_11.md](docs/handoffs/HANDOFF_POST_AKT5_11.md).

**⚠️ Externe Daten — harte NO-GOs (User, 2026-06-27):** Sevdesk nie lesen/schreiben;
die geteilte Airtable-Base nie schreiben/editieren/löschen/verschieben; der
verlinkte Google-Drive-Ordner (`0AOeReQBQKkKBUk9PVA`) **read-only** — Kopie nur zu
ausdrücklich genanntem Ziel, Änderung nur per schriftlicher Chat-Erlaubnis. Externe
Daten sind heilig; bei Datenverlust-Gefahr warnen.

| Akt | Status | Inhalt |
|---|---|---|
| Akt 0 | ✅ | Fundament: GRDB, Repository, Cold-Start-Tests, Signal-Engine |
| Akt 1 | ✅ | App-Shell, Galerie, Projekt-Detailseite, 7 Widget-Arten |
| Akt 2 | ✅ | GRDB live, WidgetBoardStore, NoteStore, Heute-Board, SaveStateBar |
| Akt 3, S1 | ✅ | Google OAuth/PKCE + Keychain, Settings-Tab mit Verbinden/Trennen |
| Akt 3, S2 | ✅ | Drive-Widget live (read-only, GoogleDriveClient) |
| Akt 3, S3 | ✅ | Token-Refresh (GoogleAccessTokenProvider) + Kalender-Widget live |
| Akt 3, S4 | ✅ | Kontakte-Widget live (GoogleContactsClient, contactsQuery) |
| Akt 3, S5 | ✅ | Clockodo-Widget live (API-Key-Auth, Settings-Sektion, ClockodoClient) |
| Akt 3, S6 | ✅ | Mail-Widget live (GoogleGmailClient, WidgetKind .mail, mailQuery) |
| Akt 3, S7 | ✅ | Drag & Drop im Widget-Board (Home + Projekt) |
| Akt 3, S8 | ✅ | Airtable-Sync live (AirtableClient, Auth, Settings, Registry.sync) |
| Akt 4 | ✅ | Assistent live (AssistantEngine, Insights, Action-Cards mit Bestätigung) |
| Akt 5 | ✅ | Politur, Dark Mode, DMG, Beta-Vorbereitung |
| Post-Akt 5, Aufgabe 1 | ✅ | Auto-Sync bei App-Start (Airtable nach lokalem Cache-Load) |
| Post-Akt 5, Aufgabe 2 | ✅ | AuditStore persistent + Assistant-Bestätigungen protokolliert |
| Post-Akt 5, Aufgabe 3 | ✅ | About-Fenster über App-Menü mit Version 6.0.0 |
| Post-Akt 5, Aufgabe 4 | ✅ | Eigenes App-Icon (`AppIcon.icns`) im Bundle |
| Post-Akt 5, Aufgabe 5 | ✅ | Claude-LLM-Integration im Assistenten (Keychain + Messages API) |
| Post-Akt 5, Aufgabe 6 | ✅ | Systemarchitektur-PDF, Code-Cleanup & Refresh-Pfad-Härtung (97 Tests) |
| Post-Akt 5, Aufgabe 7 | ✅ | ClickUp-Integration live (Tasks-Widget, ClickUpClient/Auth/Keychain, Settings, 103 Tests) |
| Post-Akt 5, Aufgabe 8 | ✅ | Sevdesk-Integration live (Cash-Widget, Ist-Umsatz vs. Budget-Balken, 109 Tests) |
| Post-Akt 5, Aufgabe 9 | ✅ | Drive-Offer-Watcher live (Polling → `offerDetected`, Baseline-Semantik, 114 Tests) |
| Post-Akt 5, Aufgabe 10 | ✅ | Angebote-Tab live (Belege aus Drive via `DriveOfferWatcher.detectOffers`, read-only) |
| Post-Akt 5, Aufgabe 11 | ✅ | Stabilisierung: Projektdetail-Crash + Galerie-Hang behoben, Multi-Agent-Bug-Audit-Fixes (118 Tests, live verifiziert) |
| Post-Akt 5, Aufgabe 12 | ✅ | Konversationeller Assistent 6.1.0: Phase 0 (ChatStore) + Phase 1 (Multi-Turn-Chat, live verifiziert) + Phase 2 (read-only Tool-Use, Opt-in, Gmail-Labels) — 155 Tests, Sevdesk-Negativtest |
| Post-Akt 5, Aufgabe 13 | ✅ | First-Run-Onboarding-Wizard + lokales Profil (UserProfile/ProfileStore/v3_profile, Overlay-Wizard, geteilte ConnectionStatusView, ehrlicher Done-State) — 158 Tests, Wizard live bestätigt |
| Post-Akt 5, Aufgabe 14 | ✅ | Streaming Phase 1e (SSE live-tippend), UserProfile im System-Prompt, dynamische Beispielfragen, Chat-Verlauf-Löschen, 2 Bugfixes (Integer-Decode, Wizard-X), 5 neue Tests — 163 Tests, Version 6.2.0 |
| Post-Akt 5, Aufgabe 15 | ✅ | Projekt-Assistent-Tab (AssistantChatView scoped auf project.projectNumber, volle Höhe, Header fix) |
| Post-Akt 5, Aufgabe 16 | ✅ | Profil-Sektion in Settings (Name + Rolle editierbar ohne Wizard-Umweg) |
| Post-Akt 5, Aufgabe 17 | ✅ | Globales Angebote-Modul (GlobalOffersView: Projektliste links + OffersTabView rechts) |
| Post-Akt 5, Aufgabe 18 | ✅ | Dateien-Tab live (FilesTabView: alle Drive-Dateien, nach Änderungszeit) + Marken & Daten (BrandsView: Integrations-Dashboard) |
| Post-Akt 5, Aufgabe 19 | ✅ | Polishing: personalisierte Begrüßung, Cmd+1..6 Navigation, projektspezifische Beispielfragen, Sidebar-Profil→Settings, Files-Refresh-Button, Signal-Strip in TodayView |
| Post-Akt 5, Aufgabe 20 | ✅ | Phase 3: `SuggestCalendarEventTool` + `CalendarActionCard` + `.calendarAction` Block (URL → Browser, kein API-Write) — 169 Tests, Version 6.3.0 |
| Live-Wiring, Session 1 | ✅ | Angebote-Tab-Bugfix, Airtable-Base "mykilOS Mastermind" (Schema + 69 Records live), ClickUp-Sandbox-Space, DemoSeed → 31 echte Projekte, hartkodierte Bugs gefixt, Force-Poll-Buttons. Details: [HANDOFF_LIVE_WIRING_1.md](docs/handoffs/HANDOFF_LIVE_WIRING_1.md) |
| Live-Wiring, Session 2 | 🟡 | Google-Login client_secret-Fix, Fenster-Drift-Guard, Projekt-Favoriten klickbar, Drive-Routing über alle 31 Projekte (alle code-fertig, **Live-Verifikation ausstehend**), Assistent-Ausbauplan (nur geplant). Details: [HANDOFF_LIVE_WIRING_2.md](docs/handoffs/HANDOFF_LIVE_WIRING_2.md) |
| Live-Wiring, Session 3 | ✅ | BrandsView-Navigationsbug behoben (`@FocusedBinding` nil → `onNavigateToSettings`-Callback), Live-App-Tour, OAuth-Handshake gesammelt. 169 Tests. Details: [HANDOFF_LIVE_WIRING_3.md](docs/handoffs/HANDOFF_LIVE_WIRING_3.md) |
| Live-Wiring, Session 4 | 📋 | Clockodo Zuhörer + Partner-App Schema: 7 Airtable-Tabellen, Stundensätze, Kalkulationen/Positionen, Ownership-Modell, Merge-Plan. Details: [HANDOFF_LIVE_WIRING_4.md](docs/handoffs/HANDOFF_LIVE_WIRING_4.md) |
| Live-Wiring, Session 5 | 📋 | mykilO$$ Vollintegration: `KalkulationsEngineProviding`-Protokoll, `AppState.kalkulationsEngine`-Slot, Airtable-Tabelle `Eingehende-Angebote` (tbliKfs5FnufjdB36), Integrationsplan. |
| Kalkulations-Port, Schritt 1 | ✅ | Target `MykilosKalkulationsCore` (Foundation-only): 10 Dateien verbatim aus mykilO$$ portiert + 16 Core-Tests (`MykilosKalkulationsCoreTests`). Branch `feat/kalkulation-core-port`. |
| Kalkulations-Port, Schritt 2 | ✅ | GRDB-Lern-Schicht `MykilosServices/Kalkulation/` (LearningDatabase/Records/Store verbatim) + **Cold-Start-Test (Merge-Gate)** `KalkulationsLearningStoreTests`. **187 Tests**. |
| Kalkulations-Port, Schritt 3 | ✅ | Contract `KalkulationsEngineProviding` (aus PR #1, `recordAdjustment` → String) + Engine-Adapter `KalkulationsEngine` (`actor`): `schaetze` live (parse→estimate→Mapping). **189 Tests**. |
| Kalkulations-Port, Schritt 4 | ✅ | `DeviceCatalog` + `CSVParser` portiert; **`geraetepreis` live** (injizierter Katalog, MYKILOS-VK). +3 DeviceCatalog-Tests +1 Engine-Test. **193 Tests**. Adapter-Stubs übrig: `importPDF` (Drive), `recordAdjustment` (Flow). |
| Kalkulations-Port, Schritt 5 | ✅ | `BaselineAnchors` + `BaselineAnchorProvider` portiert; **`AppState.kalkulationsEngine` live verdrahtet** (echte Schätzungen ohne externe Daten). App-Preview bestätigt: kein Crash, Heute-Board/Projekte/Navigation in Ordnung. **194 Tests**. Details: [HANDOFF_KALKULATION_CORE_PORT.md](docs/handoffs/HANDOFF_KALKULATION_CORE_PORT.md). Offen: Kalkulations-Widget-UI, Seed-Provider, `recordAdjustment`-Flow, `importPDF`. |
| Kalkulations-Port, Schritt 6 | ✅ | **KalkulationsWidget + Sidebar-Tab live**: `WidgetKind.kalkulation`, `KalkulationsWidget.swift` (alle 6 Renderstates, Freitext, Min/Mitte/Max, Konfidenz-Badge, Top-Evidenzen), `AppModule.kalkulation` (⌘6), `KalkulationsPageView`. **175 Tests**. |
| Kalkulations-Port, Schritt 7 | ✅ | **`recordAdjustment`-Flow live**: bestätigte Anpassung → `LearningStore.appendAdjustment` (append-only) + `AuditEntry` (`.estimateAdjusted`). `schaetze` persistiert Session → `KostenSchaetzung.schaetzungsID`. `KalkulationsActionCard` (Faktor-Slider + Grund + Bestätigung, kein Auto-Write). Neuer Cold-Start-Test `recordAdjustmentUeberlebtNeustart`. Branch `feat/kalkulation-record-adjustment`. **197 Tests**. |
| Kalkulations-Port, Schritt 8 | ✅ | **Lern-Loop sichtbar**: `recordAdjustment` bekommt `lernen: Bool` (3-Arg-Convenience via Protokoll-Extension hält Schritt-7-Aufrufer grün). Neue Engine-/Protokoll-Methoden `lernUebersicht() -> KalkulationsLernStand` (neue MykilosKit-Value-Types, kein Core-Leak) + `promote(candidateID:)` → `AuditEntry(.calibrationPromoted)`. Widget: Lern-Toggle an der ActionCard + ausklappbare Sektion „Gelernte Kalibrierung" (aktive Faktoren + Promote-Button, alle Renderstates). Neuer Cold-Start-Test `lernLoopUeberlebtNeustartUndVerschiebtSchaetzung` (3× learn → promote → Neustart → Estimator verschiebt mitteNetto). Branch `feat/kalkulation-calibration-loop`. **198 Tests**. Nur noch `importPDF` ist Stub. |
| S10 Learning (Tisch) | ✅ | **mykilOS Dev Collective gegründet**: Team Charter (14 Statuten + Kulturregel), Roadmap S17–S20, Artikel-DB `appdxTeT6bhSBmwx5` entdeckt + READ ONLY-Tabu verankert, PAT-Sicherheitsanalyse, ConversationEngine-Architektur als Tool-Use-Schleife bestätigt (kein Intent-Switch), Studio-Stundensätze von KalkulationsEngine getrennt, S18-Architektur entschieden (scope-Threading für projektID, schaetze darf schreiben). Erfahrungsträger-Archiv für alle Sessions unter `docs/erfahrungstraeger/`. TEAM_BRIEFING.md erstellt. |
| S17 | ✅ | **Security-Härtung** (`feat/security-haertung`): AirtableSyncService No-Op bestätigt, `AirtableError.invalidBaseID` + Validierung, `GoogleUserInfo` (Domain) + `GoogleUserInfoClient` + Scopes (`userinfo.email/profile`), `GoogleAuthService.currentUser` + Hook (nicht-fatal), `AppState.currentGoogleUser`, Sidebar zeigt Google-Name + E-Mail, PAT-Cleanup dokumentiert. **209 Tests**. Offen: Re-Consent live + PAT-Cleanup manuell (Johannes). |
| S18 | 📋 | **Kalkulations-Chat-Tool** im `ConversationEngine`: neues Tool in `AssistantToolRegistry`, projektID via scope-Threading, `schaetze` → strukturierte Antwort im Chat. |

---

## Build-Fixes aus Akt 2 (erledigt, Commit `553414b`)

Die 4 ursprünglich dokumentierten Stellen (SaveState-Equatable, SourceChip-
Home-Kinds, doppeltes `Color(hex:)`, doppeltes `GridTexture`) sind gefixt.
Beim ersten echten Build kamen weitere reale Bugs hinzu, die hier nicht
dokumentiert waren — Details in [HANDOFF_AKT2.md](docs/handoffs/HANDOFF_AKT2.md)
Nachtrag bzw. im Commit selbst: ein garantierter Laufzeitcrash durch
`WidgetKind(rawValue:)!` auf nicht existierenden Rohwerten, ein Sendable-
Closure-Capture-Fehler in `WidgetBoardStore.save()`, fehlende Modul-
Abhängigkeiten (`MykilosWidgets → MykilosServices`), und ein Datum-Rundtrip-
Bug in `FileBackedRepository` (`.iso8601`/`.secondsSince1970` verlieren beide
Präzision über die Unix-Epoch-Konvertierung — nur `timeIntervalSinceReferenceDate`
ist bitgenau roundtrip-sicher).

---

## Absolute Regeln (nicht verhandelbar)

### Persistenz
- Jeder Schreibvorgang `throws`. Niemals `try?` außer in begründeten, kommentierten Ausnahmen.
- `SaveState` (.idle/.saving/.saved(Date)/.failed(String)) ist in der UI sichtbar.
- Cold-Start-Test für jedes neue persistierbare Feature: schreiben → neue Instanz → lesen → identisch.

### Token-Disziplin (SwiftLint erzwingt das)
- Keine `.font(.system(...))` in Feature-/Widget-Code → `Font.mykHero` etc. aus `MykilosDesign`.
- Keine `Color(red:...)` → `MykColor.drive.color` etc.
- Keine `Color(hex:)` in Widgets/Features → `public` in `MykilosDesign/Tokens.swift` nutzen.

### Secrets
- Tokens, API-Keys, PATs → nur Keychain. Nie in Code, Dateien, Repo, Logs.
- Externe IDs (Airtable-Record, Drive-Folder, ClickUp-Liste) = Referenzen, nie Primärschlüssel.

### Widgets
- Widgets reden NIE direkt miteinander → nur über `StudioContext.emit()`.
- Signale sind VORSCHLÄGE (laut für Einsicht). Schreiben nur über Action-Card → Bestätigung → Audit.
- Jedes Widget hat alle Renderstates: loading / content / empty / permissionRequired / offline / error.
- Quelle ist immer sichtbar (Quellenzeile unten).

### Architektur
- Multi-Target: `App → Widgets → Design`, `Services → Kit`, `Integrations → Kit`.
- `MykilosKit` importiert NIE SwiftUI oder GRDB.
- `MykilosWidgets` importiert NIE GRDB.
- Schreibvorgänge kommen NIE aus Views — nur über Stores.

### Prozess
- Eine Session = ein kleiner PR = ein Handoff (`docs/handoffs/HANDOFF_AKT{n}_S{m}.md`).
- CI ist Merge-Gate: roter Build/Test = kein Merge.
- Keine parallelen Worktrees.

---

## Target-Struktur

```
Sources/
  MykilosKit/          # Foundation ← importiert NICHTS von uns
    Domain/            # Customer, Project, WidgetFoundation, AuditEntry, WidgetBoard
    Persistence/       # Repository, FileBackedRepository, PersistenceError, SaveState
    Signals/           # WidgetSignal, Mediator, StudioContext (@Observable)
  MykilosDesign/       # Tokens (MykColor, MykSpace, MykRadius), Typography, SourceColor
  MykilosServices/     # CachedProjectRegistry, AirtableRegistry, GRDBDatabase,
                       # WidgetBoardStore, NoteStore, GRDB-Records
                       # Google/ — OAuth/PKCE, Loopback-Server, Keychain-Store,
                       #   GoogleAuthService (Akt 3, S1), GoogleDriveClient (S2),
                       #   GoogleAccessTokenProvider + GoogleTokenRefreshService +
                       #   GoogleCalendarClient (Akt 3, S3), GoogleContactsClient (S4),
                       #   GoogleGmailClient (Akt 3, S6),
                       #   DriveOfferWatcher (Post-Akt 5, Aufgabe 9 — Polling → offerDetected)
                       # Clockodo/ — ClockodoClient, ClockodoAuthService,
                       #   KeychainClockodoCredentialsStore (Akt 3, S5)
                       # Airtable/ — AirtableClient, AirtableAuthService,
                       #   KeychainAirtableCredentialsStore (Akt 3, S8)
                       # ClickUp/ — ClickUpClient, ClickUpAuthService,
                       #   KeychainClickUpCredentialsStore (Post-Akt 5, Aufgabe 7)
                       # Sevdesk/ — SevdeskClient, SevdeskAuthService,
                       #   KeychainSevdeskCredentialsStore (Post-Akt 5, Aufgabe 8)
  MykilosWidgets/      # WidgetContainer, WidgetBoardView, SourceChip, SaveStateBar,
                       # Kinds/ (8 Widgets: drive, tasks, contacts, cash, calendar, notes, mail, assistant)
  MykilosApp/          # Shell (Sidebar), Gallery, Detail (ProjectDetailView,
                       # OffersTabView — Angebote-Tab live, Aufgabe 10), Today,
                       # Data (AppState, AppDatabase, RegistryStore, DemoSeed)

Tests/
  MykilosKitTests/     # Cold-Start-Tests (FileBackedRepository)
  MykilosServicesTests/# WidgetBoardStoreTests (GRDB Cold-Start), GoogleOAuthTests,
                       # GoogleDriveClientTests, GoogleCalendarClientTests,
                       # GoogleContactsClientTests, GoogleGmailClientTests,
                       # ClockodoClientTests, ClockodoAuthServiceTests,
                       # AirtableClientTests, AirtableAuthServiceTests,
                       # ClickUpClientTests (URL/Parser/notConnected),
                       # SevdeskClientTests (URL/Parser/double/notConnected),
                       # DriveOfferWatcherTests (Erkennung/Baseline/Poll-Semantik mit Fake),
                       # GoogleAccessTokenProviderTests (Refresh-Logik mit Fake) —
                       # kein echtes Keychain/Netzwerk im Testlauf, siehe
                       # HANDOFF_AKT3_S1/S2/S3/S4/S5/S6.md
```

---

## Die Palette (Tokens)

```
--paper    #FAF8F3   Grund
--ink      #1A1814   Tinte
--drive    #C26B4A   Terrakotta  → Dateien/Drive
--people   #6E8B6A   Salbei      → Menschen/Kalender
--tasks    #C99A3E   Ocker       → Aufgaben/ClickUp
--cash     #4C6280   Tiefblau    → Geld/Angebote
--personal #8A5B73   Pflaume     → Notizen
--positive #3E7A4E   --critical #B4503C
```
Farbe ist Sprache: man erkennt die Quelle, bevor man liest.

---

## Team-Modell

Persönliches Cockpit, geteilte Instrumente. Jeder hat sein eigenes mykilOS,
sieht durch seine eigene Identität auf die geteilten Drive-Ordner, ClickUp-Tasks, Kalender.
Projekt-Verdrahtung (boardID, Links) über Airtable als System-of-Record.
Kein Sync-Backend in V1.

---

## Nächste Schritte

Akt 0–5 und alle dokumentierten Post-Akt-5-Verfeinerungen sind abgeschlossen.
Die App ist feature-complete für Beta. **Beide ursprünglichen Stub-Widgets sind
jetzt live** — Tasks (ClickUp, Aufgabe 7) und Cash (Sevdesk, Aufgabe 8) — und
mit Aufgabe 9 hat auch `offerDetected` eine echte Live-Quelle. Alle Widgets
lesen echte Daten, die Integrations-Landkarte ist vollständig.

**Was nach Plan noch offen ist:** Mit Aufgaben 15–18 sind alle ursprünglich geplanten
„in Vorbereitung"-Oberflächen live: Projekt-Tabs Assistent und Dateien, Sidebar-Module
Angebote und Marken & Daten. Noch „ComingSoon": Projekt-Tabs Timeline und Material
(keine Datenquelle vorhanden). Offen: Google live verifizieren, Phase 3 ChatActionCard.

**🎯 Nächste Session (Live-Wiring 2) — konkreter Plan, siehe
[HANDOFF_LIVE_WIRING_1.md](docs/handoffs/HANDOFF_LIVE_WIRING_1.md):**
1. `DemoSeed` durch die echten 31 Projekte/30 Kunden aus
   `docs/registry/projekte.json`/`kunden.json` ersetzen (größter Hebel —
   macht Budget-/Phase-Anzeigen automatisch real statt hartkodiert).
2. Verbleibende hartkodierte Demo-Bugs fixen: `ProjectHeroView` (72%-Budget-
   Balken fix), `FocusWidget` (Text ignoriert echtes Signal-Projekt),
   `CashWidget` (Angebotstext hartkodiert).
3. Demo-Signal-Buttons (`SignalDemoView`, `HomeDemoSignalButton`) zu echten
   "Jetzt prüfen"-Force-Polls gegen `DriveOfferWatcher` umbauen.
4. Neue Tabs: Zeichnungen (PDF-Vorschau, Quelle `02 CAD`), Material
   (Quelle `03 PRÄSENTATION`), Abnahme-Bereich.
5. Optional: `RegistryStore.syncFromAirtable` testweise gegen die neue
   Mastermind-Base (`appuVMh3KDfKw4OoQ`, bereits mit 69 Records befüllt)
   laufen lassen, sobald Settings auf diese Base-ID zeigen.

**Aus Post-Akt-5 Aufgabe 10 (Angebote-Tab):**
- Der Projekt-Tab „Angebote" (`OffersTabView`, in `MykilosApp/Detail/`) war ein
  „in Vorbereitung"-Platzhalter und zeigt jetzt die Angebots-/Rechnungs-PDFs aus
  dem verlinkten Drive-Ordner.
- **Eine Quelle der Wahrheit:** erkannt wird über `DriveOfferWatcher.detectOffers`
  (dafür `public` gemacht) — exakt dieselbe Heuristik wie das `offerDetected`-
  Signal, keine zweite, abweichende Logik in der UI.
- Read-only über den bestehenden `GoogleDriveClient`: privater `@Observable`-
  Loader, `.task(id: driveFolderID)`, alle Renderstates über den geteilten
  `WidgetContainer` (leer/loading/permissionRequired/error inkl. Retry),
  Quellzeile „GOOGLE DRIVE · N BELEGE" sichtbar. Rows öffnen `webViewLink` im
  Browser, kein Download/Schreiben.
- In `ProjectDetailView.tabContent` als `case .offers` verdrahtet.
- Keine neuen Tests nötig: die einzige echte Logik (`detectOffers`) deckt der
  bestehende Test `detectOffersErkenntNurAngebotsPDFs` ab — jetzt über die
  `public`-Methode, die auch die Tab nutzt. 114 Tests grün.

**Aus Post-Akt-5 Aufgabe 9 (Drive-Offer-Watcher):**
- `DriveOfferWatcher` (`@MainActor @Observable`, in `Services/Google/`) ist die
  echte Live-Quelle für `offerDetected`. Ein echter Google-Push-Webhook bräuchte
  eine öffentliche Callback-URL und damit ein Backend — mykilOS ist local-first,
  daher **Polling** des verlinkten Drive-Ordners (read-only `files.list` über den
  bestehenden `GoogleDriveClient`).
- **Baseline-Semantik:** der erste `poll(...)` markiert alle vorhandenen Treffer
  als „gesehen" und meldet NICHTS (sonst flutete jedes alte Angebot beim Öffnen).
  Danach erzeugt nur ein wirklich neu aufgetauchtes Angebots-/Rechnungs-PDF ein
  Signal. Ein „Angebot" = PDF mit Schlüsselwort im Namen (angebot/rechnung/
  kostenvoranschlag/offer/invoice) — bewusst konservativ.
- `ProjectDetailView` startet einen `.task(id: driveFolderID)`-Loop, der solange
  das Projekt offen ist alle 60 s pollt und neue Signale über `context.emit(...)`
  in den bestehenden Mediator-/CashWidget-Pfad gibt. Fehler werden im Hintergrund-
  Poll bewusst geschluckt (Fehlerzustände zeigt das DriveWidget selbst).
- Signale bleiben VORSCHLÄGE: `offerDetected` → Mediator `reviewSuggested` →
  CashWidget-Hinweis. Es wird nie geschrieben. Der `SignalDemoView`-Button bleibt
  als sofort auslösbarer Showcase (gleiches Signal ohne echtes neues PDF).
- Tests: `DriveOfferWatcherTests` (Erkennungslogik, Baseline meldet nichts,
  zweiter Poll meldet nur Neues, kein Doppel-Report, Fehler/leer → leer) mit
  `FakeDriveClient` — 114 Tests grün.
- **Nicht live getestet:** echter Drive-Abruf mit verbundenem Account + realem
  neuen PDF bleibt ein manueller Beta-Check (Tests nutzen kein echtes Keychain/
  Netzwerk). Das Poll-Intervall (60 s) ist bewusst gemächlich gewählt.

**Aus Post-Akt-5 Aufgabe 8 (Sevdesk-Integration):**
- `SevdeskClient` liest die Rechnungen eines sevdesk-Kontakts
  (`GET my.sevdesk.de/api/v1/Invoice`, `contact[id]=ref`, `limit=100`),
  API-Token im `Authorization`-Header. Testbar über injizierbaren
  `URLSession`/Store; reine statische `buildInvoicesURL`/`parseInvoices`/`double`.
- `SevdeskAuthService` + `KeychainSevdeskCredentialsStore` (Service
  `com.mykilos6.sevdesk`, ein Feld `apiToken`) — gleiche Form wie ClickUp/Airtable.
- `CashWidget` konsumiert den Client per Loader (`sevdeskRef` als Handle):
  Ist-Umsatz = Summe `sumGross`; **Budget kommt aus Airtable** über das neue Feld
  `ProjectLinks.budget` (Spalte „Budget" → `numberValue` in `mapProjects`). Der
  Balken zeigt Ist vs. Budget, über Budget → kritische Farbe. Der Drive→Cash-
  Signal-Whisper bleibt **bewusst unabhängig** von der sevdesk-Verbindung, damit
  der Signal-Showcase auch ohne sevdesk lebt; die Sub-States (loading/empty/
  permissionRequired/error) rendert der Balken inline.
- 6. Settings-Sektion „Sevdesk Umsatz" (SecureField Token, Verbinden/Trennen).
- Tests: `SevdeskClientTests` (URL-Builder, Parser, `double`-Helfer, leere Liste,
  kaputtes JSON, `notConnected`) — 109 Tests grün.
- **Nicht live getestet:** echter sevdesk-Abruf mit Token + realem Kontakt bleibt
  ein manueller Beta-Check (Tests nutzen kein echtes Keychain/Netzwerk). Offen
  bleibt auch, welcher genaue `objectName`/Filter live die erwartete Rechnungs-
  menge liefert — bei Bedarf in `buildInvoicesURL` nachziehen.

**Aus Post-Akt-5 Aufgabe 7 (ClickUp-Integration):**
- `ClickUpClient` liest die offenen Aufgaben einer Liste
  (`GET api.clickup.com/api/v2/list/{id}/task`, `archived=false`,
  `include_closed=false`), Personal-Token im `Authorization`-Header.
  Testbar über injizierbaren `URLSession`/Store; reine statische
  `buildTasksURL`/`parseTasks`/`date(fromEpochMillis:)`.
- `ClickUpAuthService` + `KeychainClickUpCredentialsStore` (Service
  `com.mykilos6.clickup`, ein Feld `apiToken`) — gleiche Form wie Airtable-PAT.
- `TasksWidget` konsumiert den Client wie `DriveWidget`: per-Projekt-Loader,
  `clickUpListID` als Handle, alle Renderstates (leerer Handle → `.empty`,
  `notConnected` → `.permissionRequired`). In `ProjectDetailView` verdrahtet.
- 5. Settings-Sektion „ClickUp Aufgaben" (SecureField Token, Verbinden/Trennen).
- Tests: `ClickUpClientTests` (URL-Builder, Parser inkl. Fälligkeit/Assignee/
  Urgent, leere Liste, kaputtes JSON, `notConnected`) — 103 Tests grün.
- **Nicht live getestet:** echter ClickUp-Abruf mit Token + realer Liste bleibt
  ein manueller Beta-Check (Tests nutzen kein echtes Keychain/Netzwerk).

**Aus Post-Akt-5 Aufgabe 1 (Auto-Sync bei App-Start):**
- `AppState.bootstrap()` lädt weiterhin zuerst lokale Boards und Registry
  (Demo-Seed + Cache) und stößt danach bei verbundenem Airtable-Status den
  bestehenden `RegistryStore.syncFromAirtable` mit der gespeicherten Base-ID an.
- Der echte Startup-Sync mit Live-Airtable-Credentials bleibt ein manueller
  Beta-Check, weil automatisierte Tests kein echtes Keychain/Netzwerk nutzen.

**Aus Post-Akt-5 Aufgabe 2 (AuditStore):**
- `AuditStore` ist GRDB-backed, `@MainActor @Observable`, nutzt sichtbaren
  `SaveState` und schreibt Audit-Einträge ausschließlich über `append(_:)`.
- `AssistantWidget` schreibt bestätigte `SuggestedAction`s nun als
  `AuditEntry` und zeigt den Audit-Speicherstatus direkt an der Action-Card.
- Der neue Cold-Start-Test `auditEntryUeberlebtNeustart` beweist:
  schreiben → neue Store-Instanz → lesen → identische Audit-Daten.

**Aus Post-Akt-5 Aufgabe 3 (About-Fenster):**
- `MykilOS6App` besitzt ein About-Window (`id: "about"`) und ersetzt den
  macOS-AppInfo-Menüeintrag durch "Über mykilOS 6".
- Das Fenster zeigt App-Name, Version `6.0.0`, Copyright `MYKILOS` und einen
  kurzen Einzeiler mit `MykColor`/`Font.myk...` Design-Tokens.

**Aus Post-Akt-5 Aufgabe 4 (App-Icon):**
- `Sources/MykilosApp/Resources/AppIcon.icns` ist das Bundle-Icon; die
  editierbare 1024px-Quelle liegt daneben als `AppIconSource.png`.
- `script/build_and_run.sh` kopiert das Icon nach `Contents/Resources` und
  schreibt `CFBundleIconFile` in die generierte `Info.plist`.

**Aus Post-Akt-5 Aufgabe 5 (Claude-LLM-Integration):**
- `ClaudeAuthService` speichert Anthropic API-Key und Modell ausschließlich im
  Keychain. Default-Modell: `claude-sonnet-4-6`.
- `ClaudeMessagesClient` ruft die Anthropic Messages API testbar über einen
  injizierbaren HTTP-Client auf; automatisierte Tests prüfen Request-Header,
  Payload und Response-Parsing ohne echten Netzwerkzugriff.
- `AssistantWidget` zeigt weiterhin sofort die regelbasierten Insights und
  lädt nur bei verbundener Claude-Konfiguration zusätzlich eine natürliche
  Zusammenfassung. Schreibaktionen bleiben bestätigungspflichtig und laufen
  weiter über Action-Card → Audit.
- Live-API-Check mit Keychain-Credentials und `claude-sonnet-4-6` war
  erfolgreich; das App-Bundle wurde danach neu gestartet und codesign-verifiziert.

**Aus der Live-Wiring-Session 1 (2026-06-27) — Airtable Mastermind + ClickUp Testspace:**
- Neue, eigenständige Airtable-Base **"mykilOS Mastermind"**
  (`appuVMh3KDfKw4OoQ`) — vom User explizit als eigene "Schaltzentrale"
  freigegeben, **getrennt** von der ursprünglichen geteilten Base unter dem
  harten NO-GO. Schema (`Kunden`/`Projekte`/`Externe Systeme`/
  `Archiv-Übersetzung`) ist 1:1 an `AirtableClient.mapProjects`/
  `mapCustomers` angelehnt. **69 Records live eingespielt:** 30 Kunden,
  31 Projekte, 8 externe Systeme.
- Airtable-MCP-Connector kann keine Records schreiben (nur Schema) —
  Workaround per Personal-Access-Token (Keychain-Service
  `mykilos-mastermind-airtable-pat`) + lokalem `curl`-Skript, Token nie im
  Chat sichtbar gemacht.
- Neuer ClickUp-Space **"MYKILOS API TESTSPACE"** (`90128024109`) entdeckt —
  Sandbox mit Test-Liste, sicherer Ort für Aufgabe 7 (ClickUp-Handle für
  `ProjectKind`).
- Vollständiger Demo-/Dummy-Audit (11 Punkte) für die nächste Session,
  Angebote-Tab-Bugfix bereits umgesetzt + getestet.
- Details, Migrationsskript-Muster und Startprompt für Session 2:
  [HANDOFF_LIVE_WIRING_1.md](docs/handoffs/HANDOFF_LIVE_WIRING_1.md).

**Aus der Live-Wiring-Session (2026-06-27) — Drive als Projektquelle:**
- Es gibt keine Airtable-Projekttabelle. Projekte werden direkt aus dem
  echten Drive-Ordner `PROJEKTE` (`1Q-H_3JsZfiXosFmxtNgoy0hI3cvZLgST`)
  geroutet — 31 aktive Projektordner, Schema `JJJJ_lfdNr_Kunde[_Code]`,
  tolerant geparst (fehlende führende Nullen, Bindestrich-Kunden etc.).
  Projektnummer-Format in der App: `JJJJ-NR` (z. B. `2026-015`).
- `ProjectKind` (kitchen/lighting/addendum/lead/quote) lässt sich aus dem
  Drive-Ordnernamen nicht ableiten — kommt später aus ClickUp. Geplant:
  ein Handle/Link-Konnektor (ClickUp-Listen-ID pro Projekt) plus eine
  Übersetzungsregistry in Airtable, die ClickUp-Daten auf `ProjectKind`
  mapped. Noch nicht umgesetzt.
- `_PROJEKTE_ARCHIV` (`1I5P6Iu_b5NxmhcqH1PP7e9pU_hmD_YJz`) enthält ~200+
  archivierte Projektordner über 8 Jahre (2018–2026), mit einem komplett
  anderen, uneinheitlichen Namensschema (Standort-Präfixe wie `B_`, `HH_`,
  `K_`, `WI_` statt `JJJJ_lfdNr_Kunde`) und mehrfach verschachtelten
  Jahres-Unterordnern. **Bewusst zurückgestellt** — kein Parser, kein
  Import, keine Einbindung in die App jetzt. Geplanter Ansatz für später:
  eigener Namens-Mapping-Parser fürs alte Schema + eine
  Übersetzungsregistry in Airtable (Alt-Name ↔ neues `JJJJ-NR`-Schema),
  nicht direkt in mykilOS-Core.

**Aus der Live-Wiring-Session 4 (2026-06-28) — Clockodo Zuhörer Architektur:**
- Ziel: Natürliche Sprache im Assistenten-Chat → Clockodo-Zeitbuchung.
  "habe grad 4h CAD für Heinz gemacht" → Draft → Wochenabschluss → POST.
- **Kernregel:** Jeder angemeldete User bucht, sieht und editiert **ausschließlich
  seine eigenen** Zeiteinträge. `ClockodoDraftEntry.clockodoUserID` filtert
  auf GRDB-Ebene; Clockodo-API-Credentials pro User im Keychain.
- **Airtable-Schema (live in `appuVMh3KDfKw4OoQ`):**
  - `Clockodo-Nutzer` (`tblPbly2br8mR2kaU`): Name, E-Mail, Clockodo-User-ID,
    Aktiv, **Airtable-Entwurf-Tabelle** (Feld `fldsoeQHWDmbBt7FM` — zeigt auf
    die persönliche Entwurfstabelle des Users, selbstreferenziell).
    4 Records mit allen User-IDs und Entwurfs-Tabellen-IDs.
  - `Clockodo-EW-Johannes` (`tbl4vZ2UFyeTRD8hd`) — persönl. Arbeitstabelle.
  - `Clockodo-EW-Jilliana` (`tblXQIDrvPVN9ijI9`) — persönl. Arbeitstabelle.
  - `Clockodo-EW-Daniel`   (`tblNDVve3jjJ9s8HB`) — persönl. Arbeitstabelle.
  - `Clockodo-EW-Frauke`   (`tblRrqIQZmm2DosJT`) — persönl. Arbeitstabelle.
    Felder je EW-Tabelle: Datum, Von, Bis, Dauer-h, Projekt, Kunden-ID,
    Leistung, Leistungs-ID, Notiz, Billable, KW, Quelle, Status.
  - `Clockodo-Buchungen` (`tblYQxlauwej7FD1w`): Master-Audit-Log nach Bestätigung.
  - `Clockodo-Leistungen` (`tblRtsegocdpM8CJd`): bereits befüllt (8 Services).
  - `Kunden.Clockodo-Kunden-ID`: bereits gemappt (10 von 30 Kunden).
- **6-Schichten-Architektur (Code noch nicht implementiert):**
  1. Intent Layer: `ClaudeConversationEngine` erkennt `clockodoDraft`-Intent,
     extrahiert Dauer, Leistungstyp, Kunden-/Projektreferenz.
  2. Resolution Layer: `ClockodoDraftResolver` mappt Freitext auf echte IDs
     (Airtable-Lookup, Fallback auf "Mykilos GmbH intern").
  3. Draft Store: `ClockodoDraftEntry` (GRDB lokal) + Sync → persönliche
     Airtable-EW-Tabelle (ID aus `Clockodo-Nutzer.Airtable-Entwurf-Tabelle`).
  4. **Zwei UI-Orte (beide live):** ClockodoWidget (Heute-Seite, kompakt,
     Wochenbalken + Quick-Add) UND Zeiten-Tab im Chat-Assistenten (voll,
     editierbar, mit NLP-Eingabe). Beide lesen denselben Draft-Store.
  5. Confirm → POST: `POST /api/v2/entries` mit User-Credentials →
     AuditEntry (GRDB) + Record in `Clockodo-Buchungen` (Airtable-Master).
     EW-Tabelle-Eintrag wechselt Status auf "Gebucht".
  6. Mail/Kalender-Vorschläge: Claude liest Gmail + GCal → schlägt Drafts vor
     (quelle: `.calendar` / `.mail`, Bestätigung erforderlich).
- `POST /api/v2/entries` benötigt: `customers_id`, `services_id`, `time_since`,
  `time_until`, `billable`. Endpoint ist aktiv (nicht deprecated).

**Aus der Live-Wiring-Session 5 (2026-06-28) — mykilO$$ Vollintegration:**
- **Entscheidung:** mykilO$$ ist keine eigenständige App mehr. Alle Kalkulations-
  fähigkeiten (EvidenceBasedEstimator, BottomUpCostEngine, LearningStore,
  ReviewCenter 815 Positionen, DeviceCatalog 13.419 Preise, PDF-Import-Pipeline)
  werden als Modul in mykilOS 6 integriert. Alle Schreibrechte bei mykilOS 6.
- **Protokoll:** `KalkulationsEngineProviding` + Typen (`KostenSchaetzung`,
  `PriceEvidence`) in `Sources/MykilosKit/Domain/KalkulationsEngineProviding.swift`.
  `AppState.kalkulationsEngine: (any KalkulationsEngineProviding)?` gesetzt (nil
  bis Engine integriert ist).
- **Airtable:** Alle 3 Kalkulations-Tabellen live in `appuVMh3KDfKw4OoQ`:
  `Kalkulationen` (`tblO3y2jdmxDnuiZj`), `Kalkulations-Positionen`
  (`tblNamx3cHTus6gtk`), **`Eingehende-Angebote`** (`tbliKfs5FnufjdB36`, neu —
  SHA256-dedup, Lieferant, Netto-Summe, Status, Lern-Gewicht, Importiert-am).
- **Vollständiger Merge-Plan:** [KALKULATION_INTEGRATION.md](docs/KALKULATION_INTEGRATION.md)
  (10 Schritte, GRDB-Migration-Plan, UI-Slots, 59 Tests, Drive-Integration).
- **Offener Punkt:** Stundensätze in `Clockodo-Leistungen` (Feld
  `fld4NBokj4MoOy8Uq`) sind noch leer — manuell einzutragen (blockiert den
  Kostenboden aber NICHT: `CostModel.stages` sind hardcoded).
- **Offener Punkt:** Naming der `05 eingehende Angebote`-Kategorie-Unterordner
  (Tischler, Stein + was noch?) — nur Johannes kann bestätigen.
- **Verifizierte Architektur (Code gelesen):** `KalkulationsCore` (10 Dateien)
  ist Foundation-only → eigenes Target `MykilosKalkulationsCore`, NICHT in
  `MykilosServices/Kalkulation/` (GRDB). Zweistufig `parse → estimate`.
  LearningStore in eigener `learning.sqlite`. `AirtableSyncService.swift` löschen
  (ENV-Secrets, fremde Base `appkPzoEiI5eSMkNK`, Blocking). Details + Port-Reihenfolge
  in [HANDOFF_LIVE_WIRING_5.md → Teil 2](docs/handoffs/HANDOFF_LIVE_WIRING_5.md).
- **✅ BLOCKER GELÖST (2026-06-28):** Alle Geschwister-Typen liegen in den 10
  KalkulationsCore-Dateien (`CarryforwardRule`=Review.swift:33 usw.). Kompletter verbatim Port.
  Reconciliation: `EstimateSession.id` ist `String` → Protokoll-IDs auf String. Siehe Handoff Teil 3.
- **✅ Destillation ENTSCHIEDEN (Johannes): V2-Swift-Pipeline** — 3.383→204 wird in Swift
  reimplementiert (geschlossener Lernkreis, Airtable-Beobachtungen destillieren nach). V1 nutzt
  vorhandene CSVs. Offen bleibt: `gen_lexicon.py` fehlt → MaterialLexicon manuell.
- **Korpus (V4_MoneyObservations, 3.383 Beobachtungen, 8 Lieferanten):** Heimat =
  beides — Tabelle `Preis-Beobachtungen` in Base `appuVMh3KDfKw4OoQ` (System-of-Record,
  alte Base stillgelegt) + destilliertes Seed-`sqlite` zur Laufzeit.
- **✅ ENTSCHIEDEN (2026-06-28):** Workspace = Team-Plan (bezahlt), kein Verschieben nötig.
  Bases-Struktur: 1 Base (`appuVMh3KDfKw4OoQ`), kein Split geplant.
  Zulieferpreise (3.383 Beobachtungen) → **lokal in `learning.sqlite`**, nicht Airtable.
  Stundensätze (`Clockodo-Leistungen.Stundensatz`) → Airtable als Master, GRDB als Cache.
  Details: [IDEEN_UND_BACKLOG.md → Airtable-Infrastruktur](docs/IDEEN_UND_BACKLOG.md).
- **⚠️ OFFEN (Johannes-Aktion):** Stundensätze für 8 Leistungsarten manuell in Airtable eintragen.

**Bekannte offene Punkte aus Schritt 1 (noch nicht relevant geworden):**
- Ob Google "Desktop App"-OAuth-Clients bei PKCE zusätzlich ein `client_secret`
  verlangen, ist nicht live getestet (V5 unterstützte es optional, V6 aktuell
  nicht) — falls Google beim ersten echten Verbinden `invalid_client` meldet,
  `clientSecret` Parameter in `GoogleOAuthPKCEService` nachziehen.

**Aus Schritt 2 (Drive-Widget):**
- ✅ Erledigt: Der ungenutzte `Sources/MykilosWidgets/WidgetBoardView.swift`
  (öffentliches Duplikat des Dispatch-Switches) wurde gelöscht. Gerendert wird
  ausschließlich über `ProjectWidgetBoardView` (Projekt) bzw. das Heute-Board.

**Aus Schritt 3 (Token-Refresh + Kalender-Widget):**
- Token-Refresh (`GoogleAccessTokenProvider`) ist jetzt zentral verdrahtet und
  von Drive + Kalender genutzt — aber der echte Refresh-Pfad ist nur per
  Unit-Test mit Fake-Refresher abgedeckt, nie live beobachtet (ein Access-Token
  läuft typischerweise erst nach 1 Stunde ab). Beim nächsten Live-Client
  (Mail/Kontakte) im Hinterkopf behalten, falls der erste echte Ablauf
  überraschend anders reagiert als der Test.
- ✅ Korrigiert: Ein fehlgeschlagener Refresh (z. B. widerrufenes
  Refresh-Token) wird jetzt einheitlich behandelt — alle vier Google-Clients
  (Drive/Calendar/Contacts/Gmail) mappen jeden Provider-Fehler via
  `try? await tokenProvider.validAccessToken()` auf `.notConnected`, und alle
  vier Widgets übersetzen das auf `.permissionRequired`. Der Container zeigt
  dort „Berechtigung nötig · In den Einstellungen verbinden" statt eines
  generischen `httpError`. (Vorher als offener Punkt notiert — die alte Notiz
  war veraltet.)
- Offen bleibt nur die feine Unterscheidung „nie verbunden" vs. „Sitzung
  abgelaufen" — beide zeigen denselben `.permissionRequired`-Zustand. Für V1
  bewusst zusammengefasst; ein eigener `.authExpired`-State wäre Over-Engineering.

**Aus Schritt 4 (Kontakte-Widget):**
- `ProjectLinks.contactsQuery` ist eine Freitext-Suche über die echten
  Kontakte des verbundenen Accounts (People API `searchContacts`), keine
  eigene Kontaktliste je Projekt — gleiches Muster wie `calendarQuery`.
  Die Demo-Fantasie-Rollen ("Bauherr"/"Architektin") sind entfallen, die
  People API liefert sie nicht.
- Gleicher offener Punkt wie seit Schritt 1: ob Google "Desktop App"-Clients
  zusätzlich ein `client_secret` verlangen, ist weiterhin nicht live getestet.

---

## Hilfreiche Kommandos

```bash
swift package resolve          # GRDB + Dependencies holen
swift build                    # Kompilieren
swift test                     # Tests (zuerst Cold-Start-Tests)
swift run                      # App starten (ohne Bundle)
./script/build_and_run.sh      # Echtes .app-Bundle in dist/ bauen + starten
                                # (das ist auch die "Run"-Action in Codex)
swiftlint --strict              # Token-Disziplin prüfen
```

**Repo:** https://github.com/JohannesLeoB/mykilOS-6 (privat). Codex-Workflow
und Session-Regeln: `docs/codex/WORKFLOW.md`.

---

## Doku

- `docs/handoffs/HANDOFF_AKT0.md` — Fundament
- `docs/handoffs/HANDOFF_AKT1.md` — App-Shell, Galerie, Widgets
- `docs/handoffs/HANDOFF_AKT2.md` — GRDB, Heute-Board, SaveState
- `docs/handoffs/HANDOFF_AKT3_S1.md` — Google-OAuth-Fundament
- `docs/handoffs/HANDOFF_AKT3_S2.md` — Drive-Widget live
- `docs/handoffs/HANDOFF_AKT3_S3.md` — Token-Refresh + Kalender-Widget live
- `docs/handoffs/HANDOFF_AKT3_S4.md` — Kontakte-Widget live
- `docs/handoffs/HANDOFF_AKT3_S5.md` — Clockodo-Widget live
- `docs/handoffs/HANDOFF_AKT3_S6.md` — Mail-Widget live
- `docs/handoffs/HANDOFF_AKT3_S7.md` — Drag & Drop im Widget-Board
- `docs/handoffs/HANDOFF_AKT3_S8.md` — Airtable-Sync live
- `docs/handoffs/HANDOFF_AKT3.md` — Akt 3 Gesamtübersicht
- `docs/handoffs/HANDOFF_AKT4.md` — Assistent live
- `docs/handoffs/HANDOFF_AKT5.md` — Politur, Dark Mode, DMG
- `docs/handoffs/HANDOFF_POST_AKT5_1.md` — Auto-Sync bei App-Start (Airtable)
- `docs/handoffs/HANDOFF_POST_AKT5_2.md` — AuditStore + Assistant-Protokollierung
- `docs/handoffs/HANDOFF_POST_AKT5_3.md` — About-Fenster mit Versionsnummer
- `docs/handoffs/HANDOFF_POST_AKT5_4.md` — Eigenes App-Icon im Bundle
- `docs/handoffs/HANDOFF_POST_AKT5_5.md` — Claude-LLM-Integration im Assistenten
- `docs/handoffs/HANDOFF_POST_AKT5_6.md` — Systemarchitektur-PDF, Cleanup & Refresh-Härtung
- `docs/handoffs/HANDOFF_POST_AKT5_7.md` — ClickUp-Integration live (Tasks-Widget)
- `docs/handoffs/HANDOFF_POST_AKT5_8.md` — Sevdesk-Integration live (Cash-Widget, Ist vs. Budget)
- `docs/handoffs/HANDOFF_POST_AKT5_9.md` — Drive-Offer-Watcher live (Polling → offerDetected)
- `docs/handoffs/HANDOFF_POST_AKT5_10.md` — Angebote-Tab live (Belege aus Drive, geteilte Erkennung)
- `docs/handoffs/HANDOFF_POST_AKT5_11.md` — Stabilisierung: Projektdetail-Crash + Galerie-Hang + Bug-Audit-Fixes (live verifiziert, 118 Tests)
- `docs/handoffs/HANDOFF_POST_AKT5_12_ASSISTANT_PLAN.md` — Multi-Agent-Synthese-Plan für den konversationellen Assistenten (Phasen 0–4, NO-GO-Durchsetzung, offene Entscheidungen)
- `docs/handoffs/HANDOFF_POST_AKT5_13_ASSISTANT_RELEASE.md` — Release 6.1.0: ehrlicher Reality-Check, feste Vision, fester Nächste-Session-Plan, **Startprompt**
- `docs/handoffs/HANDOFF_POST_AKT5_15_SURFACE_COMPLETION.md` — Release 6.3.0: App-Vollständigkeit (Aufgaben 15–21), Phase 3 CalendarActionCard, Signal-Badges, Grounding-Update, 169 Tests
- `docs/handoffs/HANDOFF_LIVE_WIRING_1.md` — Live-Wiring Session 1: Airtable Mastermind, 31 echte Projekte, Force-Poll-Buttons
- `docs/handoffs/HANDOFF_LIVE_WIRING_2.md` — Live-Wiring Session 2: client_secret-Fix, WindowGuard, Favoriten-Navigation, Drive-Routing
- `docs/handoffs/HANDOFF_LIVE_WIRING_3.md` — Live-Wiring Session 3: BrandsView-Navigationsbug, 169 Tests, Live-App-Tour
- `docs/handoffs/HANDOFF_LIVE_WIRING_4.md` — Live-Wiring Session 4 (geplant): Clockodo Zuhörer
- `docs/handoffs/HANDOFF_LIVE_WIRING_5.md` — Live-Wiring Session 5 (geplant): mykilO$$ Vollintegration

---

## Ereignisprotokoll + Kanonischer Pfad

Lückenloses Protokoll aller Entwicklungsschritte (wer, was, wann, welcher Branch, welche Fehler):
**[docs/EREIGNISPROTOKOLL.md](docs/EREIGNISPROTOKOLL.md)**

⚠️ Dieses Dokument MUSS bei jedem Handoff und jeder Session-Dokumentation aktualisiert werden.
- `docs/handoffs/HANDOFF_POST_AKT5_14_BUGFIXES.md` — Bugfixes #1/#2 + Streaming Phase 1e + UserProfile im Prompt + dynamische Beispielfragen + Chat-Löschen (163 Tests, Version 6.2.0)
- `docs/handoffs/HANDOFF_LIVE_WIRING_1.md` — Airtable Mastermind-Base live (Schema + 69 Records), ClickUp-Testspace, Angebote-Tab-Bugfix, DemoSeed → echte Projekte, hartkodierte Bugs + Force-Poll erledigt
- `docs/handoffs/HANDOFF_LIVE_WIRING_2.md` — Google-Login-Fix, Fenster-Drift-Guard, Projekt-Favoriten klickbar, Drive-Routing über alle Projekte, Assistent-Ausbauplan, Startprompt für Session 3
- `docs/handoffs/HANDOFF_LIVE_WIRING_3.md` — BrandsView-Navigationsbug, Live-Tour-Befunde, OAuth-Handshake, Startprompt für Session 4
- `docs/handoffs/HANDOFF_LIVE_WIRING_4.md` — Clockodo Zuhörer: Architektur, Airtable-Schema live, User-Scoping-Constraint, Startprompt für Implementierungs-Session
- `docs/registry/README.md` — 3-Kopien-Redundanzmodell (Airtable/lokaler Cache/Git-JSON) für die Projekt-/Kunden-Registry
- `docs/architecture/mykilOS6_Systemarchitektur.pdf` — Systemarchitektur (9 S., A4 quer): Integrations-Landkarte, Steckbriefe (Google/Clockodo/Airtable/ClickUp/Sevdesk/Claude), Signal-Nervensystem, GRDB-Persistenz, Funktionsbaum, Trigger-/Handle-Matrix; Quelle `.html` + `build_pdf.sh` daneben
- `docs/PARTNER_APP_SCHEMA.md` — Airtable-Gesamtschema mykilOS 6 (nach Vollintegrations-Entscheidung aktualisiert): alle Tabellen-IDs, Clockodo-Nutzer-Records, Stundensatz-Priorität
- `docs/KALKULATION_INTEGRATION.md` — mykilO$$ Vollintegrations-Plan: Modulstruktur, GRDB-Migration, UI-Slots, Tests, Drive-Integration, Merge-Reihenfolge
- `docs/MYKILOS_6_TEAM_MODELL.md` — Team, Airtable, Identität
- `docs/codex/WORKFLOW.md` — Session-Regeln für Codex-Sessions in diesem Repo
