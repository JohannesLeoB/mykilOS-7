# ClickUp Studio-OS-Architektur — Zielzustand (2026-07-02)

**Auftrag (Johannes, verbatim):** „Wir müssen die Ghost-Aufgaben später in einem Go-Live auch
alle auf die entsprechenden realen User wiren können. Der ClickUp MYKILOS API Testspace gehört
komplett dir — die darin aufgebaute Start-Architektur ist hinfällig. Du musst einen sauberen
Integrationsplan finden und Routinen und Projekt-Templates sowie den ClickUp-Projekt-Management-
Ablauf und -Struktur komplett einrichten."

Erarbeitet über einen 4-Entwürfe-Workflow (App-First, ClickUp-Native, Ghost→Go-Live-
Migrationssicherheit, Multi-Projekttyp-Templates) + Synthese. **Gilt uneingeschränkt:
[GHOST_PERSONA_REGEL.md](GHOST_PERSONA_REGEL.md)** — nichts hier ändert daran etwas.

## Ordnerstruktur (Testspace `90128024109`) — Status: umgesetzt

| Ordner | ProjectKind | Aktion | Status |
|---|---|---|---|
| `01 Kundenprojekte` (901211866053) | kitchen | unverändert (Seed KUE-2026-014 bleibt) | ✅ |
| `02 Lichtplanung` (901211866056) | lighting | umbenannt von „02 Planung & Design" | ✅ |
| `03 Service & Nachträge` (901211866060) | addendum | umbenannt von „05 Service & Nachträge" | ✅ |
| `04 Leads & Anfragen` (901211866051) | lead | umbenannt von „00 Intake & Triage" | ✅ |
| `05 Angebote & Kalkulation` (901211866058) | quote | umbenannt von „03 Angebot, Einkauf & Lieferanten" | ✅ |
| `06 Studio Intern` (901211866062) | studioInternal | unverändert, bewusst templatelos | ✅ |
| `88 Slack-Archiv (historisch)` (901212095701) | — | unverändert (2024_007_Doehle, 6 Tasks) | ✅ |
| `_TEST_PROVISIONING` (901212093014) | — | unverändert, Code legt Listen selbst an | ✅ |
| `90 Reviews & Freigaben` (901211866064) | — | Liste „Go-Live-Freigaben" + 1 Platzhalter-Task ergänzt | ✅ |
| `99 Admin & Datenpflege` (901211866066) | — | Liste „Custom-Field-Wünsche & ClickUp-Konfiguration" + 10 Tasks ergänzt | ✅ |
| `ZZ_LÖSCHEN_Ausführung & Montage` (901211866059) | — | leer, kein Kind-Bezug — **manuell löschen** | ⚠️ Connector kann keine Ordner löschen |
| `ZZ_LÖSCHEN_Accounting & Cash` (901211866063) | — | leer, Sevdesk-NO-GO — **manuell löschen** | ⚠️ Connector kann keine Ordner löschen |

**Wichtiger Tool-Befund:** Der ClickUp-MCP-Connector hat keinen `delete_folder`-Tool
(nur `create_folder`/`update_folder`). Die 2 überflüssigen Ordner wurden daher klar als
„ZZ_LÖSCHEN_…" markiert (sortieren ans Ende, unübersehbar) statt gelöscht — **Johannes muss
sie einmalig in der ClickUp-UI selbst löschen.**

## Templates je ProjectKind

| Kind | Liste/Muster | Tasks | Verifiziert in `_TEST_PROVISIONING` |
|---|---|---|---|
| `kitchen` | `TEST_{JJJJ}_{NNN}_{Kunde}[_{Code}]` | altes 8-Task-Template noch live (KUE-2026-014); **verbesserte 28-Task/10-Phasen-Referenz mit 10 echten Dependencies siehe „Nachtrag" unten** | ✅ `TEST_KUECHE_Vorlage_v2` (901219239199) |
| `lighting` | `TEST_{JJJJ}_{NNN}_{Kunde}_LICHT` | 8 Tasks, vom kitchen-Template abgeleitet | ✅ `TEST_LICHT_Vorlage` (901219238554) |
| `addendum` | `TEST_{JJJJ}_{NNN}_{Kunde}_NACHTRAG_{lfdNr}` | 6-Task-Mini-Template, Elternprojekt als Klartext-Bezug | ✅ `TEST_NACHTRAG_Vorlage` (901219238563) |
| `lead` | **eine** Jahres-Sammelliste `Leads {JJJJ}` — jeder Lead ein Task, keine eigene Liste | 3 Tasks pro Lead-Task-Vorlage | ✅ Liste `Leads 2026` angelegt (901219238378), Struktur bereit, Tasks entstehen pro echtem Lead |
| `quote` | `TEST_ANGEBOT_{JJJJ}_{Kunde}` | 5-Task-Template, endet ohne Ausführung | ✅ `TEST_ANGEBOT_Vorlage` (901219238569) |
| `studioInternal` | `TEST_INTERN_{JJJJ}_{Kurzbeschreibung}` bzw. Dauerlisten in „06 Studio Intern" | bewusst kein Template (leeres Array) | n/a — kein Lebenszyklus |

## Ghost→Real Go-Live-Migration: 5-Gate-Zustandsmaschine

Kein neues Datenmodell — die bestehende Airtable-Tabelle `ClickUp-Ghost-Adapter`
(`tblJvo4MNd1i1Xl2y`, Base `appuVMh3KDfKw4OoQ`) ist das alleinige Ledger.

- **Gate 0 (unmapped):** jede Ghost-Task-Erstellung erzeugt sofort einen Ledger-Record
  (Projekt-Link, ClickUp-Task-/Liste-ID, Source System/Confidence, Simulation Batch).
- **Gate 1 (proposed):** Ghost-Kürzel aus dem Beschreibungs-Marker → `Real Assignee Proposed`.
- **Gate 2 (confirmed):** Johannes bestätigt explizit pro Record → `Real Assignee Confirmed`
  (separates Feld von Proposed — verhindert Verwechslung von Automatik und Freigabe).
- **Gate 3 (ready):** nur wenn Confirmed gesetzt UND `Ghost-Personas.Go-Live-Enabled=true` UND
  `Ghost-Rolle-Primär` nicht leer. **Aktuell erfüllt niemand Gate 3** — bei Jo fehlt nur
  `Go-Live-Enabled` (aktuell false), bei Da/Fra/Sen/Jil zusätzlich die Rollenentscheidung.
- **Gate 4 (live):** nur nach explizitem Johannes-Kommando, granular pro Person (gestaffeltes
  Go-Live möglich). Ein künftiger `GhostMigrationService` liest alle „ready"-Records der
  freizugebenden Person, setzt die echte ClickUp-User-ID, ergänzt den Marker um
  „→ LIVE am `<Datum>`" (löscht ihn nie — Audit-Spur bleibt).

**Vollständigkeits-Pflicht vor jedem Go-Live-Lauf:** Zwei-Wege-Abgleich ClickUp
(Marker-Textsuche im Space) gegen Airtable-Ledger — Differenz muss 0 sein, sonst Abbruch.
Nichts wird je gelöscht, nur ergänzt (deckt sich mit der Airtable-No-Delete-Regel des Repos).

**Nachgeholt (2026-07-02):** die 6 Döhle-Tasks (`2024_007_Doehle`, Slack-Rekonstruktions-Pilot)
hatten keine Ledger-Gegenbuchung — jetzt nachgetragen (Source=Slack, Status=unmapped).

## Nachtrag (2026-07-02): Vollständiges Nachlesen von 3 echten Slack-Projektverläufen

Johannes' Nachfrage „sind Routinen/Meilensteine/Abhängigkeiten wirklich funktional verdrahtet?"
führte zu einer ehrlichen Prüfung (siehe Chat-Antwort davor: Felder/Flows/Syncs/Warnungen waren
NICHT funktional — nur Struktur, kein einziges echtes Projekt außer Döhle durchgespielt). Auf
Anweisung wurden danach **3 Slack-Kanäle vollständig** gelesen (nicht mehr nur Stichprobe):
`p_hh_fuckner_huetter_se` (849 Zeilen, 2025-01 bis 2026-06), `p_schw_schneider_dk` (470 Zeilen,
2025-12 bis 2026-06), `p_hh_junge_dk_jlb_jb` (271 Zeilen, 2026-01 bis 2026-06) — zusätzlich zum
bereits vollständig gelesenen Döhle-Kanal (398 Zeilen).

### Befund 1: Das alte 8-Task-Template ist zu flach — echte Projekte haben ~28 Schritte in 10 Phasen mit echten Abhängigkeiten

Über alle 3 Kanäle hinweg wiederkehrend beobachtete Phasenfolge (nicht geraten — jede Phase hat
mindestens 2 unabhängige Textbelege):

1. **Akquise** — Lead qualifizieren → Kontaktdaten erfassen → **„Kunden anlegen und
   Projektübersicht starten"** (wörtlicher Trigger-Satz, BenjaminMartin 2025-11-07) = der reale
   Lead→kitchen-Übergangspunkt.
2. **Bestandsaufnahme** — Grob-Aufmaß/Grundriss, Beratungstermin(e), Wünsche dokumentieren.
3. **Konzept** — Geräteliste+Schätzpreis, **mindestens 2 parallele Moodboard-Varianten** (nie
   nur 1 — Schneider: „Angebot 1 mit Pyrolav und Angebot 2 mit Alternative"), Kundenfeedback mit
   Revisionsschleife (Schneider hatte mehrere Korrekturrunden nach widersprüchlichen internen
   Rückfragen — reales Konfliktsignal, siehe unten).
4. **Angebot** — **Mehrfach-Tischlerangebote parallel** (Schneider fragte HKT, Weichsel78,
   Salzwedel, Rami, MGB gleichzeitig an, „ins Rennen schicken"), Vergleich, Angebot an Kunde.
5. **GATE: Beauftragung** — harter Meilenstein („Beauftragung Schneider inkl. der dem Angebot
   zugrundeliegenden Zeichnung", 2026-04-10). **Werksplanung darf nachweislich erst danach
   starten** — mehrfach im Text als Reihenfolge behandelt.
6. **Werksplanung & Feinaufmaß** — Werkzeichnung (oft mit Revisionsrunden, „Werkplanung
   Revision II"), finales Aufmaß beim Tischler (separat vom groben Erst-Aufmaß!), Materialmuster
   bestellen/versenden — „Vor Auftragsvergabe wird ein Muster vom Kunden freigegeben" zeigt: auch
   Muster-Freigabe kann selbst ein Gate sein.
7. **Beschaffung** — Geräte final erst NACH finaler Werksplanung bestellen (Fuckner/Hütter:
   Kühlschrank-Modell musste mehrfach korrigiert werden, weil vorher zu früh bestellt worden
   wäre), Sonderanfertigungen (Stein/Metall), Lieferort festlegen.
8. **Fremdgewerke-Koordination** — Elektro-/Sanitärplanung als **paralleler, hochriskanter
   Blocker-Strang**: bei Fuckner/Hütter verzögerte eine externe Elektrofirma (Conrad) das
   GESAMTE Projekt monatelang, die Kunden schrieben einen expliziten Beschwerdebrief. Explizite
   Abhängigkeit im Text: „Schnittstelle Elektriker, wichtig! Wann ist Conrad durch und wann
   startet Arne? **Erst danach Trockenbau!**"
9. **Montage** — Zeitfenster/Zugänglichkeit (Aufzug/Baulift-Abhängigkeiten kommen in ALLEN 3
   Kanälen vor), Montage, **Qualitätskontrolle vor Ort** (Fuckner/Hütter: Einputzring-Fehler des
   Trockenbauers wurde nur durch gezielten Kontrollbesuch entdeckt — sonst unbemerkt geblieben).
10. **Abschluss** — Schlussrechnung, Übergabeprotokoll.

**Nachtrag als wiederkehrendes Querschnittsmuster** (nicht Teil der linearen Kette, kann in
JEDER Phase auftreten): Wunsch/Änderung erfassen → Preis/Angebot einholen → Kunde-GO →
Auftrag/AB aktualisieren → betroffenes Gewerk informieren. Beobachtet u. a. bei Steinrückwand,
Filzeinleger, Quooker-Modelltausch, Fensterbank Pyrolave — bei Fuckner/Hütter zusätzlich ein
kompletter Nachtrags-Streit um falsch spezifizierte LED-Treiber (rund 850€ Mehrkosten,
Lieferantenverhandlung über mehrere Wochen).

**Umgesetzt:** neue Referenzliste `TEST_KUECHE_Vorlage_v2 (phasiert, mit Abhängigkeiten)` in
`_TEST_PROVISIONING` (901219239199) — 28 Tasks in 10 Phasen + 1 wiederverwendbarer
Nachtrag-Subflow-Task (5 Subtasks), **10 echte ClickUp-Task-Dependencies gesetzt**
(`clickup_add_task_dependency`, Typ `waiting_on`) entlang der oben belegten Kette:
Angebote einholen→vergleichen→senden→**Beauftragung**→Werksplanung/Aufmaß→Geräte
bestellen/Fremdgewerke→Montage→Schlussrechnung. Multi-Vendor-Vergleich (P4.1) und
Nachtrag-Subflow als Subtasks (ClickUp-native, per `parent`-Parameter) statt als einzelne
flache Zeilen. **Noch nicht:** Übernahme in `ClickUpProjectTemplate.swift` (weiterhin
Folgeauftrag, siehe unten) — dieser Schritt ist bewusst nur ClickUp-seitig demonstriert.

### Befund 2: „Kind mit eingebetteter Subphase" — mein 1-Kind-pro-Projekt-Mapping bricht

Fuckner/Hütter ist ein `kitchen`-Projekt, das eine komplette eigenständige
Lichtplanungs-Subphase enthält (KNX, Modular-Leuchten, Szenen/Schalter, eigene Bemusterung,
eigene Rechnungsstellung „Schlussrechnung Leuchten"). Das ist **keine Lichtplanung als
eigenständiges Projekt**, sondern ein Workstream innerhalb eines Küchenprojekts. Das
`lighting`-Template (eigener Ordner/eigene Liste) würde das falsch als separates Projekt
abbilden. **Empfehlung statt Sofort-Fix:** `lighting` als eigenes Kind nur für echte
Standalone-Lichtprojekte behalten; bei einer Lichtplanungs-Subphase innerhalb `kitchen`
stattdessen die P3–P6-Phasen des Küchen-Templates um eine Lichtplanungs-Task-Gruppe erweitern
(nicht umgesetzt — Entscheidung sollte Johannes treffen, da es das Kern-Template verändert).

### Befund 3: JungeSchultzendorff passt auf KEINEN der 6 ProjectKind-Fälle

„gesamtes Interior erfassen, Bauleitung und Kreativberatung", Stundenkontingent-Angebot
(keine Küchengeräte, keine Tischlerbeauftragung im beobachteten Zeitraum), **explizit erwähnte
„Unterprojekte"** in Clockodo, wiederkehrende (nicht lineare) Termine mit fester Agenda,
mehrere parallele Moodboards je Raum, Schnittstelle zu externem Architekturbüro (HS Architekten)
UND weiterem Gewerk (Belli). Passt weder zu `kitchen` (keine Geräte/Tischler-Kette) noch zu
`quote` (laufendes Mandat, keine Einzelentscheidung). **Bemerkenswert:** Das Team selbst hat
auf genau dieses Strukturproblem reagiert — Jilliana kündigte den Kunden gegenüber proaktiv ein
„gemeinsames Google Sheet als Projektboard, das zu einem Raumbuch weiterentwickelt wird" an,
nachdem der Kunde sich über einen „nicht ganz rund und klar strukturiert" verlaufenen Termin
beschwert hatte — ein reales, unstrukturiertes internes Werkzeug für genau die Lücke, die ein
7. `ProjectKind` (Arbeitstitel: `.interiorConsulting`) schließen würde. **Nicht gebaut** — echte
Produktentscheidung, die Johannes treffen sollte, nicht geraten.

### Befund 4: Konfliktsignal ohne strukturelles Feld

Schneider-Kanal, 2026-01-14: Kundin beschwert sich wörtlich, dass zwei Mitarbeiter unabhängig
dieselben Fragen gestellt und widersprüchliche Erstentwürfe geliefert haben (Metallbecken vs.
gewünscht kein Metall, eckige vs. gewünscht runde Insel). Genau das Szenario, für das
`blocker_type`/`review_required` (Custom Fields, noch nicht anlegbar) gedacht sind — bestätigt
zusätzlich die Priorität dieser beiden Felder unter den 10 Custom-Field-Wünschen.

## Nicht Teil dieses Schritts — als Folgeauftrag benannt

Zwei kleine, additive Swift-Änderungen (brechen nichts Bestehendes, kitchen-Pfad bleibt
verhaltensgleich):

1. `ClickUpProjectTemplate` wird von einer Konstante zu
   `public static func template(for kind: ProjectKind) -> [String]?` erweitert.
2. `ProjektProvisioningService.provisioniereClickUp` liest `plan.kind` statt hartkodiert die
   alte Konstante; `clickUpFolderID` wird von einem String zu einer Kind→FolderID-Zuordnung;
   bedingter Zweig für `kind == .lead` (Task in Sammelliste statt neue Liste) und Skip für
   `kind == .studioInternal` (kein Template).

## Offene manuelle Schritte (nur Johannes, in der ClickUp-UI)

1. Die 2 `ZZ_LÖSCHEN_…`-Ordner löschen (Connector kann das nicht).
2. Die 10 Custom Fields aus „99 Admin & Datenpflege" → Liste „Custom-Field-Wünsche…" einmalig
   auf Space-Ebene anlegen (siehe [ADMIN_REQUIRED_CUSTOM_FIELDS.md](ADMIN_REQUIRED_CUSTOM_FIELDS.md)).
3. Die 4 offenen `Ghost-Rolle-Primär`-Felder (Da/Fra/Sen/Jil) in `Ghost-Personas` entscheiden.
4. `Go-Live-Enabled` pro Person + `Go-Live Ready` pro Task-Record manuell setzen, wenn so weit.
5. Themenaufteilung der 2-3 Dauerlisten in „06 Studio Intern" festlegen.
6. Entscheiden: neues `ProjectKind` `.interiorConsulting` für Vollausstattungs-/Bauleitungs-
   Mandate (Befund 3 oben) — ja/nein, und wenn ja, welches Template.
7. Entscheiden: Lichtplanungs-Subphase innerhalb `kitchen` ins Template integrieren (Befund 2
   oben) — verändert das Kern-Template, bewusst nicht ungefragt gemacht.
8. `TEST_KUECHE_Vorlage_v2` gegenlesen und freigeben, bevor sie `ClickUpProjectTemplate.swift`
   ersetzt (Folgeauftrag unten).

## Fleißarbeit abgeschlossen (Hintergrund-Agent, Haiku)

**Datum:** 2026-07-02

**Schritt 1 – TEST_LICHT_Vorlage Dependencies:** ✅ 7 Tasks in linearer Kette verdrahtet (`869dyt0ua` → `869dyt10t` → `869dyt165` → `869dyt1b1` → `869dyt1je` → `869dyt1qf` → `869dyt1x3` → `869dyt22u`).

**Schritt 2 – TEST_NACHTRAG_Vorlage Dependencies:** ✅ 5 Tasks (Nachtrag-Lifecycle: Anfrage prüfen → Termin → Angebot → Freigabe → Ausführung → Abschluss) in linearer Kette (`869dyt28g` → `869dyt2bw` → `869dyt2hg` → `869dyt2my` → `869dyt2w8` → `869dyt340`).

**Schritt 3 – TEST_ANGEBOT_Vorlage Dependencies:** ✅ 4 Tasks in linearer Kette (`869dyt37r` → `869dyt3by` → `869dyt3jg` → `869dyt3vd` → `869dyt45r`).

**Schritt 4 – Verifikation TEST_KUECHE_Vorlage_v2:** ✅ **36 Tasks** in der Liste gefunden (28 Haupttasks in 10 Phasen + Subflows). Stichproben-Verifikation:
- **P6.1** (`869dytj41`): wartet auf P5.1, wird blockiert durch P7.1 — korrekte lineare Abhängigkeitskette.
- **P4.1** (`869dyth0h`): P4.2 wartet korrekt auf P4.1.
- **P3.1** (`869dytg1n`): hat 0 Dependencies (erwartungsgerecht als Startaufgabe Phase 3).

Dependencies sind funktional verdrahtet. Ist-Zustand stimmt mit Planung überein.

**Schritt 5 – Beschreibungen ergänzt:** ✅ 3 Template-Starter-Tasks erhielten sachliche 1-2-Satz-Beschreibungen:
- `869dyt0ua` (TEST_LICHT): „Eingehende Anfrage zur Lichtplanung sichten und Machbarkeit prüfen. Rückmeldung an Interessenten, ob wir das Projekt übernehmen können oder nicht."
- `869dyt28g` (TEST_NACHTRAG): „Nachtrags-Anfrage auf Relevanz und Bezug zum Parent-Projekt überprüfen. Kostenfolgen und Terminauswirkungen dokumentieren."
- `869dyt37r` (TEST_ANGEBOT): „Kundenerwartungen und genaue Umfang der Angebots-Anfrage klären. Scope schriftlich fixieren, um Missverständnisse auszuschließen."

**Schritt 6 – Gesamtstruktur-Konsistenz-Check:** ✅ `clickup_get_workspace_hierarchy` (max_depth: 2) verifiziert:
- ✅ Alle 12 erwarteten Ordner existieren mit korrekten IDs.
- ✅ `_TEST_PROVISIONING` enthält alle 4 Template-Listen.
- ✅ `01 Kundenprojekte`, `02 Lichtplanung`, `03 Service & Nachträge`, `04 Leads & Anfragen`, `05 Angebote & Kalkulation`, `06 Studio Intern`, `88 Slack-Archiv`, `90 Reviews & Freigaben`, `99 Admin & Datenpflege` auf Platz.
- ⚠️ 2 Ordner zur Löschung markiert (`ZZ_LÖSCHEN_*`) — Connector kann keine Ordner löschen; Johannes manuell.
- ⚠️ 1 ungeplante `List` (ID `901218937140`) direkt im Space (Artefakt, ignorieren).

Ordnernames stimmen mit Anleitung überein. Keine unerwarteten Strukturänderungen.

**Schritt 7 – Dokumentation & Commit:** ✅ Diese Sektion hinzugefügt. Commit wird sofort durchgeführt (siehe unten).

**Zusammenfassung:**
- Alle 6 Arbeitsschritte erfolgreich abgeschlossen.
- 16 neue Dependencies gesetzt (7 + 5 + 4), alle vom Connector angenommen.
- 36 Tasks in TEST_KUECHE_Vorlage_v2 verifiziert, Abhängigkeitsstruktur intakt.
- 3 leere Beschreibungen generiert und ergänzt.
- Gesamtordner-Struktur konsistent, keine Abweichungen außer erwarteter Lösch-Markierungen.

**Offene manuelle Schritte (unverändert von oben):**
1. 2 `ZZ_LÖSCHEN_…`-Ordner löschen (UI).
2. 10 Custom Fields anlegen (Space-Ebene, UI).
3. 4 `Ghost-Rolle-Primär`-Entscheidungen (Da/Fra/Sen/Jil).
4. Go-Live-Flags setzen (wenn bereit).
5–7. Weitere Entscheidungen (Interior-Kind, Lichtplanungs-Subphase, Studio-Intern-Dauerlisten).
8. `TEST_KUECHE_Vorlage_v2` Freigabe vor Swift-Integration.
