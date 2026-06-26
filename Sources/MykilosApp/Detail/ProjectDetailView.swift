import SwiftUI
import MykilosKit
import MykilosDesign
import MykilosServices
import MykilosWidgets

// MARK: - ProjectDetailView (Akt 2)
// Nutzt jetzt AppState für WidgetBoardStore und NoteStore — persistent, GRDB.
struct ProjectDetailView: View {
    let project: Project
    let onBack: () -> Void

    @Environment(StudioContext.self) private var context
    @Environment(AppState.self)      private var appState
    @State private var activeTab: ProjectTab = .overview

    private var boardStore: WidgetBoardStore { appState.board(for: project.projectNumber, kind: project.kind) }
    private var noteStore:  NoteStore        { appState.notes(for: project.projectNumber) }

    var body: some View {
        ZStack(alignment: .bottom) {
            MykColor.paper.color.ignoresSafeArea()
            VStack(spacing: 0) {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        ProjectHeroView(
                            project:  project,
                            customer: appState.registry.customer(for: project),
                            onBack:   onBack
                        )
                        tabBar
                        Divider().overlay(MykColor.line.color)
                        SignalDemoView(projectID: project.projectNumber)
                        tabContent
                    }
                }
            }
            // Sichtbarer Speichern-Vertrag für das Widget-Board
            SaveStateBar(state: boardStore.saveState) {
                try? boardStore.save()
            }
        }
        .onAppear {
            context.focus(project: project.projectNumber)
            try? boardStore.load()
            try? noteStore.load()
        }
    }

    // MARK: Tab-Leiste
    private var tabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                ForEach(ProjectTab.allCases) { tab in
                    TabButton(tab: tab, isActive: activeTab == tab) {
                        withAnimation(.easeInOut(duration: 0.15)) { activeTab = tab }
                    }
                }
            }
            .padding(.horizontal, MykSpace.s9)
            .padding(.top, MykSpace.s5)
        }
    }

    @ViewBuilder
    private var tabContent: some View {
        switch activeTab {
        case .overview:
            ProjectWidgetBoardView(
                boardStore: boardStore,
                noteStore: noteStore,
                auditStore: appState.audit,
                llmProvider: appState.claudeAuth.status == .connected ? appState.assistantLLM : nil,
                projectID: project.projectNumber,
                driveFolderID: project.links.driveFolderID,
                clickUpListID: project.links.clickUpListID,
                calendarQuery: project.links.calendarQuery,
                contactsQuery: project.links.contactsQuery,
                mailQuery: project.links.mailQuery
            )
                .padding(.horizontal, MykSpace.s9)
                .padding(.top, MykSpace.s7)
                .padding(.bottom, 64)   // Platz für SaveStateBar
        default:
            ComingTabView(tab: activeTab)
        }
    }
}

// MARK: - ProjectWidgetBoardView
private struct ProjectWidgetBoardView: View {
    let boardStore: WidgetBoardStore
    let noteStore:  NoteStore
    let auditStore: AuditStore
    let llmProvider: (any AssistantLLMProviding)?
    let projectID:  String
    let driveFolderID: String?
    let clickUpListID: String?
    let calendarQuery: String?
    let contactsQuery: String?
    let mailQuery: String?

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
    }

    private func draggableCell(for instance: WidgetInstance) -> some View {
        projectWidgetView(for: instance)
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

    @ViewBuilder
    private func projectWidgetView(for instance: WidgetInstance) -> some View {
        switch instance.kind {
        case .drive:     DriveWidget(projectID: projectID, driveFolderID: driveFolderID)
        case .tasks:     TasksWidget(projectID: projectID, clickUpListID: clickUpListID)
        case .contacts:  ContactsWidget(projectID: projectID, contactsQuery: contactsQuery)
        case .cash:      CashWidget(projectID: projectID)
        case .calendar:  CalendarWidget(projectID: projectID, calendarQuery: calendarQuery)
        case .notes:     NotesWidget(projectID: projectID, noteStore: noteStore)
        case .assistant: AssistantWidget(projectID: projectID, auditStore: auditStore, llmProvider: llmProvider)
        case .mail:      MailWidget(projectID: projectID, mailQuery: mailQuery)
        default:         EmptyView()
        }
    }

    private var rows: [RowLayout] {
        var result: [RowLayout] = []
        var remaining = boardStore.instances.filter(\.isVisible).sorted { $0.position < $1.position }
        while !remaining.isEmpty {
            var rowItems: [WidgetInstance] = []; var used = 0
            while !remaining.isEmpty && used < 3 {
                let next = remaining[0]; let span = next.size.columnSpan
                if used + span <= 3 { rowItems.append(next); used += span; remaining.removeFirst() } else { break }
            }
            result.append(RowLayout(items: rowItems, totalColumns: 3))
        }
        return result
    }
}

private struct RowLayout: Identifiable {
    let id = UUID(); let items: [WidgetInstance]; let totalColumns: Int
    var usedSpan: Int { items.reduce(0) { $0 + $1.size.columnSpan } }
    var fillerSpan: Int { totalColumns - usedSpan }
    var needsFiller: Bool { fillerSpan > 0 }
}

// MARK: - Tab-Helfer
enum ProjectTab: String, CaseIterable, Identifiable {
    case overview = "Übersicht"; case files = "Dateien"; case offers = "Angebote"
    case timeline = "Timeline"; case material = "Material"
    var id: String { rawValue }
}

private struct TabButton: View {
    let tab: ProjectTab; let isActive: Bool; let action: () -> Void
    @State private var isHovered = false
    var body: some View {
        Button(action: action) {
            Text(tab.rawValue).font(.mykSmall)
                .foregroundStyle(isActive ? MykColor.ink.color : MykColor.muted.color)
                .padding(.horizontal, MykSpace.s5).padding(.bottom, MykSpace.s4)
                .overlay(alignment: .bottom) {
                    if isActive { Rectangle().fill(MykColor.ink.color).frame(height: 2) }
                }
        }
        .buttonStyle(.plain).onHover { isHovered = $0 }
    }
}

private struct ComingTabView: View {
    let tab: ProjectTab
    var body: some View {
        VStack { Spacer().frame(height: 80)
            Text("\(tab.rawValue) — in Vorbereitung").font(.mykBody).foregroundStyle(MykColor.muted.color)
        }.frame(maxWidth: .infinity).padding(MykSpace.s9)
    }
}
