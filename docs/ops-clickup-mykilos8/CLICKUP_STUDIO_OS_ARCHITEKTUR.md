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
| `kitchen` | `TEST_{JJJJ}_{NNN}_{Kunde}[_{Code}]` | bestehendes 8-Task-Template (unverändert) | bereits live (KUE-2026-014) |
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
