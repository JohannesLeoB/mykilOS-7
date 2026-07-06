# 🏁 Handoff — Nacht-Session 2026-07-06/07 (Übergabe an neue/fremde Session)

```
Pfad:   /Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilOS Mac/
Branch: feat/multi-user-login (NICHT nach main gemergt — main ist Johannes' bewusste Entscheidung)
Build:  ✅ swift build grün
Tests:  ✅ 1171 grün (151 Suites)
Lint:   ✅ 0 neue Verstöße gegen swiftlint-baseline.json
DMG:    dist/mykilOS-11.1.0-alpha7.dmg (frisch gebaut, Rauchtest bestanden)
Datum:  2026-07-07 ~00:10 Uhr
```

## ⚠️ ZUERST LESEN (Maxime #1, nicht verhandelbar)

1. `pwd` und `git -C "<pfad>" remote get-url origin` MUSS `mykilOS-macOS` enthalten — sonst SOFORT STOP.
2. Nur absoluter Pfad, nie cwd-relativ (Session-cwd kann fälschlich auf `mykilOS iOS` zeigen).
3. Volle Regeln: `KOORDINATEN.md` + `CLAUDE.md`.
4. **Kein main-Push/-Merge ohne Johannes' explizites GO.** Feature-Branch-Commits + Push auf denselben Branch sind ok.

## Wörtliche MAXIME von Johannes (gilt weiter, bis er "stopp" sagt)

> Arbeite weiter, ohne zu stoppen und ohne auf Freigabe zu warten, auch über Session-/Kontext-/
> 5h-Limit-Unterbrechungen hinweg. "Nie stoppen" heißt "nächste Aufgabe suchen", NICHT
> "Sicherheitsregeln ignorieren". Alle 30-40 Minuten: frische DMG bauen, sichern, testen, weiter.
> Nutze Subagents, um das eigene Kontextfenster zu schonen. Stoppe NUR, wenn Johannes im Chat
> ausdrücklich "stopp" sagt.

**Standing NO-GOs (immer in Kraft):**
- Kein echter Drive-Write außerhalb der Test-Sandbox.
- Keine ClickUp-Schreibvorgänge außerhalb Testspace/Ghost-Personas, NIE echte Assignee-IDs
  (KI weist NIE Menschen zu — eiserne Regel, siehe CLAUDE.md "Aufgaben & Autorität").
- Keine echten externen Notifikationen an Dritte.
- Nie main pushen/mergen/force-pushen, nie Tag `v7.0.0` anfassen.
- Sevdesk nie lesen/schreiben. Airtable-Base `appdxTeT6bhSBmwx5` (Daniels Artikel-DB) nur lesen.
- Kein `git reset --hard`/`clean -f` ohne explizites GO.

## Technische Fallstricke dieser Session (spart Zeit!)

- **SourceKit-Diagnosen sind oft stale/falsch** ("Cannot find X in scope" direkt nach einem Edit,
  obwohl X existiert). Immer erst `swift build` laufen lassen und DAS Ergebnis glauben, nicht die
  Editor-Diagnose.
- **SwiftLint-Baseline "Zeilen-Shift"-Effekt:** jede Zeilen-Einfügung/-Löschung verschiebt
  nachfolgende Zeilennummern, wodurch `swiftlint-baseline.json` alte (längst akzeptierte)
  Verstöße nicht mehr matched → sie tauchen als "neu" auf. Fix jedes Mal: erst prüfen, ob es
  wirklich NEUER Code ist (git diff), dann `swiftlint lint --strict --write-baseline
  swiftlint-baseline.json.new && mv swiftlint-baseline.json.new swiftlint-baseline.json`.
- **Vor jedem "das ist noch offen laut Plan X"**: erst im Code selbst nachsehen, ob es nicht
  längst gebaut wurde. Diese Session fand mehrfach veraltete Pläne (Projekt-Status-Ableitung war
  schon gebaut, nur die Doku war alt).
- Cron-Job für Autonomie ist **session-only**, obwohl `durable: true` angefordert wird — das
  System bestätigt das explizit in der Antwort. Funktioniert nur, solange dieses Claude-Code-
  Fenster auf dem Mac offen bleibt (Mac darf nicht schlafen).

## Was diese Nacht gebaut wurde (13 Commits, alle grün+getestet+gelintet)

1. **Ordner-Schema editierbar** (Stufe 1: GRDB-Persistenz) + **Admin-Editor-UI** (Stufe 2)
2. **Mail-Anhang Unterordner-Drill-Down + Marker→Slot-Vorschlag**
3. **ClickUp-Status-Ableitung** — war schon gebaut, nur Doku korrigiert
4. **`.mykinvite` Admin-Einladung** (AES-verschlüsselt, Ebene 2 Onboarding-Plan)
5. **Google-Client-Secret-Einbacken** (Ebene 1 Onboarding-Plan, `script/.google-oauth.local.sh`)
6. **Aufmaß-Widget Laser-Adapter** (LaserMeasuring-Protokoll + CoreBluetooth-Grundgerüst,
   BLE-Service-/Characteristic-UUIDs ehrlich als Platzhalter markiert — echte Werte brauchen
   Zugriff auf das iOS-Satellit-Repo, den ich nicht habe)
7. **Datenschutz-Freigabe-Sektion** (Settings, UI-Gerüst, Entwurfstexte)
8. **Bugfix: Mail-Signatur fehlte im Assistenten-Versand** (echter, gemeldeter Bug)
9. **Mail-Nachrichten-Aktionen** (gelesen/Stern/Archiv/Papierkorb, `gmail.modify`-Scope)
10. **Live-Feedback-Runde (14 Screenshots, siehe unten) — 8 Punkte gefixt:**
    - Wortmarke zu klein → SVG-viewBox-Zuschnitt (war 16.8% Ink-Anteil, jetzt 91%)
    - Jiggle-Bug im Dateien-Tab → verschachtelte WidgetContainer-Hover-Scales entkoppelt
    - Header-Baseline auf 5 Hauptseiten vereinheitlicht (alle jetzt `MykSpace.s7`, wie Sidebar)
    - "Drive-Ordner noch nicht geprüft"-Leiste von JEDER Projektseite entfernt (war ein
      unvollständiger Cleanup von Item D, 2026-07-05)
    - Preis-Wissen als eigener Katalog-Tab (Default AUS, Opt-in — echtes Rollensystem fehlt noch)
11. **Aufgaben-Alarm-Fundament** (Spalte 1 von 3, siehe unten — **UNVOLLSTÄNDIG, nächster Schritt!**)

## 🔴 OFFEN — genau hier weitermachen

### Sofort (Task #11 fertig machen, halb gebaut)
`AssistantTasksStore`, `TaskAlarmScheduler`, `AssistantTask.alarmAktiv`, Settings→Mitteilungen
sind fertig+getestet. **Was fehlt:** `AufgabenKatalogTab` (`Sources/MykilosApp/KatalogeContentTabs.swift`,
Zeile ~600) braucht:
- Datum+Zeit-Picker beim Anlegen (`DatePicker` mit `.hourAndMinute`)
- Alarm-Toggle beim Anlegen
- Ruft `TaskAlarmScheduler.reschedule(_:)` nach create/update/setDone/delete auf
- Nutzt die neuen ID-präzisen Store-Methoden (`update(id:...)`, `setDone(id:...)`, `delete(id:...)`)
  statt der Fuzzy-Matching-Methoden (die bleiben für die Chat-Tools unverändert)
- Editier-Sheet für bestehende Aufgaben ("volle Editierbarkeit")

### Danach: Aufgaben-3-Spalten-System, Spalten 2+3
Aus Johannes' Original-Feedback (wörtlich):
> Neue zweite Spalte: ClickUp Aufgaben: Meine Aufgaben, alle Aufgaben, Aufgaben eines bestimmten
> Projektes, Aufgaben einer bestimmten Prio, Aufgaben einer bestimmten Fälligkeit.
> Dann 3. Spalte ClickUp Aufgaben erstellen, zuweisen an Person und/oder Projekt, Datum,
> Fälligkeit, volle ClickUp-Editierbarkeit... komplettes In-App-ClickUp-Aufgaben-Management-Cockpit.
> Alle 3 Listen über Toggle an- und ausschaltbar. Default ist die interne, private Aufgabenliste.

**Spalte 2** (lesend): über alle Projekte mit `clickUpListID` iterieren (Muster existiert schon in
`HeuteAnstehendView.swift`, `withTaskGroup` über `ClickUpClient.tasks(listID:)`), dann clientseitig
filtern (meine/alle/Projekt/Prio/Fälligkeit). Sicher, kein NO-GO-Konflikt.

**Spalte 3** (schreibend — ⚠️ VORSICHT): "zuweisen an Person" kollidiert mit der eisernen Regel
"KI weist NIE zu" + der Ghost-Persona-Regel (nie echte Assignee-IDs außerhalb Testspace
`90128024109`). Baue die Maske so, dass eine simulierte Zuweisung NUR als Ghost-Kürzel-Text-Marker
läuft (wie `ClickUpTestWerkbankView` es schon vormacht) — NIE das native `assignees`-Feld mit
einer echten Personen-ID. Reales Schreiben in ECHTE Projekt-Listen (nicht Testspace) bleibt
ohnehin ein größerer, eigener Schritt mit Johannes' Blick.

### Danach (aus Johannes' MAXIME): Handbuch/Hilfe-System
"Help isn't available for mykilOS" (macOS-Standard-Fallback) → `docs/BENUTZERHANDBUCH.md` existiert
schon (Pflichtdoku laut CLAUDE.md), aber es gibt keine ECHTE In-App-Hilfe. Müsste eine eigene
HelpView + `.helpBook`/NSHelpManager-Anbindung oder eine simple In-App-Suchseite werden.
**Wichtig:** jede Behauptung darin gegen den echten Code verifizieren, nicht erfinden (siehe
Diskussion im Chat: Claude schreibt es selbst, kein Modell ohne Codebase-Zugriff).

### Danach: `docs/IDEEN_UND_BACKLOG.md` nach weiteren unblockierten Strängen durchsuchen
Die meisten übrigen Punkte brauchen entweder Johannes' Entscheidung/externe Aktion oder sind
explizit "kein Umsetzungsauftrag" markiert — nicht bauen, nur die wirklich unblockierten.

## Volles Live-Feedback vom 2026-07-06 ~23:47 (14 Screenshots, `~/Desktop/mykilOS-Feedback/FEEDBACK DEV/`)

Status je Punkt (✅ gefixt · ⬜ noch offen · ❓ investigiert, nicht eindeutig):

1. ⬜ Aufgaben-3-Spalten-System (siehe oben — Spalte 1 halb, 2+3 offen)
2. ✅ Header-Baseline (Projekte-Seite)
3. ✅ Header-Baseline ("Heute")
4. ❓ "Unsauberer Satz" rechtes Inhaltsfenster (HeuteAnstehendView-Karte hat schon 17pt Padding —
   ohne breiteren/Live-Screenshot nicht eindeutig zuzuordnen)
5. ❓ "4er-Eck-Kreuzung" im Widget-Grid (HomeBoardView nutzt natives SwiftUI-`Grid` mit
   variablen `gridCellColumns`-Spans — bekannte SwiftUI-Grid-Eigenheit bei Spalten über mehrere
   Zeilen, ODER dieselbe WidgetContainer-Hover-Kollision wie Punkt 8-12. Nicht live verifiziert.)
6. ✅ Wortmarke zu klein (SVG-Zuschnitt)
7. ⬜ Fenster-Traffic-Lights/Sidebar-Abstände — `.hiddenTitleBar` Fenster-Stil, genaue
   OS-Pixel-Position der Ampel-Buttons nicht sicher aus Code allein bestimmbar, braucht Live-Blick
8. ✅ Jiggle-Bug Dateien-Tab (Mouseover-Zittern)
9. ✅ (gleicher Bug wie 8)
10. ✅ (gleicher Bug wie 8)
11. ✅ Drive-Ordner-Leiste entfernt
12. ✅ (gleicher Bug wie 8)
13. ⬜ Handbuch/Hilfe/FAQ — siehe "Danach" oben, noch nicht begonnen
14. ✅ Preis-Wissen als Katalog-Tab (Default aus)

## Kanonische Kommandos

```bash
cd "/Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilOS Mac"
swift build && swift test 2>&1 | tail -10
swiftlint lint --strict --baseline swiftlint-baseline.json --quiet   # bei Fehlern: Baseline neu erzeugen (s.o.)
rm -rf "dist/mykilOS 11.1.0-alpha7.app" "dist/mykilOS-11.1.0-alpha7.dmg"
MYKILOS_NO_LAUNCH=1 ./script/build_and_run.sh && ./script/create_dmg.sh
```

## Vibe

Sehr produktive Nacht (13 Commits, ~5h durchgehende Arbeit), ein echter Bug gefunden+gefixt
(Mail-Signatur), ein echter Bug gefunden+gefixt (Hover-Jiggle), acht Live-Feedback-Punkte real
verifiziert gefixt. Zwei Punkte ehrlich als "nicht eindeutig ohne Live-Blick" gekennzeichnet statt
geraten. Session endet wegen Kontextfenster-Grenze (91%) und 5h-Limit-Nähe, nicht weil die Arbeit
fertig ist — nahtlos hier weitermachen.
