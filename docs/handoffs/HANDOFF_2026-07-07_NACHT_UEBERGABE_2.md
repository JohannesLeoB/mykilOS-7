# 🏁 Handoff — Nacht-Session Fortsetzung 2026-07-07 (~00:10–02:50 Uhr)

```
Pfad:   /Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilOS Mac/
Branch: feat/multi-user-login (NICHT nach main gemergt)
Build:  ✅ swift build grün
Tests:  ✅ 1213 Tests grün (157 Suites)
Lint:   ✅ 0 Verstöße gegen swiftlint-baseline.json
DMG:    dist/mykilOS-11.1.0-alpha16.dmg (frisch gebaut, an Johannes geschickt)
Datum:  2026-07-07 ~02:50 Uhr
```

Diese Session hat direkt an [HANDOFF_2026-07-07_NACHT_UEBERGABE.md](HANDOFF_2026-07-07_NACHT_UEBERGABE.md)
angeknüpft (dessen "🔴 OFFEN — genau hier weitermachen"-Abschnitt war der Startpunkt) und ist
non-stop bis zu diesem sauberen Abschluss weitergelaufen.

## ⚠️ ZUERST LESEN (Maxime #1, unverändert)

1. `pwd` + `git remote get-url origin` MUSS `mykilOS-macOS` enthalten — sonst SOFORT STOP.
2. Nur absoluter Pfad, nie cwd-relativ.
3. Volle Regeln: `KOORDINATEN.md` + `CLAUDE.md`.
4. Kein main-Push/-Merge ohne Johannes' explizites GO. Feature-Branch-Commits + Push auf
   denselben Branch sind ok (in dieser Session so gemacht, auf explizite Anweisung).

## Was diese Session gebaut wurde (9 Features + 2 Doku-Korrekturen, alle grün+getestet+gelintet)

1. **Private Aufgaben — Fälligkeit + Alarm + Bearbeiten** (`b10a6d8`) — schloss Teil 1 der
   Vornacht ab: Datum/Zeit-Picker, Alarm-Toggle beim Anlegen, Edit-Sheet, echte macOS-
   Benachrichtigung (`TaskAlarmScheduler`, `UNUserNotificationCenter`). Neue Tests für die
   ID-präzisen Store-Methoden (update/setDone/delete) + Cold-Start-Beweis für `alarmAktiv`.
2. **ClickUp-Aufgaben-Spalte 2** (`acb0f93`) — projektübergreifende, rein lesende ClickUp-
   Ansicht in `AufgabenKatalogView` (Quellen-Toggle Privat/ClickUp). Filter: Meine/Alle,
   Projekt, Prio (4 native ClickUp-Stufen), nur mit Fälligkeit. Modell-Erweiterung
   `ClickUpTask.assigneeID` (für "meine Aufgaben" — der bisherige Username reichte dafür
   nicht) + volle `ClickUpPriority`-Granularität.
3. **Nachfass-Erinnerung** (`41d00ff`) — ehrlicher Alters-Hinweis in "Alle Angebote" →
   Ausgehend: "seit X Tagen ohne Aktivität". Bewusst NICHT als "keine Reaktion bestätigt"
   verkauft — es gibt kein echtes Reaktions-Signal, nur das Drive-Änderungsdatum.
4. **"Bitte reagieren"-Hinweis** (`d5b592b`) — Gegenrichtung zu 3: eingehende Belege ohne
   eigene Aktivität, eigener Toggle + eigene Tages-Schwelle.
5. **"Neue Werkzeichnung"-Alert** (`f41c091`) — neues `WidgetSignal.drawingDetected`, eigenes
   Schlüsselwort-Set ("zeichnung"/"werkzeichnung") in `DriveOfferWatcher`, NICHT in die
   bestehenden `offerKeywords` gemischt (hätte das Cash-Widget-Signal verwässert).
6+7. **VWPlankopfPort v1+v2** (`3fd6f94`, `9bb0570`) — Johannes-Auftrag: CheckoutPort für
   Vectorworks-Planköpfe (Kunde/Projekt/Material/Geräte/Ausstattung/Beschläge). v2 hat das
   Feld-Vokabular an Johannes' ECHTE Vectorworks-Exporte geerdet (read-only Recherche in
   `~/Desktop/Icloud desktop/vectorworks/exporte/`: `Custom.csv`, Häfele-Beschläge-Liste) —
   Projekt-Nr./Bauvorhaben/Kommission/Position/Artikel/Bezeichnung/Lieferant/Menge/
   Einzelpreis/Gesamtpreis. **Ehrliche Grenze bleibt:** `.vwx`/`.sta` sind reine Binärdateien
   ohne auslesbare Klassen-/Records-Namen — das echte Vectorworks-Titelblock-Zielformat ist
   NICHT verifiziert (Referenz-Screenshot von Johannes steht noch aus). Liefert bewusst nur
   einen Text-Entwurf, keine Vectorworks-native Ausgabe. Noch keine UI-Verdrahtung (wie die
   Geschwister-Ports DokumentPort/MoodboardPort auch).
8. **Echte Mac-Mitteilungen für Signale** (`5cc9b54`) — `SignalNotificationDispatcher`
   (gleiches `UNUserNotificationCenter`-Muster wie TaskAlarmScheduler): sofortige lokale
   Mitteilung für `offerDetected`/`drawingDetected`. Gilt NUR für den Mac — Handy-Zustellung
   bräuchte eigene Infrastruktur (Pushover/ntfy.sh-Relay o.ä.), bewusst nicht gebaut
   (Johannes-Entscheidung offen).
9. **Assistent-Tagebuch** (`2331acb`) — S10_WIRBELSAEULE §9, Parallel-Track: statt Code
   selbst zu editieren (verworfen, "zu dünnes Eis"), schreibt der Assistent bei
   Friktionspunkten (kann etwas nicht lesen/Widerspruch/fehlende Info) einen Eintrag ins
   append-only `AssistantTagebuchStore` (gleiches Muster wie `AuditStore`, NICHT per-User
   isoliert). Neues Chat-Tool `log_friction_point`. Noch keine UI-Leseansicht.
- **Doku-Korrekturen:** Datenschutz-Settings-Sektion war schon gebaut (nur Backlog veraltet),
  "Bestätigung per natürlichem Befehl" war ebenfalls schon vollständig gebaut (`950d442`) —
  beide Male per Code-Verifikation korrigiert statt blind neu gebaut.

DMGs alpha8 bis alpha16 gebaut (9 Stück, jede ~alle 30-40 Min wie gefordert). **alpha16 ist der
aktuelle Stand** — an Johannes geschickt.

## 🔴 Ehrlich offen — braucht Johannes' Entscheidung/Input, nicht mehr Code

1. **Live-Check aller 9 Features durch Johannes** — Build/Test/Lint sind Proxy, kein Beweis
   (eiserne Regel). Besonders die Aufgaben-Alarme (feuert der echte macOS-Alarm wirklich zur
   Fälligkeit?) und der ClickUp-Tab (echte Daten, echte Filter) verdienen einen Live-Blick.
2. **Datenschutz-Onboarding-Screen** — Settings-Hälfte ist gebaut, Onboarding-Hälfte fehlt
   weiterhin. Braucht Johannes' Wortlaut/Freigabe für Rechtstexte (kein Kandidat für
   unbeaufsichtigten Automode).
3. **Vectorworks-Referenz-Screenshot** — Johannes hatte einen angekündigt (Feedback-Ordner),
   lag beim Bau von VWPlankopfPort noch nicht vor. Sobald da: Format in
   `Sources/MykilosApp/Wirbelsaeule/Ports/VWPlankopfPort.swift` nachziehen.
4. **Handy-Push-Zustellung** — drei Wege (Pushover/ntfy.sh-Relay, CloudKit+iOS-App, eigene
   APNs), Johannes muss den Einstieg wählen.
5. **ClickUp-Schreib-/Signal-Integration (Aufgaben-Spalte 3)** — von Johannes selbst als
   "nächste große Session" vorgemerkt (Ghost-Persona-Regel beachten, nur Johannes' Ghost →
   echt). Bewusst NICHT in dieser Nacht angefasst.
6. **Dubletten-Zusammenführung realer Projekte** (z. B. Vinahl + Uetersen) — braucht Johannes'
   Urteil, welche echten Projekte tatsächlich Duplikate sind.
7. **Datei-/Screenshot-Upload → Bild-Analyse + Action-Vorschläge** — bräuchte neue Action-
   Card-Typen (z. B. Maps/Route) + sorgfältiges Vision-Klassifikations-Prompt-Design, Risiko
   falscher Vorschläge bei zu schnellem Bau. Bewusst zurückgestellt.

## Technische Lektionen dieser Session

- **Subagent-Berichte nie blind übernehmen** — mehrfach lohnte sich das Gegenlesen im echten
  Code (ein Bericht widersprach sich sogar selbst: "Barcode-Scanner existiert bereits" UND
  "ist noch zu bauen" im selben Report).
- **Vor jedem Scoping-Agent erst selbst grep(pen)**, ob die Backlog-Idee nicht schon (ganz
  oder teilweise) im Code existiert — hätte bei "Bestätigung per natürlichem Befehl" einen
  kompletten Scoping-Durchlauf gespart.
- **SwiftLint-Baseline-Zeilenshift** (aus der Vornacht) trat wieder mehrfach auf — Standard-
  Fix bleibt: `swiftlint lint --strict --write-baseline swiftlint-baseline.json.new --quiet`,
  neue Treffer manuell gegen `git diff` prüfen (eigener Code vs. verschobene Altlast), dann
  `mv` + Re-Verify mit `--baseline`.
- **`#require` ist ein Macro, keine Funktion** — verschachtelte `#require(...try #require(...))`
  scheitern mit "recursive expansion". Immer in zwei Zeilen aufteilen.

## Kanonische Kommandos

```bash
cd "/Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilOS Mac"
swift build && swift test 2>&1 | tail -10
swiftlint lint --strict --baseline swiftlint-baseline.json --quiet
```

## Vibe

Sehr produktive, disziplinierte Nachtsession (9 echte Features, 2 Doku-Korrekturen nach
Code-Verifikation statt blindem Vertrauen). Mehrere Ideen bewusst NICHT gebaut, weil sie
entweder externe Eingaben brauchten oder zu risikoreich für unbeaufsichtigten Bau gewesen
wären — kein hohles "erledigt" erzwungen. Session endet sauber auf Wunsch, nicht wegen
Kontextfenster-Druck.
