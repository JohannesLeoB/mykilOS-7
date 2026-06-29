# HANDOFF — feat/layout-polish (Spacings in allen Modi geradeziehen)

```
Pfad:   /Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilOS6/
Branch: feat/layout-polish (von feat/sidebar-app-dock — enthält S25–S28)
Modell: Opus 4.8 empfohlen (siehe unten)
Datum:  2026-06-30
```

> ⚠️ Nicht der veralteten `CLAUDE.md` trauen. Lebender Stand: HYPERBUILD + Memory.

## Ziel
Durch die vielen UI-Umbauten (S25–S28) sind **Abstände Inhalt↔Rand gedriftet** — inkonsistent
zwischen den Modi, am stärksten im **Sidebar-Mini-(Kompakt-)Modus**. Alles **app-weit konsistent
geradeziehen**, in **allen** Modi.

## ⛔ Harte Arbeitsregel: KEIN Screen-Use
- **Keine computer-use / Screenshots durch diese Session.** Rein code-basiert.
- Den **visuellen Abgleich macht Johannes MORGEN.** Deshalb: **principled** arbeiten, nicht
  „pixeln durch Ausprobieren". Konsistenz über klare Regeln + Token-Disziplin, nicht über Raten.

## Vorgehen (principled)
1. **Inventar:** Wo werden Spacing-Tokens (`MykSpace.s1…s9`) für content-to-edge benutzt — Shell,
   `SidebarView`, `AppDock`, die Page-Views (TodayView, ProjectGalleryView, AssistantPageView,
   GlobalOffersView, KatalogeView, ProjectDetailView, SettingsView)? Liste die Ist-Werte.
2. **EINE Regel festlegen** und überall durchziehen, z. B.:
   - Page-Inhalt: einheitlicher horizontaler Rand (vermutlich `MykSpace.s9`) — überall gleich.
   - Sidebar: konsistente Insets, die **expanded UND compact** sauber aufgehen (gleicher Abstand
     der Icons/Texte zum Rail-Rand; im Kompakt-Modus alles sauber zentriert auf EINER Mittellinie:
     Brand, NavItems, App-Dock, Footer-Avatar).
   - App-Dock-Pille: linke Kante / Breite konsistent mit den NavItem-Reihen (breit) bzw. zentriert (kompakt).
3. **Bekannte Verdächtige (zuerst prüfen):** `SidebarView` Haupt-VStack `.padding(.horizontal/.vertical)`,
   `AppDockStrip` Pillen-Insets vs. NavItem-Breite, Footer-Alignment in beiden Modi, die in
   S25/S27/S28 angefassten Paddings. Header/Subtitle-Abstände der Page-Views gegenchecken.
4. **Dokumentieren:** je geänderter Regel ein kurzer Kommentar („einheitlicher Page-Rand s9" etc.),
   damit Johannes' visueller Check morgen schnell geht.

## Regeln
- Token-Disziplin: nur `MykSpace`/`MykColor`/`Font.myk…` (SwiftLint). Keine Magic-Numbers neu einführen.
- Signierte Commits, Conventional Commits. `main` heilig. **Nicht pushen/mergen** — Johannes
  verifiziert visuell morgen, dann erst weiter.
- `swift build` + `swift test` (428) grün als Gate.

## Abschluss-Liefergegenstand
- Build + 428 Tests grün.
- Eine kurze **„Geändert + warum"-Liste** (Datei · alter Wert → neuer Wert · Grund) — die ist
  morgen Johannes' Checkliste beim visuellen Abgleich.
