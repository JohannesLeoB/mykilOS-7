# Ghost-Mode: Live-Airtable-Schema (angelegt 2026-07-02, 04:39 CEST)

Umsetzung von Johannes' Auftrag: „Alerts, Trigger etc an Airtable ClickUp-Adapter-Tabelle.
Lege diese nach deinem Bedarf an." + „Kreiere Avatare der realen Nutzer, teste und arbeite
mit diesen." Beide Tabellen liegen in der Mastermind-Base `appuVMh3KDfKw4OoQ`, direkt neben
den bestehenden Studio-OS-Tabellen (Kunden/Projekte/Kontakte/Datenstrom-Handbuch).

**Noch NICHT an App-Code angebunden** — reine Airtable-Struktur + Ghost-Persona-Seed-Daten.
Kein `dataFlow.log`-Aufruf existiert dafür, daher (bewusst) noch KEIN Eintrag im
Datenstrom-Handbuch (`tblaUVftka0GvXzeU`) — folgt, sobald echter App-Code liest/schreibt.

## Tabelle 1: `Ghost-Personas` (`tbl56f2arYm0ynrYx`)

Die „Avatare" der 5 realen Mitglieder — reine Rollen-Referenz, kein ClickUp-Account.

| Feld | Field-ID | Typ |
|---|---|---|
| Ghost-Kürzel (primär) | `fldR1W0ymi05DM8Zm` | singleLineText |
| Realer Name | `fldCQxiDvqc7rKlj7` | singleLineText |
| Ghost-Rolle-Primär | `fldr22A2TCwkJ3VDB` | singleSelect (9 Ghost-Rollen) |
| ClickUp-User-ID (Referenz) | `fldjYvaUrGYAzNrQ8` | singleLineText |
| Go-Live-Enabled | `fldZTekAoBFHKx0w8` | checkbox (alle 5 Seed-Rows: **false**) |
| Notification-Mode-Default | `fldGIOhzvFCGr3KEl` | singleSelect (silent/digest/live) |
| Notiz | `fldVakBJV9vARdeG0` | multilineText |

**Seed-Daten (5 Records, alle `Go-Live-Enabled=false`, `Notification-Mode-Default=silent`):**

| Ghost-Kürzel | Realer Name | ClickUp-User-ID | Ghost-Rolle-Primär |
|---|---|---|---|
| Jo | Johannes Leo Berger | 99729772 | GHOST_MYKILOS_ADMIN |
| Da | Daniel Klapsing | 296479146 | *(noch offen — nicht geraten)* |
| Fra | Frauke Fudickar | 296476295 | *(noch offen — nicht geraten)* |
| Sen | Sebastian Enders | 99729773 | *(noch offen — nicht geraten)* |
| Jil | Jilliana Bahr | 248493812 | *(noch offen — nicht geraten)* |

**Für Johannes offen:** die 4 fehlenden Primärrollen bestätigen (bewusst nicht geraten —
Rollenzuordnung ist eine echte Organisationsentscheidung, keine, die ich raten sollte).

## Tabelle 2: `ClickUp-Ghost-Adapter` (`tblJvo4MNd1i1Xl2y`)

Der myKilOS-seitige Adapter für simulierte ClickUp-Aufgaben/Meilensteine/Alerts/Trigger.

| Feld | Field-ID | Typ |
|---|---|---|
| Titel (primär) | `fldgniu0DiOZ72cvk` | singleLineText |
| Projekt | `fldqLWfJZvoet40F6` | multipleRecordLinks → `Projekte` (`tblGJR13OliFt6Ewi`) |
| Typ | `fldCv4moaBKUqXtdV` | singleSelect (Aufgabe/Meilenstein/Alert/Follow-up/Blocker) |
| ClickUp-Task-ID | `fldKCTNQRdbjZGXiY` | singleLineText |
| ClickUp-Liste-ID | `fldLJ9ushgcwtrIAA` | singleLineText |
| Ghost Owner Role | `fldI8ONvgi0bNOUtv` | singleSelect (9 Ghost-Rollen) |
| Ghost Review Role | `flddQPeIQEh61tPa1` | singleSelect (9 Ghost-Rollen) |
| Real Assignee Proposed | `fldr5cto0fBmveWLi` | singleLineText (Ghost-Kürzel, NIE echte ID) |
| Real Assignee Confirmed | `fldlHVT65s3QNUSFj` | singleLineText (Ghost-Kürzel, NIE echte ID) |
| Assignee Mapping Status | `fldQqgHb2bdRnfj6r` | singleSelect (unmapped/proposed/confirmed/live) |
| Notification Mode | `fldHot8bOAyYiqxb3` | singleSelect (silent/digest/live) |
| Go-Live Ready | `fldHmsuN1SCjtUI4n` | checkbox |
| Go-Live Gate Status | `fldR0MpW7Zl6iNZ8f` | singleSelect (blocked/review/ready/live) |
| Source System | `fldiwofPYPiitN9nR` | singleSelect (Slack/Drive/Airtable/myKilOS/manuell) |
| Source Confidence | `fld4N6xwOq4MWYbIP` | singleSelect (stark/mittel/schwach/Konflikt) |
| Source Evidence Link | `fldNg8IGHjgMg4OFo` | url |
| Drive Folder ID | `fldSueU545SkVnW0X` | singleLineText |
| myKilOS Entity ID | `fld1RUZP85CVEmIlj` | singleLineText |
| Simulation Batch | `fld1Y8T7uqxiiJp88` | singleLineText |
| Notiz | `fldczPGWStfiFoak6` | multilineText |
| Erstellt-am | `fldplueMTOK4QuuWL` | dateTime (Europe/Berlin) |

**Noch leer** (0 Records) — bereit für den Slack-Rekonstruktions-Piloten
(siehe [SLACK_RECONSTRUCTION_PLAN.md](SLACK_RECONSTRUCTION_PLAN.md)): jede rekonstruierte
Aufgabe/jeder Meilenstein sollte hier ZUERST als Ghost-Zeile entstehen (Source System=Slack,
Source Confidence gesetzt, Assignee Mapping Status=unmapped, Go-Live Ready=false), BEVOR die
entsprechende ClickUp-Liste/Task im Testspace angelegt wird — das Airtable-Feld
`ClickUp-Task-ID`/`ClickUp-Liste-ID` wird danach nachgetragen.

## Konsistenz mit der bestehenden Eisernen Regel

Beide Tabellen speichern AUSSCHLIESSLICH Airtable-interne Zustände. Kein Feld hier schreibt
jemals automatisch nach ClickUp — die tatsächliche ClickUp-Liste/Task-Anlage läuft weiterhin
über `ClickUpProjectProvisioning` (App-Code) bzw. den ClickUp-MCP-Connector, beides bereits
Ghost-Persona-konform (nie `assignees`, nur Testspace). Diese Tabellen sind die **Buchhaltung**
über den Simulationszustand, nicht ein neuer Schreibpfad nach außen.
