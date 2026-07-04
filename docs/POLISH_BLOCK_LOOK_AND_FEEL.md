# Look & Feel Polish Block (2026-07-04, Nachtlauf)

**Leitgedanke:** *Ehrliche, konsistente Oberfläche.* Die App zeigt nie widersprüchliche,
platzhalterhafte oder redundante Information. Kein neuer Funktionsumfang — nur Schliff.
Quelle: Bilder-Inventur des Feedback-Ordners (2026-07-04) + [[design-nordstern-minimal]].

## Punkte (verifizierbar per Logik/Test — kein Live-Screenshot nötig)

| # | Fund (aus Screenshots) | Datei | Status |
|---|---|---|---|
| P1 | „EK 0.00 €"/„VK 0 €" wirkt unfertig → 0-Werte ausblenden | ProjectFavoritesWidget/Verlauf | ⏳ |
| P2 | Favoriten-Zähler „7" bei 6 sichtbaren Karten → Zähler = Realität | ProjectFavoritesWidget | ⏳ |
| P3 | Heute-Signale doppeln sich (gleiches Projekt mehrfach) → dedup | TodayView/Signal-Strip | ⏳ |
| P4 | Pipeline-Karte „Neuhaus / Neuhaus" → Kunde nur wenn ≠ Titel | ProjectCard/ProjectPipelineView | ⏳ |
| P5 | Dateien-Tab: zwei „Prüfen"-Leisten (Banner + innen) → eine | FilesTabView/DriveFolderRefreshBar | ⏳ |
| P6 | „ZEIT 0 h" im Hero → nur zeigen wenn > 0 | ProjectHeroView | ⏳ |

## Vorsichtig (rein visuell — defensiv verbessern + für Live-Abnahme flaggen)

| # | Fund | Ansatz |
|---|---|---|
| P7 | Command-Bar/Titel-Umbruch „Pro jekt e" bei schmaler Breite | lineLimit(1)+minWidth / ViewThatFits, low-risk |

## Regeln für diesen Block
- Schritt-Test-Safe: ein Punkt = ein Commit, Build+Tests grün.
- Kein Live-Screenshot (Johannes weg, No-Screenuse-Regel) → nur logik-/testverifizierbare
  Fixes voll durchziehen; rein visuelle defensiv + explizit zur Live-Abnahme markieren.
- Token-Disziplin (MykColor/Font.myk…), keine `.font(.system)`/Rohfarben.
- Am Ende: Version-Bump + DMG mit Schleife.
