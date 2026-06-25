import SwiftUI
import MykilosKit
import MykilosDesign
import MykilosServices
import MykilosWidgets

// MARK: - HomeBoardView
// Das Home-Widget-Grid. Nutzt WidgetBoardStore für Persistenz.
// Widget-Typen sind Home-spezifisch + die bekannten Projekt-Widgets (notes etc).
struct HomeBoardView: View {
    let boardStore: WidgetBoardStore
    let noteStore:  NoteStore

    var body: some View {
        Grid(alignment: .topLeading,
             horizontalSpacing: MykSpace.s5,
             verticalSpacing: MykSpace.s5) {
            ForEach(rows, id: \.id) { row in
                GridRow {
                    ForEach(row.items) { instance in
                        homeWidgetView(for: instance)
                            .gridCellColumns(instance.size.columnSpan)
                    }
                    if row.needsFiller {
                        Color.clear.gridCellColumns(row.fillerSpan)
                    }
                }
            }
        }
    }

    // MARK: Widget-Dispatch (Home-Arten + Projekt-Arten wo sinnvoll)
    @ViewBuilder
    private func homeWidgetView(for instance: WidgetInstance) -> some View {
        switch instance.kind.rawValue {
        case "focus":        FocusWidget()
        case "projectFaves": ProjectFavoritesWidget()
        case "clockodo":     ClockodoWidget()
        case "recentActivity": RecentActivityWidget()
        case "notes":        NotesWidget(projectID: "home", noteStore: noteStore)
        default:             EmptyView()
        }
    }

    // MARK: Zeilen-Bin-Packing
    private var rows: [BoardRow] {
        var result: [BoardRow] = []
        var remaining = boardStore.instances.filter(\.isVisible)
            .sorted { $0.position < $1.position }
        while !remaining.isEmpty {
            var rowItems: [WidgetInstance] = []
            var used = 0
            while !remaining.isEmpty && used < 3 {
                let next = remaining[0]
                let span = next.size.columnSpan
                if used + span <= 3 {
                    rowItems.append(next); used += span; remaining.removeFirst()
                } else { break }
            }
            result.append(BoardRow(items: rowItems, totalColumns: 3))
        }
        return result
    }
}

// BoardRow auch für HomeBoardView — selbe Logik wie WidgetBoardView
private struct BoardRow: Identifiable {
    let id = UUID()
    let items: [WidgetInstance]
    let totalColumns: Int
    var usedSpan: Int { items.reduce(0) { $0 + $1.size.columnSpan } }
    var fillerSpan: Int { totalColumns - usedSpan }
    var needsFiller: Bool { fillerSpan > 0 }
}
