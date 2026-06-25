# Handoff — Akt 3, Schritt 8: Airtable-Sync live

**Status:** abgeschlossen — Akt 3 ist damit komplett.

---

## Was passiert ist

Airtable als System-of-Record für Kunden und Projekte. Der bisherige Stub (`throw State.implementedInAkt3`) ist durch eine echte Implementierung ersetzt.

### Neue Dateien

| Datei | Zweck |
|---|---|
| `Sources/MykilosServices/Airtable/AirtableClient.swift` | REST-Client für Airtable API v0. Paginiert (pageSize 100 + offset). `AirtableFetching`-Protokoll für Fakes. Enthält `mapCustomers` und `mapProjects` als statische, testbare Mapping-Funktionen. |
| `Sources/MykilosServices/Airtable/AirtableAuthService.swift` | `@Observable` Auth-Service: speichert PAT + Base-ID im Keychain. Status: disconnected/connected/syncing/error. |
| `Tests/MykilosServicesTests/AirtableClientTests.swift` | URL-Bau, Paging-Parsing, Customer-Mapping, Project-Mapping, Fehlerfall — kein Netzwerk. |
| `Tests/MykilosServicesTests/AirtableAuthServiceTests.swift` | Connect/Disconnect/Trim/Leere Felder/Syncing-Status — In-Memory-Store. |

### Geänderte Dateien

| Datei | Was |
|---|---|
| `Sources/MykilosServices/AirtableRegistry.swift` | Stub → echte Implementierung: holt Kunden + Projekte via `AirtableClient`, mappt sie, schreibt in `CachedProjectRegistry`. |
| `Sources/MykilosApp/Data/AppState.swift` | `airtableAuth: AirtableAuthService` hinzugefügt. |
| `Sources/MykilosApp/Data/RegistryStore.swift` | `syncFromAirtable(baseID:auth:)` — Sync-Trigger mit Status-Feedback. |
| `Sources/MykilosApp/Settings/SettingsView.swift` | Airtable-Sektion: Base-ID + PAT Felder, Verbinden/Sync/Trennen. |
| `Tests/MykilosServicesTests/RegistryTests.swift` | Alter Stub-Test → echter Sync-Test mit `FakeAirtableFetcher`. |

---

## Architektur-Entscheidungen

1. **PAT im Keychain** — Personal Access Token wird wie alle Secrets über den bestehenden `KeychainStore` gespeichert, nie in Code oder Dateien.

2. **Airtable-Feldnamen auf Deutsch** — Die Mapping-Funktionen erwarten Airtable-Felder wie `Kundennummer`, `Projektnummer`, `Titel`, `Art`, `Drive-Ordner-ID`, `Kalender-Suche` etc. Das passt zum bestehenden Airtable-Setup. Konfigurierbare Feldnamen sind für V1 nicht nötig.

3. **Tabellennamen konfigurierbar** — `AirtableRegistry` nimmt `customersTable` und `projectsTable` als Parameter (Default: "Kunden" / "Projekte").

4. **Paginierung** — Airtable liefert max. 100 Records pro Request. Der Client paginiert automatisch über den `offset`-Parameter.

5. **`AirtableFieldValue` als flexibler Decoder** — Airtable-Felder können String, Array (Linked Records), Number oder null sein. Der Enum decodiert alle Varianten sicher.

6. **Sync schreibt blind** — `replaceCustomers`/`replaceProjects` ersetzt den gesamten lokalen Cache bei jedem Sync. Kein Diff, kein Merge — Airtable ist die einzige Wahrheit.

---

## Tests

73 Tests grün, davon 16 neue:

- `AirtableClientTests` (8): URL-Bau, Paging-Parsing, Customer/Project-Mapping, Fehlerfall
- `AirtableAuthServiceTests` (7): Init-Status, Connect, Disconnect, Trim, Syncing/Synced
- `RegistryTests.airtableSyncSchreibtInCache` (1): End-to-End mit FakeAirtableFetcher

Kein echtes Netzwerk, kein echtes Keychain im Testlauf.

---

## Airtable-Feldmapping

| Airtable-Feld | Domain-Property |
|---|---|
| `Kundennummer` | `Customer.customerNumber` |
| `Name` | `Customer.name` |
| `Projektnummer` | `Project.projectNumber` |
| `Titel` | `Project.title` |
| `Art` | `Project.kind` (rawValue) |
| `Kundennummer` oder `Kunde` (linked) | `Project.customerNumber` |
| `Eltern-Projekt` | `Project.parentProjectNumber` |
| `Phase` | `Project.phase` |
| `Drive-Ordner-ID` | `ProjectLinks.driveFolderID` |
| `Drive-Pfad` | `ProjectLinks.driveFolderPath` |
| `ClickUp-Liste` | `ProjectLinks.clickUpListID` |
| `Kalender-Suche` | `ProjectLinks.calendarQuery` |
| `Kontakte-Suche` | `ProjectLinks.contactsQuery` |
| `Mail-Suche` | `ProjectLinks.mailQuery` |
| `sevdesk-Ref` | `ProjectLinks.sevdeskRef` |

---

## Offene Punkte

- **Erster Live-Test steht aus** — Feldnamen müssen exakt zum Airtable-Setup passen. Falls Namen abweichen, Mapping in `mapCustomers`/`mapProjects` anpassen.
- **Kein Delta-Sync** — Jeder Sync ersetzt den gesamten Cache. Bei großen Bases ineffizient, aber für die aktuelle Projektgröße ausreichend.
- **Kein Auto-Sync** — Sync muss manuell über Settings → "Jetzt synchronisieren" ausgelöst werden. Automatischer Sync bei App-Start oder periodisch wäre ein Akt-4-Feature.
