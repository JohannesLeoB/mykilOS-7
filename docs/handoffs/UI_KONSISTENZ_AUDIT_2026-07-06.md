# UI/UX-Konsistenz-Audit — 2026-07-06 (Nacht-Session)

```
Pfad:   /Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilOS6/
Branch: feat/multi-user-login
Status: NUR DOKUMENTIERT, NICHTS GEÄNDERT — braucht Johannes' Live-Sichtprüfung
```

## Warum nur dokumentiert, nicht gebaut

Johannes' Auftrag: jede Unterseite gegen ein Master-Layout prüfen, analytisch, gründlich,
Funktionen unangetastet. Ein 4-Agenten-Audit hat 24+ Spacing-Abweichungen und 4 strukturelle
Header-Inkonsistenzen gefunden. **Aber:** fast keine der vorgeschlagenen Korrekturen ist eine reine
Syntax-Umbenennung — die meisten ändern den tatsächlichen Zahlenwert (z. B. `.padding(.vertical, 7)`
→ `MykSpace.s3` = 12pt ist eine sichtbare +71%-Vergrößerung, kein Alias). Ohne Screenshot-Vergleich
kann ich nicht beurteilen, ob das Ergebnis besser oder schlechter aussieht — und Screenuse ist in
dieser Session tabu. Blind 24 visuelle Werte über Nacht zu ändern wäre genau das "gegen die Wand
fahren", vor dem Johannes gewarnt hat. Deshalb: sauber dokumentiert, review-bereit, nichts angefasst.

## A — Mechanische Token-Verstöße (Wert würde sich ändern, braucht Sicht-Check)

| Datei | Zeile | Aktuell | Vorschlag | Δ |
|---|---|---|---|---|
| `SchaltzentrumView.swift` | 148–149 | `.padding(.horizontal, 4)` / `.padding(.vertical, 2)` | `MykSpace.s2` (8) / `MykSpace.s1` (4) | 4→8, 2→4 |
| `MykilOS6App.swift` | 519 | `.padding(3)` | `MykSpace.s1` (4) | 3→4 |
| `Today/TodayView.swift` | 156 | `.padding(.vertical, 5)` | `MykSpace.s2` (8) | 5→8 |
| `Today/HeuteAnstehendView.swift` | 280 | `.padding(3)` | `MykSpace.s1` (4) | 3→4 |
| `Today/FocusWidget.swift` | 111 | `.padding(.top, 5)` | `MykSpace.s2` (8) | 5→8 |
| `Gallery/ProjectCard.swift` | 200, 214, 95, 106 | `.padding(6)`, `.padding(.horizontal,7).padding(.vertical,3)`, `.padding(.vertical,4)`, `.padding(.vertical,5)` | `MykSpace.s2/s3/s1` | mehrfach |
| `Detail/ProjectHeroView.swift` | 124, 147, 187, 198, 327 | `.padding(.vertical, 7)` (5×) | `MykSpace.s3` (12) | 7→12 |
| `Mail/MailClientView.swift` | 544-545, 508 | `.padding(.horizontal,6).padding(.vertical,2)`, `.padding(.vertical,4)` | `MykSpace.s3/s1/s2` | mehrfach |
| `Mail/ComposeMailView.swift` | 380 | `.padding(.vertical, 4)` | `MykSpace.s2` (8) | 4→8 |
| `Settings/KeychainInventoryView.swift` | 89, 101 | `.padding(.leading, 22)`, `.padding(.vertical, 2)` | `MykSpace.s7`, `MykSpace.s1` | ~22→20, 2→4 |
| `KatalogeView.swift` | 247 | `.padding(.vertical, 2)` | `MykSpace.s1` (4) | 2→4 |
| `Shell/AppDock.swift` | 155 | `.padding(.vertical, 3)` | `MykSpace.s1/s2` | 3→4/8 |
| `Shell/SidebarView.swift` | 321 | `.padding(.vertical, 10)` | `MykSpace.s4` (16) | 10→16 |

**Font:** `Mail/MailClientView.swift:322` — `.font(.largeTitle)` statt `Font.mykTitle`/`mykHeadline`
(unklar, welche Token-Größe optisch am nächsten liegt — Sichtvergleich nötig).

**Color (Dark-Mode-Risiko, NICHT blind ändern):** `.white`/`.black.opacity(...)` ohne `MykColor` in
`ProjectHeroView.swift` (7×), `ProjectCard.swift` (5×), `CommandPaletteView.swift:33`,
`ProjektTimerView.swift:113`, `ProvisioningTestView.swift:66`, `TimerSidebarPill.swift:72`.
Diese am wenigsten blind anfassen — Kontrast/Dark-Mode kann brechen, reine Optik-Entscheidung.

## B — Strukturelle Muster-Abweichung (Design-Entscheidung, kein Bugfix)

**Header-Padding ist auf jeder Haupt-Seite eigenständig gebaut** (kein gemeinsames Component) —
das ist vermutlich die technische Ursache für Feedback-Item B ("Header sitzen 124–192px unterschiedlich
hoch"):

| Seite | Datei | Padding |
|---|---|---|
| Heute | `Today/TodayView.swift` | `s9` horizontal + `s5` vertikal |
| Projekte | `Gallery/ProjectGalleryView.swift` | `s9` + `s5` ✅ gleich wie Heute |
| Kataloge | `KatalogeView.swift` | `s9` + `.top s9` + `.bottom s4` — abweichend |
| Assistent | `MykilOS6App.swift:451` | `s9` + `.top s9` + `.bottom s5` — Hybrid |
| Mail | `Mail/MailClientView.swift:166-169` | `s6` (nicht `s9`!) + `.top s6` + `.bottom s3` — deutlich abweichend |

**Entscheidung, die nur Johannes treffen kann:** einen gemeinsamen Header-Standard (`MykHeaderView`
o.ä.) einführen, oder Mail bewusst als schmalere Spalte (320pt) mit kleinerem Padding dokumentieren.

## C — Nur visuell beurteilbar (nicht vertieft, Screenshot nötig)

- MYKILOS-Wortmarke neben Squircle zu klein (Feedback Item C) — vermutlich `Shell/SidebarView.swift`,
  aber welche Zeile/welcher Font-Size-Wert ohne Sichtvergleich nicht bestimmbar.
- Katalog-Ansichten (Alle Angebote/Alle Pläne) nicht bündig — evtl. `AllOffersColumns.swift:163/186`
  (24pt vs. 60pt), ungeprüft.

## Gesamteinschätzung

**Codebase ist überraschend sauber** — geschätzt 85%+ nutzt korrekt `Font.myk*`/`MykColor`. Das hier
sind echte, aber kleine Restabweichungen, kein systemisches Problem.

## Empfehlung für die 9-Uhr-Session

1. Diese Tabelle mit 2-3 echten Screenshots gegenprüfen (v.a. `ProjectHeroView` 7→12, da 5× betroffen).
2. Header-Standard (Punkt B) ist die wertvollste Einzelentscheidung — behebt die einzige bereits
   gemeldete Nutzer-Beschwerde direkt.
3. Color-Funde (Dark-Mode) zuletzt, brauchen den sorgfältigsten Blick.
4. Danach: Werte einzeln übernehmen, jede Änderung mit Vorher/Nachher-Screenshot, kein Batch-Commit.
