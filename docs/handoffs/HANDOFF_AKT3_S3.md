# Handoff — Akt 3, Schritt 3: Token-Refresh + Kalender-Widget live

**Datum:** 2026-06-25 · **Basis:** Akt 3, Schritt 2 (Commit `7c59d72`) · **Status:** Build + Tests grün, echter Refresh-Pfad nicht live beobachtet.

## Warum diese Reihenfolge

Der Handoff von Schritt 2 hat ausdrücklich empfohlen, den fehlenden
Token-Refresh zu schließen, bevor ein weiterer Live-API-Aufrufer dazukommt —
sonst hätte der Kalender-Client dieselbe Lücke dupliziert. Diese Session
schließt die Lücke zentral, dann baut der Kalender-Client direkt darauf auf.

"Kalender + Mail" aus der ursprünglichen Roadmap-Zeile wurde aufgeteilt:
`CalendarWidget` hatte schon ein fertiges Demo-Widget mit "GOOGLE"-Label und
`Project.links.calendarQuery` als passendes Domain-Feld — 1:1 umstellbar.
Mail/Gmail hat noch keinen `WidgetKind`, kein Widget, keinen Platz im Board —
das braucht zuerst eine UI-Entscheidung und ist eine eigene, spätere Session.

## Was in diesem Commit liegt

### Token-Refresh (zentral, für alle Live-Clients)
- **`GoogleTokenRefreshService.swift`** (neu) — `GoogleTokenRefreshing`-Protokoll
  + Implementierung, tauscht ein Refresh-Token über
  `POST oauth2.googleapis.com/token` (`grant_type=refresh_token`) gegen ein
  neues Access-Token. Nutzt denselben `GoogleOAuthTokenExchangeResponse` wie
  der PKCE-Code-Exchange.
- **`GoogleAccessTokenProvider.swift`** (neu) — `GoogleAccessTokenProviding`-
  Protokoll + Implementierung: `validAccessToken()` gibt das Access-Token
  direkt zurück, wenn `GoogleTokens.isExpired == false`; sonst ruft sie den
  Refresh auf, persistiert das neue Token im Keychain-Store und gibt es
  zurück. Kein Token überhaupt → `GoogleOAuthError.notConnected`. Abgelaufen,
  aber kein Refresh-Token/keine Client-ID → `.refreshUnavailable`.
- **`GoogleOAuthModels.swift`**: zwei neue `GoogleOAuthError`-Fälle
  (`notConnected`, `refreshUnavailable`); die Form-Encoding-Funktion aus
  `GoogleOAuthPKCEService` wurde zu `urlEncodedFormBody` extrahiert, damit
  `GoogleTokenRefreshService` sie mitnutzt statt sie zu duplizieren.
- **`GoogleDriveClient.swift`**: nimmt jetzt `tokenProvider:
  GoogleAccessTokenProviding` statt `tokenStore: GoogleTokenStoring` —
  jeder Provider-Fehler wird zu `GoogleDriveError.notConnected` gemappt
  (Provider-Fehler sind immer Auth-Zustand, nie Drive-API-Zustand).

### Kalender live
- **`GoogleCalendarClient.swift`** (neu) — gleiches Muster wie
  `GoogleDriveClient`: `GoogleCalendarEvent`, `GoogleCalendarError`,
  `GoogleCalendarFetching`-Protokoll. Liest vom **primären** Kalender des
  verbundenen Accounts (`calendars/primary/events`), gefiltert über `q` =
  `Project.links.calendarQuery` — das Feld ist eine Freitext-Suche über den
  primären Kalender, keine eigene Kalender-ID je Projekt (z. B. `"Meyer"`
  findet alle Termine, die "Meyer" im Titel/Ort/etc. tragen). Zeitfenster:
  jetzt → +14 Tage. `buildListEventsURL`/`parseEvents` als reine, testbare
  statische Funktionen.
- **`CalendarWidget.swift`** (überarbeitet) — `init(projectID:calendarQuery:)`.
  `CalendarEventLoader` (privat, `@MainActor @Observable`, gleiches Muster
  wie `DriveFolderLoader`). Demo-Events ersetzt durch echte Termine
  (Titel, Zeit/All-Day, Ort). Renderstate: kein `calendarQuery` → `.empty`
  (Projekt noch nicht an den Kalender angebunden), `notConnected` →
  `.permissionRequired` (mit "Erneut versuchen"), sonstiger Fehler →
  `.error`, leeres Ergebnis → `.empty`, sonst `.content`.
- **Verdrahtung:** `ProjectDetailView.swift` reicht
  `project.links.calendarQuery` durch `ProjectWidgetBoardView` an
  `CalendarWidget`. `WidgetBoardView.swift` (toter Code, siehe Schritt-2-
  Handoff) bekommt `calendarQuery: nil` zur Kompilierbarkeit.

## Tests (9 neue, 33 insgesamt)
- **`GoogleAccessTokenProviderTests.swift`**: kein Token → `notConnected`;
  gültiges Token → direkt zurückgegeben, kein Refresh-Aufruf; abgelaufen ohne
  Refresh-Token → `refreshUnavailable`; abgelaufen mit Refresh-Token → ruft
  Fake-`GoogleTokenRefreshing` auf, persistiert das neue Token, behält das
  alte Refresh-Token, wenn die Antwort keins mitschickt.
- **`GoogleCalendarClientTests.swift`**: URL enthält `timeMin`/`timeMax`/`q`
  korrekt, kein `q` ohne `calendarQuery`; `parseEvents` dekodiert getimte UND
  All-Day-Events sowie Events ohne Titel korrekt; kaputtes JSON →
  `decodingFailed`; kein Token → `notConnected`.
- **`GoogleDriveClientTests.swift`**: Konstruktor-Aufruf auf
  `tokenProvider: GoogleAccessTokenProvider(tokenStore: store)` angepasst.

Gleiche Testgrenze wie immer: kein echtes Netzwerk/Keychain im automatisierten
Lauf.

## Build & Tests
- `swift build` — clean (nur die bekannte Pre-Akt-3-Warnung in `NotesWidget`).
- `swift test` — 33/33 grün.
- `./script/build_and_run.sh` — App startet ohne Crash.

## Manuell zu verifizieren / bekannte Grenzen
- Der echte Refresh-Pfad ist **nicht live beobachtet** — ein Access-Token
  läuft typischerweise erst nach 1 Stunde ab, das lässt sich in einer Session
  nicht erzwingen. Abgedeckt nur durch den Unit-Test mit Fake-Refresher.
  Falls der erste echte Token-Ablauf in der Praxis anders reagiert (z. B.
  Google verlangt für Refresh-Requests doch ein `client_secret`, ähnlich wie
  beim Code-Exchange — siehe offener Punkt aus Schritt 1), hier zuerst nachsehen.
- Schlägt ein Refresh fehl (z. B. widerrufenes Refresh-Token), zeigt das
  Widget einen generischen `.error("httpError(...)")`, nicht ein klares
  "bitte neu verbinden". Bewusst einfach gehalten für V1.
- `DemoSeed.swift` hat echte Freitext-Queries (`"Meyer"`, `"Loft"`) statt
  Mock-IDs wie beim Drive-Ordner — das Kalender-Widget sollte daher eher
  `.empty` als `.error` zeigen, wenn der verbundene Account keine
  passenden Termine hat (kein 404-Risiko wie bei einer fremden Ordner-ID).

## Nächster Schritt — Akt 3, Schritt 4
Vor dem Mail-Widget (braucht erst eine UI-Entscheidung) ist Kontakte live
der natürlichere nächste Schritt: `ContactsWidget` hat schon ein
"GOOGLE"-Label-Demo, `contactsReadonly`-Scope ist schon im Token, und das
Muster (`GoogleContactsClient` mit `buildX`/`parseX`) ist jetzt dreimal
etabliert (Drive, Calendar, würde Contacts).
