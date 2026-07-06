# Handoff — Post-Akt 5, Aufgabe 6: Systemarchitektur-PDF, Cleanup & Refresh-Härtung

**Status:** abgeschlossen

---

## Was gebaut wurde

Diese Session hatte drei Stränge: ein vollständiges, aus dem Quellcode
verifiziertes Architektur-Dokument (PDF), einen fokussierten Code-Cleanup und
eine testgesicherte UX-Härtung des Google-Token-Refresh-Pfads. Kein neues
Feature, keine neue Integration — Konsolidierung und Dokumentation des
Beta-Stands.

## 1. Systemarchitektur-Dokument

Ein 9-seitiges A4-quer-PDF in der mykilOS-Palette, das alle externen
Integrationen, deren Protokolle/Auth/Trigger/Handles, das interne
Signal-Nervensystem, die Persistenz und den Funktionsbaum darstellt.

| Datei | Was |
|---|---|
| `docs/architecture/mykilOS Mac_Systemarchitektur.pdf` | Das fertige Dokument (9 S.) |
| `docs/architecture/mykilOS Mac_Systemarchitektur.html` | Versionierte Quelle (HTML/CSS/SVG) |
| `docs/architecture/build_pdf.sh` | Repo-relatives Render-Skript (Chrome headless) |

Inhalt: Integrations-Landkarte (Google/Clockodo/Airtable/Claude live;
ClickUp/Sevdesk/Drive-Webhook geplant), Steckbriefe je Integration (Endpunkte,
Methoden, Auth-Header, Scopes, Keychain-Service, Trigger, Tags), das
Airtable→`ProjectLinks`-Feld-Mapping, das Signal→Mediator→Assistant→Audit-
Nervensystem, das GRDB-Schema und die Trigger-/Handshake-Matrix.

**Reproduzierbar:** `./docs/architecture/build_pdf.sh` rendert das PDF aus der
HTML-Quelle neu (benötigt Google Chrome).

## 2. Code-Cleanup

| Datei | Änderung |
|---|---|
| `Sources/MykilosWidgets/Kinds/CashWidget.swift` | Budgetleiste war Ocker (`MykColor.tasks`) statt Tiefblau (`MykColor.cash`) — „Farbe ist Sprache" wiederhergestellt |
| `Sources/MykilosWidgets/WidgetBoardView.swift` | **Gelöscht** — öffentliches, ungenutztes Duplikat des Dispatch-Switches (gerendert wird über `ProjectWidgetBoardView` bzw. Heute-Board) |
| `Sources/MykilosApp/Today/FocusWidget.swift` | Ungenutztes `pid` in `.deadlineNear(let pid, …)` → `_` (Compiler-Warnung entfernt) |
| `Sources/MykilosApp/Detail/ProjectDetailView.swift` | User-sichtbarer Text „— kommt in Akt 3" → „— in Vorbereitung" (Akt 3–5 sind fertig) |
| `Sources/MykilosKit/Domain/AuditEntry.swift` | Veralteter Kommentar „Tabelle kommt mit GRDB in Akt 2" → realer Live-Stand |

## 3. Refresh-Pfad: Härtung & Tests

Verifiziert, dass ein fehlgeschlagener Google-Token-Refresh (z. B. widerrufenes
Refresh-Token) bereits korrekt behandelt wird: alle vier Clients
(Drive/Calendar/Contacts/Gmail) mappen jeden Provider-Fehler via
`try? await tokenProvider.validAccessToken()` auf ihren `.notConnected`-Zustand,
und alle vier Widgets übersetzen das auf `.permissionRequired`. Die alte
CLAUDE.md-Notiz („landet als generischer `.error`") war veraltet und wurde
korrigiert.

**UX-Verbesserung** (`Sources/MykilosWidgets/WidgetContainer.swift`): Der
`.permissionRequired`-Zustand zeigt jetzt zusätzlich „In den Einstellungen
verbinden" statt nur „Berechtigung nötig" — greift konsistent für alle vier
Google-Widgets.

**Neue Tests** (97 statt 92):

| Test | Beweist |
|---|---|
| `GoogleAccessTokenProviderTests.reichtRefreshFehlerBeiWiderrufenemTokenWeiter` | Refresh wirft `httpError(400)` → Provider reicht weiter, altes Token bleibt unangetastet |
| `GoogleDriveClientTests.listFolderMapptRefreshFehlerAufNotConnected` | Provider-Fehler → `.notConnected` |
| `GoogleCalendarClientTests.listUpcomingEventsMapptRefreshFehlerAufNotConnected` | dito |
| `GoogleContactsClientTests.searchContactsMapptRefreshFehlerAufNotConnected` | dito |
| `GoogleGmailClientTests.searchMessagesMapptRefreshFehlerAufNotConnected` | dito |

Neuer Test-Stub `ThrowingTokenProvider` (in `GoogleOAuthTests.swift` bei den
übrigen Test-Doubles) — kein echtes Keychain/Netzwerk im Testlauf.

## Sicherheitsgrenzen

- Das Architektur-Dokument enthält **nur** Keychain-Service- und Feldnamen
  (`com.mykilos6.*`, `tokens`, `apiKey`, …) — keine echten Secret-Werte.
- Externe IDs bleiben als Referenz-Handles dargestellt, nie als Primärschlüssel.
- Tests nutzen kein echtes Keychain und kein echtes Netzwerk.

## Verifikation

- `swift build` — warnungsfrei (die vorherige `pid`-Warnung ist weg).
- `swift test` — **97 Tests in 16 Suites grün**, inkl. der neuen
  Refresh-Fehler-Tests und aller bestehenden Cold-Start-Tests.
- `./docs/architecture/build_pdf.sh` — regeneriert das 9-seitige PDF.

## Offen / nicht hier testbar

- Ob Googles „Desktop App"-OAuth-Clients bei PKCE zusätzlich ein
  `client_secret` verlangen — zeigt sich erst beim ersten echten Live-Verbinden
  (`invalid_client`). Unverändert seit Akt 3, S1.
- Feine Unterscheidung „nie verbunden" vs. „Sitzung abgelaufen" bleibt bewusst
  ein gemeinsamer `.permissionRequired`-Zustand (ein eigener `.authExpired`
  wäre für V1 Over-Engineering).
