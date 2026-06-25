# Handoff — Akt 3, Schritt 7: Drag & Drop im Widget-Board

**Status:** abgeschlossen

---

## Was passiert ist

Widget-Boards (Home + Projekt) unterstützen jetzt Drag & Drop zum Umsortieren.

### Geänderte Dateien

| Datei | Was |
|---|---|
| `Sources/MykilosApp/Today/HomeBoardView.swift` | `.draggable()` + `.dropDestination()` auf jeder Widget-Zelle. Drop-Highlight (Ocker-Rahmen). `handleDrop` ruft `boardStore.move()` auf, persistiert automatisch via GRDB. |
| `Sources/MykilosApp/Detail/ProjectDetailView.swift` | Gleiches Drag & Drop-Muster für `ProjectWidgetBoardView`. Zusätzlich: `mailQuery` durchgereicht (fehlte seit S6), `.mail`-Case im Widget-Dispatch ergänzt. |

### Nicht geändert

`WidgetBoardView` (MykilosWidgets) — das ist die alte stateless View aus Akt 1, die nicht mehr aktiv genutzt wird. Drag & Drop lebt in den App-level Board-Views, die direkten Zugriff auf den `WidgetBoardStore` haben.

---

## Architektur-Entscheidungen

1. **SwiftUI `.draggable` + `.dropDestination`** — Moderne API (macOS 14+), kein Legacy `onDrag`/`onDrop`. `Transferable`-Typ ist `String` (UUID als String).

2. **Flat-Index-Reorder** — Drag & Drop arbeitet auf den flachen Indizes von `boardStore.instances`, nicht auf der 2D-Grid-Position. `WidgetBoardStore.move(fromOffsets:toOffset:)` persistiert automatisch via GRDB.

3. **Visuelles Feedback** — Drop-Target bekommt einen Ocker-Rahmen (Highlight). Kein Opacity-Fadeout beim Draggen — SwiftUI erzeugt automatisch ein Drag-Preview.

4. **Kein `WidgetBoardView`-Umbau** — Die alte stateless View in MykilosWidgets wird perspektivisch entfernt oder zum reinen Preview-Renderer. Live-Boards laufen über HomeBoardView und ProjectWidgetBoardView.

---

## Tests

57 Tests grün (keine neuen Tests — Drag & Drop ist reine UI-Logik, `WidgetBoardStore.move` war bereits durch `WidgetBoardStoreTests` abgedeckt).

---

## Offene Punkte

- **Kein Cross-Size-Feedback** — Wenn ein `wide`-Widget auf einen `medium`-Slot gezogen wird, passt sich die Zeilen-Packung automatisch an, aber es gibt keine visuelle Vorschau des neuen Layouts während des Drags.
- **Kein Undo** — Ein versehentlicher Drop kann nicht rückgängig gemacht werden (kein UndoManager-Integration).
- **`WidgetBoardView` Cleanup** — Die alte View in MykilosWidgets sollte perspektivisch entfernt werden, da sie nicht mehr aktiv genutzt wird und eine redundante Kopie des Dispatch-Switches pflegt.
