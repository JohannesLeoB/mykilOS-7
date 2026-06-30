# HANDOFF — mykilOS 8 Block A: Fundament (Eine Wahrheit + Sicherheits-Sockel)

```
Pfad:   /Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilOS6/
Branch: feat/mykilos8-block-a-fundament (von docs/mykilos8-handoff abgezweigt)
Build:  ✅ swift build grün
Tests:  ✅ 652 Tests grün (0 fehlgeschlagen)
Datum:  2026-06-30
```

## 0. Auftrag

Block A aus [HANDOFF_MYKILOS8_ROLLING_PLAN.md](HANDOFF_MYKILOS8_ROLLING_PLAN.md) §2: S0-Audit ·
SoR-Karte Mastermind↔Artikel auflösen · `ExternalMappingRegistry` als Grundgerüst ·
`WriteShadowRecorder` + `mykilOS-Backup` · TEST-Sandbox + Schalter + `TestSandboxCleaner` ·
Rechte-Matrix scharf. Nach dem S0-Verständnis-Report hat Johannes mit „nach deinen besten
Empfehlungen" alle drei offenen Fragen an mich delegiert — die Entscheidungen + Begründungen
stehen unten.

## 1. S0-Audit — was code-verifiziert wurde (nicht nur behauptet)

Der Split-Brain aus `AIRTABLE_DATENFLUSS_AUDIT.md` §3 wurde bis ins konkrete Symptom verfolgt:
`AppState.erzeugeKundeUndProjekt` schreibt Kunde+Projekt in die Artikel-Base
(`appdxTeT6bhSBmwx5`), ruft danach aber `registry.syncFromAirtable(baseID:
AirtableClient.writableBaseID, …)` — das ist **Mastermind**. `CachedProjectRegistry.
replaceProjects` überschreibt den Cache komplett (kein Merge, kein Source-Tag), und
`AirtableClient.mapProjects` verlangt zwingend `Projektnummer`+`Titel` (Mastermind-Schema). Ein
frisch angelegtes Intake-Projekt war dadurch in der App **unsichtbar**, bis irgendwann ein
Mastermind-Routing-Eintrag dafür entsteht — was heute nirgends automatisch passiert.

## 2. Die drei offenen Fragen — Entscheidung + Begründung

1. **`Projektnummer`-Feld in Artikel-`Projekte`:** NICHT fuzzy über `Projektname` gejoint (zu
   gefährlich bei Geld-/Statusdaten — ein Fehljoin ist schlimmer als kein Treffer). Stattdessen:
   `ExternalMappingRegistry` joint ausschließlich über die Projektnummer und macht den fehlenden
   Join ehrlich sichtbar (`businessOnlyUnbound`, `unboundBusinessProjects()`), statt zu raten.
   **Von Johannes bestätigt (2026-06-30):** die bestehende Artikel-Projektliste wird von mykilOS/
   Claude NIE editiert (weder Schema noch Bestandsdaten) — das Feld kommt ausschließlich, wenn
   Daniel es in seiner Backend-Hoheit anlegt, ohne Drängen unsererseits. Siehe `IDEEN_UND_BACKLOG.md`.
2. **`mykilOS-Backup`-Base:** versucht, live über den verfügbaren Airtable-MCP anzulegen.
   `list_workspaces` liefert für diese Session eine leere Liste, `search_bases` sieht nur
   Mastermind — `create_base` braucht aber eine `workspaceId`, die nicht ermittelbar war. Statt zu
   raten oder eine falsche Base zu erzeugen: `WriteShadowRecorder` ist komplett fertig und läuft
   lokal (GRDB, Cold-Start-getestet) — der Airtable-Spiegel ist verdrahtet und aktiviert sich,
   sobald `backupBaseID` gesetzt wird. Bis dahin ist die Lücke sichtbar (`WRITE_SHADOW_BACKUP_
   FEHLT`), nicht versteckt.
3. **Block-Scope:** volles Block A in dieser Session (statt nur SoR-Auflösung + Registry).

## 3. Was gebaut wurde

| Komponente | Datei | Status |
|---|---|---|
| `ExternalMappingRegistry` (Resolver) | `Sources/MykilosServices/ExternalMappingRegistry.swift` | ✅ live, in `AppState` verdrahtet |
| `BusinessCustomer`/`BusinessProject`/`ResolvedProject` | `Sources/MykilosKit/Domain/BusinessRecord.swift` | ✅ |
| `CachedBusinessRegistry` (eigener Dateicache) | `Sources/MykilosServices/CachedBusinessRegistry.swift` | ✅ |
| `mapBusinessCustomers`/`mapBusinessProjects` | `Sources/MykilosServices/Airtable/AirtableClient.swift` | ✅ Feldnamen aus echtem Schreibpfad verifiziert |
| `WriteShadowRecorder` + GRDB `writeShadowLog` | `Sources/MykilosServices/WriteShadowRecorder.swift` | ✅ lokal fertig, Airtable-Spiegel wartet auf Backup-Base |
| `ProvisioningMode` + `ProvisioningModeStore` | `Sources/MykilosServices/ProvisioningMode.swift` | ✅ `.test` Default, `.prod` hart gesperrt |
| `TestMarker` (Doppel-Strategie) | `Sources/MykilosServices/ProvisioningMode.swift` | ✅ |
| `AirtableClient.deleteRecord` + `testDeletableMap` | `Sources/MykilosServices/Airtable/AirtableClient.swift` | ✅ Whitelist bewusst leer |
| `TestSandboxCleaner` | `Sources/MykilosServices/TestSandboxCleaner.swift` | ✅ Whitelist + Doppel-Marker + Re-Fetch |
| Verdrahtung in `erzeugeKundeUndProjekt` | `Sources/MykilosApp/Data/AppState.swift` | ✅ Write-Shadow bei jedem Create (Erfolg + Fehlschlag), Business-Registry-Refresh |

Neue Tests: `ExternalMappingRegistryTests` (4), `WriteShadowRecorderTests` (3),
`ProvisioningModeStoreTests` (2), `TestMarkerTests` (1), `TestSandboxCleanerTests` (6) — alle
neu, plus volle Bestandssuite. GRDB-Migrationen `v12_write_shadow_log` + `v13_app_settings`
(additiv, keine bestehende Tabelle geändert).

## 4. ZIEL-CHECK (Rolling-Plan §3)

1. **Vollständigkeit:** Resolver, WriteShadow, TEST-Schalter, Cleaner — alle live im Bundle
   gebaut, nicht nur kompiliert (siehe §3 oben + ZIEL-CHECK-Bericht in der Session).
2. **Quer-Wirkung:** Einzige UI-Berührung ist `erzeugeKundeUndProjekt` (Try/catch-Pfade um je
   einen `try?`-Shadow-Call erweitert, neue Felder/Stores additiv in `AppState`) — keine
   bestehende View/Layout verändert. Volle Bestandssuite bleibt grün (Beweis: keine andere
   Funktion gebrochen).
3. **Eine-Wahrheit:** `ExternalMappingRegistryTests.businessSyncSchreibtNurInBusinessCacheNiemals
   InRouting` beweist den getrennten Cache explizit; Budget-Doppel-Wahrheit (Mastermind vs.
   Artikel) bewusst NICHT gefixt, sondern in `IDEEN_UND_BACKLOG.md` als offener Punkt dokumentiert
   (Scope-Grenze: CashWidget-Umbau ist nicht Block-A-Auftrag).
4. **Sicherheit:** `TestSandboxCleanerTests` beweist Whitelist-Block + Re-Fetch-Schutz +
   Idempotenz + Produktiv-Fixture-Unberührtheit. `WriteShadowRecorderTests` beweist Cold-Start +
   sichtbare Warnung bei fehlender Backup-Base + dass der Primär-Write nie blockiert wird.
5. **Tests:** 652 grün, davon 16 neu für Block A.
6. **Abschluss:** siehe §5 (DMG) unten.

## 5. Offene Punkte für Johannes / nächste Sessions

- **`mykilOS-Backup`-Base live anlegen** (Workspace, gewünschtes Schema siehe
  `HANDOFF_TEST_SANDBOX.md` §7) → danach nur `backupBaseID` in `AppState.init` setzen.
- **Artikel-`Projekte`: Feld `Projektnummer` ergänzen** (oder Block C übernimmt das beim Anlegen).
- **CashWidget-Budget** auf `ExternalMappingRegistry`-Resolve umstellen, sobald Projekte gebunden
  sind (siehe `IDEEN_UND_BACKLOG.md`).
- **Block B (Lokales Zeit-Subsystem, S1)** ist der nächste Block im Rolling-Plan — rein lokal,
  keine externe Abhängigkeit, kann sofort starten.

## 6. Push/Merge

Branch `feat/mykilos8-block-a-fundament` ist bereit für Review. Push/Merge nach
`docs/mykilos8-handoff`/`main` nur durch Johannes (Eiserne Regel).
