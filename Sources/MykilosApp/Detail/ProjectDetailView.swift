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

    // Wie oft der Drive-Ordner auf neue Angebots-PDFs gepollt wird, solange das
    // Projekt offen ist. Bewusst gemächlich — read-only, schont API-Quota.
    private static let offerPollInterval: Duration = .seconds(60)

    private var boardStore: WidgetBoardStore { appState.board(for: project.projectNumber, kind: project.kind) }
    private var noteStore:  NoteStore        { appState.notes(for: project.projectNumber) }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            VStack(alignment: .leading, spacing: 0) {
                // Fester Header (Hero + Tabs) — immer sichtbar, nicht scrollbar.
                ProjectHeroView(
                    project:  project,
                    customer: appState.registry.customer(for: project),
                    onBack:   onBack,
                    isFavorite: appState.favorites.isFavorite(project.projectNumber),
                    onToggleFavorite: { try? appState.favorites.toggle(projectNumber: project.projectNumber) }
                )
                tabBar
                Divider().overlay(MykColor.line.color)
                // Chat braucht volle Höhe; alle anderen Tabs scrollen.
                if activeTab.isFullHeight {
                    tabContent
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 0) {
                            SignalDemoView(projectID: project.projectNumber, driveFolderID: project.links.driveFolderID)
                            tabContent
                        }
                    }
                    .clipped()
                }
            }
            // Sichtbarer Speichern-Vertrag für das Widget-Board — nur bei scrollbaren Tabs.
            if activeTab.isFullHeight == false {
                SaveStateBar(state: boardStore.saveState) {
                    try? boardStore.save()
                }
            }
        }
        // Identischer Fix wie in ProjectGalleryView: ohne diese Angabe würde
        // der VStack eine spezifisch breite Preferred-Size nach oben propagieren
        // (ProjectHeroView + TabBar haben eine eigene Idealbreite, die kleiner als
        // die des Gallery-Grids sein kann) → NSHostingView verschiebt das Fenster.
        .background(MykColor.paper.color)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // Widget-Board-Drift: Widgets laden ihren Inhalt async (API-Runden
        // 300–1800 ms) und verschieben das Fenster, nachdem der initiale
        // 260-ms-Guard aus ProjectGalleryView bereits gefeuert hat.
        // guardWindowPositionOnAppear holt das Fenster nach jedem Lade-Zyklus
        // zurück. guardWindowPosition(on: activeTab) korrigiert beim
        // Tab-Wechsel zurück zur Übersicht.
        .guardWindowPositionOnAppear()
        .guardWindowPosition(on: activeTab)
        .onAppear {
            context.focus(project: project.projectNumber)
            try? boardStore.load()
            try? noteStore.load()
        }
        // Live-Quelle für offerDetected: solange das Projekt offen ist, pollt der
        // Watcher den verlinkten Drive-Ordner. Der erste Lauf legt nur die
        // Baseline an (meldet nichts); danach erzeugt jedes neu aufgetauchte
        // Angebots-PDF ein Signal → Mediator → CashWidget-Review-Vorschlag.
        .task(id: project.links.driveFolderID) {
            guard let folderID = project.links.driveFolderID, folderID.isEmpty == false else { return }
            // Gecachten, projektweiten Watcher holen — seine Baseline/„seen"-Menge
            // überlebt so Navigation, statt bei jeder neuen Detailseite zu
            // re-baselinen (was neue Angebote unsichtbar machte).
            let offerWatcher = appState.offerWatcher(for: project.projectNumber)
            while Task.isCancelled == false {
                let signals = await offerWatcher.poll(projectID: project.projectNumber, folderID: folderID)
                for signal in signals { context.emit(signal) }
                try? await Task.sleep(for: Self.offerPollInterval)
            }
        }
    }

    // MARK: Tab-Leiste
    // frame(maxWidth: .infinity) verhindert, dass der HStack eine zu große
    // preferred width nach oben meldet und den ZStack verschiebt (P0-Fix).
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
        .frame(maxWidth: .infinity, alignment: .leading)
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
                mailQuery: project.links.mailQuery,
                sevdeskRef: project.links.sevdeskRef,
                budget: project.links.budget
            )
                .padding(.horizontal, MykSpace.s9)
                .padding(.top, MykSpace.s7)
                .padding(.bottom, 64)   // Platz für SaveStateBar
        case .chat:
            // Konversationeller Assistent, scoped auf dieses Projekt.
            // Gleiche Engine wie der globale Assistent — Verlauf je Scope getrennt.
            AssistantChatView(
                scope: .project(project.projectNumber),
                chatStore: appState.chat,
                engine: appState.conversation,
                isConnected: appState.claudeAuth.status == .connected,
                modelName: (try? appState.claudeAuth.storedCredentials()?.model)
                    ?? ClaudeAuthService.defaultModel,
                projects: appState.registry.projects,
                focusedProjectID: project.projectNumber,
                focusedDriveFolderID: project.links.driveFolderID,
                focusedClickUpListID: project.links.clickUpListID,
                profile: appState.profile.profile,
                onCreateContact: { await appState.createContact($0) },
                onCreateDraft: { await appState.createDraft($0) },
                onUploadFileToDrive: { [driveFolderID = project.links.driveFolderID] file in
                    // Ordner-ID zum Zeitpunkt des Drops aufgelöst (via FileDropCardView /
                    // DriveFolderSuggestionResolver). Hier kennen wir ihn direkt.
                    guard let folderID = driveFolderID, !folderID.isEmpty else {
                        return .failed("Kein Drive-Ordner für dieses Projekt konfiguriert.")
                    }
                    return await appState.uploadFileToDrive(file, parentFolderID: folderID)
                },
                onAttachFileToMailDraft: { await appState.createDraftWithAttachment($0) }
            )
        case .files:
            FilesTabView(
                projectID: project.projectNumber,
                driveFolderID: project.links.driveFolderID,
                driveFolderPath: project.links.driveFolderPath
            )
        case .offers:
            OffersTabView(
                projectID: project.projectNumber,
                driveFolderID: project.links.driveFolderID,
                driveFolderPath: project.links.driveFolderPath
            )
        case .zeit:
            ProjektTimerView(projektNummer: project.projectNumber, projektTitel: project.title)
        case .material:
            MaterialTabView(
                projectID: project.projectNumber,
                driveFolderID: project.links.driveFolderID
            )
        case .timeline:
            TimelineTabView(
                projectID: project.projectNumber,
                driveFolderID: project.links.driveFolderID,
                calendarQuery: project.links.calendarQuery,
                auditStore: appState.audit
            )
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
    let sevdeskRef: String?
    let budget: Double?

    @Environment(AppState.self) private var appState
    @State private var dropTargetID: UUID?

    var body: some View {
        // frame(maxWidth: .infinity) bindet den Grid explizit an die vom ScrollView
        // vorgeschlagene Breite. Color.clear als Füllzelle ist entfernt: eine
        // flexible Zelle trieb die ideale Grid-Breite auf "unlimited", was via
        // ZStack-Zentrierung den Inhalt in den Sidebar-Bereich schob.
        Grid(alignment: .topLeading,
             horizontalSpacing: MykSpace.s5,
             verticalSpacing: MykSpace.s5) {
            ForEach(rows, id: \.id) { row in
                GridRow {
                    ForEach(row.items) { instance in
                        draggableCell(for: instance)
                    }
                }
            }
        }
        .frame(minWidth: 0, maxWidth: .infinity, alignment: .topLeading)
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
        case .cash:      CashWidget(projectID: projectID, sevdeskRef: sevdeskRef, budget: budget, auditStore: auditStore)
        case .calendar:  CalendarWidget(projectID: projectID, calendarQuery: calendarQuery)
        case .notes:     NotesWidget(projectID: projectID, noteStore: noteStore)
        case .assistant: ProjectAssistantChatWidget(projectID: projectID, driveFolderID: driveFolderID, clickUpListID: clickUpListID)
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
    let items: [WidgetInstance]; let totalColumns: Int
    // Stabile Identität aus dem ersten Widget der Zeile. Mit `id = UUID()` bekam
    // jede Zeile bei JEDEM Re-Render (z. B. wenn der SaveState wechselt) eine
    // neue Identität → SwiftUI riss alle Widgets ab und baute sie neu auf
    // (Loader-Churn + Mit-Ursache des Notiz-Datenverlusts).
    var id: UUID { items.first?.id ?? Self.emptyRowID }
    private static let emptyRowID = UUID()
    var usedSpan: Int { items.reduce(0) { $0 + $1.size.columnSpan } }
    var fillerSpan: Int { totalColumns - usedSpan }
    var needsFiller: Bool { fillerSpan > 0 }
}

// MARK: - Tab-Helfer
enum ProjectTab: String, CaseIterable, Identifiable {
    case overview = "Übersicht"; case chat = "Assistent"
    case zeit = "Zeit"
    case files = "Dateien"; case offers = "Angebote"
    case timeline = "Timeline"; case material = "Material"
    var id: String { rawValue }

    // Chat braucht volle Höhe und darf nicht in einen äußeren ScrollView geraten.
    var isFullHeight: Bool { self == .chat }
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
