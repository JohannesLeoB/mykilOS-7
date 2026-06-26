# Handoff — Post-Akt 5, Aufgabe 7: ClickUp-Integration live (Tasks-Widget)

**Status:** abgeschlossen

---

## Was gebaut wurde

Das **Tasks-Widget** (WidgetKind `.tasks`, Ocker) las bisher 4 fest verdrahtete
Demo-Aufgaben (immer `.content`). Es liest jetzt **live** die offenen Aufgaben
der im Projekt verlinkten ClickUp-Liste — read-only, mit allen Renderstates.
Damit ist von den ursprünglich zwei Stub-Widgets nur noch **Cash (Sevdesk)**
Demo.

Gebaut nach exakt demselben Muster wie die bestehenden Integrationen:
`ClockodoClient`/`AirtableClient` als Service-Vorlage, `DriveWidget` als
per-Projekt-Live-Widget-Vorlage.

## Neue / geänderte Dateien

| Datei | Was |
|---|---|
| `Sources/MykilosServices/ClickUp/ClickUpClient.swift` | **Neu.** `ClickUpTask`-Modell, `ClickUpError`, `ClickUpFetching`-Protokoll, `ClickUpClient`. Statische, testbare Bausteine `buildTasksURL`, `parseTasks`, `date(fromEpochMillis:)`. |
| `Sources/MykilosServices/ClickUp/ClickUpAuthService.swift` | **Neu.** `@MainActor @Observable`, synchrones Speichern (kein `.connecting`), `connect(apiToken:)`/`disconnect()`/`storedCredentials()`. |
| `Sources/MykilosServices/ClickUp/KeychainClickUpCredentialsStore.swift` | **Neu.** `ClickUpCredentials` (ein Feld `apiToken`), Protokoll + Keychain-Impl über generischen `KeychainStore`, Service `com.mykilos6.clickup`. |
| `Sources/MykilosKit/Domain/ClickUpConnectionStatus.swift` | **Neu.** `disconnected/connected/error` — analog `ClockodoConnectionStatus`. |
| `Sources/MykilosWidgets/Kinds/TasksWidget.swift` | **Umgeschrieben.** Konsumiert `ClickUpFetching` über einen privaten `@Observable`-Loader (wie `DriveFolderLoader`). Nimmt `clickUpListID` als Handle, `.task(id:)`, Retry-Button. |
| `Sources/MykilosApp/Detail/ProjectDetailView.swift` | `clickUpListID` (aus `project.links`) durch `ProjectWidgetBoardView` an `TasksWidget` durchgereicht. |
| `Sources/MykilosApp/Data/AppState.swift` | `clickUpAuth: ClickUpAuthService` ergänzt. |
| `Sources/MykilosApp/Settings/SettingsView.swift` | 5. Sektion „ClickUp Aufgaben" (SecureField Token, Status-Badge, Verbinden/Trennen, Laden im `.task`). |
| `Tests/MykilosServicesTests/ClickUpClientTests.swift` | **Neu.** URL-Builder, Parser (Fälligkeit/Assignee/Urgent), leere Liste, kaputtes JSON, `notConnected`. + `InMemoryClickUpCredentialsStore`. |
| `docs/architecture/mykilOS6_Systemarchitektur.html/.pdf` | ClickUp von „GEPLANT/STUB" auf **LIVE** umgestellt (Landkarte, Legende, Steckbrief, Feld-Mapping, Funktionsbaum, Keychain-Notiz). PDF neu gerendert (9 S.). |

## Auth & Protokoll

- **Endpunkt:** `GET https://api.clickup.com/api/v2/list/{listID}/task`
  mit `archived=false`, `include_closed=false`, `subtasks=false` (nur offene
  Top-Level-Aufgaben).
- **Auth:** Personal-API-Token direkt im `Authorization`-Header (kein „Bearer").
- **Parsing:** `name`, `status.status`, `due_date` (Epoch-ms-String → `Date`),
  erster `assignees[].username`, `priority.priority == "urgent"` → `isUrgent`
  (rot markierte Checkbox).

## Regeln eingehalten

- **Secrets nur Keychain:** Token ausschließlich in `com.mykilos6.clickup`,
  nie in Code/Logs/Repo. `clickUpListID` bleibt Referenz-Handle, kein
  Primärschlüssel.
- **Widgets:** read-only Lesefetch, kein Schreiben aus dem Widget; alle
  Renderstates vorhanden (leerer Handle → `.empty`, `notConnected` →
  `.permissionRequired`, sonst `.error`). Quellzeile sichtbar.
- **Architektur:** `MykilosWidgets` importiert `MykilosServices` (kein GRDB);
  Schreibvorgänge gibt es hier keine — reiner Read-Client.

## Verifikation

- `swift build` — warnungsfrei.
- `swift test` — **103 Tests in 17 Suites grün** (97 + 6 neue ClickUp-Tests).
- Token-Disziplin manuell geprüft (kein `.font(.system`/`Color(red:`/`Color(hex:`
  in den neuen Dateien; SwiftLint nicht im PATH dieser Umgebung).
- `./docs/architecture/build_pdf.sh` — PDF neu, weiterhin 9 Seiten.

## Offen / nicht hier testbar

- Echter ClickUp-Abruf mit realem Token + realer Liste ist ein **manueller
  Beta-Check** (Tests nutzen kein echtes Keychain/Netzwerk) — gleiches Muster
  wie bei Clockodo/Airtable/Google.
- Write-back (Aufgabe abhaken aus mykilOS) ist bewusst **nicht** gebaut; falls
  je gewünscht, liefe er über Action-Card → Bestätigung → Audit.

## Nächster Schritt nach Plan

Sevdesk-Integration für das Cash-Widget nach exakt demselben Muster
(`SevdeskClient` + `SevdeskAuthService` + Keychain `com.mykilos6.sevdesk` +
Settings-Sektion + Tests, Handle `sevdeskRef`).
