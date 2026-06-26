# Handoff — Post-Akt 5, Aufgabe 8: Sevdesk-Integration live (Cash-Widget)

**Status:** abgeschlossen

---

## Was gebaut wurde

Das **Cash-Widget** (WidgetKind `.cash`, Tiefblau) zeigte bisher eine fest
verdrahtete Demo-Budgetleiste (72 %). Es liest jetzt **live** aus Sevdesk: den
**Ist-Umsatz** (Summe der `sumGross` aller Rechnungen für den im Projekt
verlinkten sevdesk-Kontakt `sevdeskRef`) und stellt ihn als Balken dem
**Soll-Budget** gegenüber. Das Budget kommt — gemäß Produktentscheidung
„Budget-Balken behalten" — aus **Airtable** über das neue Feld
`ProjectLinks.budget`.

Damit sind **beide ursprünglichen Stub-Widgets live** (Tasks/ClickUp = Aufgabe 7,
Cash/Sevdesk = Aufgabe 8). Gebaut nach exakt demselben Muster wie ClickUp:
`ClickUpClient`/`AirtableClient` als Service-Vorlage, `DriveWidget` als
per-Projekt-Live-Widget-Vorlage.

Der **Drive→Cash-Signal-Whisper** (StudioContext, `reviewSuggested`) bleibt
bewusst **unabhängig** von der sevdesk-Verbindung erhalten: Das Cash-Widget ist
„DAS Widget, das die Signal-Kommunikation zeigt", also darf der Showcase nicht an
einem externen Token hängen. Der Budget-Balken rendert seine Sub-States
(loading/empty/permissionRequired/error) **inline** im Content, statt den ganzen
Container umzuschalten.

## Neue / geänderte Dateien

| Datei | Was |
|---|---|
| `Sources/MykilosServices/Sevdesk/SevdeskClient.swift` | **Neu.** `SevdeskInvoice`-Modell, `SevdeskError`, `SevdeskFetching`-Protokoll, `SevdeskClient`. Statische, testbare Bausteine `buildInvoicesURL`, `parseInvoices`, `double(from:)`. |
| `Sources/MykilosServices/Sevdesk/SevdeskAuthService.swift` | **Neu.** `@MainActor @Observable`, synchrones Speichern (kein `.connecting`), `connect(apiToken:)`/`disconnect()`/`storedCredentials()`. |
| `Sources/MykilosServices/Sevdesk/KeychainSevdeskCredentialsStore.swift` | **Neu.** `SevdeskCredentials` (ein Feld `apiToken`), Protokoll + Keychain-Impl über generischen `KeychainStore`, Service `com.mykilos6.sevdesk`. |
| `Sources/MykilosKit/Domain/SevdeskConnectionStatus.swift` | **Neu.** `disconnected/connected/error` — analog `ClickUpConnectionStatus`. |
| `Sources/MykilosKit/Domain/Project.swift` | `ProjectLinks.budget: Double?` ergänzt (Soll-Budget, Bezugswert für den Cash-Ist-Vergleich) inkl. Init-Parameter. |
| `Sources/MykilosServices/Airtable/AirtableClient.swift` | `AirtableFieldValue.numberValue`-Accessor neu; `mapProjects` mappt Spalte „Budget" → `budget`. |
| `Sources/MykilosWidgets/Kinds/CashWidget.swift` | **Umgeschrieben.** Konsumiert `SevdeskFetching` über privaten `@Observable`-Loader (`SevdeskInvoicesLoader`). Nimmt `sevdeskRef` + `budget` als Handles, `.task(id:)`, Retry. Signal-Whisper unverändert erhalten. |
| `Sources/MykilosApp/Detail/ProjectDetailView.swift` | `sevdeskRef` + `budget` (aus `project.links`) durch `ProjectWidgetBoardView` an `CashWidget` durchgereicht. |
| `Sources/MykilosApp/Data/AppState.swift` | `sevdeskAuth: SevdeskAuthService` ergänzt. |
| `Sources/MykilosApp/Data/DemoSeed.swift` | `sevdeskRef` + `budget` an zwei Demo-Projekten (ME-24, LO-23) ergänzt. |
| `Sources/MykilosApp/Settings/SettingsView.swift` | 6. Sektion „Sevdesk Umsatz" (SecureField Token, Status-Badge, Verbinden/Trennen, Laden im `.task`). |
| `Tests/MykilosServicesTests/SevdeskClientTests.swift` | **Neu.** URL-Builder, Parser, `double`-Helfer, leere Liste, kaputtes JSON, `notConnected`. + `InMemorySevdeskCredentialsStore`. |
| `docs/architecture/mykilOS6_Systemarchitektur.html/.pdf` | Sevdesk von „GEPLANT/STUB" auf **LIVE** umgestellt (Landkarte, SVG-Pfeil/Box, Karten S.1, Steckbrief, Feld-Mapping inkl. `budget`, Widget-Katalog, Keychain-Notiz). PDF neu gerendert (9 S.). |

## Auth & Protokoll

- **Endpunkt:** `GET https://my.sevdesk.de/api/v1/Invoice`
  mit `contact[id]={sevdeskRef}`, `contact[objectName]=Contact`, `limit=100`.
- **Auth:** API-Token direkt im `Authorization`-Header (kein „Bearer"),
  `Accept: application/json`.
- **Parsing:** `objects[].id`, `invoiceNumber`, `sumGross` (String → `Double`
  über `double(from:)`), `status`. Ist-Umsatz = Summe aller `sumGross`.
- **Budget:** Soll-Wert aus Airtable-Spalte „Budget" → `ProjectLinks.budget`.
  Balken = Ist/Budget; über Budget → kritische Farbe + Prozent in Rot.

## Regeln eingehalten

- **Secrets nur Keychain:** Token ausschließlich in `com.mykilos6.sevdesk`,
  nie in Code/Logs/Repo. `sevdeskRef` bleibt Referenz-Handle, kein
  Primärschlüssel; `budget` ist eine nicht-sensible Projektzahl.
- **Widgets:** read-only Lesefetch, kein Schreiben aus dem Widget; alle
  Renderstates vorhanden (kein Handle → `.empty`, `notConnected` →
  `.permissionRequired`, sonst `.error`, hier inline gerendert). Quellzeile
  sichtbar. Signal-Kommunikation weiter ausschließlich über `StudioContext`.
- **Architektur:** `MykilosWidgets` importiert `MykilosServices` (kein GRDB);
  reiner Read-Client, keine Schreibvorgänge.

## Verifikation

- `swift build` — warnungsfrei.
- `swift test` — **109 Tests in 18 Suites grün** (103 + 6 neue Sevdesk-Tests).
- Token-Disziplin manuell geprüft (kein `.font(.system`/`Color(red:`/`Color(hex:`
  in den neuen/geänderten View-Dateien; SwiftLint nicht im PATH dieser Umgebung).
- `./docs/architecture/build_pdf.sh` — PDF neu, weiterhin 9 Seiten.

## Offen / nicht hier testbar

- Echter sevdesk-Abruf mit realem Token + realem Kontakt ist ein **manueller
  Beta-Check** (Tests nutzen kein echtes Keychain/Netzwerk) — gleiches Muster
  wie bei ClickUp/Clockodo/Airtable/Google.
- Der genaue Live-Filter ist noch nicht verifiziert: ob `contact[objectName]=
  Contact` + `limit=100` live exakt die gewünschte Rechnungsmenge (z. B. nur
  abgerechnete Rechnungen, Statusfilter) liefert, ist offen — bei Bedarf in
  `buildInvoicesURL` nachziehen (z. B. `status`/`embed`-Query).
- Write-back (Angebot/Rechnung aus mykilOS erzeugen) ist bewusst **nicht**
  gebaut; der Audit-Lifecycle `offerImported/draftCreated/draftSent` ist dafür
  bereits vorgesehen, liefe über Action-Card → Bestätigung → Audit.

## Nächster Schritt nach Plan

Letzter geplanter Anschluss: **Drive-Webhook** als Live-Quelle für das Signal
`offerDetected` (heute nur per Demo-Button). Im lokalen Desktop-Kontext
vermutlich als Polling von `changes.list`. Danach ist die Integrations-Landkarte
vollständig.
