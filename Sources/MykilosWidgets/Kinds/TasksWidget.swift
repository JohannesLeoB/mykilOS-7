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
    /// Eigene ClickUp-Member-ID (ClickUp-Vollintegration, 2026-07-07) — für den
    /// personalisierten `myClickUpTaskDueSoon`-Alert. `nil` = kein Alert (unbekannt).
    public let eigeneClickUpID: String?
    /// Für den gegateten Status-Wechsel/Anlegen (S4) — `nil` = Schreib-UI ausgeblendet
    /// (Fallback für Aufrufer ohne Audit-Anschluss, statt eines Schreibpfads ohne Protokoll).
    public let auditStore: AuditStore?
    public let actorUserID: String
    /// Go-Live-Whitelist (S10) — `nil` = nur Testspace erlaubt (sicherer Default).
    public let goLiveWhitelist: ClickUpGoLiveWhitelistStore?

    public init(
        projectID: String, clickUpListID: String?, eigeneClickUpID: String? = nil,
        auditStore: AuditStore? = nil, actorUserID: String = "local",
        goLiveWhitelist: ClickUpGoLiveWhitelistStore? = nil
    ) {
        self.projectID = projectID
        self.clickUpListID = clickUpListID
        self.eigeneClickUpID = eigeneClickUpID
        self.auditStore = auditStore
        self.actorUserID = actorUserID
        self.goLiveWhitelist = goLiveWhitelist
    }

    @State private var loader = ClickUpTasksLoader()
    @State private var statusFehler: String?
    @State private var neueAufgabe = ""
    @State private var neuerGhost: String?
    @State private var legeAn = false
    @Environment(StudioContext.self) private var context

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
                if auditStore != nil { anlegenZeile }
            }
        }
        .task(id: clickUpListID) {
            await loader.load(listID: clickUpListID)
            let now = Date()
            let sevenDays: TimeInterval = 7 * 24 * 3600
            for task in loader.tasks {
                guard let due = task.dueDate else { continue }
                let secs = due.timeIntervalSince(now)
                guard secs >= 0 && secs <= sevenDays else { continue }
                let days = Calendar.current.dateComponents([.day], from: now, to: due).day ?? 0
                context.emit(.deadlineNear(projectID: projectID, days: max(0, days)))
                // Personalisiert: nur wenn ICH zugewiesen bin (nicht jede Fälligkeit im
                // Projekt) — anders als der projektweite deadlineNear oben.
                if let eigeneClickUpID, task.assigneeIDs.contains(eigeneClickUpID) {
                    context.emit(.myClickUpTaskDueSoon(projectID: projectID, taskName: task.name, days: max(0, days)))
                }
            }
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
        VStack(alignment: .leading, spacing: 0) {
            if let statusFehler {
                Text(statusFehler).font(.mykMono(9)).foregroundStyle(MykColor.critical.color)
                    .padding(.bottom, MykSpace.s2)
            }
            ForEach(loader.tasks) { task in
                TaskRow(task: task, bekannteStatuswerte: bekannteStatuswerte,
                        onStatusChange: auditStore == nil ? nil : { status in await aendereStatus(task: task, status: status) })
                if task.id != loader.tasks.last?.id {
                    Divider().overlay(MykColor.line.color.opacity(0.6))
                }
            }
        }
    }

    // Statuswerte kommen ausschließlich aus bereits geladenen Aufgaben dieser Liste — keine
    // erfundenen Werte, keine zusätzliche Metadaten-Abfrage nötig (Muster: ClickUpTestWerkbankView).
    private var bekannteStatuswerte: [String] {
        Array(Set(loader.tasks.map(\.status))).sorted()
    }

    /// Gegateter Status-Wechsel (S4) — schreibt NUR in Testspace-/Go-Live-Listen
    /// (`ClickUpWriteGate`); jede andere Liste liefert sichtbar `🔒` statt eines stillen No-Ops.
    private func aendereStatus(task: ClickUpTask, status: String) async {
        statusFehler = nil
        guard let clickUpListID, let auditStore else { return }
        let actionStore = ClickUpTaskActionStore(audit: auditStore, goLiveWhitelist: goLiveWhitelist)
        do {
            try await actionStore.setStatus(
                taskID: task.id, listID: clickUpListID, status: status,
                projectID: projectID, actorUserID: actorUserID)
            await loader.load(listID: clickUpListID)
        } catch {
            statusFehler = (error as? LocalizedError)?.errorDescription ?? "Status ändern fehlgeschlagen."
        }
    }

    private static let ghostKuerzel = ["Jo", "Da", "Fra", "Sen", "Jil"]

    private var anlegenZeile: some View {
        VStack(alignment: .leading, spacing: MykSpace.s2) {
            HStack(spacing: MykSpace.s3) {
                TextField("Neue Aufgabe …", text: $neueAufgabe)
                    .textFieldStyle(.roundedBorder)
                    .font(.mykSmall)
                Picker("Ghost-Kürzel", selection: $neuerGhost) {
                    Text("Keine Zuweisung").tag(String?.none)
                    ForEach(Self.ghostKuerzel, id: \.self) { kuerzel in
                        Text(kuerzel).tag(String?.some(kuerzel))
                    }
                }
                .labelsHidden()
                .frame(width: 130)
                Button {
                    Task { await legeAufgabeAn() }
                } label: {
                    if legeAn { ProgressView().controlSize(.small) } else { Text("Anlegen") }
                }
                .disabled(neueAufgabe.trimmingCharacters(in: .whitespaces).isEmpty || legeAn)
            }
            Text("Ghost-Kürzel schreibt nur einen Text-Hinweis in die Beschreibung — kein echtes ClickUp-Assignee, keine Benachrichtigung.")
                .font(.mykMono(8)).foregroundStyle(MykColor.faint.color)
        }
    }

    private func legeAufgabeAn() async {
        statusFehler = nil
        guard let clickUpListID, let auditStore else { return }
        legeAn = true
        defer { legeAn = false }
        let actionStore = ClickUpTaskActionStore(audit: auditStore, goLiveWhitelist: goLiveWhitelist)
        do {
            try await actionStore.createTask(
                listID: clickUpListID, name: neueAufgabe.trimmingCharacters(in: .whitespacesAndNewlines),
                ghostKuerzel: neuerGhost, projectID: projectID, actorUserID: actorUserID)
            neueAufgabe = ""
            neuerGhost = nil
            await loader.load(listID: clickUpListID)
        } catch {
            statusFehler = (error as? LocalizedError)?.errorDescription ?? "Anlegen fehlgeschlagen."
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
    // Generation-Token: nur das jüngste load() committet (Projektwechsel/Retry).
    private var loadGeneration = 0

    init(client: ClickUpFetching = ClickUpClient()) {
        self.client = client
    }

    func load(listID: String?) async {
        loadGeneration &+= 1
        let generation = loadGeneration
        guard let listID, listID.isEmpty == false else {
            tasks = []
            renderState = .empty
            return
        }
        renderState = .loading
        do {
            let result = try await client.tasks(listID: listID)
            guard generation == loadGeneration else { return }
            tasks = result
            renderState = result.isEmpty ? .empty : .content
        } catch ClickUpError.notConnected {
            guard generation == loadGeneration else { return }
            tasks = []
            renderState = .permissionRequired
        } catch {
            guard generation == loadGeneration else { return }
            tasks = []
            renderState = .error(String(describing: error))
        }
    }
}

// MARK: - TaskRow
private struct TaskRow: View {
    let task: ClickUpTask
    let bekannteStatuswerte: [String]
    /// `nil` = kein Status-Menü (kein AuditStore übergeben, TasksWidget bleibt read-only).
    let onStatusChange: ((String) async -> Void)?

    @State private var aendernd = false

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
                HStack(spacing: MykSpace.s3) {
                    Text(subtitle).font(.mykMono(9.5)).foregroundStyle(MykColor.muted.color)
                    AssigneeChipRow(assigneeIDs: task.assigneeIDs)
                }
            }
            Spacer()
            if let onStatusChange {
                statusMenu(onStatusChange)
            }
        }
        .padding(.vertical, MykSpace.s4)
    }

    private func statusMenu(_ onStatusChange: @escaping (String) async -> Void) -> some View {
        Menu {
            ForEach(bekannteStatuswerte, id: \.self) { status in
                Button(status) {
                    aendernd = true
                    Task { await onStatusChange(status); aendernd = false }
                }
            }
        } label: {
            HStack(spacing: MykSpace.s2) {
                if aendernd { ProgressView().controlSize(.small) }
                Image(systemName: "chevron.down").font(.mykMono(8))
            }
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
    }

    private var subtitle: String {
        var parts: [String] = []
        if let dueDate = task.dueDate {
            parts.append(dueDate.formatted(.relative(presentation: .named)).uppercased())
        } else if task.status.isEmpty == false {
            parts.append(task.status.uppercased())
        }
        return parts.joined(separator: "  ·  ")
    }
}
