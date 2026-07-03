# Slack-Rekonstruktion Pilot: Döhle (`2024_007_Doehle`)

**Status: Signal-Extraktion abgeschlossen. ClickUp-Schreibschritt BLOCKIERT (Connector nicht autorisiert).**

Quelle: Slack-Kanal `p_hh_doehle_dk`, Export-Zeitraum 2025-01-02 bis 2026-04-20,
185 Rohnachrichten, 170 mit Text, konsolidiert zu 398 Zeilen
(`docs/ops-clickup-mykilos8/SLACK_RECONSTRUCTION_PLAN.md` §4 folgend).

Ziel-Ort (sobald ClickUp wieder erreichbar): Ordner **„88 Slack-Archiv (historisch)“**
im Testspace `90128024109`, Liste **`2024_007_Doehle`**
(Beschreibung: „Rekonstruiert aus Slack-Archiv (Kanal `p_hh_doehle_dk`), historisch,
keine Live-Synchronisation“).

## Warum blockiert

Der ClickUp-MCP-Connector (`plugin:productivity:clickup`) verlangt in dieser Session
eine Autorisierung, die in einer nicht-interaktiven Umgebung nicht durchführbar ist.
Vor dem letzten Kontext-Kompaktierungspunkt hatte ich noch Zugriff (siehe frühere
Ghost-Persona-Vorfall-Dokumentation) — jetzt ist die Verbindung offenbar abgelaufen
oder session-gebunden. **Johannes muss den Connector neu autorisieren** (via
`claude mcp` bzw. `/mcp` in einer interaktiven Session), bevor der Schreibschritt
unten ausgeführt werden kann.

## Signal-Extraktion (Beweisgrad je Fund: stark/mittel/schwach/konflikt)

Methodik gemäß `SLACK_RECONSTRUCTION_PLAN.md`: Aufgaben-Muster, Blocker,
Status/Meilenstein, Finance, Akte/Datei-Signal — nie ein Signalwort blind als
Task übernommen, nur explizite, im Kontext eindeutige Befunde.

| # | Datum(-spanne) | Aufgabe/Meilenstein | Beweisgrad | Ghost-Zuordnung (Text, NIE Assignee-Feld) | Vorgeschlagener Status |
|---|---|---|---|---|---|
| 1 | 2025-01-02 | Edelstahl-Schraube (Probolt) fürs Studio bestellen, Kommission Döhle | stark | Jo | Erledigt |
| 2 | 2025-01-02–01-07 | Abschlagsrechnung Bato — Zahlungserinnerung an Kunde | stark | Jo/Da | Erledigt |
| 3 | 2025-01-03–02-12 | Silikon Gästebad-Duschnische erneuern (Bartels) | stark | Fra | Erledigt |
| 4 | 2025-01-06 | THG-Heizkörper im Studio abholen | stark | Fra | Erledigt |
| 5 | 2025-01-06–03-11 | Perlatoren bei THG bestellen (mehrere Nachbestellungen) | stark | Fra/Jo | Erledigt |
| 6 | 2025-01-08–11-14 | Liebherr-Kühlschrank: fehlende Abdeckung, Lieferverzögerung, Reparatur/Wasserschaden-Service | stark | Da/Sen | Erledigt |
| 7 | 2025-01-15 | Gessi-Drückerplatte — Lieferverzögerung, Update abwarten | mittel | Fra | Offen (kein Abschluss im Kanal sichtbar) |
| 8 | 2025-01-15 | Kühlschrankfilter bestellt | stark | Fra | Erledigt |
| 9 | 2025-01-16 | Große Mängelliste zu Rechnungen 0409/0408/0412 (Löcher, Blendrahmen-Kosten, Verfugung, Barschrank-Befestigung, Kühlschranktür, Kühlschrankblende, Einzelteile) — mit Punkt-für-Punkt-Zuordnung an Gewerke | stark | Jo/Sen | Erledigt |
| 10 | 2025-01-27–02-11 | Vor-Ort-Termin koordinieren (Malte/Bahadir/Mathias/Jost) — mehrfach verschoben, krankheitsbedingt abgesagt, neu auf 21.02. gelegt | stark | Jo/Da | Erledigt |
| 11 | 2025-02-12 | Strukturierte Arbeitsliste (Rakete/Bato/Bartels) — 16 Rakete-Punkte, 2 Bato-Punkte, 3 Bartels-Punkte | stark | Jo/Sen/Fra | Erledigt |
| 12 | 2025-02-12–10-21 | Kühlschranktüren gleichzeitig öffnen — wiederkehrendes ungelöstes Problem | stark | Sen | Offen (über Monate wiederkehrend, kein Abschluss belegt) |
| 13 | 2025-02-17 | Nachgang-Mängelliste (2. große Beschwerde Jost): Spüldruck, lockere Duscharmaturen, Handbrausenschlauch, Handbrause Masterbad, Waschtischarmaturen, schiefe Betätigungsplatte, Lackkanten Küche | stark | Jo/Sen | Erledigt |
| 14 | 2025-02-17–03-17 | Brauseschlauch bestellen (Dornbracht/Keuco, mehrere Passform-Iterationen) | stark | Jo/Sen | Erledigt |
| 15 | 2025-02-18 | Antwortmail an Jost mit vollständigem Sanitär-Status | stark | Da | Erledigt |
| 16 | 2025-02-24 | Rückmeldung zu Einzelpunkten (WC-Sitz, Handbrause, Drossel, Betätigungsplatte, UP-Teile, Brauseschlauch-Alternative) | stark | Jo | Erledigt |
| 17 | 2025-02-19–05-09 | Malte: Fronten-Nachbesserung (Demontage, Neulackierung, Montage) — mehrfach verschoben | stark | Jo/Da | Erledigt |
| 18 | 2025-04-02 | Krankosten-Beteiligung mit Decorazioni klären (strittig) | mittel | Sen | Offen (kein Abschluss belegt) |
| 19 | 2025-04-02 | Gefrierschubladenfront-Maße, Beschlag-Mangel, Fronten einstellen | stark | Sen | Erledigt |
| 20 | 2025-04-04–04-28 | THG-Reklamation Fleck auf Armatur-Auslauf — Kulanzangebot 471€ netto verschickt | stark | Fra/Da | Erledigt |
| 21 | 2025-05-20 | Neuer Mangel: Nägel schauen aus Barschrank-Rundung heraus | stark | — (nur gemeldet) | Offen |
| 22 | 2025-06-19–11-07 | **Eskalation:** Gewährleistungsstreit mit Rakete/Malte — Fugen erneut aufgeplatzt, Kühlschrankfront schleift erneut; Wechsel zu neutralem Gutachter-Tischler Gurali; Versicherungs-Schadensabwicklung vorbereitet | stark (konflikt) | Sen/Da | In Bearbeitung |
| 23 | 2025-11-07 | Großes Mängelbesprechungsprotokoll vor Ort (Jost, Bartels, Malte/Rakete, Branko Liptow/Likoo, Johannes Thilo/Gurali, Daniel) — vollständige Aufgabenliste je Gewerk (Rakete/Likoo/MYKILOS-Liebherr/Sanitär/Maler) | stark | Da | Erledigt (Protokoll) |
| 24 | 2025-11-11–11-14 | Liebherr-Reparaturtermin (Wasserschaden) durchgeführt | stark | Sen | Erledigt |
| 25 | 2025-11-26–12-08 | Handmuster für magnetische Türlösung gefertigt — Test negativ (Magnetkraft zu schwach) | stark | Jo | Erledigt (Ergebnis: Nacharbeit nötig) |
| 26 | 2026-01-19 | **Eskalationssignal:** Jost droht komplette Küche zu reklamieren | stark (konflikt) | — | Offen (Kundenbeziehung kritisch) |
| 27 | 2026-02-23–04-20 | Finaler Nachbesserungs-Zeitplan: Demontage 20.03., Montage 25.03., Übergabe 27.03.; Schlüsselübergabe 02.03.; Fronten-Besichtigung 26.03.; Malertermin (offen, „Malte meldet sich“) | stark | Sen/Da | In Bearbeitung (letzter Kanal-Eintrag, offen) |

**Bewusst nicht übernommen** (zu vage/reine Small-Talk-Nachfragen ohne eindeutigen
Task-Charakter): Wer ist „H. Mikifos“ (01-24, Scherzfrage), diverse reine
Terminbestätigungs-Pingpong-Zeilen ohne neuen Inhalt.

## Nächster Schritt (sobald ClickUp autorisiert ist)

1. Ordner „88 Slack-Archiv (historisch)“ in Testspace `90128024109` finden oder anlegen.
2. Liste `2024_007_Doehle` darin anlegen (Beschreibung wie oben).
3. Für jede Zeile der Tabelle einen Task anlegen: Name = Kurzform der Spalte
   „Aufgabe/Meilenstein“, Status wie vorgeschlagen, Ghost-Kürzel **nur als Text**
   in der Beschreibung (nie `assignees`-Feld), Datum aus Spalte 2 als Kontext in
   der Beschreibung (kein `due_date`-Fake, da historisch).
4. Row in Airtable `ClickUp-Ghost-Adapter` (`tblJvo4MNd1i1Xl2y`) für Traceability anlegen.
5. **Danach STOPPEN** — kein automatischer Übergang zu den übrigen 10 gematchten
   Projekten, erst Johannes' Review dieses Piloten abwarten (Format/Qualität/Umfang).
