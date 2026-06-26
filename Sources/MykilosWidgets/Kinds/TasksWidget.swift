import SwiftUI
import MykilosKit
import MykilosDesign
import MykilosServices

// MARK: - TasksWidget
// Offene Aufgaben aus der im Projekt verlinkten ClickUp-Liste
// (Project.links.clickUpListID). Fokus-Auswahl, nicht das ganze Board.
// Reiner Lesefetch — nie Schreiben hier. Ocker.
public struct TasksWidget: View {
    public let projectID: String
    public let clickUpListID: String?

    public init(projectID: String, clickUpListID: String?) {
        self.projectID = projectID
        self.clickUpListID = clickUpListID
    }

    @State private var loader = ClickUpTasksLoader()

    public var body: some View {
        WidgetContainer(
            kind: .tasks,
            sourceLabel: sourceLabel,
            renderState: loader.renderState,
            projectID: projectID
        ) {
            VStack(alignment: .leading, spacing: MykSpace.s5) {
                widgetHeader
                taskList
            }
        }
        .task(id: clickUpListID) {
            await loader.load(listID: clickUpListID)
        }
    }

    private var sourceLabel: String {
        switch loader.renderState {
        case .content: "CLICKUP  ·  \(loader.tasks.count) OFFEN"
        default:       "CLICKUP"
        }
    }

    private var widgetHeader: some View {
        HStack {
            SourceChip(kind: .tasks)
            Text("Aufgaben · Fokus").mykWidgetTitle()
            Spacer()
            if case .error = loader.renderState {
                retryButton
            } else if case .permissionRequired = loader.renderState {
                retryButton
            }
        }
    }

    private var retryButton: some View {
        Button("Erneut versuchen") {
            Task { await loader.load(listID: clickUpListID) }
        }
        .font(.mykMono(9.5))
        .buttonStyle(.plain)
        .foregroundStyle(MykColor.tasks.color)
    }

    private var taskList: some View {
        VStack(spacing: 0) {
            ForEach(loader.tasks) { task in
                TaskRow(task: task)
                if task.id != loader.tasks.last?.id {
                    Divider().overlay(MykColor.line.color.opacity(0.6))
                }
            }
        }
    }
}

// MARK: - ClickUpTasksLoader
// Pro Widget-Instanz, kein geteilter Zustand — Aufgaben sind reine
// Lesefetches, kein Speichern-Vertrag wie bei NoteStore/WidgetBoardStore.
@MainActor
@Observable
private final class ClickUpTasksLoader {
    private(set) var tasks: [ClickUpTask] = []
    private(set) var renderState: WidgetRenderState = .loading

    private let client: ClickUpFetching

    init(client: ClickUpFetching = ClickUpClient()) {
        self.client = client
    }

    func load(listID: String?) async {
        guard let listID, listID.isEmpty == false else {
            tasks = []
            renderState = .empty
            return
        }
        renderState = .loading
        do {
            let result = try await client.tasks(listID: listID)
            tasks = result
            renderState = result.isEmpty ? .empty : .content
        } catch ClickUpError.notConnected {
            tasks = []
            renderState = .permissionRequired
        } catch {
            tasks = []
            renderState = .error(String(describing: error))
        }
    }
}

// MARK: - TaskRow
private struct TaskRow: View {
    let task: ClickUpTask

    var body: some View {
        HStack(alignment: .top, spacing: MykSpace.s4) {
            RoundedRectangle(cornerRadius: 4)
                .stroke(task.isUrgent ? MykColor.critical.color : MykColor.faint.color, lineWidth: 1.5)
                .background(
                    task.isUrgent
                        ? RoundedRectangle(cornerRadius: 4).fill(MykColor.critical.color.opacity(0.12))
                        : nil
                )
                .frame(width: 14, height: 14)
                .padding(.top, 2)
            VStack(alignment: .leading, spacing: 2) {
                Text(task.name).font(.mykSmall).foregroundStyle(MykColor.ink.color)
                Text(subtitle).font(.mykMono(9.5)).foregroundStyle(MykColor.muted.color)
            }
        }
        .padding(.vertical, MykSpace.s4)
    }

    private var subtitle: String {
        var parts: [String] = []
        if let dueDate = task.dueDate {
            parts.append(dueDate.formatted(.relative(presentation: .named)).uppercased())
        } else if task.status.isEmpty == false {
            parts.append(task.status.uppercased())
        }
        if let assignee = task.assignee, assignee.isEmpty == false {
            parts.append(assignee.uppercased())
        }
        return parts.joined(separator: "  ·  ")
    }
}
