# Handoff: Live-Wiring-Session 1 (2026-06-27)

**Ziel der Session:** echte Daten (Drive-Projekte, Airtable, ClickUp) end-to-end
verdrahten statt mit Demo-Daten weiterzuarbeiten. Ergebnis: eine neue,
eigenständige Airtable-Base als "Schaltzentrale", ein lebender ClickUp-
Sandbox-Space, ein konkreter Bugfix im Angebote-Tab, und eine ehrliche
Bestandsaufnahme aller verbleibenden Demo-/Dummy-Stellen in der App.

---

## 1. Architektur-Entscheidung: Drive ist die Projektquelle, nicht Airtable

Es gibt **keine** Airtable-Tabelle "Projekte" im ursprünglichen, geteilten
Sinn. Projekte werden direkt aus dem echten Google-Drive-Ordner `PROJEKTE`
(`1Q-H_3JsZfiXosFmxtNgoy0hI3cvZLgST`) abgeleitet:

- 31 aktive Projektordner, Namensschema `JJJJ_lfdNr_Kunde[_Code]`, tolerant
  geparst (fehlende führende Nullen, Bindestrich-Kunden, fehlender Code etc.).
- App-internes Projektnummer-Format: `JJJJ-NR` (z. B. `2026-015`).
- `_PROJEKTE_ARCHIV` (~200+ Ordner, 2018–2026, komplett anderes Namensschema
  mit Standort-Präfixen) ist **bewusst zurückgestellt** — kein Parser, kein
  Import, eigene Übersetzungsregistry später (siehe Aufgabe 6 unten).
- `ProjectKind` (kitchen/lighting/...) lässt sich aus dem Drive-Ordnernamen
  nicht ableiten — kommt später aus ClickUp (siehe Abschnitt 4).

Details und der vollständige 31-Projekte-Scan stehen bereits in CLAUDE.md
unter "Aus der Live-Wiring-Session — Drive als Projektquelle".

---

## 2. Bugfix: Angebote-Tab fand die Drive-Unterordner nicht

**Symptom:** `OffersTabView` zeigte nie Belege an, obwohl Projekte echte
Angebots-PDFs in Drive haben.

**Root Cause:** `GoogleDriveClient.listFolder(folderID:)` listet nur
**direkte** Kinder (nicht rekursiv). Die alte Implementierung suchte Angebote
direkt im Projekt-Root-Ordner — die echten PDFs liegen aber in den
Unterordnern `04 ausgehende Angebote` / `05 eingehende Angebote`.

**Fix** (`Sources/MykilosApp/Detail/OffersTabView.swift`): zweistufige
Auflösung — erst Root-Ordner listen, per Namens-Keyword die beiden
Unterordner finden (`subfolder(in:matching:)`), dann beide parallel per
`async let` auslesen. UI ist jetzt zweispaltig: **Eingehende Angebote** /
**Ausgehende Angebote**, jede Spalte mit eigenem Leer-/„Ordner nicht
gefunden"-Zustand. `OffersLoader` ist jetzt `@MainActor @Observable` mit
`incoming`/`outgoing`/`incomingFolderFound`/`outgoingFolderFound`.

**Verifiziert:** `swift build` clean, `swift test` → **169/169 Tests grün**.
Noch **nicht** live im laufenden Bundle gegen echte Drive-Daten angeschaut —
das ist der erste manuelle Check für die nächste Session.

---

## 3. Airtable "mykilOS Mastermind" — neue, eigenständige Base

**Wichtig:** Das ist eine andere Base als die ursprüngliche geteilte
Airtable-Base, die unter dem harten NO-GO steht (nie schreiben/editieren/
löschen/verschieben). Der User hat diese neue Base explizit als "meine Datei"
freigegeben: *"Das ist DEINE Datei. du darfst die Architektur sinnvoll
anlegen und mit detailiertem Handshake und Live feed führen ... als Registry
und 'Schaltzentrale' oder mykilOS 6 I/O Master aufbauen."*

- **Base-ID:** `appuVMh3KDfKw4OoQ`
- **Tabellen** (Schema 1:1 an `AirtableClient.mapProjects`/`mapCustomers`
  angelehnt, damit die App ohne Code-Änderung syncen könnte):
  - `Kunden` — Name, Kundennummer, Kontakte-Suche
  - `Projekte` — Projektnummer, Titel, Art, Kundennummer, Drive-Ordner-ID,
    Drive-Pfad, Drive-Ordnername, ClickUp-Liste, Kalender-Suche,
    Kontakte-Suche, Mail-Suche, sevdesk-Ref, Budget, Eltern-Projekt, Phase,
    Clockodo-Projekt-ID, Quelle, ParseConfidence, Hinweis
  - `Externe Systeme` — System, Rolle, Status, Hinweis
  - `Archiv-Übersetzung` — Alter Ordnername, Vermutete Projektnummer, Jahr,
    Standort-Präfix, Status (Schema vorbereitet, noch leer — für später,
    siehe Aufgabe 6)
  - `Table 1` — Airtable-Default-Tabelle, ungenutzt, nicht aufgeräumt

**Aktueller Datenstand (heute live eingespielt): 69 Records**
  - Kunden: 30/30
  - Projekte: 31/31
  - Externe Systeme: 8/8

### Wie die Daten geschrieben wurden — wichtige technische Notiz

Der Airtable-MCP-Connector in dieser Session (`mcp__fb31f5ff-...`) bietet
**kein Tool zum Schreiben von Records** (`create_records_for_table` o. ä.
existiert nicht im exponierten Toolset, mehrfach bestätigt — Schema-Tools
wie `create_table`/`create_field` funktionieren, Daten-Schreiben nicht).
Workaround: ein Personal-Access-Token des Users, im macOS-Keychain unter
Service-Name `mykilos-mastermind-airtable-pat` / Account `johannesleoberger`
gespeichert, plus ein lokales Python-Skript (`migrate_to_airtable.py`, lag im
Scratchpad dieser Session, **nicht im Repo**), das per `curl`-Subprozess
direkt gegen `api.airtable.com` schreibt (`typecast: true`, Batches à 10
Records). Der Token wurde dabei nie im Chat/Transkript sichtbar — nur per
`security find-generic-password -w` innerhalb von Command-Substitutions
gelesen.

**Für die nächste Session, falls weitere Records nötig sind:** Token liegt
noch im Keychain (`security find-generic-password -a "$USER" -s
"mykilos-mastermind-airtable-pat" -w`), das Migrationsskript-Muster ist
oben beschrieben und kann für `Archiv-Übersetzung` wiederverwendet werden,
sobald der Archiv-Parser steht (Aufgabe 6).

### Redundanz-Modell (3 Kopien, bewusst getrennt)

1. **Airtable "mykilOS Mastermind"** — die kollaborative Arbeitsoberfläche.
2. **Lokaler Cache pro Nutzer** — `CachedProjectRegistry` über
   `FileBackedRepository`, existiert strukturell bereits seit Akt 0/3,
   kein neuer Code nötig.
3. **`docs/registry/*.json`** im Git-Repo — `projekte.json` (31), `kunden.json`
   (30), portable ISO-Datums-JSON, **kein** Drop-in-Ersatz für den App-Cache
   (der nutzt `timeIntervalSinceReferenceDate`-Double-Encoding für
   bitgenauen Round-Trip). Siehe `docs/registry/README.md` für Details.

---

## 4. ClickUp "MYKILOS API TESTSPACE" — neuer Sandbox-Space entdeckt

Beim Connector-Recheck dieser Session ist im ClickUp-Workspace ein neuer
Space `MYKILOS API TESTSPACE` (`90128024109`) aufgetaucht — vom User frisch
angelegt/freigeschaltet. Struktur:

```
00 Intake & Triage
01 Kundenprojekte → Liste "KUE-2026-014 Küche Müller TEST" (8 Test-Tasks:
   Lead/Anfrage qualifizieren → Briefing prüfen → Aufmaß/Termin →
   Planung starten → Angebot vorbereiten → Bestellung prüfen →
   Montagefenster abstimmen → Abschluss/Review)
02 Planung & Design · 03 Angebot, Einkauf & Lieferanten ·
04 Ausführung & Montage · 05 Service & Nachträge · 06 Studio Intern ·
07 Accounting & Cash · 90 Reviews & Freigaben · 99 Admin & Datenpflege
```

Die Test-Liste hat ein Custom Field `Drive-Ordner anlegen` (Checkbox) — sieht
nach dem Beginn eines Drive-Folder-Automatisierungs-Triggers aus.

**Bedeutung für die App:** Das ist ein sicherer Ort, um Aufgabe 7
(ClickUp-Handle für `ProjectKind`) und den ClickUp-Teil der Timeline-
Anbindung live zu testen, **ohne** echte Produktionsdaten in ClickUp zu
berühren. Noch nicht genutzt — reine Bestandsaufnahme in dieser Session.

---

## 5. Demo-/Dummy-Audit — vollständige Liste für die nächste Session

Bestätigt per Code-Lesung, **noch nicht gefixt** (außer #5, Abschnitt 2):

| # | Was | Wo | Befund |
|---|---|---|---|
| 1 | Tab-/Widget-Architektur sichten | — | Grundlage für alle weiteren Punkte, größtenteils erledigt durch diese Session |
| 2 | Zeichnungen-Tab mit PDF-Vorschau | neu | User-Entscheidung: neuer Tab, Quelle `02 CAD`-Unterordner |
| 3 | Abnahme-Bereich für Abnahmeprotokoll | neu | eigener Bereich, noch nicht gebaut |
| 4 | Timeline-Tab an Google Calendar | `ComingTabView` Platzhalter | jetzt: Calendar: später: ClickUp (siehe Abschnitt 4) |
| 5 | ✅ Angebote-Tab zwei Spalten | `OffersTabView.swift` | **erledigt, gebaut, getestet** (Abschnitt 2) |
| 6 | Archiv-Übersetzungsregistry | `_PROJEKTE_ARCHIV` | zurückgestellt, Airtable-Tabelle `Archiv-Übersetzung` ist schon angelegt und leer |
| 7 | ClickUp-Handle für `ProjectKind` | `Project.swift` | jetzt testbar im neuen ClickUp-Sandbox-Space (Abschnitt 4) |
| 8 | DemoSeed → echte 31 Projekte | `Sources/MykilosApp/Data/DemoSeed.swift` | **höchster Hebel, noch offen** — 6 Fantasie-Projekte ("Küche Meyer" etc.) statt der 31 echten |
| 9 | Hartkodierte Demo-Bugs | `ProjectHeroView.swift` (72%-Budget-Balken fix), `FocusWidget.swift` (Text immer "Küche Meyer"/"Loft" unabhängig vom echten Signal), `CashWidget.swift` (Angebotstext hartkodiert "Arbeitsplatte Naturstein") | echte, reale Bugs — nicht nur Demo-Kosmetik |
| 10 | Demo-Buttons → "Jetzt prüfen" Force-Poll | `SignalDemoView.swift`, `TodayView.swift` (`HomeDemoSignalButton`) | sollen echten `DriveOfferWatcher`-Poll auslösen statt Fake-Signale zu emittieren |
| 11 | Material-Tab Quelle anbinden | `ComingTabView` Platzhalter | Quelle: `03 PRÄSENTATION`-Unterordner |

**Empfehlung für nächste Session (unverändert seit dem Audit dieser
Session):** zuerst #8 (DemoSeed ersetzen — größter Hebel, macht #9 teilweise
automatisch korrekt, weil reale `project.links.budget` etc. dann existieren),
dann #9 (verbleibende hartkodierte Texte), dann #10 (Force-Poll), dann die
drei neuen Tabs #2/#3/#11 in beliebiger Reihenfolge je nach Priorität.

---

## 5a. Detaillierter Implementierungsplan: Minimal-Pfad zum ersten Live-Test

Dieser Abschnitt ist bewusst **konkreter** als die Tabelle oben — Ziel ist,
dass eine spätere Session (oder ein späterer Blick zurück) exakt sieht, was
angedacht war, ohne den Code erneut komplett lesen zu müssen. Reihenfolge ist
absichtlich so gewählt, dass nach Schritt A bereits ein echter Live-Test in
der laufenden App möglich ist — B–D sind unabhängig voneinander und können
in beliebiger Reihenfolge folgen.

### Schritt A — Aufgabe 8: DemoSeed durch die echten 31 Projekte ersetzen

**Status: noch nicht begonnen.** Das ist der einzige Schritt, der für einen
ersten echten Live-Blick in der App nötig ist.

- **Datei:** `Sources/MykilosApp/Data/DemoSeed.swift`
- **Aktueller Zustand:** `DemoSeed.inject(into:)` baut 4 fiktive `Customer`
  und 6 fiktive `Project`-Werte (Küche Meyer/ME-24, Nachtrag Beleuchtung/
  ME-24-N1, Loft Umbau Mitte/LO-23, Lichtplanung Praxis/SO-24, Studio
  Bergmann Küche/BE-24, Bad Meyer/ME-23) als Swift-Literale und schreibt sie
  über `registry.replaceCustomers(...)`/`registry.replaceProjects(...)`.
- **Aufrufstelle:** `RegistryStore.seedIfEmpty()`
  (`Sources/MykilosApp/Data/RegistryStore.swift:79`) ruft `DemoSeed.inject`
  **nur** auf, wenn `reg.allProjects().isEmpty` — Cold-Start-sicher, kein
  Risiko für bestehende echte Daten.
- **Wichtige Erkenntnis aus dieser Session:** Die in `docs/registry/
  projekte.json` (31 Einträge) und `docs/registry/kunden.json` (30 Einträge)
  liegenden echten Daten nutzen ISO-8601-Datumsstrings — das ist **kein**
  Problem für diesen Schritt, weil sie hier nur als *Quelle zum Bauen der
  Swift-Literale* dienen, nicht direkt in den App-eigenen Cache kopiert
  werden. Die im `docs/registry/README.md` beschriebene Inkompatibilität
  (Double- vs. ISO-Encoding) betrifft nur den Versuch, die JSON-Dateien
  1:1 in den `FileBackedRepository`-Cache-Ordner zu kopieren — **nicht**
  relevant, wenn man sie zum Erzeugen von `Project`/`Customer`-Werten in
  Swift-Code verwendet.
- **Zwei Umsetzungs-Optionen, beide gültig:**
  1. **Swift-Literale (empfohlen, konsistent mit bestehendem Stil):**
     `DemoSeed.swift`-Inhalt durch 31 `Project(...)`-/30 `Customer(...)`-
     Literale ersetzen, generiert aus `docs/registry/projekte.json` +
     `kunden.json`. Kein neuer Code, keine Bundle-Resource, keine
     `Package.swift`-Änderung. Nachteil: lange Datei (~31 Literale statt 6).
  2. **JSON-Bundle + Decoder:** `projekte.json`/`kunden.json` als Resource
     in `Sources/MykilosApp/Resources/` aufnehmen, in `Package.swift` als
     `.copy(...)`-Resource deklarieren, zur Laufzeit per
     `JSONDecoder` mit `.dateDecodingStrategy = .iso8601` laden. Vorteil:
     kürzerer Code. Nachteil: neue Abstraktion für einen einmaligen
     Seed-Vorgang — gegen das CLAUDE.md-Prinzip "keine Abstraktion ohne
     echten Bedarf", da die Daten sich nicht mehr ändern, sobald Airtable
     die Quelle der Wahrheit wird.
  - **Empfehlung:** Option 1, weil es exakt dem bestehenden Muster folgt
    und CLAUDE.md explizit vor vorzeitiger Abstraktion warnt.
- **Mapping-Hinweis:** `Project.kind` (`ProjectKind`) ist in den echten
  Daten für alle 31 Projekte `kitchen` (außer `2026-001` MYKILOS =
  `studioInternal`, siehe Drive-Scan dieser Session) — `ClickUp-Liste`,
  `Kalender-Suche` etc. aus `Projekte.csv`-Spalten direkt übernehmen.
- **Nach der Umsetzung zwingend:**
  - `swift build` + `swift test` — Cold-Start-Tests dürfen nicht brechen.
  - `./script/build_and_run.sh` — echtes Bundle starten, Galerie ansehen,
    mindestens 2–3 echte Projekte öffnen (Dateien-Tab, Angebote-Tab,
    Budget-Anzeige in `ProjectHeroView`). **Das ist der "erste echte
    Live-Test" aus dieser Session.**
  - Kein neuer Cold-Start-Test nötig — `DemoSeed.inject` wird bereits über
    bestehende Mechanismen getestet (indirekt über `RegistryTests`).

### Schritt B — Aufgabe 9: Verbleibende hartkodierte Demo-Bugs

**Status: noch nicht begonnen.** Unabhängig von Schritt A, aber durch
Schritt A teilweise entschärft (echte `project.links.budget`-Werte stehen
dann zur Verfügung).

| Datei | Zeile(n) | Befund | Fix-Ansatz |
|---|---|---|---|
| `Sources/MykilosApp/Detail/ProjectHeroView.swift` | 114, 119, 121, 133 | Budget-Balken-Breite (`geo.size.width * 0.72`), Text `"BUDGET 72 % · 4 H HEUTE"` und Trim-Wert `0.72` sind für **jedes** Projekt identisch hartkodiert, unabhängig vom echten Budget | Echte Berechnung aus `project.links.budget` vs. tatsächlichem Ist-Umsatz (gleiche Quelle wie `CashWidget` nutzt — `SevdeskClient`/`sumGross`) ableiten; falls kein `sevdeskRef` gesetzt: sauberer Leerzustand statt Fake-Prozent |
| `Sources/MykilosApp/Today/FocusWidget.swift` | 73, 83 | `synthesized`-Property erzeugt Text wie `"Angebot Küche Meyer prüfen → Cash-Widget"` und Fallback `["Küche Meyer — Bartresen-Detail freigeben", "Loft — Zeichnungen für Freitag"]` **unabhängig vom echten `projectID` des Signals** | Signal-Payload (`projectID`) tatsächlich auflösen → echten Projekttitel aus der Registry nachschlagen statt String-Literal |
| `Sources/MykilosWidgets/Kinds/CashWidget.swift` | 71 | `signalPrompt`-Text hartkodiert `"Lieferanten-PDF erkannt — **Arbeitsplatte Naturstein, 3 Positionen**. Liegt 8 % über dem aktuellen Bieterspiegel."` für jedes Projekt mit `hasReviewSignal` | Echten Signal-Payload-Text durchreichen (Dateiname/Betrag aus `DriveOfferWatcher`-Treffer), nicht generischen Platzhaltertext |
| `Sources/MykilosWidgets/Kinds/CashWidget.swift` | 26, 75, 94 | `reviewAccepted` ist nur `@State` (View-lokal) — "In Review übernehmen" persistiert nichts, überlebt keinen Neustart | Muss über Action-Card → `AuditStore.append(...)` laufen, nicht direkt im View-State (Architektur-Regel: Schreibvorgänge nie direkt aus Views) |

### Schritt C — Aufgabe 10: Demo-Signal-Buttons → echter Force-Poll

**Status: noch nicht begonnen.**

- **Dateien:** `Sources/MykilosApp/Detail/SignalDemoView.swift` (Button auf
  jeder Projektseite), `Sources/MykilosApp/Today/TodayView.swift:144-146`
  (`HomeDemoSignalButton`, ruft `context.emit(.offerDetected(projectID:
  "ME-24", ...))` mit fest verdrahteter Projekt-ID `"ME-24"` — die nach
  Schritt A nicht mehr existiert, also würde der Button nach Schritt A ins
  Leere zeigen, falls nicht vorher angepasst).
- **Fix-Ansatz:** Button soll `DriveOfferWatcher.poll(...)` für das aktuell
  offene Projekt (bzw. auf der Heute-Seite: für alle Projekte mit
  `driveFolderID`) **sofort** auslösen statt ein Fake-Signal zu emittieren
  — der Watcher existiert bereits und läuft eh alle 60 s im Hintergrund
  (`ProjectDetailView`), hier nur ein manueller Sofort-Trigger derselben
  Funktion.
- **Wichtig:** `TodayView.swift:144-146` MUSS spätestens mit Schritt A
  angepasst werden (feste `"ME-24"`-Referenz existiert dann nicht mehr) —
  auch wenn Schritt C selbst aufgeschoben wird, diesen einen Punkt vorher
  prüfen.

### Schritt D — Aufgaben 2/3/11: Neue Tabs (Zeichnungen, Abnahme, Material)

**Status: noch nicht begonnen, größter Einzelaufwand.**

- **Zeichnungen-Tab (Aufgabe 2):** neuer `ProjectTab`-Fall, Quelle
  `02 CAD`-Unterordner (gleiches Subfolder-Resolution-Pattern wie der
  frisch gefixte Angebote-Tab, Abschnitt 2 dieses Dokuments). PDF-Vorschau
  ist der technisch unklarste Teil — `QuickLookThumbnailing`/`PDFKit` in
  SwiftUI einbinden, noch nicht recherchiert. **Hier ggf. Opus statt Sonnet
  einsetzen, falls es hakt** (siehe Modell-Empfehlung aus dem Chat).
  Erfordert vermutlich Drive-Datei-Download (aktuell nur `webViewLink`
  geöffnet, kein echter Download/Cache) — neue Funktionalität, kein
  bestehendes Pattern.
- **Material-Tab (Aufgabe 11):** Quelle `03 PRÄSENTATION`-Unterordner,
  sollte dem Angebote-Tab-Pattern (Liste von Drive-Dateien) sehr ähnlich
  sein, kein PDF-Vorschau-Bedarf vermutet — einfacher als Zeichnungen.
- **Abnahme-Bereich (Aufgabe 3):** noch keine Drive-Quelle identifiziert/
  zugeordnet — erster Schritt wäre, mit dem User zu klären, ob es einen
  eigenen Unterordner oder ein eigenes Datenmodell (Abnahmeprotokoll als
  Formular?) braucht. Am wenigsten konkret von allen offenen Punkten.

---

## 6. Was diese Session NICHT angefasst hat (bewusst)

- Die ursprüngliche, geteilte Airtable-Base — NO-GO bleibt vollständig in
  Kraft, unverändert.
- Sevdesk — NO-GO bleibt vollständig in Kraft.
- Der verlinkte Google-Drive-Ordner — nur gelesen, nichts geschrieben/
  verschoben/umbenannt.
- Keine echten Customer-/Projektnamen wurden an externe Visualisierungs-Tools
  geschickt (ein Fehlversuch wurde vom System geblockt und korrigiert — seither
  nur fiktive Platzhalternamen für Mockups).

---

## Empfohlener Startprompt für die nächste Session

> "Live-Wiring-Session 2: Lies HANDOFF_LIVE_WIRING_1.md, Abschnitt 5a für den
> detaillierten Plan. Starte mit Schritt A (DemoSeed → echte 31 Projekte/
> 30 Kunden aus docs/registry/projekte.json + kunden.json, Option 1 =
> Swift-Literale). Danach swift build + swift test + ./script/build_and_run.sh
> für den ersten echten Live-Test. Schritt B (hartkodierte Bugs in
> ProjectHeroView/FocusWidget/CashWidget) und Schritt C (Demo-Buttons →
> Force-Poll) nur wenn noch Zeit/Budget übrig ist — beide sind unabhängig
> von Schritt A, außer der ME-24-Referenz in TodayView.swift:144-146, die
> nach Schritt A angepasst werden muss. Schritt D (neue Tabs) ist der
> größte Einzelaufwand, eigene Session wert. Airtable Mastermind-Base ist
> bereits live befüllt (69 Records) — RegistryStore.syncFromAirtable könnte
> optional testweise gegen appuVMh3KDfKw4OoQ laufen, sobald die App-Settings
> auf diese Base-ID zeigen."

## Status dieses Plans (für spätere Sessions auf einen Blick)

| Schritt | Aufgabe(n) | Status |
|---|---|---|
| A | #8 DemoSeed → echte Daten | ✅ erledigt, `769d63e`, live verifiziert |
| B | #9 Hartkodierte Bugs | ✅ erledigt, `d27eaeb` |
| C | #10 Force-Poll-Buttons | ✅ erledigt, `866b491` |
| D | #2/#3/#11 Neue Tabs | ⬜ offen — größter Aufwand |

Fortsetzung dieser Session (Google-Login-Fix, Identity-Plan, Assistent-Plan,
Window-Drift-Guard, Projekt-Favoriten klickbar, Drive-Routing über alle
Projekte): siehe
[HANDOFF_LIVE_WIRING_2.md](HANDOFF_LIVE_WIRING_2.md).

Wird ein Schritt in einer Folgesession umgesetzt: bitte hier den Status auf
✅ setzen und kurz verlinken, in welchem Commit/Handoff er erledigt wurde —
damit dieses Dokument dauerhaft der ehrliche Stand bleibt, nicht nur eine
Momentaufnahme vom 2026-06-27.
