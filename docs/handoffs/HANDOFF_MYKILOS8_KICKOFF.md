# HANDOFF — mykilOS 8 Kickoff (Brücke: Briefing ↔ echter Code-Stand)

```
Pfad:   /Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilOS Mac/
Branch: main (= origin/main), Tag v7.7.2, Commit d36063c
Build:  ✅ swift build grün
Tests:  ✅ 661 Tests grün (636 Swift-Testing @Test + 25 XCTest)
Datum:  2026-06-30
Modus:  Read-first · fragen bevor bauen · UI/UX/Daten sind Major.
```

> **Diese Datei ist der EINSTIEG für die neue mykilOS-8-Session (anderes Claude-Konto, gleicher Rechner,
> gleiches Repo, User = Johannes).** Sie ist selbsttragend: kein Zugriff auf das Gedächtnis oder den Chat
> der Vorsession nötig. Lies sie ganz, dann `CLAUDE.md` + `AGENTS.md`, dann das volle Briefing unter
> `mykilOS8_Orchestrierung/codesession_handoff/`.

## 1. Worum es geht (mykilOS 8 = Feature-Paket aus einer Strategie-Session)

Sechs Bausteine, in Sessions **S0→S4** gebaut:
- **S0 Audit** — App verstehen, Verständnis-Report.
- **S1 Lokales Zeit-Subsystem** — Projekt-Timer (Start/Stopp/Pause), 3–5 Kostenstellen-Buttons, Single-Instance-Invariante, Sidebar-Puls-Erinnerung, doppelte Buchungs-Bestätigung. **Rein lokal, kein externer Write.**
- **S2 Read-Wiring + Registry + Kdnr** — Kostenstellen aus Airtable-Projektfeld, `ExternalMappingRegistry` (Kdnr/Token/Projektnummer → Customer/Project).
- **S3 Persönlicher Clockodo-Upload** — Timer-Segmente → Clockodo mit nutzereigenem Keychain-Key, anonymisierter Rücklauf.
- **S4 Provisioning-Bundle** — Mehrsystem-Projekt-Geburt.

Volles Briefing + Mockups + kanonisches Modell: **`mykilOS8_Orchestrierung/codesession_handoff/`**
(`Handoff_Brief_an_Claude_Code_Session.md`, `briefs/S0–S4`, `entwuerfe/*.html`, `modelle/`, `strategie/`).
Zusätzlich liegt die ältere Strategie-Ablage daneben in `mykilOS8_Orchestrierung/` (00_START_HERE etc.).

## 2. ⚠️ Synthese — wo das Briefing vom echten Code abweicht (ZUERST lesen)

Das Briefing stammt aus einer Strategie-Session und beschreibt teils einen **älteren/idealisierten** Stand.
Gegen den echten Code abgeglichen:

| Briefing sagt | Realität im Repo (2026-06-30) | Konsequenz |
|---|---|---|
| Baseline **7.7, 409 Tests** | **7.7.2, 661 Tests**, main d36063c | Neuer als gedacht — frisch geshippt: Webshop, Projektfragebogen-Intake, Drive-PDF (s. §3). |
| **`ExternalMappingRegistry`** existiert | **Existiert NICHT** im Code. Es gibt `CachedProjectRegistry`/`AirtableRegistry` (Projekt-/Kunden-Sync). | S2 **baut** die Registry neu (oder erweitert die bestehende) — nicht nach etwas Nicht-Existentem suchen. |
| `OfferDocumentClassifier` parst AN/AB/SR/TR + Kdnr | Logik lebt in `Sources/MykilosServices/Google/OffersCollector.swift` (Klassenname ggf. anders). | Vorhanden — vor Nutzung den echten Typ verifizieren. |
| Projektnummer **`YYYY-MM-NNNN`** | Echtes Format **`JJJJ-NR`** (z. B. `2026-015`), Drive-geroutet aus dem PROJEKTE-Ordner. | Schlüssel-Format mit Johannes klären, **bevor** S2 die Registry-Keys festlegt. |
| Schreib-Muster Karte→Bestätigung→Audit | **Existiert** (`create_contact`, `create_draft`, Kalender-Vorschlag) — und neu: der **Intake-Schreibpfad** (`AppState.erzeugeKundeUndProjekt`, gated CREATE, append-only). | Muster ist gesetzt; S1/S3-Writes sind Instanzen davon. |

## 3. Was GERADE geshippt wurde (7.7.2) — neuer Kontext, den das Briefing nicht kennt
- **Webshop Phase 4:** Artikel/Shop live aus Airtable (13.419), Liste/Kacheln, Filter, Pagination; **Warenkörbe-Tab**; „Geräte"-Tab entfernt.
- **Projektfragebogen-Intake:** geführte 24-Sektionen-Maske → **Kunde + Projekt (Airtable Artikel-Base, nur CREATE, append-only) + Erst-Warenkorb + PDF-Export** ins Drive `01 INFOS/07 Fragebogen`. Dateien: `Sources/MykilosApp/Intake/`, Schreibpfad in `AppState.swift`.
- **Drive-Schreiben:** `GoogleDriveClient.uploadFile`, `DriveProjectFolderResolver`, `MykPDFRenderer`, Scope `drive.file` (Re-Consent durch Johannes offen).
- **Lerneffekt (für Airtable-Mapping):** `AirtableClient.fetchRecords` liefert Felder per **NAME**, nicht Feld-ID; bei Zahlenfeldern `anyStringValue` nutzen (sonst werden Records still verworfen).

## 4. 🔑 Kritische Überschneidung: Clockodo ist schon entworfen — NICHT neu erfinden
Das S1/S3-Zeit-/Upload-Thema sitzt auf einer **bereits durchdachten Architektur** im Repo:
- **`docs/handoffs/_archiv/HANDOFF_LIVE_WIRING_4.md`** — „Clockodo-Zuhörer", 6-Schichten (Intent→Resolution→Draft-Store→UI→Confirm/POST→Vorschläge), User-Scoping-Constraint („jeder bucht nur seine eigenen Einträge").
- **Airtable-Schema lebt schon** in Base `appuVMh3KDfKw4OoQ`: `Clockodo-Nutzer` (tblPbly2br8mR2kaU, Key + Entwurf-Tabelle je User), persönliche `Clockodo-EW-<Name>`-Tabellen, `Clockodo-Buchungen`, `Clockodo-Leistungen` (Services + Stundensatz). `Kunden.Clockodo-Kunden-ID` teils gemappt.
- `ClockodoClient` existiert (`Sources/MykilosServices/Clockodo/`).
- **Unterschied:** mykilOS-8-S1 ist **Timer-getrieben** (UI), der Zuhörer war **Sprach-getrieben** (Chat). Beide speisen denselben **Draft→Confirm→Upload-Pfad** mit **per-User-Keychain-Key** + **anonymisiertem Rücklauf**. → S1 baut den lokalen Timer/Store; S3 verdrahtet den schon entworfenen Upload. **Vorher `_archiv/HANDOFF_LIVE_WIRING_4.md` lesen.**

## 5. Eiserne Regeln (gelten unverändert — Voll: `CLAUDE.md` + `AGENTS.md`)
- **Kanonischer Ordner** (oben), nie in Desktop-Worktrees dauerhaft arbeiten. **Parallele Agenten = isolierte git-Worktrees.**
- **main heilig:** nie direkt/force; Feature-Branch → grün → nur **Johannes** merged. Signierte Commits, Conventional Commits, `Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>`. **Push/Release nur mit Johannes' Freigabe.**
- **Jeder Write `throws`.** Schreiben nur über Stores, hinter **Karte→Bestätigung→Audit**.
- **Airtable nur CREATE/PATCH, NIE DELETE/Overwrite** (Inaktivierung per Status/Version). Base `appkPzoEiI5eSMkNK` + Drive `0AOeReQBQKkKBUk9PVA` **tabu**. **Sevdesk nie aus der App** (nur via Airtable-Checkbox → Make.com). Secrets nur Keychain; EK-Preise/Kundendaten nie ins Repo.
- **Design-Tokens Pflicht** (`MykColor`/`Font.myk…`), CI-Gate grün. **MykilosKit** importiert nie SwiftUI/GRDB. **GRDB + versionierte Migrationen.**
- **Tests gehören zu „fertig".** Cold-Start-Test für jedes neue persistierbare Feature.
- **Daten-Landkarte:** zwei Airtable-Bases (Mastermind `appuVMh3KDfKw4OoQ` = Routing/Clockodo/Schaltzentrale; Artikel `appdxTeT6bhSBmwx5` = Geschäft/Sevdesk-Pipeline). Vollständig: `docs/AIRTABLE_DATENFLUSS_AUDIT.md`. Jede neue Daten-Weiche → ins Datenstrom-Handbuch (Airtable `tblaUVftka0GvXzeU`) + `docs/BENUTZERHANDBUCH.md`.

## 6. Offene Entscheidungen (Johannes — bevor S3/S4 gebaut wird)
1. **Write-Gate:** Darf die App nach Clockodo/Mehrsystem schreiben, oder vorerst nur lesen?
2. **ClickUp:** integrieren (read-write), via Slack Lists, oder weglassen? (Im 7.x ist ClickUp nur read; mykilOS-8-Orchestrierung war bewusst vertagt.)
3. **S1-Details:** Timer-Wechsel auto-umschalten oder nachfragen? Puls-Verhalten bei Ignorieren? Projektnummer-Format final (`JJJJ-NR`)?

→ Bis geklärt: **S0 (Audit) + S1 (rein lokal, keine externe Abhängigkeit)** sind sofort baubar. S2–S4 warten auf die Entscheidungen.

## 7. Arbeitsweise dieser Session
1. **S0:** Code lesen (Targets, GRDB-Schema/Migrationen, Schreib-Pattern, Widgets/Tokens, Tests) → kurzer **Verständnis-Report** an Johannes, Fragen stellen.
2. **S1 planen:** GRDB-Entities (`aktiverTimer`, Segmente, Zielkontingent) + SwiftUI-Views (Timer auf Projektseite, Sidebar-Pille, Puls/Check-in, Doppel-Bestätigung) + Tests **als Entwurf** vorstellen → mit Johannes abstimmen → **erst dann** bauen.
3. Pro Session: implementieren → `swift build` + `swift test` grün → UI/UX gegen die Mockups (`entwuerfe/*.html`) checken → Datenfluss absprechen → Branch + Report → nächste Session.
4. **Nicht raten** — bei Architektur-/Daten-Entscheidungen fragen.

## 8. Aktueller Schreib-Stand (was die App HEUTE wirklich triggert) — Code-verifiziert 2026-06-30

Quelle: `AppState.erzeugeKundeUndProjekt` (vom Intake-Submit `FragebogenView:625` aufgerufen).

| System | Schreibt heute? | Details |
|---|---|---|
| **Airtable** | ✅ **JA** | Kunde + Projekt (Artikel-Base `appdxTeT6bhSBmwx5`, gated CREATE, append-only) + Erst-Warenkorb (Warenkörbe + Projektartikel via CartStore). Das ist der **einzige** real feuernde Schreibpfad. |
| **Drive** | ❌ **NEIN** | Es werden **keine** Projektordner angelegt. Der `MykFragebogenDriveUploader` ist verdrahtet, wird aber im Submit **nicht aufgerufen**; und selbst wenn — er kann nur `01 INFOS/07 Fragebogen` **unter einem existierenden** Projektordner anlegen, **nicht** den vollen BEISPIELORDNER-Baum (`02 CAD`, `03 PRÄSENTATION`, `01 Pläne` … werden nirgends erzeugt). Braucht zudem `drive.file`-Re-Consent. |
| **Clockodo** | ❌ **NEIN** | Nur entworfen (`_archiv/HANDOFF_LIVE_WIRING_4.md`), nicht gebaut. Kein Write. |
| **ClickUp** | ❌ **NEIN** | In 7.x read-only. Kein Write. |
| **Kunden-/Projektnummer** | ❌ **NICHT generiert** | Kein Kdnr (die Artikel-Base-`Kunden` hat kein Kundennummer-Feld). Der **Projektname ist Freitext** aus der Maske — keine automatische Nummerierung/Schema-Bildung. |

**Konsequenz (gut für uns):** Es ist **keine Nomenklatur in Code zementiert**. Wir sind frei, sie ZUERST
festzuzurren und aus dem bestehenden Bestand zu **lernen**, bevor Provisioning (S4) reale Ordner/Nummern erzeugt.

## 9. Nomenklatur-Vertrag (verbindlich — gilt für Intake-Masken UND S4-Provisioning)

> **Erst lernen, dann zementieren.** Bevor die App reale Ordner/Nummern in Drive/Clockodo/ClickUp/Airtable
> erzeugt, wird das Schema aus dem **vorhandenen** PROJEKTE-Bestand abgeleitet und mit Johannes bestätigt.

- **Projektordner-Name:** `JJJJ_Projektnr_Kunde_STR-Nr` (Vorlage `_BEISPIELORDNER_JJJJ_Projektnr_Kunde_STR-Nr`,
  Unterordner-Baum siehe `HANDOFF_PROJEKT_INTAKE.md` §B.1).
- **Letzter Block `STR-Nr`** = **abgekürzte Straße der Baustelle + Hausnummer** (Baustellen-/Projektadresse, nicht Rechnungsadresse).
- **Fallback-Regel:** Fehlen Straße/Hausnummer in der Eingabemaske → **`ORT` eintragen** (Stadt der Baustelle).
- **Warn-Pflicht:** Würde ein Ordner das Schema brechen, weil auch der Fallback fehlt (kein ORT, kein
  Projektname, etc.), **muss die Maskenübermittlung einen Warnbefehl auslösen** — kein schema-brechender
  Ordner/Record wird stillschweigend angelegt. Die Validierung gehört in die Eingabemaske
  (`FragebogenModel`/`IntakeResultBuilder` bzw. die S4-Provisioning-Maske), VOR dem gated CREATE.
- **Kdnr + Projektnummer** (`JJJJ-NR`, echtes Format — NICHT `YYYY-MM-NNNN` aus dem alten Briefing) werden
  ebenfalls erst nach Lern-/Bestätigungsrunde vergeben; nie raten.

**S4-Provisioning baut auf diesem Vertrag** — Drive-Ordnerbaum + Cross-System-Geburt erzeugen erst Records,
wenn die Maske die Schema-Daten vollständig (oder per ORT-Fallback) liefert; sonst Warnung statt Anlage.

---

**Willkommen. Lies zuerst (§2 + §4 + §8/§9 sind die Stolpersteine). Frag früh. Baue dann sauber.**
