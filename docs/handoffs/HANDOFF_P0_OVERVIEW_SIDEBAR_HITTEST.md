# P0-Handoff — Projekt-„Übersicht“ überlagert die Sidebar

```
Pfad:   /Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilOS6/
Branch: main
HEAD:   dd235ab bei forensischer Untersuchung
Build:  nicht neu ausgeführt (Dokumentation, keine Codeänderung)
Tests:  192 laut dd235ab; nicht neu ausgeführt
Datum:  2026-06-28
Status: 🚨 OFFEN · P0 · NICHT LIVE BEHOBEN
```

## Warum dieser Handoff existiert

Dieser Fehler war über mehrere Sessions als „Fenster-Drift“ oder
„Sidebar-Collapse“ beschrieben worden. Mehrere äußere Layoutmaßnahmen
(`.opacity`, `.clipped()`, Infinity-Frames, WindowGuard, `.fixedSize`,
`.layoutPriority`) beseitigten Teilfolgen, aber nicht den realen
Nutzerfehler.

Die Live-Screenshots von Johannes vom 2026-06-28 um 09:38/09:39 liefern den
entscheidenden Vergleich:

| Screenshot | Aktiver Tab | Befund |
|---|---|---|
| `Bildschirmfoto 2026-06-28 um 09.38.54.png` | Angebote | Sidebar klickbar, Detail korrekt |
| `Bildschirmfoto 2026-06-28 um 09.38.59.png` | Timeline | Sidebar klickbar, Detail korrekt |
| `Bildschirmfoto 2026-06-28 um 09.39.02.png` | Material | Sidebar klickbar, Detail korrekt |
| `Bildschirmfoto 2026-06-28 um 09.39.09.png` | Übersicht | Inhalt links abgeschnitten, Sidebar blockiert |
| `Bildschirmfoto 2026-06-28 um 09.39.12.png` | Übersicht | gleicher Fehler reproduziert |

Die Originale liegen zum Zeitpunkt dieses Handoffs auf Johannes' Mac unter:

```
/Users/johannesleoberger/Desktop/Bildschirmfoto 2026-06-28 um 09.38.54.png
/Users/johannesleoberger/Desktop/Bildschirmfoto 2026-06-28 um 09.38.59.png
/Users/johannesleoberger/Desktop/Bildschirmfoto 2026-06-28 um 09.39.02.png
/Users/johannesleoberger/Desktop/Bildschirmfoto 2026-06-28 um 09.39.09.png
/Users/johannesleoberger/Desktop/Bildschirmfoto 2026-06-28 um 09.39.12.png
```

## Gesicherter Symptombeweis

Bei aktiver Übersicht:

- `SCHMIDT` erscheint nur noch als `DT`.
- Der Back-Button verschwindet links.
- Der erste sichtbare Tab beginnt mitten im Wort `Assistent` als `sistent`.
- Die Sidebar selbst bleibt vollständig gezeichnet.
- Sidebar-Buttons reagieren dennoch nicht.

Damit ist ausgeschlossen, dass die Sidebar bewusst ausgeblendet oder ihr
Navigations-State deaktiviert wird. Stattdessen liegt eine unsichtbare
Interaktionsfläche der nach links überstehenden Detailansicht über ihr.

## Root Cause

Nur der Tab „Übersicht“ rendert `ProjectWidgetBoardView`. Dieses verwendet ein
intrinsisch vermessenes SwiftUI-`Grid`:

```swift
Grid {
    ForEach(rows, id: \.id) { row in
        GridRow {
            ForEach(row.items) { instance in
                draggableCell(for: instance)
            }
            if row.needsFiller {
                Color.clear.gridCellColumns(row.fillerSpan)
            }
        }
    }
}
```

Die Kombination ist kritisch:

1. Grid-Spalten richten sich nach den breitesten Zellen.
2. `Color.clear` ist eine flexible Zelle und kann die Spaltenbreite treiben.
3. Drive-, Kontakte-, Aufgaben-, Kalender- und andere Widgets wechseln nach
   asynchronem Laden ihren Inhalt und ihre intrinsische Breite.
4. Das Board wird breiter als das rechte Content-Pane.
5. Die übergroße Detailansicht wird im Pane zentriert beziehungsweise nach links
   verdrängt.
6. `.clipped()` versteckt den visuellen Überstand, begrenzt aber nicht
   zuverlässig die Hit-Test-Fläche der übergroßen Unteransicht.
7. Diese unsichtbare Fläche fängt Sidebar-Klicks ab.

Die früheren Crash-Stacks mit
`NSHostingView.updateWindowContentSizeExtremaIfNecessary` erklären die
historische Fensterbreiten-Eskalation. Die aktuellen Screenshots beweisen
zusätzlich den noch offenen, tab-spezifischen Interaktionsfehler.

## Fixvertrag

### Pflicht

1. `Color.clear`-Filler entfernen. Unvollständige `GridRow`s benötigen keinen
   flexiblen Platzhalter.
2. Das Widget-Board an eine explizite, endliche Content-Pane-Breite binden.
   Widget-Inhalte dürfen die Board-Breite niemals vergrößern.
3. Falls `Grid` weiterhin keine stabile Breitenbegrenzung liefert, durch einen
   eigenen Drei-Spalten-Layout-Container ersetzen, der Spaltenbreiten aus der
   verfügbaren Pane-Breite berechnet.
4. Hit-Test-Fläche des rechten Panes ausdrücklich auf dessen Frame begrenzen.
5. Sidebar in der Treffer-/Z-Reihenfolge schützen.

### Nur zusätzliche Sicherheitsnetze

- `.clipped()`
- `.fixedSize` / `.layoutPriority`
- `WindowGuard`
- `.background` statt `.ignoresSafeArea`
- Hero `.frame(maxWidth: .infinity)`

Diese Maßnahmen dürfen bleiben, gelten aber allein nicht als Fix.

## Definition of Done — hart

Der P0 ist erst geschlossen, wenn alle Punkte erfüllt und dokumentiert sind:

- [ ] Projekt öffnen, Übersicht aktivieren.
- [ ] `SCHMIDT`, Back-Button und komplette Tab-Leiste bleiben sichtbar.
- [ ] Alle Sidebar-Ziele sind unmittelbar anklickbar.
- [ ] Sidebar bleibt nach 300, 800 und 1800 ms anklickbar.
- [ ] Drive-/Kontakte-/Aufgaben-/Kalender-Loader dürfen die Breite nicht ändern.
- [ ] Mindestens drei Projekte geprüft.
- [ ] Kleine, mittlere und große Fensterbreite geprüft.
- [ ] Wechsel Übersicht → anderer Tab → Übersicht mehrfach geprüft.
- [ ] Rückkehr zur Galerie funktioniert.
- [ ] Live-Screenshots nach dem Fix im Ereignisprotokoll verlinkt.
- [ ] Build und vollständige Testsuite grün.

**Nicht ausreichend:** „192 Tests grün“, „kein Crash“, „Sidebar sichtbar“ oder
„WindowGuard hat das Fenster zurückgezogen“. Entscheidend ist die reale
Klickbarkeit der Sidebar bei aktiver Übersicht.

## Schutz vor Wiederholung

Jeder zukünftige Handoff, der Projekt-Detail, Widget-Layout, neue Widgets oder
asynchrone Widget-Loader verändert, muss diese Live-Prüfung erneut ausführen.
Ohne diese Abnahme darf kein solcher Handoff „fertig” oder „live” melden.

---

## 🚨 CRASH-REPORT: Gescheiterter Fix-Versuch 1 (Claude Sonnet 4.6, 2026-06-28)

**Agent:** Claude Code (Worktree `angry-benz-2df776`)
**Ergebnis:** ABGEBROCHEN — Live-Test negativ, Bug unverändert aktiv

### Uncommitted Changes bei Abbruch

Alle folgenden Änderungen sind ungestaged in `main` (relativ zu `dd235ab`):

| Datei | Inhalt der Änderung | Herkunft |
|---|---|---|
| `Sources/MykilosApp/MykilOS6App.swift` | `detailPane` → `GeometryReader { proxy in moduleView.frame(width: proxy.size.width, height: proxy.size.height, alignment: .topLeading).clipped().contentShape(.interaction, Rectangle()) }` · `.zIndex(1)` für Sidebar + Divider | Andere Session (vor diesem Versuch) |
| `Sources/MykilosApp/Gallery/ProjectGalleryView.swift` | `ZStack` → `ZStack(alignment: .topLeading)` · `ProjectDetailView.frame(maxWidth: .infinity, maxHeight: .infinity)` | Dieser Versuch (Fix-Versuch 1) |
| `Sources/MykilosApp/Detail/ProjectDetailView.swift` | `Color.clear.gridCellColumns(row.fillerSpan)` entfernt · Grid bekommt `.frame(maxWidth: .infinity, alignment: .topLeading)` | Dieser Versuch (Fix-Versuch 1) |
| `Sources/MykilosApp/Detail/ProjectHeroView.swift` | Kleinere Änderungen (anderer Agent) | Andere Session |
| `docs/CLAUDE.md`, `docs/EREIGNISPROTOKOLL.md` etc. | P0-Block + Protokoll | Dieser Versuch |

### Was der Live-Test zeigte

```
Build:        ✅ (swift build + build_and_run.sh — alle uncommitted changes eingebaut)
Tests:        nicht ausgeführt (kein swift test nach Code-Änderungen)
Live-Abnahme: ❌ FEHLGESCHLAGEN
```

**Beobachtungen nach Build und Launch:**
- Projekt geöffnet (SCHMIDT) → Tab „Übersicht” aktiv
- Tab-Leiste zeigte nur `Angebote | Timeline | Material` als erste sichtbare Tabs (Tabs 4–6)
- Tabs 1–3 (`Übersicht`, `Assistent`, `Dateien`) verdeckt hinter Sidebar
- Hero-Titel weiterhin abgeschnitten
- Klick auf „Heute” in Sidebar → keine Reaktion (Sidebar weiterhin blockiert)
- Inhalt ca. 1 Sidebar-Breite (≈212 px) nach links verschoben

Die vier angewandten Code-Änderungen waren **nicht ausreichend**.

### Analyse: Warum blieb der Bug trotz GeometryReader?

Das `detailPane`-GeometryReader-Konstrukt in `MykilOS6App.swift` (andere Session):

```swift
private var detailPane: some View {
    GeometryReader { proxy in
        moduleView
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .topLeading)
            .clipped()
            .contentShape(.interaction, Rectangle())
    }
    .frame(minWidth: 0, maxWidth: .infinity, ...)
    .layoutPriority(0)
    .zIndex(0)
}
```

**Theoretisch** sollte das den Bug beenden: `moduleView` wird auf exakte Pane-Abmessungen gezwungen, Overflow wird geclippt, Hit-Test-Fläche auf Rectangle begrenzt.

**Praktisch** besteht der Bug weiter. Die wahrscheinlichsten verbliebenen Ursachen:

#### Ursache A (wahrscheinlichste): Innere ZStack-Zentrierung in `ProjectDetailView.body`

```swift
// ProjectDetailView.body, Zeile 25:
ZStack(alignment: .bottom) {     // .bottom = horizontal CENTER
    VStack(spacing: 0) {          // VStack default = auch .center
        ProjectHeroView(...)
        tabBar                    // ScrollView(.horizontal) — preferred width ≈663px
        Divider()
        ScrollView(.vertical) { ... }
    }
    SaveStateBar(...)
}
.frame(maxWidth: .infinity, maxHeight: .infinity)
```

Der äußere `ZStack(alignment: .bottom)` zentriert alle Kinder horizontal. Wenn die VStack eine `preferredWidth` meldet, die kleiner als die verfügbare ZStack-Breite ist (z. B. weil `ScrollView(.horizontal)` die preferred width auf die Inhaltsbreite zieht), werden VStack und Inhalt zentriert statt links ausgerichtet — was bei einer narrow preferred width einen positiven x-Offset ergibt. ABER: Bei einer zu großen preferred width entsteht ein negativer x-Offset → Inhalte rutschen links aus dem Pane heraus.

**Verdächtigster Fix:**
```swift
// Zeile 25, ProjectDetailView.body:
ZStack(alignment: .bottomLeading) {   // war: .bottom
    VStack(alignment: .leading, spacing: 0) {   // war: kein alignment (= .center)
```

#### Ursache B: GeometryReader initial size 0

`GeometryReader` rendert beim ersten Pass mit `proxy.size = (0, 0)`. Wenn die Größe nach dem ersten Pass korrekt gesetzt wird, aber in der Zwischenzeit Widgets async ihren Inhalt laden und die preferredWidth verändern, kann ein zweiter Layout-Pass stattfinden, der inkonsistent ist.

**Diagnostik-Hinweis:** `.border(Color.red)` auf den VStack in `ProjectDetailView.body` setzen, um beim Start zu sehen ob er korrekt positioniert wird.

#### Ursache C: ScrollView(.horizontal) treibt VStack preferred width

`ScrollView(.horizontal)` für die Tab-Leiste meldet die Inhaltsbreite (≈663px) als preferred width an den umgebenden VStack. Der VStack übernimmt diese als eigene preferred width (max aller Kinder). Wenn der ZStack darunter dann `663px < Pane-Breite` zentriert, gibt es einen `(1153 - 663) / 2 = 245px` Offset nach rechts — das wäre kein links-Shift, sondern rechts. Das erklärt den Bug also NICHT allein, aber in Kombination mit anderen Effekten könnte es zu Inkonsistenzen führen.

### Empfehlung für den nächsten Versuch (Codex)

**Schritt 1 — Diagnostic-Only Build:**
`ZStack(alignment: .bottom)` auf `.bottomLeading` setzen UND VStack auf `VStack(alignment: .leading, spacing: 0)`. Das sind 2 Zeilen in `ProjectDetailView.body`. Build, Test, Live-Abnahme.

```swift
// Sources/MykilosApp/Detail/ProjectDetailView.swift, Zeile 25–26:
ZStack(alignment: .bottomLeading) {
    VStack(alignment: .leading, spacing: 0) {
```

**Schritt 2 — Falls immer noch fehlgeschlagen:**
Innere `ScrollView(.vertical)` + VStack durch `GeometryReader`-gestützte explizite Breite ersetzen, damit nichts die Preferred-Width „nach innen” meldet.

**Schritt 3 — Falls immer noch fehlgeschlagen:**
`Grid` durch manuelles `LazyVGrid` oder `VStack` mit HStack-Zeilen ersetzen, das die pane-Breite als Input bekommt und nie darüber hinaus meldet.

### Uncommitted Code-Stand bitte nicht revertieren

Die bestehenden Änderungen (GeometryReader in `MykilOS6App.swift`, Grid-Fix in `ProjectDetailView.swift`, ZStack.topLeading in `ProjectGalleryView.swift`) sind inhaltlich korrekt — nur unvollständig. Bitte auf diesem Stand aufbauen und NICHT revertieren.

### Nächste P0-Abnahme-Pflicht

**KEIN Commit, KEIN S18/S20-Feature, KEIN weiterer Handoff** bis Live-Abnahme laut Definition of Done oben erfüllt ist und dokumentiert wurde.
