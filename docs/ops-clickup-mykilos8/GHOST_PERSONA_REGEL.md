# Eiserne Regel: Ghost-Personas statt echter ClickUp-Nutzer

**Verankert: 2026-07-02, Johannes (verbindlich für JEDEN Agenten — Claude, Codex, jede Session).**

## Die Regel (verbatim)

> Eiserne Regel: nur in mykilOS API Testspace anlegen und arbeiten. Aufgaben erstellen aber
> zunächst an Dummy-User wie Jo / Da / Fra / Sen / Jil oder andere vergeben. Stumme Dummy-Personas
> ablegen, die erst später mit den realen Usern gekappt und direkt verdrahtet werden.
> Keine Aufgaben- oder Termin-Writes an echte ClickUp-Nutzer. Nur simulieren mit Dummy-Avataren,
> die aber jeweils als Ghost des Nutzers gelten. Keinerlei echte externe Notifikation senden.

## Was das konkret heißt

1. **Nur der Space „MYKILOS API TESTSPACE" (`90128024109`)** — kein anderer ClickUp-Space,
   keine andere externe Umgebung, wird angelegt oder beschrieben.
2. **Niemals eine echte ClickUp-Assignee-ID setzen** (die 5 echten Workspace-Mitglieder:
   Johannes Leo Berger `99729772`/johannes@, Daniel Klapsing `296479146`/dk@, Frauke Fudickar
   `296476295`/ff@, Jilliana Bahr `248493812`/jb@, Sebastian Enders `99729773`/sen@) — ClickUps
   native `assignees`-Feld löst bei einer echten Person eine ECHTE Benachrichtigung aus
   (App-Push/E-Mail je nach deren Einstellungen), unabhängig davon, ob die Aufgabe „nur ein Test"
   ist.
3. **Ghost-Persona-Konvention:** Kürzel `Jo` (Johannes), `Da` (Daniel), `Fra` (Frauke), `Sen`
   (Sebastian), `Jil` (Jilliana) — stehen für „diese Aufgabe würde später an diese reale Person
   gehen", sind aber KEINE ClickUp-Accounts. Simulierte Zuweisung geschieht ausschließlich als
   **Klartext-Marker in der Task-Beschreibung** (`markdown_description`), z. B.:
   `Ghost-Zuweisung (simuliert, NICHT real): Jo` — niemals über das native `assignees`-Feld,
   niemals über Custom Fields, die an echte User-IDs gebunden sind.
4. **Keine Fälligkeitsdaten in Kombination mit einer echten Zuweisung.** Ein Fälligkeitsdatum
   ohne Assignee ist unkritisch (kein Empfänger für eine Erinnerung); die Kombination
   „echter Assignee + Datum" ist der eigentliche Auslöser für externe Benachrichtigungen und
   deshalb tabu.
5. **Keinerlei echte externe Notifikation** — die Regel ist NICHT auf ClickUp beschränkt. Sie
   gilt sinngemäß für jedes System in diesem Studio-OS-Umbau: keine echten Kalender-Einladungen,
   keine echten Mails/Slack-Nachrichten an reale Empfänger, solange ein Vorgang als Simulation/
   Testaufbau gekennzeichnet ist.
6. **Umschaltpunkt:** Ghost-Personas werden erst „gekappt und direkt verdrahtet" (also mit den
   echten ClickUp-Accounts verbunden), wenn Johannes das ausdrücklich freigibt. Das ist ein
   bewusster, separater Schritt — niemals ein Nebeneffekt eines anderen Features.

## Vorfall + Korrektur (2026-07-02, dokumentiert zur Nachvollziehbarkeit)

Vor Verankerung dieser Regel wurden in dieser Session 3 Tasks der Test-Liste
„KUE-2026-014 Küche Müller TEST" (Ordner „01 Kundenprojekte", `901218940344`) versehentlich mit
dem ECHTEN Assignee Johannes (`99729772`) + Fälligkeitsdatum beschrieben:
`Lead / Anfrage qualifizieren` (fällig 2026-06-20 — **zum Korrekturzeitpunkt bereits überfällig,
eine echte Benachrichtigung kann vor der Korrektur bereits ausgelöst worden sein**),
`Aufmaß / Termin vorbereiten` (2026-07-04), `Planung starten` (2026-07-11). Eine vierte
Zuweisung (`Briefing prüfen`) wurde vom Claude-Code-Sicherheits-Layer automatisch blockiert
(„Auto Mode Classifier") — kein Schaden dort.

**Korrektur:** Alle 3 Tasks wurden sofort auf `assignees: []` + `due_date: none` zurückgesetzt
(verifiziert). Der neu gebaute Studio-OS-ClickUp-Code (`ClickUpProjectTemplate`,
`ProjektProvisioningService.provisioniereClickUp`, `AppState.provisioniereEchtesProjekt`
ClickUp-Block) setzte zu keinem Zeitpunkt Assignees — dieser Teil war nie betroffen.

## Für Code (wenn Task-Zuweisung je gebaut wird)

Sollte ein künftiger Schritt Aufgaben Rollen/Personen zuordnen (z. B. aus dem Studio-OS-Handoff
§8, Standardrolle je Task), MUSS das über die Ghost-Persona-Textkonvention laufen — niemals über
`assignees` mit einer echten ID, bis Johannes die Verdrahtung freigibt. Ein Custom Field
`simulated_assignee` (Dropdown Jo/Da/Fra/Sen/Jil) wäre der sauberere Zielzustand, ist aber
aktuell nicht anlegbar (siehe [ADMIN_REQUIRED_CUSTOM_FIELDS.md](ADMIN_REQUIRED_CUSTOM_FIELDS.md)).
