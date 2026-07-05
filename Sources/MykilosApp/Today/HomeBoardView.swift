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

    @State private var dropTargetID: UUID?

    var body: some View {
        Grid(alignment: .topLeading,
             horizontalSpacing: MykSpace.s5,
             verticalSpacing: MykSpace.s5) {
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
        .frame(minWidth: 0, maxWidth: .infinity, alignment: .topLeading)
    }

    private func draggableCell(for instance: WidgetInstance) -> some View {
        homeWidgetView(for: instance)
            .gridCellColumns(instance.size.columnSpan)
            .overlay(dropHighlight(for: instance.id))
            .draggable(instance.id.uuidString)
            .dropDestination(for: String.self) { items, _ in
                handleDrop(items: items, targetID: instance.id)
            } isTargeted: { targeted in
                dropTargetID = targeted ? instance.id : nil
            }
    }

    private func dropHighlight(for id: UUID) -> some View {
        RoundedRectangle(cornerRadius: MykRadius.md)
            .stroke(MykColor.tasks.color, lineWidth: 2)
            .opacity(dropTargetID == id ? 1 : 0)
    }

    private func handleDrop(items: [String], targetID: UUID) -> Bool {
        defer { dropTargetID = nil }
        guard let droppedString = items.first,
              let droppedUUID = UUID(uuidString: droppedString),
              let sourceIndex = boardStore.instances.firstIndex(where: { $0.id == droppedUUID }),
              let destIndex = boardStore.instances.firstIndex(where: { $0.id == targetID }),
              sourceIndex != destIndex else { return false }
        let offset = destIndex > sourceIndex ? destIndex + 1 : destIndex
        try? boardStore.move(fromOffsets: IndexSet(integer: sourceIndex), toOffset: offset)
        return true
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
        case "barcode":      BarcodeWidget()
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

private struct BoardRow: Identifiable {
    let items: [WidgetInstance]
    let totalColumns: Int
    var id: UUID { items.first?.id ?? Self.emptyRowID }
    private static let emptyRowID = UUID()
    var usedSpan: Int { items.reduce(0) { $0 + $1.size.columnSpan } }
    var fillerSpan: Int { totalColumns - usedSpan }
    var needsFiller: Bool { fillerSpan > 0 }
}
