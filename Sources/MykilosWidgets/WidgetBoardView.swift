import SwiftUI
import MykilosKit
import MykilosDesign
import MykilosServices

// MARK: - WidgetBoardView
// Rendert das Widget-Grid für ein Projekt. Nutzt SwiftUI Grid mit
// gridCellColumns für echte 3-Spalten-Layouts. Layout-Strategie per
// Projekt-Archetyp: jeder Kind-Typ bekommt eine kurierte Anordnung.
// Die volle drag&drop-Customization kommt in Akt 2.
public struct WidgetBoardView: View {
    public let instances: [WidgetInstance]
    public let projectID: String
    public let noteStore: NoteStore

    public init(instances: [WidgetInstance], projectID: String, noteStore: NoteStore) {
        self.instances = instances.filter(\.isVisible).sorted { $0.position < $1.position }
        self.projectID = projectID
        self.noteStore = noteStore
    }

    public var body: some View {
        Grid(alignment: .topLeading, horizontalSpacing: MykSpace.s5, verticalSpacing: MykSpace.s5) {
            ForEach(rows, id: \.id) { row in
                GridRow {
                    ForEach(row.items) { instance in
                        widgetView(for: instance)
                            .gridCellColumns(instance.size.columnSpan)
                    }
                    // Leer-Zellen auffüllen, damit Grid-Ausrichtung stimmt
                    if row.needsFiller {
                        Color.clear
                            .gridCellColumns(row.fillerSpan)
                    }
                }
            }
        }
    }

    // MARK: Widget-Dispatch
    @ViewBuilder
    private func widgetView(for instance: WidgetInstance) -> some View {
        switch instance.kind {
        case .drive:     DriveWidget(projectID: projectID, driveFolderID: nil)
        case .tasks:     TasksWidget(projectID: projectID)
        case .contacts:  ContactsWidget(projectID: projectID, contactsQuery: nil)
        case .cash:      CashWidget(projectID: projectID)
        case .calendar:  CalendarWidget(projectID: projectID, calendarQuery: nil)
        case .notes:     NotesWidget(projectID: projectID, noteStore: noteStore)
        case .assistant: AssistantWidget(projectID: projectID)
        case .focus, .projectFaves, .clockodo, .recentActivity:
            EmptyView()
        }
    }

    // MARK: Zeilen-Bin-Packing (greedy, Akt 1 — statisch gut genug)
    // Füllt Instanzen Zeile für Zeile in ein 3-Spalten-Raster.
    private var rows: [BoardRow] {
        var result: [BoardRow] = []
        var remaining = instances
        while !remaining.isEmpty {
            var rowItems: [WidgetInstance] = []
            var used = 0
            while !remaining.isEmpty && used < 3 {
                let next = remaining[0]
                let span = next.size.columnSpan
                if used + span <= 3 {
                    rowItems.append(next)
                    used += span
                    remaining.removeFirst()
                } else { break }
            }
            result.append(BoardRow(items: rowItems, totalColumns: 3))
        }
        return result
    }
}

// MARK: - BoardRow
private struct BoardRow: Identifiable {
    let id = UUID()
    let items: [WidgetInstance]
    let totalColumns: Int

    var usedSpan: Int { items.reduce(0) { $0 + $1.size.columnSpan } }
    var fillerSpan: Int { totalColumns - usedSpan }
    var needsFiller: Bool { fillerSpan > 0 }
}
