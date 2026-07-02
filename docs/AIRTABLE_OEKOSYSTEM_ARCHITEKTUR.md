# Airtable-Ökosystem-Architektur (Stand 2026-07-02)

Johannes' Ausgangsfrage: 24 Airtable-Bases mit Präfix `mykilOS_...` existieren, viele leer
oder unklar. Auftrag: sinnvoll befüllen, "Human-verständlich" führen, spätere Umbauten
mitdenken, eine Gesamt-Schaltzentrale für alle Daten-I/Os mappen — **aber nicht sinnlos
über viele Tabellen fächern.**

## Kernentscheidung: Es gibt bereits EINE Schaltzentrale — nicht neu bauen, nutzen

**`Datenstrom-Handbuch`** (Base `mykilOS Mastermind`, `appuVMh3KDfKw4OoQ`, Tabelle
`tblaUVftka0GvXzeU`) ist bereits die zentrale, Eiserne-Regel-governte Wahrheit für JEDEN
App-Code-getriebenen Datenfluss — **48 echte Einträge**, exaktes Feldschema (Integrations-ID,
System, Richtung, Trigger, Status, Swift-Code-Pfad, Payload, Notizen, NO-GO, Opt-in, Frequenz).
Antwort auf "macht Fächern über viele Tabellen Sinn?": **Nein, für App-Code-I/O-Dokumentation
nicht — hier existiert bereits der eine Hub.**

**Gefundener und behobener Regelverstoß:** `CLICKUP_FRAGEBOGEN_PROJEKT_ANLEGEN` (Swift-Code
+ lokales `DatastromManifest.json` existierten bereits aus einer früheren Session) fehlte im
echten Airtable-Handbuch — Verstoß gegen die eigene Eiserne Regel "jede neue Daten-Weiche
sofort eintragen". Nachgetragen als Record `recXHiRB8I81nTIVA`.

**Selbstkorrektur:** Am selben Tag wurde versehentlich eine parallele, doppelte Struktur
gebaut — Tabelle "Schnittstellen (I/O)" in der neuen Base `mykilOS_Adapter ClickUp`
(`app5ab3FhXJRfNr8r`). Auf `deprecated` gesetzt (nicht gelöscht — Airtable-Records werden nie
gelöscht, nur inaktiviert), mit Verweis auf die echten Handbuch-Records. Einzige verbliebene
Zeile dort bleibt gültig: die Slack-Rekonstruktion (kein App-Code, daher korrekt NICHT im
Handbuch, sondern hier dokumentiert).

## Die tatsächlich sinnvolle Aufteilung (kein Wildwuchs, klare Zuständigkeiten)

| Base/Tabelle | Zweck | Warum NICHT im Datenstrom-Handbuch |
|---|---|---|
| `Datenstrom-Handbuch` (Mastermind) | JEDER App-Code-I/O-Fluss | — ist selbst der Hub |
| `mykilOS_TRESOR` → `Zugangsdaten-Registry` | Welches System braucht welchen Zugang (Keychain-Referenz, NIE der echte Wert) | Andere Fragestellung: Credential-Metadaten, nicht Datenfluss |
| `mykilOS_Projekte` → `Intake — Daniel-DB Zuordnung` | Übersetzungsschicht Daniels read-only Kunden-DB → mykilOS-Projektnummern, mit Warnstufen | Reine Datenabgleichs-/Reconciliation-Aufgabe, kein wiederkehrender Datenfluss |
| `mykilOS Mastermind` → `Datenqualität` (neu) | Sichtbare Duplikat-/Schema-Verstoß-Warnungen für Projekte | Warnungs-Ledger, kein I/O-Fluss — aber bewusst in Mastermind, nicht in einer 4. leeren Base |
| `mykilOS-Adapter Clockodo` | Bereits real live verdrahtet (`TimerStore.confirmBooking` schreibt hierhin) | Eigenständige funktionale Infrastruktur, kein Dokumentations-Duplikat |
| `mykilOS_Alerts News/Cash/Timelines` | **Bewusst nicht angefasst** — alle 3 sind identische, leere Airtable-Standardvorlagen ohne inhaltlichen Bezug zu ihrem Namen. Für Datenqualität ungeeignet (siehe oben). Wofür sie stattdessen gedacht waren: unklar, nicht geraten. | — |

## Airtable-Automationen: bewusst NICHT gebaut

Zwei unabhängige Gründe (per Workflow-Analyse verifiziert):
1. **Technisch:** Der verfügbare Airtable-MCP-Connector bietet ausschließlich Daten-CRUD
   (Bases/Tabellen/Felder/Records), kein Automation-Tooling. Native Automationen wären nur
   manuell in der Airtable-Web-UI baubar.
2. **Architektonisch:** Verstößt gegen "Signale sind VORSCHLÄGE... Schreiben nur über
   Action-Card → Bestätigung → Audit" — auch eine Benachrichtigung nur an Johannes selbst wäre
   ein impliziter Nebeneffekt ohne Bestätigungs-Gate. Alerts/Warnungen bleiben rein passiv
   sichtbar (nur wenn die Tabelle aktiv geöffnet wird), kein E-Mail-/Slack-Versand, kein Trigger.

## Intake — Daniel-DB Zuordnung: Ergebnis der Erstbefüllung (11 Records)

3 eindeutig (sauberes `JJJJ_NNN_Kunde`-Muster + ClickUp-ID): Wobig, Mohadjer, Schmidt.
8 mit Warnung, davon 2 von Johannes am 2026-07-02 aufgelöst (Vinahl/Neurologie Ütersen =
EIN reales Projekt, `2026_004_Neurologie_Uetersen_GRO50` — Vinahl kanonisch, Uetersen
verworfen). 6 bleiben offen (2× Verdacht interner/Test-Eintrag, 1× Verdacht Testdaten,
3× kein Nummernmuster) — siehe Tabelle `Datenqualität` in Mastermind für den aktuellen Stand.

**Grundsatz, der für jede künftige Erweiterung gilt:** nie automatisch übernehmen, nie
Fuzzy-Match, nie erfinden was nicht in den Quelldaten steht. Jede Unklarheit wird als
sichtbare Warnung geführt, nicht still aufgelöst.
