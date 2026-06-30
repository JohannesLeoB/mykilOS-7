# HANDOFF — Masterplan „Projekt-Aufnahme & Webshop" (an alle Agenten / Systeme)

```
Stand:   2026-06-30, abends. Basis-Branch: feat/webshop-phase4 (623 Tests grün, swift build exit 0).
Owner:   Johannes (nur er merged main / pusht / hebt Version / baut Release-DMG).
Lies zuerst: AGENTS.md · CLAUDE.md · docs/handoffs/HANDOFF_COLLABORATION.md
Begleitverträge: HANDOFF_PROJEKT_INTAKE.md · HANDOFF_PLANNED_FEATURES.md · ../AIRTABLE_DATENFLUSS_AUDIT.md
```

> **Für jedes andere System/Agenten, das hier weiterbaut, während Johannes' Wochenlimit aus ist:**
> Diese Datei ist der Einstieg. Halte die eisernen Regeln, arbeite in isolierten Worktrees, pushe nicht.

## 1. Branch-Landkarte (Stand jetzt)

| Branch | Inhalt | Status |
|---|---|---|
| `main` | Release-Stand | unangetastet (nur Johannes merged) |
| `feat/webshop-phase4` | **Basis dieser Runde.** Artikel-Leer-Bug-Fix, Warenkörbe-Tab, Kacheln/Pagination, Geräte-Tab raus | ✅ gebaut+verifiziert (Commit 1591cad) |
| `feat/drive-pdf-plumbing` | GoogleDriveClient.uploadFile + DriveProjectFolderResolver (01 INFOS/07 Fragebogen) + MykPDFRenderer + `drive.file`-Scope | ✅ in `feat/intake-suite` |
| `feat/projekt-intake` | Projektfragebogen-Maske → Kunde+Projekt (Artikel-Base) + Erst-Warenkorb + PDF/Drive | ✅ in `feat/intake-suite` |
| **`feat/intake-suite`** | **Release 7.7.2** — P4 + Drive + Intake + Verdrahtung + Docs konsolidiert | ✅ 661 Tests grün, DMG gebaut |

> **✅ RELEASE 7.7.2 (2026-06-30):** `feat/intake-suite` = alles oben zusammengeführt (FF-fähig auf main),
> 661 Tests (636 Swift-Testing + 25 XCTest), `mykilOS-7.7.2.dmg` signiert gebaut. PDF/Drive-Stubs sind
> mit `MykPDFRenderer` + `DriveProjectFolderResolver` verdrahtet. **Wave-1-Agenten wurden durch einen
> Prozess-Neustart unterbrochen; Claude hat ihre unkommittierte Arbeit geborgen + repariert** (Layering,
> Aktor-Isolation, Base-Konsistenz Kunde→Artikel-Base, Whitelist). **Offen Johannes:** Google Re-Consent
> (`drive.file`) für Live-Upload. **Wave 2 noch offen** (s. §4): lokaler Artikel-Spiegel, Feature A/C,
> Export D (Warenkorb CSV/PDF), Linienzeichnungen.

Die Branches zweigen von `feat/webshop-phase4` ab, sind **datei-disjunkt** und wurden konfliktfrei gemergt.

## 2. Wichtigster Lerneffekt dieser Runde (für Airtable-Mapping)
**`AirtableFieldValue.stringValue` ist `nil`, wenn Airtable das Feld als `.number` liefert** (z. B. `Artikelnummer`).
Das hat in Phase 4 alle 13.419 Artikel verworfen. Fix: `AirtableClient.anyStringValue` (.number→String).
→ **Beim Mappen IMMER `anyStringValue` für Felder nutzen, die numerisch sein können.** Dazu die ältere Lektion:
**fetchRecords liefert Felder per NAME, nicht per Feld-ID.** Beide Fehler gegen echte Feldnamen+Typen testen.

## 3. Architektur-Entscheidungen (verbindlich)
- **Zwei Airtable-Bases, klare Rollen** (siehe AIRTABLE_DATENFLUSS_AUDIT.md): Mastermind `appuVMh3KDfKw4OoQ` =
  Routing; **Artikel `appdxTeT6bhSBmwx5` = Geschäft/Sevdesk-Pipeline**. Doppelte `Kunden`/`Projekte` über
  **`Projektnummer`** verbinden.
- **Neue Kunden/Projekte aus dem Intake → in die Artikel-Base** (`Kunden` tblImZ3fKYBXBT7Wb, `Projekte`
  tblOXF9Cv8Jze6595). **Nur CREATE, nie update/delete bestehender Records** („ohne etwas zu verletzen").
  `writableMap` eng erweitern.
- **Drive-Fragebogen-PDF** → `<Projektordner>/01 INFOS/07 Fragebogen/` (Schema bestätigt, HANDOFF_PROJEKT_INTAKE §B.1).
  Braucht **`drive.file`-Scope → Google Re-Consent (Johannes, Trennen→Verbinden)**, bis dahin Code fertig aber Drive-Live aus.
- **App schnell halten:** lokaler Artikel-Spiegel (GRDB, inkrementell über `Zuletzt geändert`), nie UI auf Live-Fetch blocken.

## 4. Warteschlange (nach den zwei laufenden Strängen)
| # | Feature | Vertrag | Kollidiert mit |
|---|---|---|---|
| 1 | **Verdrahtung**: Intake-PDF-/Drive-Protokolle ↔ `MykPDFRenderer` + `DriveProjectFolderResolver` | dieser Plan | klein, am Consolidation-Punkt |
| 2 | **Lokaler Artikel-Spiegel** (GRDB-Cache, inkrementeller Sync) | INTAKE §D / AUDIT §6 | `ArtikelKatalogStore` |
| 3 | **Export Feature D**: Warenkorb CSV+PDF im Warenkörbe-Tab (nutzt MykPDFRenderer) | PLANNED_FEATURES Feature D | Warenkörbe-Tab |
| 4 | **Feature A**: „+"-Anlegen-Masken (Kunde/Artikel/Kontakt/Lagerartikel) | PLANNED_FEATURES Feature A | `KatalogeView` „+" |
| 5 | **Feature C**: Warenkorb→Projekt-Widget auf Projekt-Detailseite | PLANNED_FEATURES Feature C | `ProjectDetailView`, `CartStore` |
| 6 | **Linienzeichnungen** als Option-Illustrationen in der Fragebogen-Maske | INTAKE §E | Assets nach Resources/ |

**Sequenzierungs-Regel:** Stränge, die `KatalogeView`/`ArtikelKatalogStore`/`CartStore`/`WebshopTabs` anfassen,
**nie parallel** zueinander — sonst Worktree-Kollision. Parallel nur, wenn die Datei-Mengen disjunkt sind.

## 5. Abschluss-Prozess dieser Runde (Claude/Johannes)
1. Beide Agenten-Branches verifizieren (`git log`, `git show --stat`, **eigener `swift build`+`swift test`** — Agent-Bericht nie blind glauben).
2. Verdrahten (Protokoll-Impls), zu einem Integrations-Branch zusammenführen, konfliktfrei.
3. `swift build` + `swift test` grün, dann **App-Bundle + DMG bauen** (`script/build_and_run.sh` / `create_dmg.sh`),
   Version + Name nach Zahlenkreis (z. B. **7.8.0**), BUNDLE_ID konstant `de.mykilos.mykilos6`.
4. Doku: BENUTZERHANDBUCH + Datenstrom-Handbuch (Airtable `tblaUVftka0GvXzeU`) um neue Weichen ergänzen
   (`AIRTABLE_INTAKE_KUNDE_PROJEKT`, `DRIVE_FRAGEBOGEN_UPLOAD`, `AIRTABLE_PROJEKT_JOIN`).
5. Commit (signiert), Branch sauber. **Push/Merge nach main = NUR Johannes.**

## 6. Eiserne Regeln (Kurzform — Vollform in AGENTS.md)
Airtable nur CREATE/PATCH, **nie DELETE/Overwrite**; Base `appkPzoEiI5eSMkNK` + Drive `0AOeReQBQKkKBUk9PVA` tabu;
Sevdesk nie aus der App; Secrets nur Keychain; EK-Preise/Kundendaten nie ins Repo; Token-Disziplin (MykColor/Font.myk…);
MykilosKit nie SwiftUI/GRDB; Schreiben nur über Stores hinter Bestätigung→Audit; isolierte Worktrees; signierte Commits;
Safe-State-Tag `v7.0.0` (e629e84) unantastbar.
