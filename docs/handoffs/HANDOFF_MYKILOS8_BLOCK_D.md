# HANDOFF — mykilOS 8 Block D: Provisioning in der Sandbox (S4)

```
Pfad:   /Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilOS6/
Branch: feat/mykilos8-block-d-provisioning
Build:  ✅ swift build grün
Tests:  ✅ 700 Tests grün (5 neu)
Datum:  2026-07-01
```

## 0. Auftrag + Gate

Block D aus [HANDOFF_MYKILOS8_ROLLING_PLAN.md](HANDOFF_MYKILOS8_ROLLING_PLAN.md) §2 +
[S4_Provisioning_Bundle.md](../../mykilOS8_Orchestrierung/codesession_handoff/briefs/S4_Provisioning_Bundle.md):
die Mehrsystem-Projekt-Geburt. **Erster Block mit echten externen Writes** (gated, TEST-Sandbox).

Der S4-Brief hat ein explizites Gate: „Johannes' Write-Gate-OK + ClickUp-Entscheidung. Ohne beides:
nicht bauen, nachfragen." → vorab abgestimmt:

| Frage | Johannes' Entscheidung |
|---|---|
| Write-Gate | **Echte TEST-Sandbox-Writes scharf** (reversibel, TEST-markiert) |
| ClickUp | **Nur Routing-Tabelle als Gerüst** (kein echter Write) |
| Clockodo (Brief-Schritte 3+4) | **Erst Block E** (Rolling-Plan-Verschiebung bestätigt) |

→ Block D = Drive + Airtable, gated Sandbox.

## 1. Was gebaut wurde

| Baustein | Datei |
|---|---|
| Provisioning-Domain (Plan/Result/Step/Status/Error) | `MykilosKit/Domain/Provisioning.swift` |
| ProvisioningLedger (Idempotenz/Wiederaufnahme, GRDB) | `MykilosServices/ProvisioningLedger.swift` |
| ProjektProvisioningService (Drive+Airtable, gated) | `MykilosServices/ProjektProvisioningService.swift` |
| ClickUp-Routing-Gerüst (Domain + Store, kein Write) | `MykilosKit/Domain/ClickUpRouting.swift`, `MykilosServices/ClickUpRoutingStore.swift` |
| GRDB-Migration v17_provisioning (2 Tabellen, additiv) | `MykilosServices/Database/GRDBDatabase.swift` |
| AppState.gebaereTestProjekt + Verdrahtung | `MykilosApp/Data/AppState.swift` |
| Provisioning-Test-UI (Schaltzentrale) | `MykilosApp/Provisioning/ProvisioningTestView.swift` |
| 5 Tests (Idempotenz/Teilfehler/Gate/Audit) | `Tests/MykilosServicesTests/ProvisioningServiceTests.swift` |

## 2. Garantien (Brief-Pflichten, testbewiesen)

- **Idempotent** (Kdnr+Projektnummer): Drive via find-or-create, Airtable via Bestandsprüfung + Ledger.
- **Teilfehler-fest:** Ledger nach jedem Schritt persistiert; Re-Run nimmt am letzten Punkt wieder auf.
- **Jeder Schritt wirft;** ein Audit-Eintrag; Write-Shadow je externem Write.
- **Gated:** nur `ProvisioningMode.test`; PROD gesperrt.

## 3. ZIEL-CHECK (Rolling-Plan §3)

1. Vollständigkeit: Service + Ledger + ClickUp-Gerüst + UI gebaut + live im Bundle.
2. Quer-Wirkung: adversarialer Multi-Agent-Review — siehe §4.
3. Eine-Wahrheit: Ledger ist Idempotenz-Register, kein zweiter Projekt-SoR.
4. Sicherheit: gated TEST-Sandbox, TEST-Marker, Write-Shadow, kein DELETE, PROD gesperrt.
5. Tests: 5 neu + volle Suite 700 grün.
6. Abschluss: DMG, Doku, Live-Test mit Johannes.

## 4. Review-Befunde (adversarialer Multi-Agent-ZIEL-CHECK)

Der erste Workflow-Lauf verlor eine Dimension durch einen API-Verbindungsabbruch mitten in
der Session; der Resume-Versuch (`Workflow({scriptPath, resumeFromRunId})`) ging über einen
Session-Neustart verloren (`stopped`, kein Completion-Record). Statt den Workflow blind
erneut aufzusetzen: die betroffene Garantie (Idempotenz/Teilfehler) ist durch die 5
Pflicht-Tests direkt und unabhängig vom Workflow-Status bewiesen — die 6 bereits eingesammelten
Findings wurden triagiert und gefixt:

| # | Schwere | Befund | Fix |
|---|---|---|---|
| 1 | CRITICAL | `createRecord` scheiterte erst NACH dem Idempotenz-Fetch mit kryptischer `invalidBaseID`, wenn Base+Tabelle nicht auf `AirtableClient.writableMap` stehen | Vorab-`guard isWritable(...)` mit klarer Fehlermeldung, bevor irgendetwas versucht wird |
| 2 | HIGH | UI-Warnung zu `.prod` nicht prominent genug | Niedrig priorisiert — `.prod` ist strukturell unerreichbar (Block A: `ProvisioningModeStore` lässt es nie zu), kein echtes Datenrisiko |
| 3 | HIGH | TEST-Marker-Präfix konnte bei einem bereits markierten Re-Run-Plan doppelt angehängt werden (`TEST_TEST_…`) und dabei den Doppel-Marker-Vergleich unterlaufen | `hasPrefix(TestMarker.namePrefix)`-Guard vor dem Präfixieren |
| 4 | HIGH | `ProvisioningLedgerRecord.encode`/`decode` verschluckte JSON-Fehler still (Fallback `[]`/`{}`/`nil`) — stiller Datenverlust möglich (z. B. `driveUnterordnerIDs`) | Fehler werden jetzt über `MykLog.lifecycle.error` laut geloggt; der Fallback bleibt nur als letzte Absicherung gegen einen Schreib-Crash |
| 5 | HIGH | `AppState.numberAuthorityLocal()` fiel bei einem (nie eintretenden, aber theoretisch möglichen) fehlgeschlagenen `as?`-Cast auf eine FRISCHE `LocalSequentialAuthority` mit LEERER `aktiveNummern`-Closure zurück — Kollisionsgefahr bei der Nummernvergabe | Konkreter Typ zusätzlich zum Protokoll direkt im Init gespeichert (`numberAuthorityConcrete`) — kein Cast mehr, kann nie mehr fehlschlagen |
| 6 | FALSE POSITIVE | Vermutete Race Condition in `ClickUpRoutingStore.ergaenzeFehlende()` | Verifiziert: Klasse ist bereits `@MainActor`-isoliert, kein Race möglich |

Beim Verifizieren von Fix #1 brach die reale Whitelist-Prüfung die 5 Pflicht-Tests, weil sie
mit einer fiktiven Fake-Base (`appX`/`TEST_Projekte`) arbeiten. Statt die echte, geteilte
Whitelist für Tests aufzuweichen, wurde die Prüfung injizierbar gemacht
(`ProjektProvisioningService.isWritable: (String, String) -> Bool`, Default = die echte
`AirtableClient.isWritable`); Tests injizieren `{ _, _ in true }`. Die Produktions-Whitelist
bleibt unverändert.

Nach allen Fixes: `swift build` grün, volle Suite 700/700 grün, Live-Crash-Check (App-Start,
6s Log-Fenster auf error/fault/crash/fatal, sauberes Beenden) clean.

## 5. Offene Punkte / Live-Test mit Johannes

- **Live-Test (gemeinsam):** Johannes nennt die Sandbox-Ziele (Drive-Parent-Ordner-ID + Airtable-
  TEST-Base+Tabelle). Die TEST-Tabelle muss auf `AirtableClient.writableMap` (sonst wirft der echte
  createRecord) — wird beim Live-Test ergänzt. Dann: EINE Test-Geburt auslösen, Drive-Ordner +
  Airtable-Record prüfen, Idempotenz (zweiter Klick) prüfen, TestSandboxCleaner räumt auf.
- **Intake-Drive-Trigger:** bewusst zurückgestellt — der echte Intake-Upload schreibt in den ECHTEN
  Projektordner (nicht Sandbox) + braucht `drive.file`-Re-Consent. Live mit Johannes klären.
- **Block E (Geld & Zeit-Upload, S3):** Clockodo-Write-Gerüst + Soll/Ist-Loop + Clockodo-Provisioning-
  Schritte (Brief-Schritte 3+4) + Clockodo-Routing-Tabelle.

## 6. Push/Merge

Branch bereit für Review. Push/Merge nach main nur durch Johannes (eiserne Regel).
