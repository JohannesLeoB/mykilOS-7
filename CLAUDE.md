# mykilOS 6 — Claude Code Projektgedächtnis

**Smarte Projektplanung und Management mit intelligenten Automationen und Integrationen.**
Das Cockpit, das alles kann. macOS 14+, SwiftUI, local-first.

---

## Wo wir stehen

**🟢 Release 6.1.0 — Konversationeller Assistent (Branch `feat/conversational-assistant`).**
Der Assistent ist jetzt ein echter Chat: Multi-Turn über Claude (Phase 1, **live
verifiziert** — erdet sich an echten Projekten, bleibt ehrlich), read-only Tool-Use mit
agentischer Schleife + Datenschutz-Opt-in (Phase 2, gebaut + unit-getestet, **noch nicht
live**, weil App-Google-OAuth unverbunden), Gmail-„wo abgelegt?" via Labels. **Sevdesk
strukturell aus der Tool-Whitelist + Negativtest.** 155 Tests grün, Version 6.1.0 markiert,
gepusht. Ehrlicher Stand + Vision + Startprompt in
[HANDOFF_POST_AKT5_13_ASSISTANT_RELEASE.md](docs/handoffs/HANDOFF_POST_AKT5_13_ASSISTANT_RELEASE.md).
Offen: Onboarding/Profil, Google live verifizieren, ToolCallRow, Streaming, Phase 3.

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

**Was nach Plan noch offen ist:** kein verdrahteter Integrations-Anschluss mehr.
Mit Aufgabe 10 ist die erste App-Feature-Seite (Projekt-Tab **Angebote**) live.
Verbleibende GEPLANT-Punkte sind weitere reine Oberflächen ohne neue Datenquelle:
Projekt-Tabs Dateien/Timeline/Material und die Sidebar-Module Marken & Daten /
Angebote.

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
- `docs/architecture/mykilOS6_Systemarchitektur.pdf` — Systemarchitektur (9 S., A4 quer): Integrations-Landkarte, Steckbriefe (Google/Clockodo/Airtable/ClickUp/Sevdesk/Claude), Signal-Nervensystem, GRDB-Persistenz, Funktionsbaum, Trigger-/Handle-Matrix; Quelle `.html` + `build_pdf.sh` daneben
- `docs/MYKILOS_6_TEAM_MODELL.md` — Team, Airtable, Identität
- `docs/codex/WORKFLOW.md` — Session-Regeln für Codex-Sessions in diesem Repo
