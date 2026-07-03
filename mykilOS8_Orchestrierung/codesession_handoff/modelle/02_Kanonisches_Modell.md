# 02 · Kanonisches Modell — mykilOS 8

*Der Vertrag, gegen den jede Session baut. Knapp gehalten; Begründungen stehen in `strategie/`.*

## Identität
- **Kdnr** = kanonischer **Kunden**schlüssel (Airtable = System-of-Record, Contacts, Dokumente `AN/AB/SR/TR-…-Kdnr-NNNNN`; wird vom `OfferDocumentClassifier` bereits geparst).
- **`kunde`-Token** = menschenlesbarer Kunden-Slug (Slack-Channel `phase_ort_kunde_lead`, Drive-Ordner).
- **Projektnummer** `YYYY-MM-NNNN` = **Projekt**schlüssel; Nachträge via `parentProjectNumber`.
- Kdnr + Token sind **kunden**-, die Projektnummer ist **projekt**eindeutig. Die ExternalMappingRegistry mappt alle externen Referenzen (Slack/Drive/Airtable/ClickUp/Clockodo/Contacts) auf `(Customer, Project)`.

## Schreib-Disziplin
- Externe Quellen sind **read-only**. Writes ausschließlich über **Karte → Bestätigung → Audit** (bestehendes 7.x-Muster: `create_contact`, `create_draft`, Kalender-Vorschlag). **Jeder Write wirft.** ClickUp/Clockodo/Airtable-Writes sind Instanzen dieses Musters, keine Ausnahme.

## Zeiterfassung
- **Ein** globaler Timer-Zustand in der lokalen DB: `aktiverTimer = {Projekt, Kostenstelle, Start}` oder leer. **Nie zwei gleichzeitig.**
- **Pause** hält die Uhr (Slot bleibt belegt), **Stopp** beendet das Segment (Slot frei).
- **Buchen = doppelte Bestätigung** (Übersichts-Karte → expliziter zweiter „Ja, buchen").
- **Puls-Erinnerung:** Intervall in User-Settings (Default 60 Min, lokal pro Person). Ganze Sidebar pulsiert; Klick → minimaler Check-in.
- **Privater, lokaler Store pro Nutzer.** Upload nach Clockodo mit **nutzereigenem Key** (eigene Keychain), nie app-weit. Rücklauf **aggregiert/anonymisiert** je Kostenstelle/Projekt — nie personenbezogen.
- **Kostenstelle** kommt aus dem **Airtable-Projektfeld** (projektabhängig, 3–5 je Projekt) und mappt auf einen **Clockodo-Service**.

## Geld-Loop (Soll/Ist)
- **Soll**-Stunden aus der Sevdesk-Angebotsposition (`Order`/`OrderPos`, strukturiert — kein PDF-Parsing).
- **Ist** aus der anonymisierten Clockodo-Aggregation.
- **Verkaufsbalken in %** im Geld-Widget (Indigo), rollend; > 100 % → Coral.
- **Zielkontingent editierbar** mit Herkunfts-Flag (`auto`/`manuell`). Manuell **pinnt** — ein erneutes Sevdesk-Read überschreibt eine manuelle Korrektur nie.

## Status ↔ Phase (nur falls ClickUp/Phasen-Rail)
- Das 11-Phasen-Rail in der UI ist eine **Präsentationsschicht** über die ordner-bezogenen Status-Sets. Mapping-Tabelle: `strategie/MASTER_Orchestrierung_mykilOS_ClickUp.md`. **Routine = Checkliste, Aufgaben = Subtasks.**

## Farbsprache
Sage = Zeit/Menschen · Indigo = Geld · Ochre = Aufgaben/ClickUp · Terrakotta = Dateien · Plum = Notizen · Coral = Risiko (sparsam).
