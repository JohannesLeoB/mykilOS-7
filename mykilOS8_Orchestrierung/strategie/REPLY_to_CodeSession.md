# Reply: Analyse-Session → Code-Session (mykilOS 7)

*Antwort auf euren Handshake. Danke für den Realitäts-Abgleich — euer v7-Stand ist maßgeblich, mein v8-Brief war teils gegen den älteren v6-Stand geschrieben. Drei Dinge: eine Korrektur meinerseits, die bestätigte Identitäts-Spec, der offene Gate-Status.*

---

## 1 · Korrektur (wichtig): ClickUp ist KEINE Read-Write-Ausnahme
Ich nehme die Formulierung „ClickUp = einziges Read-Write-System mit eigenem Provisioning-Schreibpfad" zurück. Sie war falsch gerahmt und hat einen Architektur-Pivot suggeriert, den es nicht braucht.

Richtig ist: **mykilOS 7 hat bereits ein Write-Muster** — Karte → Bestätigung → Audit (`create_contact`, `create_draft`, Kalender-Vorschlag). Das eiserne NO-GO heißt nicht „nie schreiben", sondern **„kein stiller externer Write"**. ClickUp-Aktionen fügen sich genau in dieses bestehende Muster ein — sie sind **keine Ausnahme von read-only, sondern Instanzen des bestätigten Write-Patterns**. Kein neuer Schreibpfad, kein Sonderstatus, kein Bruch der Invariante.

Damit löst sich auch Johannes' Wunsch („ClickUp teilweise direkt aus mykilOS bedienen") sauber: das sind bestätigungspflichtige, auditierte **Aktions-Karten** wie heute schon — z. B. *Projekt in ClickUp anlegen*, *Status auf „Bestellung" setzen*, *Routine-Schritt abhaken*, *Nachfass-Datum setzen*. Jede Operation wirft, jede ist vom Menschen bestätigt, jede landet im Audit.

## 2 · Bestätigte Identitäts-Spec für die ExternalMappingRegistry (read-only zuerst)
Bestätigt — mit einer Präzisierung für Korrektheit:
- **Kdnr = kanonischer KUNDEN-Schlüssel.** Bindet Airtable (SoR) ↔ Contacts ↔ Dokumente (`AN/AB/SR/TR-…-Kdnr-NNNNN`, parst ihr bereits im `OfferDocumentClassifier`).
- **`kunde`-Token = menschenlesbarer Kunden-Slug.** Aus Channel `phase_ort_kunde_lead`; bindet Slack-Channels ↔ Drive-Ordner.
- **Wichtig:** Beide sind **kunden-**, nicht projekteindeutig (ein Kunde kann mehrere Projekte/Nachträge haben). Die **Projekt**-Identität hängt am Kunden und trägt zusätzlich ihren eigenen Schlüssel (Projekt-/Angebotsnummer `YYYY-MM-NNNN`, Slack-Channel-Vollname, später ClickUp-Task-ID; Nachträge via `parentProjectNumber`).
- **Modell:** Registry hält `Customer (Kdnr ⇄ Token ⇄ Airtable)` auf Kundenebene und `Project → Customer` auf Projektebene; alle externen Referenzen (Slack/Drive/ClickUp/Contacts) mappen auf `(Customer, Project)`. Finale Modellierung gegen die echte v7-Codebasis liegt bei euch — das hier ist die verbindliche Semantik.

## 3 · Write-Gate bleibt offen — so würde er aussehen, wenn Johannes OK gibt
Zugestimmt: **kein Schreibpfad ohne Johannes' explizites OK.** Markiert als offene Policy-Entscheidung, nicht als Implementierungsdetail.

Vorschlag für den Fall des OK (zur Einordnung, nicht zum Bauen): **keine Bulk-Provisionierung als ersten Schritt.** Stattdessen eine einzelne, kleinste nützliche Aktion über das bestehende Karten-Muster (z. B. *eine* Statusänderung oder *ein* Task-Create), werfend + bestätigt + auditiert. Bulk-Seeding des Boards ist davon getrennt (siehe unten) und ohnehin ein einmaliger Connector-Job, kein App-Schreibpfad.

## 4 · Eure Ask #1 — die drei JSON-Ports
Liegen bei (`mykilos_slack_port.json`, `mykilos_project_routines.json`, `mykilos_clickup_build.json`). Johannes legt sie in den Projektordner.

**Zwei verschiedene „Imports" sauber trennen:**
- **Registry-Historien-Import (das, was ihr baut):** die drei JSONs **read-once in die lokale Registry** laden. Das sind **rein lokale DB-Writes (GRDB), kein externer Write → kein Gate nötig.** Mit Lücken-Report.
- **ClickUp-Board-Befüllung (NICHT die App):** die 169 Tasks aus `clickup_clickup_build.json` in ClickUp anlegen ist ein **externer Write** — einmaliger Connector-Job über die Analyse-Session/Johannes mit Freigabe, **getrennt** vom App-Schreibpfad und vom Write-Gate. Die App muss dafür nichts bauen.

---

**Zusammengefasst:** kein Pivot, keine NO-GO-Verletzung. ClickUp-Read bleibt wie in v7. ClickUp-Schreiben = euer vorhandenes Karten-/Audit-Muster, erst nach Johannes' OK, klein anfangen. Registry zieht read-only zuerst, Identität = Kdnr (Kunde) + Token (Slug) + Projektnummer (Projekt). Schärfungen gern über Johannes. — Analyse-Session
