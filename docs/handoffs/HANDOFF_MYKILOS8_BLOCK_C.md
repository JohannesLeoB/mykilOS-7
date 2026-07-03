# HANDOFF — mykilOS 8 Block C: Identität + Nomenklatur (S2)

```
Pfad:   /Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilOS6/
Branch: feat/mykilos8-block-c-identitaet-nomenklatur
Build:  ✅ swift build grün
Tests:  ✅ 695 Tests grün (24 neu)
Datum:  2026-07-01
```

## 0. Auftrag

Block C aus [HANDOFF_MYKILOS8_ROLLING_PLAN.md](HANDOFF_MYKILOS8_ROLLING_PLAN.md) §2 +
[HANDOFF_PROVISIONING_NOMENKLATUR.md](HANDOFF_PROVISIONING_NOMENKLATUR.md): die Identitäts- und
Nomenklatur-Schicht. **Rein lokal, kein externer Write** (Gate=keins). Das echte Provisioning
(Ordner/Records erzeugen) ist Block D — Block C baut das Fundament dafür.

Der S2-Brief vermischt Nomenklatur (→ Block C) mit dem Sevdesk/Clockodo-Soll/Ist-Loop (→ Block E);
maßgeblich ist die Rolling-Plan-Aufteilung. Block C = nur Identität + Nomenklatur.

## 1. Johannes' Entscheidungen (vorab abgestimmt)

| Frage | Entscheidung |
|---|---|
| Kostenstellen-Quelle (Airtable-Feld fehlt) | Provider-Abstraktion + Default jetzt, Airtable-Quelle sobald Feld da |
| FolderSchema + Konnektor-Heimat | GRDB-Config lokal (nicht Airtable) |
| STR-Nr-Strenge | Default-Regel + Bestand-Varianten als Whitelist (erweiterbar), sonst Warn+Block |
| Umfang | Voll durchziehen (alle 8 Bausteine) |

## 2. Was gebaut wurde

| Baustein | Datei(en) |
|---|---|
| Projektnummer (parse/format/normalisieren, max+1-Logik) | `MykilosKit/Domain/Projektnummer.swift` |
| NumberAuthority-Protokoll (Adapter-Seam für Sevdesk) | `MykilosKit/Domain/NumberAuthority.swift` |
| LocalSequentialAuthority (max+1 aktiv+archiv, GRDB-Register) | `MykilosServices/LocalSequentialAuthority.swift` |
| STR-Nr-Bildung (Adresse/ORT/Variante-Whitelist/Warn+Block) | `MykilosKit/Domain/STRNummer.swift` |
| FolderSchema v1 + OrdnerKonnektor (versionierte Daten) | `MykilosKit/Domain/FolderSchema.swift` |
| Anti-Duplikat-Checks (Kunde/Kdnr/Mail/Tel/Name) | `MykilosKit/Domain/AntiDuplikat.swift` |
| KostenstellenProvider (Default + Override, Airtable-ready) | `MykilosKit/Domain/KostenstellenProviding.swift` |
| NomenklaturStore (Konnektoren/Schema/Kostenstellen, GRDB) | `MykilosServices/NomenklaturStore.swift` |
| GRDB-Migration v16_nomenklatur (4 Tabellen, additiv) | `MykilosServices/Database/GRDBDatabase.swift` |
| Registry voll: Kdnr/Projektnr/Token-Lookups | `MykilosServices/ExternalMappingRegistry.swift` |
| Kdnr auf Detail-Übersicht | `MykilosApp/Detail/ProjectHeroView.swift` |
| Kostenstellen-Provider in Timer (löst S1-Mock ab) | `MykilosApp/Time/ProjektTimerView.swift` |
| 24 Tests | `Tests/MykilosKitTests/NomenklaturTests.swift`, `Tests/MykilosServicesTests/NomenklaturServiceTests.swift` |

## 3. ZIEL-CHECK (Rolling-Plan §3)

1. Vollständigkeit: alle 8 Bausteine gebaut + live im Bundle (App startet ohne Crash, Log sauber).
2. Quer-Wirkung: adversarialer Multi-Agent-Review (4 Dimensionen) — siehe §4.
3. Eine-Wahrheit: aktive Projektnummern kommen LIVE aus dem Routing-Cache (Registry), die Authority
   hält nur ein Zusatz-Register (Archiv/Reservierung) — kein zweiter SoR für Projekte. Kdnr≠Projektnr.
4. Sicherheit: kein externer Write; Migration additiv; alle Writes throws.
5. Tests: 19 neu (Projektnummer, STR-Nr, FolderSchema, Anti-Duplikat, NumberAuthority max+1/Archiv/
   Reserve/Cold-Start, NomenklaturStore Cold-Start, Registry-Lookups, Review-Fix-Tests) + volle Suite 695 grün.
6. Abschluss: DMG 7.10.0, Doku synchron.

## 4. Review-Befunde (adversarialer Multi-Agent-ZIEL-CHECK)

4 parallele Dimensionen (Regression, Nomenklatur-Logik, Persistenz, Token/SwiftUI) + adversariale
Verifikation: **10 Findings, 8 bestätigt + gefixt, 2 als False-Positive verworfen** (753k Tokens, 14 Agenten).

| # | Schwere | Befund | Fix |
|---|---|---|---|
| 1+5 | high/med | `nextProjektnummer()` + `reserve()` nicht atomar → Race könnte dieselbe Nummer doppelt vergeben | neue `nextAndReserve(jahr:)`: berechnet + reserviert in EINER GRDB-Transaktion (serielle Write-Queue → race-frei). `nextProjektnummer` bleibt reine Vorschau. Test mit `async let`-Parallelaufruf |
| 2 | high | leerer Kostenstellen-Override (`[]`) ließ den Timer ganz ohne Kostenstellen | Default-Fallback bei leerem Override (Provider + Store), `setzeKostenstellen([])` löscht den Override statt `[]` zu speichern |
| 3 | high | Konnektor-Seed nur „wenn Tabelle leer" → ein teilweiser Bestand hinterließ fehlende Slots (`konnektor(.cad)`→nil) | `ergaenzeFehlendeKonnektoren()`: füllt fehlende Default-Slots beim Laden, behält bestehende. Test mit simuliert-gelöschtem Slot |
| 4 | high | `aktiveNummern`-Closure machte synchrones Datei-IO in async-Kontext | `Task.detached(.utility)` — IO explizit off-main |
| 6 | med | `archiviere()` überschrieb still eine extern (Sevdesk) gebundene Nummer | Guard: extern-gebundene behält ihre Herkunft |
| 7 | med | `kostenstellen` allokierte pro View-Frame einen neuen Provider | direkte `NomenklaturStore.kostenstellen(fuer:)`-Methode statt Provider-Allokation |
| 8 | low | `load()` schluckte kaputten Kostenstellen-JSON still | `do/catch` mit `MykLog`-Sichtbarkeit |

**False-Positives (vom Verifizierer korrekt verworfen):** „Projektnummer-Parsing nimmt Zahlengruppen in
beliebiger Reihenfolge" (die erste Gruppe ist per `guard jahr>=2000` immer das Jahr) · „Telefon-Dedupe
inkonsistent bei Ländervorwahl" (nur ein schwacher Hinweis-Treffer, unkritisch).

4 neue Tests für die Fixes (atomare Vergabe, leere-Kostenstellen-Fallback, partielle Konnektoren,
archiviere-Guard). Build + 695 Tests grün.

## 5. Offene Punkte / nächste Blöcke

- **Kostenstellen-Airtable-Feld:** Daniel legt ggf. ein Projektfeld an → dann nur den
  `KostenstellenProviding`-Provider gegen einen Airtable-Provider tauschen (Abstraktion steht).
- **STR-Nr-Whitelist:** die Bestand-Varianten sind als Default drin — Johannes kann sie jederzeit
  erweitern (`STRNummer.defaultVariantenWhitelist`).
- **Block D (Provisioning, S4):** nutzt NumberAuthority + FolderSchema + Konnektoren + Anti-Duplikat,
  um in der TEST-Sandbox echte Ordnerbäume + Records zu erzeugen (gated, live mit Johannes).
- **ClickUp-Routing / Clockodo-Routing-Tabellen:** §9/§11 des Provisioning-Vertrags → Block D/E.

## 6. Push/Merge

Branch bereit für Review. Push/Merge nach main nur durch Johannes (eiserne Regel).
