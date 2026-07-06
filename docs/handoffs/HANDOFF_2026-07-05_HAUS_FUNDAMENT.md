# 🏠 HANDOFF — Haus-Fundament (2026-07-05) → nächste Sessions

```
Pfad:    /Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilOS Mac/
Branch:  feat/kamera-barcode-widget   (offsite: origin @ 0f2aaf6, lokal == remote)
Build:   ✅ swift build grün
Tests:   ✅ 1024 grün (132 Suites) — verifiziert nach Personalausweis-Commit 8320538;
         seither nur Doku-Commits (keine Swift-Änderung)
DMG:     dist/mykilOS-10.0.0-alpha20.dmg (15M, rollback-sicher)
Datum:   2026-07-05
```

**Zweck:** Damit eine frische Session (oder Johannes) in Ruhe + mit der aufgebauten Energie
nahtlos weitermacht. Sauberes Ende, fester Sattel, festes Ziel, gewusst wie.

---

## 0. In 30 Sekunden: wo wir stehen

Das **Haus-Fundament ist gebaut, verifiziert und offsite.** Drei Bau-Meilensteine heute,
je durch den Zyklus **Bauplan-Schwarm → Torwächter-Kritiker → Bau-Worker → eigenes
`swift build && swift test` → committen**:

| Commit | Was | Status |
|---|---|---|
| `e9dd572` | **CheckIn-Spine** — `propose→confirm→audit`-Naht, zentraler Audit, harte Idempotenz (DB-Constraint), erster Adapter `offerImported`. Sevdesk bewusst NICHT angedockt. | ✅ grün |
| `d9673a4` | **Warenkorb-Draht** — Positionen-Picker → sichtbarer Korb (war: zwei getrennte Instanzen) + volle Daten-Fidelität in den Checkout. | ✅ grün |
| `8320538` | **Personalausweis-Fundament** — `ResidentIdentity` (local-first, `@mykilos.com`=Schlüssel, GRDB v24, read-only Airtable-Enrich). Zersplitterung gelöst. | ✅ grün |

Dazu: **Grundriss + Kommode-Ansicht** (lebende Artifacts), **Airtable-Vermessung**,
**iOS-Satelliten-Briefing**, alle Branches offsite gesichert. Vision voll dokumentiert
(Haus-Metapher als Nordstern).

---

## 1. Memorandum of Understanding — wie wir arbeiten (fest)

*Kanonisch im Gedächtnis: [[zusammenarbeits-charter]] + [[orchestrator-partner-role]]. Hier die Essenz.*

**Rollen:** Johannes = **Ideengeber, Visionär, Projektleiter auf Augenhöhe** + GO-Instanz für
alles Outward-facing. Claude = **technischer Architekt + Orchestrator + Torwächter** — hält die
Fäden, delegiert an Schwärme/Worker, verifiziert selbst, sichert, baut. **Stehende Vollmacht** für
technische/Sicherungs-Entscheidungen (inkl. Feature-Branch offsite pushen). **GO nötig** für: `main`/
Releases/Tags, externe Writes (Airtable/Drive/Mail/ClickUp), verbuchungsrelevantes, Outward-facing.

**Sprachstil:** kurz, direkt, fachlich, Problem zuerst. Kollege statt Cheerleader. Ehrlich über
Fähigkeiten (lieber „weiß ich nicht" als erfinden). Deutsch. Johannes' lockerer Ton wird gespiegelt.

**Arbeitsweise:** Beppo (Schritt für Schritt, nicht galoppieren, erst verstehen) · Workflow-
Voranfrage (kurz was/warum vor jedem Schwarm) · **Torwächter** (returnte Arbeit selbst per `swift
build && swift test` verifizieren — nie „completed"/Diagnostics blind glauben) · Kontextfenster-
Wache (bei ~85% aktiv melden — Bauch läuft ~2× zu hoch, echtem Tacho trauen) · GO startet nichts
automatisch (erst fragen WELCHER Strang).

**Feedback-Briefkasten:** Johannes legt Screenshots in `~/Desktop/mykilOS-Feedback/FEEDBACK DEV/`.
Auf „schau in den Ordner" nur die **noch-nicht-verbuchten** lesen (Bild→Kommentar), `_LOG.md` ist
der Verbucht-Index. Nicht vorher schnüffeln.

**Eiserne Regeln, die bei jedem Schritt gelten:** append-only (nie löschen/überschreiben, kein
DELETE) · Keys nur Keychain · per-User-Isolation (Mail/Memos/Clockodo/Chat nie kreuzlesbar) ·
Aufgaben nur Mensch→Mensch (KI weist nie zu) · kein Identitäts-Vortäuschen · Belege extern (mykilOS
stellt nie verbuchungspflichtige Dokumente aus) · Sevdesk nur über Briefkasten (Nachbar/Buchhalter,
nie integriert) · MykilosKit importiert nur Foundation, Widgets nie GRDB, Writes nie aus Views ·
jeder Write `throws` + sichtbarer SaveState · Cold-Start-Test für jedes persistierbare Feature.

---

## 2. Der Fahrplan — die nächsten Ausbaustufen (was · wie · wo · wie zu prüfen)

### Stufe 1 — Bewohner-Schicht fertig *(direkt anschlussfähig)*
**(a) Orphan-Rebind** — der volle „Gerätewechsel/Neuinstallation verwaist keine Schlüssel"-Fix.
- *Was:* Das Personalausweis-Fundament persistiert den Anker (`googleEmail`→`userID`) in `db.sqlite`,
  aber der Rebind-Zweig wurde in V1 **bewusst weggelassen** (war toter Code — der einzige `ensureUserID`-
  Call-Site in `AppState.init` läuft VOR der Google-Hydration).
- *Wie:* (1) `AppState` umbauen, dass NACH der Google-Hydration ein **zweiter** `ensureUserID(db:,
  googleEmail:)`-Aufruf läuft und ggf. an die alte Identität rebindet. (2) Den Anker **zusätzlich im
  Keychain** spiegeln (überlebt DB-Reset/Neuinstallation — der DB-Anker allein deckt nur den selteneren
  Fall). Volle Analyse: `tasks/wt4fnabe7.output` (sollLayer 0) + Personalausweis-Bauplan
  `tasks/w4vx7fmpt.output` (Kritiker: breaks[1], missing[3], verschaerfungen[1]).
- *Wo:* `ProfileStore.ensureUserID`, `AppState` (bootstrap/init), neuer Keychain-Anker-Spiegel.
- *Wie prüfen:* Bauplan-Schwarm → Kritiker → Worker → **eigenes `swift build && swift test`** (1024+
  grün halten). Neuer Test: simulierter DB-Reset mit gleicher Mail → rebindet statt verwaist (nicht
  inMemory, echte Datei, Ganzsekunden-Timestamp). Nur volle E-Mail als Anker, nie nur Domain.

**(b) Schlüssel-Inventar** — „das sind alle MEINE Schlüssel" *(klein–mittel, entscheidungsfrei, read-only)*
- *Was:* Read-only Dashboard: alle 6 Schlüssel (Google/Clockodo/ClickUp/Sevdesk/Airtable/Claude) mit
  Status (verbunden/getrennt), **privat vs. geteilt**-Label, + **Verwaist-Erkennung** (aktive `userID`
  gegen tatsächliche Keychain-Suffixe abgleichen → sichtbarer Hinweis statt stillem „nicht verbunden").
- *Wo:* neue View, abgeleitet aus bestehendem Auth-Status; Enum-Flag geteilt/persönlich am Keychain-Base.
- *Wie prüfen:* liest nur Status/Metadaten, NIE Secret-Werte, nie in Logs. Surft in Stufe 2 (Settings).

**(c) Meldeadresse/Onboarding** *(braucht Airtable-Write-GO von Johannes)*
- Wizard-Schritt „Du bist Johannes, johannes@…, Clockodo 421694 — stimmt das?" → bei Bestätigung
  Ausweis lokal schreiben + (gated, opt-in, append-only) Airtable-Team-Record find-or-create/verknüpfen.

### Stufe 2 — Die Settings-Ebene *(der sichtbare Zahltag)*
- *Was:* macOS-System-Settings-Stil (ruhige gruppierte Sektionen, Status-Badges, Chevrons) mit
  UNSEREN Kategorien: **Personalausweis** (Account-Header) · **Integrationen** (mit Status-Punkten) ·
  **Schlüssel-Inventar** · **Darstellung** (Hell/Dunkel/Auto ✅ + CI-Akzent) · **Team/Hausmeister** ·
  **Gemeinsame Räume** (Drive/Projekte/Kataloge). Mapping steht in `docs/IDEEN_UND_BACKLOG.md` (2026-07-05).
- *Kein Neubau — ein Zusammenführen* der Teile aus Stufe 1. (Mockup auf Abruf.)

### Stufe 3 — CHECK-IN-Spine ausrollen
- Weitere Flüsse durch die Naht: `recordAdjustment` (Kalkulation, Plan-Schritt 8, **Kritiker-Auflage:**
  NICHT die Protokoll-Requirement ändern, Zusatz-Überladung) · `warenkorbGesendet` (CartStore, `try?`→
  throws-Muster wie `createContact`) · generische `CheckInActionCard` (ersetzt schrittweise die 4
  duplizierten Karten). Voller Bauplan: `tasks/wcjyptzdz.output`.

### Stufe 4 — Feld-/Sensor-Features *(decision-gated)*
Visitenkarte→Kontakt (Google-Consent) · Barcode→Lager aus/ein (Schreibrechte + Abnabelung Daniel) ·
Foto→Projekt (Kontext-Zuordnung). Teils Mac, teils Satellit.

### Stufe 5 — iOS-Satellit zünden + andocken
Zweiter Claude-MAX-Account, **sequentiell** (ein Account pro macOS-Nutzer). Startprompt liegt in
`~/Claude/Projects/myMini/ANDOCK_UND_STARTPROMPT.md`. Satellit = **Sinnesorgan** (funkt Fotos/Aufmaß/
Termine/Kundendaten zur Erde, trägt schlanke Feld-Mappe), NICHT Moodboards/Warenkörbe/Kalkulation.

---

## 3. 🔴 Ehrlich offen — Blocker, Risiken, Park-Stapel, Prozess-Schuld

**⚠️ GRÖSSTE echte Lücke (safety):** **Kein „Ferienhaus" für die DATEN + Time Machine ist AUS.**
Code ist offsite (git), aber `learning.sqlite` (Schätz-Korpus), lokale GRDB und die Abhängigkeit von
Airtable-/Google-Cloud haben **kein eigenes Backup.** → **Sofort (Johannes, 2 Min): Time Machine
anschalten.** Voller Fix (eigener Strang): Airtable-Voll-Export + Korpus offsite + Keychain-`userID`-
Kopplung härten. Befund: Statik-Vermessung `tasks/wrr48wmze.output`.

**Nicht live-verifiziert:** Spine/Personalausweis/Enrich sind **test-grün, nie gegen echtes Google/
Airtable gelaufen.** Besonders: die **Airtable-Feldnamen** für den Ausweis-Enrich (`Clockodo-Nutzer`,
`tblPbly2br8mR2kaU`) sind **geraten** — Mapper probiert tolerant Kandidaten, gibt sonst still `nil`.
Beim ersten Live-Lauf gegen echte Airtable prüfen, ggf. Kandidatenliste in `mapResidentIdentity` nachziehen.

**Prozess-Schuld:** die neue Airtable-Lese-Weiche (Enrich) ist **nicht ins Airtable-Datenstrom-Handbuch**
eingetragen (eiserne Regel, im Bau-Sprint durchgerutscht). Im Benutzerhandbuch dokumentiert; Airtable-
Eintrag nachzuholen (ist ein Write → wenn der Enrich live geht).

**Park-Stapel (nichts brennt, sammelt sich):**
- **Workspace-Scope des Airtable-PAT** — geparkt (Johannes macht später). Klick-Pfad in
  [[airtable-datenfluss-audit]]. Bis dahin: neue Bases unsichtbar.
- **M-Liste** (CLAUDE.md): Google Re-Consent (userinfo-Scopes), Clockodo-Stundensätze in Airtable,
  ClickUp-Listen-IDs, sevdeskRef+Budget. Gate B5/B6.
- **2 Airtable-„Table 1"-Dummies + V1-Legacy-Totholz** — Löschkandidaten (brauchen GO + Airtable-Session).
- **Warenkorb-Politur:** Extra-Positionsfelder werden getragen, aber im Panel noch nicht **angezeigt**;
  Einzelprojekt-`GlobalOffersView` reicht den Picker/Korb noch nicht durch (90%→101%, später).

**Was NICHT klemmt:** alles offsite, Tree sauber, 1024 grün, DMG in der Hand, Architektur stimmig.

---

## 4. Wie eine nächste Session startet (Startprompt)

1. **Ankommen:** dies lesen + `MEMORY.md` (Index) + [[session-stand-2026-07-05-checkin]] (neuester Anker,
   Endstand-Block) + [[haus-mykilos-grundriss-metapher]] (der Nordstern) + [[zusammenarbeits-charter]] (MoU).
2. **Pflichtprüfung** (eiserne Regel): `pwd` (gelber Ordner), `git status`/`git branch`,
   `swift build && swift test` grün — erst dann bauen.
3. **Empfohlener erster Zug:** *(Safety first)* Johannes: Time Machine an. Dann **Stufe 1**: entweder
   **Orphan-Rebind** (finished den Ausweis) ODER **Schlüssel-Inventar** (klein, entscheidungsfrei, hoher
   sichtbarer Wert). Bei beidem: **Bauplan-Schwarm zuerst** (read-only) → Kritiker → Worker → selbst verifizieren.
4. **Takt:** ein Strang, Schritt für Schritt, Voranfrage vor Schwärmen, nichts auf `main`/nichts extern
   ohne GO, DMG an Checkpoints, Lessons-Log am Ende.

---

## 5. Die Anker (wo alles liegt)

> **📦 Wichtig:** Alle detaillierten Baupläne/Designs (`tasks/*.output`, im Text unten referenziert) lagen
> ursprünglich im Session-Scratchpad (`/private/tmp/…`, session-gebunden) und sind jetzt **durabel ins Repo
> kopiert:** `docs/handoffs/plaene-2026-07-05/` (git-tracked + offsite). Wo unten `tasks/X.output` steht,
> liegt die Datei in `docs/handoffs/plaene-2026-07-05/X.output`.


- **Nordstern/Vision:** [[haus-mykilos-grundriss-metapher]] · Grundriss-Artifact (lebend, macOS-Client)
  · Kommode-Artifact · `docs/HAUS_GESAMTPLAN.md`
- **MoU/Arbeitsweise:** [[zusammenarbeits-charter]] · [[orchestrator-partner-role]] · [[bumerang-flotte-torwaechter]]
- **Bewohner-Entwurf:** `tasks/wt4fnabe7.output` (3 sollLayers, 7 Fragen) · Personalausweis-Bauplan `tasks/w4vx7fmpt.output`
- **Spine/Warenkorb-Baupläne:** `tasks/wcjyptzdz.output` · Airtable-Vermessung `tasks/wrr48wmze.output` + `whki9yhxe.output`
- **iOS-Satellit:** `~/Claude/Projects/myMini/ANDOCK_UND_STARTPROMPT.md` · [[mykilos-mobile-satellit-betreuung]]
- **Feedback:** `~/Desktop/mykilOS-Feedback/FEEDBACK DEV/_LOG.md` · [[feedback-screenshot-workflow-regel]]
- **Logs:** `docs/erfahrungstraeger/PROZESS_LESSONS.md` (Eintrag 2026-07-05) · `docs/BENUTZERHANDBUCH.md` · `docs/IDEEN_UND_BACKLOG.md`
- **Safe State (unantastbar):** Tag `v7.0.0` · [[safe-state-mykilos-7]] · [[git-workflow]]

---

*Sauberes Ende. Grandioser weiterer Weg. Fest im Sattel, festes Ziel, gewusst wie. 🏠🫡*
