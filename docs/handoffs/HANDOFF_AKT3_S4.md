# Handoff — Akt 3, Schritt 4: Kontakte-Widget live (read-only)

**Datum:** 2026-06-25 · **Basis:** Akt 3, Schritt 3 (Commit `58d5438`) · **Status:** Build + Tests grün, App startet.

## Warum diese Reihenfolge

Schritt 3 hat empfohlen, vor dem Mail-Widget (braucht erst eine UI-
Entscheidung — kein `WidgetKind`/keine Stelle im Board bisher) zuerst
Kontakte live zu machen: `ContactsWidget` hatte schon ein fertiges
Demo-Widget mit "GOOGLE"-Label, `contactsReadonly`-Scope war schon im Token
(Schritt 1). Im Unterschied zu Drive (`driveFolderID`) und Kalender
(`calendarQuery`) gab es aber noch kein Domain-Feld, das ein Projekt mit
"seinen" Kontakten verknüpft — die Google People API kann keine
projektbezogene Kontaktliste liefern, nur eine Freitext-Suche über die
echten Kontakte des verbundenen Accounts.

Entscheidung (mit Nutzer abgestimmt): `ProjectLinks` bekommt ein neues Feld
`contactsQuery: String?`, gleiches Muster wie `calendarQuery` — durchsucht
`people:searchContacts` nach Name/Firma/E-Mail.

## Was in diesem Commit liegt

### Domain-Modell
- **`Sources/MykilosKit/Domain/Project.swift`**: `ProjectLinks` hat jetzt
  `contactsQuery: String?` (Init-Parameter mit Default `nil`, analog zu
  `calendarQuery`).
- **`Sources/MykilosApp/Data/DemoSeed.swift`**: das Demo-Projekt `ME-24`
  ("Küche Meyer", das schon `calendarQuery: "Meyer"` trägt) bekommt
  zusätzlich `contactsQuery: "Meyer"` — echter Freitext-Suchbegriff, kein
  Mock, der gegen echte Google-Daten ins Leere/auf einen Fehler läuft.

### Kontakte live
- **`GoogleContactsClient.swift`** (neu) — gleiches Muster wie
  `GoogleDriveClient`/`GoogleCalendarClient`: `GoogleContact`
  (id/displayName/email?/phone?/organization?), `GoogleContactsError`
  (notConnected/invalidResponse/httpError/decodingFailed),
  `GoogleContactsFetching`-Protokoll. Nutzt `GoogleAccessTokenProviding`
  (aus Schritt 3, kein eigener Token-Code). Ruft
  `GET people:searchContacts?query=<q>&readMask=names,emailAddresses,phoneNumbers,organizations`.
  `buildSearchURL`/`parseContacts` als reine, testbare statische Funktionen
  — die People-API-Antwortform ist `results[].person` (verschachtelt),
  anders als Drive's flaches `files[]` und Calendar's flaches `items[]`.
- **`ContactsWidget.swift`** (überarbeitet) — `init(projectID:contactsQuery:)`.
  `ContactsLoader` (privat, `@MainActor @Observable`, gleiches Muster wie
  `DriveFolderLoader`/`CalendarEventLoader`). Demo-Kontakte (Familie
  Meyer/Sandra Adler/Holz Thiel mit Fantasie-Rollen "Bauherr"/"Architektin")
  ersetzt durch echte Treffer: Initialen aus `displayName`, Name,
  Firma/E-Mail als Untertitel — die People API liefert keine Rollen, das
  war ohnehin freie Erfindung der Demo-Daten und entfällt live. Renderstate:
  kein `contactsQuery` → `.empty`, `notConnected` → `.permissionRequired`
  (mit "Erneut versuchen"), sonstiger Fehler → `.error`, leeres Ergebnis →
  `.empty`, sonst `.content`.
- **Verdrahtung:** `ProjectDetailView.swift` reicht
  `project.links.contactsQuery` durch `ProjectWidgetBoardView` an
  `ContactsWidget`. `WidgetBoardView.swift` (toter Code, siehe
  Schritt-2-Handoff) bekommt `contactsQuery: nil` zur Kompilierbarkeit.

## Tests (4 neue, 37 insgesamt)
- **`GoogleContactsClientTests.swift`**: URL enthält korrekt kodierten
  `query`- und `readMask`-Parameter; `parseContacts` dekodiert die
  `results[].person`-Struktur korrekt, inkl. fehlender
  E-Mail/Telefon/Firma; kaputtes JSON → `decodingFailed`; kein Token →
  `notConnected` (über `GoogleAccessTokenProvider` +
  `InMemoryGoogleTokenStore`, gleiches Double wie bisher).

Gleiche Testgrenze wie immer: kein echtes Netzwerk/Keychain im
automatisierten Lauf.

## Build & Tests
- `swift build` — clean (nur die bekannten Pre-Akt-3-Warnungen in
  `NotesWidget` und `FocusWidget`).
- `swift test` — 37/37 grün.
- `./script/build_and_run.sh` — App startet ohne Crash.

## Manuell zu verifizieren / bekannte Grenzen
- Wie bei Drive/Kalender: `DemoSeed.swift` nutzt einen echten Freitext-
  Suchbegriff (`"Meyer"`), kein Mock — das Kontakte-Widget sollte daher
  eher `.empty` als `.error` zeigen, wenn der verbundene Account keine
  passenden Kontakte hat.
- Der echte Token-Refresh-Pfad ist weiterhin nur per Unit-Test mit
  Fake-Refresher abgedeckt (siehe Schritt-3-Handoff) — Kontakte nutzt
  denselben `GoogleAccessTokenProvider`, keine neue Lücke.
- People API "Desktop App"-Client-Anforderungen (`client_secret` bei PKCE?)
  noch nicht live getestet — gleicher offener Punkt wie seit Schritt 1.

## Nächster Schritt — Akt 3, Schritt 5
Drive, Kalender und Kontakte sind jetzt alle live, alle nach demselben
Muster (`GoogleXClient` mit `buildX`/`parseX`, `XLoader` im Widget). Nächste
sinnvolle Schritte aus der Roadmap (jeder eine eigene Session):
1. Mail-Widget — braucht zuerst eine UI-Entscheidung (neuer `WidgetKind
   .mail`, eigenes Widget, Platz im Board), dann Gmail live nach demselben
   Muster (`gmailReadonly`-Scope ist schon vorhanden).
2. Clockodo-Widget live (ZEITEN-Regel: nur Mapping/Status, nie Buchung).
3. Drag&Drop im Widget-Board (`WidgetBoardStore.move` existiert bereits).
4. Airtable-Sync implementieren.

Weiterhin offen, nicht Teil dieser Session: die tote
`Sources/MykilosWidgets/WidgetBoardView.swift` (per `spawn_task` geflaggt,
noch nicht entfernt), die untracked `skills/`-Verzeichnisse im Repo-Root.
