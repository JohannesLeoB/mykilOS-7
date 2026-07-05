# UI-Konsistenz + Skalierungs-Audit

**Datum:** 2026-07-05
**Status:** Report, KEINE Änderungen; Fixes brauchen Johannes' visuelle Abnahme (Layout-Drift-Regel).

Konsolidiert aus drei Einzel-Audits (READ-ONLY) entlang von drei Dimensionen:
**Abstände/Ausrichtung**, **Skalierung**, **Tokens+Renderstates**. Alle Findings sind
Beobachtungen — es wurde nichts angefasst. Jeder Fix hier ist ein Vorschlag, der erst nach
visueller Live-Abnahme gegen Screenshots umgesetzt werden darf (Eiserne Regel: Build-grün ≠
Layout-korrekt, UI-Änderungen erzeugen Quer-Wirkung).

MykSpace-Raster zur Referenz: `s2=6 · s3=9 · s4=13 · s5=17 · s6=22 · s7=28 · s8=36 · s9=48`.

---

## Dimension 1 — Abstände / Ausrichtung

Kurzfazit: Die globalen Sammlungsansichten (AllPlansView / AllOffersView) sind untereinander
praktisch bit-genau identisch — das ist die saubere Referenz. Die Abweichungen konzentrieren
sich auf (a) die Projekt-Detail-Tabs, die jeder für sich padden statt an einer Stelle, und
(b) ein paar rohe Zahlen-Paddings, die aus dem Token-Raster ausbrechen. Toolbar-/Suchfeld-/
Filter-Insets sind durchgängig sauber (`s4/s3`), kein Handlungsbedarf.

| # | Datei:Zeile | Problem | Empfohlener Fix | Schwere |
|---|---|---|---|---|
| A-1 | `Sources/MykilosApp/Detail/ProjectDetailView.swift:116-197` | Detail-Tabs padden je selbst, kein gemeinsames Raster: nur `.overview` am Switch-Level gepaddet (`.horizontal s9, .top s7, .bottom 64`), die anderen padden intern divergent, `.chat`/`.zeit` bekommen gar kein einheitliches Außenraster → Inhalt springt beim Tab-Wechsel. | Außenraster an genau einer Stelle setzen (`.horizontal s9`, `.top s7`, `.bottom` = SaveBar-Token), interne Tab-Paddings entfernen; Sektions-`spacing` app-weit auf `MykSpace.s5`. | hoch |
| A-2 | `Detail/OffersTabView.swift:53` · `MaterialTabView.swift:95` · `TimelineTabView.swift:36` · `FilesTabView.swift:228` | Rohes `.padding(.bottom, 64)` („Platz für SaveStateBar") in vier Detail-Tabs vs. `MykSpace.s7` (=28) in den Global-Views — rohe Zahl außerhalb Raster + grobe Inkonsistenz bei sonst gleicher Optik. | Benannten SaveBar-Token einführen (z. B. `MykSpace.saveBarInset` oder `s9`=48) und app-weit dieselbe Konstante nutzen; mind. die 4 Vorkommen vereinheitlichen. | hoch |
| A-3 | `Detail/FilesTabView.swift:244` | Status-Dot `frame(width: 7, height: 7)` statt Haus-Standard 5×5 (`WidgetContainer.swift:88`, `AllPlansView.swift:415`, `AllOffersView.swift:370`, `TodayView:148`). | `.frame(width: 5, height: 5)`. | mittel |
| A-4 | `Detail/OffersTabView.swift:41` | Sektions-`VStack spacing: MykSpace.s7` bricht das Kohorten-Raster `s5` (AllPlans:141, AllOffers:166, Material:76, Timeline:28). | `spacing: MykSpace.s5` — falls größerer Abstand bewusst, kommentieren. | mittel |
| A-5 | `Detail/AllOffersColumns.swift:163` | Rohes `.padding(.trailing, 24)` (≈ zwischen s6=22 und s7=28), innerhalb sonst durchgängig getokter Angebote-Kohorte. | `.padding(.trailing, MykSpace.s6)` (22) oder `s7` (28). | mittel |
| A-6 | `KatalogeView.swift:220` | Header `.top MykSpace.s9` (48) statt Modul-Standard `.top s7` (AllPlans:149, AllOffers:174, alle Detail-Tabs) → Kataloge-Überschrift sitzt tiefer als jede andere Modul-Überschrift. | `.padding(.top, MykSpace.s7)` — außer bewusst gewollt. | mittel |
| A-7 | `Detail/OffersTabView.swift:404` (`.vertical, 1`) · `:534` (`.vertical, 4`) | Mikro-Roh-Insets für Badges unterhalb `s2`=6; es gibt keine Token-Stufe darunter. | Akzeptabel als Ausnahme; falls Badge-Vertikalen app-weit häufig (MailClientView:545, KatalogeView:247, WidgetSelectorView:95 je `.vertical, 2`), lohnt ein `MykSpace.s1=3`-Token, sonst lassen. | niedrig |

Gegenprobe positiv (kein Finding): Such-/Filter-Felder in AllPlansView (`:212-213`),
AllOffersView (`:239-240`), MaterialTabView (`:216-217`) und alle Filter-Menüs nutzen
einheitlich `.horizontal MykSpace.s4 / .vertical MykSpace.s3`. Diese Dimension ist sauber.

---

## Dimension 2 — Skalierung

Gesamturteil: überwiegend sauber. Der Kernpfad (DocumentViewerView, ProjectHeroView/Store,
DateiKachel, FilePreviewView, ThumbnailStore) ist gegen „großes Bild sprengt Layout" bereits
gehärtet — `GeometryReader`+`.clipped()`, gedeckelte Import-/Thumbnail-Pixelgrößen,
`scaledToFit`/`scaledToFill` mit Bezugsrahmen, dokumentierte Bug-Fixes (SCHMIDT→DT, „Bild
sprengt Pane"). Keine offene Stelle gefunden, an der ein großes Bild/PDF/Fenster das Layout
real sprengt. Zwei niedrigschwellige Konsistenz-/Robustheits-Punkte:

| # | Datei:Zeile | Problem | Empfohlener Fix | Schwere |
|---|---|---|---|---|
| B-1 | `Sources/MykilosApp/Gallery/ProjectCard.swift:238-246` | `focalImage(_:in:)` liefert übergroßes `Image` im `Color.clear.overlay` **ohne eigenes `.clipped()``; die identischen Zwillinge haben es (`ProjectHeroView.swift:100`, `ProjectFavoritesWidget.swift:173`). Nur das äußere `.clipped()` am Aufrufer (`ProjectCard.swift:82`) fängt es ab — fragil: fällt das äußere weg, blutet das Bild bei Extrem-Seitenverhältnissen über die Kartenkante ins Grid. | `.frame(width:height:)` in Zeile 245 um `.clipped()` ergänzen (analog Z. 100/173). Datenhygiene-Nebenbefund: `focalImage` ist 3× nahezu wortgleich dupliziert → Kandidat für geteilte `MykilosDesign`-Helper-View. | niedrig |
| B-2 | `Sources/MykilosApp/WebshopTabs.swift:657` (`produktbild`) · `:571` (`ArtikelMiniaturBild`) | AsyncImage-Erfolgszweig nutzt `.resizable().aspectRatio(contentMode: .fit)`. Aktuell layout-sicher, weil Container feste Rahmen setzt (`:670 frame(height:220)`, `:586 frame(width/height:groesse)`). Nur ein Hinweis: würde der Container künftig unbeschränkt, hat `.fit` ohne `maxWidth/maxHeight`-Deckel keinen Bezug (exakt der in `DocumentViewerView.swift:175-178` dokumentierte alte Bug). | Kein Fix nötig, solange die festen Frames stehen. Beim Umbau `maxWidth/maxHeight`-Grenze mitziehen. | niedrig |

Explizit sauber geprüft (kein Handlungsbedarf): `DocumentViewerView.swift:179-181`
(Bild-Case bounded, dokumentierter Fix; PDF via `PDFView.autoScales`, QuickLook via
`QLPreviewView`), `ProjectHeroView.swift` (`GeometryReader`+`.clipped()`, feste Höhe 190,
Titel `minimumScaleFactor(0.5)`), `ProjectHeroImageStore.swift` (Import auf 2400 px
heruntergerechnet), `DateiGalerie.swift` (`scaledToFill`+`clipShape`, adaptive Grid),
`FilePreviewView.swift` (bounded frames), `ThumbnailStore.swift` (Remote auf `min(1600,…)`
gedeckelt), `ProjectFavoritesWidget/MoodboardPort/AppDock/MykWordmark` (`.resizable()`+fester
Rahmen), `AssistantChatView.swift` (nur SF-Symbols). Die im Prompt genannten Verdächtigen
sind die am besten gehärteten Dateien im Repo.

---

## Dimension 3 — Tokens + Renderstates

Weitgehend sauber. Der Sweep über rohe Farben/System-Fonts liefert nur einen echten Treffer
im Feature-/Widget-Code; alle übrigen sind Token-Infrastruktur (`Tokens.swift`/`Typography.swift`),
Kommentare, oder die dokumentierte `MykPDFRenderer`-PDF-Druck-Ausnahme. `WidgetRenderState`
definiert alle 6 Zustände; `WidgetContainer` rendert sie zentral. Keine echte Lücke bei einem
Widget, das einen dieser Zustände wirklich braucht.

| # | Datei:Zeile | Problem | Empfohlener Fix | Schwere |
|---|---|---|---|---|
| C-1 | `Sources/MykilosWidgets/DateiGalerie.swift:94` | `.font(.system(size: side * 0.3))` ist echter Code im gelinteten Target. Die Custom-Rule `no_system_font_in_features` matcht die Zeile → `swiftlint --strict` bricht hart. Der Prosa-Kommentar „bewusste Token-Ausnahme" hält den Linter NICHT auf. Die dynamische, kachelgrößen-abhängige Größe ist inhaltlich gerechtfertigt. | Entweder `// swiftlint:disable:next no_system_font_in_features` (ehrlichste Minimal-Lösung), oder `.font(Font.mykBody)` + `.scaleEffect(side*0.3 / basiskonstante)`. Ziel: `--strict` grün. | niedrig |
| C-2 | systemweit — `DriveWidget.swift:114-121`, `CalendarWidget.swift:102-109`, `ContactsWidget.swift:106-113`, `MailWidget.swift:107-114`, `TasksWidget.swift:120-127`, `CashWidget.swift:323-330`, `Today/ClockodoWidget.swift:112-115`, `Detail/*TabView`-Loader | `.offline(since:)`-Renderstate wird von KEINEM Widget je emittiert (toter Code): jeder Loader mappt „nicht verbunden" → `.permissionRequired` und JEDEN anderen Fehler (inkl. echter Offline-Fehler) → `.error(String(describing:))`. Realer Offline-Fall zeigt „Fehler: The Internet connection appears to be offline" statt der gebauten `wifi.slash`-Kachel (`WidgetContainer.swift:137`). | In den `catch`-Blöcken vor dem generischen `.error` ein `catch let e as URLError where e.code == .notConnectedToInternet \|\| e.code == .networkConnectionLost` → `renderState = .offline(since: Date())`. Design-Schuld, kein Bug (V1 bewusst Offline/Auth zusammengefasst). | niedrig |

Sauber bestätigt (keine Lücke): Drive/Calendar/Contacts/Mail/Tasks-Widgets (vollständige
Zustandsableitung + Retry); `CashWidget` (`renderState: .content` am Container ist korrekt —
Loader-Zustände inline in `budgetSection:208-225`, damit Signal-Whisper vom sevdesk-Zustand
unabhängig lebt); `NotesWidget` (rein lokal, Persistenz über `SaveStateBar`);
`WarenkorbWidget` (loading/error/content lokal); `BarcodeWidget`/`RechnerWidget`/`FocusWidget`
(interaktive lokale Tools, kein async Load); `ProjectFavoritesWidget` (loading+content); alle
Detail-Tab-Loader (vollständig, mit Retry). Keine rohen Farben im Feature-Code.

**Doku-Drift (kein Finding, zur Kenntnis):** CLAUDE.md beschreibt ein `KalkulationsWidget.swift`
mit „allen 6 Renderstates" unter `Kinds/` — diese Datei existiert nicht mehr; Kalkulation lebt
nur noch als Chat-Card in `AssistantChatView.swift` (konsistent mit „Kalkulation von Sidebar
entkoppeln"). Free-Climber-Anker-Prinzip: Projektdoku an der Stelle veraltet.

---

## Top-5 Quick-Wins (klein, sicher)

Kleine, lokal begrenzte, niedrig-riskante Fixes — trotzdem gilt die visuelle Abnahme.

1. **`FilesTabView.swift:244`** — Status-Dot `7×7` → `5×5`. Ein-Zahl-Änderung, richtet Files-Tab
   auf den app-weiten Quellzeilen-Standard aus. (A-3)
2. **`OffersTabView.swift:41`** — Sektions-`spacing: MykSpace.s7` → `MykSpace.s5`. Bringt den
   Angebote-Tab auf das Kohorten-Raster. (A-4)
3. **`KatalogeView.swift:220`** — Header `.top MykSpace.s9` → `.top MykSpace.s7`. Setzt die
   Kataloge-Überschrift auf dieselbe Höhe wie jede andere Modul-Überschrift. (A-6)
4. **`AllOffersColumns.swift:163`** — rohes `.padding(.trailing, 24)` → `MykSpace.s6`. Ein
   Roh-Wert weniger, kein Layout-Sprung. (A-5)
5. **`DateiGalerie.swift:94`** — `// swiftlint:disable:next no_system_font_in_features`
   voranstellen. Macht `swiftlint --strict` grün, ohne die legitime dynamische Größe anzufassen. (C-1)

Bewusst NICHT als Quick-Win eingestuft: A-1 (Detail-Tab-Zentralisierung) und A-2 (SaveBar-Token)
sind die höchstwertigen Findings, aber sie berühren mehrere Views gleichzeitig und tragen echtes
Layout-Drift-Risiko — die gehören in eine eigene, gegen Screenshots verifizierte Runde.
