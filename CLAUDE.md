# mykilOS 6 — Claude Code Projektgedächtnis

**Smarte Projektplanung und Management mit intelligenten Automationen und Integrationen.**
Das Cockpit, das alles kann. macOS 14+, SwiftUI, local-first.

---

## Wo wir stehen

**Akt 3, Schritt 7 abgeschlossen.** Drag & Drop im Widget-Board.

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
| Akt 3, S8+ | 🔜 | Airtable-Sync |
| Akt 4 | 🔜 | Assistent live (Tool-Use, proaktiver ein-Satz-Dolmetscher) |
| Akt 5 | 🔜 | Politur, Dark Mode, DMG, Beta |

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
                       #   GoogleGmailClient (Akt 3, S6)
                       # Clockodo/ — ClockodoClient, ClockodoAuthService,
                       #   KeychainClockodoCredentialsStore (Akt 3, S5)
  MykilosWidgets/      # WidgetContainer, WidgetBoardView, SourceChip, SaveStateBar,
                       # Kinds/ (8 Widgets: drive, tasks, contacts, cash, calendar, notes, mail, assistant)
  MykilosApp/          # Shell (Sidebar), Gallery, Detail, Today, Data (AppState, AppDatabase,
                       # RegistryStore, DemoSeed)

Tests/
  MykilosKitTests/     # Cold-Start-Tests (FileBackedRepository)
  MykilosServicesTests/# WidgetBoardStoreTests (GRDB Cold-Start), GoogleOAuthTests,
                       # GoogleDriveClientTests, GoogleCalendarClientTests,
                       # GoogleContactsClientTests, GoogleGmailClientTests,
                       # ClockodoClientTests,
                       # ClockodoAuthServiceTests,
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

## Nächste Schritte (Akt 3, ab Schritt 8)

Jeder Schritt ist eine eigene Session/PR (siehe Prozess-Regel oben):

1. Airtable-Sync implementieren (`AirtableRegistry.sync(into:)`)

**Bekannte offene Punkte aus Schritt 1 (noch nicht relevant geworden):**
- Ob Google "Desktop App"-OAuth-Clients bei PKCE zusätzlich ein `client_secret`
  verlangen, ist nicht live getestet (V5 unterstützte es optional, V6 aktuell
  nicht) — falls Google beim ersten echten Verbinden `invalid_client` meldet,
  `clientSecret` Parameter in `GoogleOAuthPKCEService` nachziehen.

**Aus Schritt 2 (Drive-Widget):**
- `Sources/MykilosWidgets/WidgetBoardView.swift` (öffentlich, seit Akt 2
  unbenutzt) ist als separater Cleanup-Task geflaggt — falls noch nicht
  erledigt, vor dem nächsten großen Widget-Umbau aufräumen, sonst pflegt man
  zwei Kopien des Dispatch-Switches.

**Aus Schritt 3 (Token-Refresh + Kalender-Widget):**
- Token-Refresh (`GoogleAccessTokenProvider`) ist jetzt zentral verdrahtet und
  von Drive + Kalender genutzt — aber der echte Refresh-Pfad ist nur per
  Unit-Test mit Fake-Refresher abgedeckt, nie live beobachtet (ein Access-Token
  läuft typischerweise erst nach 1 Stunde ab). Beim nächsten Live-Client
  (Mail/Kontakte) im Hinterkopf behalten, falls der erste echte Ablauf
  überraschend anders reagiert als der Test.
- Schlägt ein Refresh fehl (z. B. Refresh-Token wurde widerrufen), landet das
  als generischer `.error("httpError(...)")` im Widget, nicht als
  `.permissionRequired` mit klarem "Bitte neu verbinden"-Hinweis — das ist für
  V1 bewusst einfach gehalten, könnte aber verwirrend sein, falls es in der
  Praxis öfter vorkommt als gedacht.

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
- `docs/MYKILOS_6_TEAM_MODELL.md` — Team, Airtable, Identität
- `docs/codex/WORKFLOW.md` — Session-Regeln für Codex-Sessions in diesem Repo
