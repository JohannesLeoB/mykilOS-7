import SwiftUI
import MykilosDesign
import MykilosServices
import MykilosKit
import MykilosWidgets

// MARK: - ClickUp-Aufgaben-Spalte (Aufgaben-Spalten-System, Spalte 2/3, 2026-07-07)
// Johannes-Feedback (wörtlich): "Neue zweite Spalte: ClickUp Aufgaben: Meine Aufgaben,
// alle Aufgaben, Aufgaben eines bestimmten Projektes, Aufgaben einer bestimmten Prio,
// Aufgaben einer bestimmten Fälligkeit."
// Rein LESEND — projektübergreifend über alle Projekte mit `links.clickUpListID`
// (gleiches Muster wie `HeuteAnstehendView.ScheduleLoader`, `withTaskGroup`). Kein
// Schreiben hier — Spalte 3 (erstellen/zuweisen) ist bewusst ein separater, späterer
// Schritt (kollidiert sonst mit der eisernen Regel "KI weist NIE zu").

// MARK: - ClickUpAufgabeMitProjekt (Task + die Projekt-Referenz, aus der sie kam)
struct ClickUpAufgabeMitProjekt: Identifiable, Equatable {
    let task: ClickUpTask
    let projectNumber: String
    let projectTitle: String
    var id: String { task.id }
}

// MARK: - ClickUpAufgabenLoader (testbare Logik, getrennt von der View)
@MainActor
@Observable
final class ClickUpAufgabenLoader {
    private(set) var items: [ClickUpAufgabeMitProjekt] = []
    private(set) var isLoading = false
    private(set) var loaded = false
    private(set) var fehlerText: String?

    private let clickUp: ClickUpFetching
    private var gen = 0

    init(clickUp: ClickUpFetching = ClickUpClient()) {
        self.clickUp = clickUp
    }

    func load(refs: [ProjectClickUpRef]) async {
        gen &+= 1
        let mine = gen
        guard refs.isEmpty == false else {
            items = []
            isLoading = false
            loaded = true
            fehlerText = nil
            return
        }
        isLoading = true
        let clickUp = self.clickUp
        let (gefunden, hatteFehler): ([ClickUpAufgabeMitProjekt], Bool) = await withTaskGroup(
            of: (items: [ClickUpAufgabeMitProjekt], fehlgeschlagen: Bool).self
        ) { group in
            for ref in refs {
                group.addTask {
                    do {
                        let tasks = try await clickUp.tasks(listID: ref.listID)
                        let mapped = tasks.map {
                            ClickUpAufgabeMitProjekt(task: $0, projectNumber: ref.projectNumber, projectTitle: ref.title)
                        }
                        return (mapped, false)
                    } catch ClickUpError.notConnected {
                        return ([], false)   // nicht verbunden ist kein Fehler, nur leer
                    } catch {
                        return ([], true)
                    }
                }
            }
            var out: [ClickUpAufgabeMitProjekt] = []
            var fehler = false
            for await (part, fehlgeschlagen) in group {
                out.append(contentsOf: part)
                fehler = fehler || fehlgeschlagen
            }
            return (out, fehler)
        }
        guard mine == gen else { return }
        items = gefunden.sorted { lhs, rhs in
            switch (lhs.task.dueDate, rhs.task.dueDate) {
            case let (due1?, due2?): return due1 < due2
            case (nil, nil): return lhs.task.name < rhs.task.name
            case (nil, _): return false
            case (_, nil): return true
            }
        }
        fehlerText = hatteFehler ? "Einige ClickUp-Listen konnten nicht geladen werden." : nil
        isLoading = false
        loaded = true
    }
}

// MARK: - ClickUpAufgabenFilter (Meine/Alle · Projekt · Prio)
enum ClickUpZuweisungsFilter: String, CaseIterable, Identifiable {
    case meine, alle
    var id: String { rawValue }
    var label: String { self == .meine ? "Meine" : "Alle" }
}

enum ClickUpPrioFilter: String, CaseIterable, Identifiable {
    case alle, urgent, high, normal, low
    var id: String { rawValue }
    var label: String {
        switch self {
        case .alle: "Alle Prios"
        case .urgent: ClickUpPriority.urgent.label
        case .high: ClickUpPriority.high.label
        case .normal: ClickUpPriority.normal.label
        case .low: ClickUpPriority.low.label
        }
    }
    var matching: ClickUpPriority? {
        switch self {
        case .alle: nil
        case .urgent: .urgent
        case .high: .high
        case .normal: .normal
        case .low: .low
        }
    }
}

// MARK: - ClickUpAufgabenSpalte (die View)
struct ClickUpAufgabenSpalte: View {
    @Environment(AppState.self) private var appState
    @Environment(StudioContext.self) private var context
    @State private var loader = ClickUpAufgabenLoader()
    @State private var zuweisung: ClickUpZuweisungsFilter = .alle
    @State private var projektFilter: String?   // nil = alle Projekte
    @State private var prioFilter: ClickUpPrioFilter = .alle
    @State private var nurMitFaelligkeit = false

    private static let stamp: DateFormatter = {
        let fmt = DateFormatter(); fmt.dateFormat = "dd.MM.yy · HH:mm"; fmt.locale = Locale(identifier: "de_DE"); return fmt
    }()

    private var eigeneClickUpID: String? { appState.residentIdentity.identity?.clickUpMemberID }

    private var projektRefs: [ProjectClickUpRef] {
        appState.registry.activeProjects().compactMap { project in
            guard let listID = project.links.clickUpListID, listID.isEmpty == false else { return nil }
            return ProjectClickUpRef(projectNumber: project.projectNumber, title: project.title, listID: listID)
        }
    }

    private var gefiltert: [ClickUpAufgabeMitProjekt] {
        loader.items.filter { item in
            if zuweisung == .meine {
                guard let eigeneClickUpID, item.task.assigneeID == eigeneClickUpID else { return false }
            }
            if let projektFilter, item.projectNumber != projektFilter { return false }
            if let match = prioFilter.matching, item.task.priority != match { return false }
            if nurMitFaelligkeit, item.task.dueDate == nil { return false }
            return true
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            filterBar
            if zuweisung == .meine && eigeneClickUpID == nil {
                emptyHint("""
                    Keine eigene ClickUp-Mitglieds-ID bekannt — "Meine Aufgaben" kann noch nicht \
                    gefiltert werden. Bitte in Airtable (Clockodo-Nutzer) hinterlegen.
                    """)
            } else if let fehler = loader.fehlerText {
                errorLine(fehler)
            }
            if loader.isLoading && loader.loaded == false {
                loadingHint()
            } else if gefiltert.isEmpty {
                emptyHint(loader.items.isEmpty
                    ? "Keine ClickUp-Aufgaben — kein Projekt mit verknüpfter Liste oder alle Listen leer."
                    : "Keine Aufgaben für diese Filterkombination.")
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(gefiltert) { item in
                            row(for: item)
                            Divider().overlay(MykColor.line.color)
                        }
                    }
                }
            }
        }
        .task(id: appState.registry.projects.count) {
            await loader.load(refs: projektRefs)
            emitEigeneFaelligkeitsAlerts()
        }
    }

    /// Refresh-on-open (kein Hintergrund-Poll über alle Projekte, Rate-Budget) — bei jedem
    /// Laden dieser Spalte ein personalisierter Alert für EIGENE Aufgaben, die in ≤7 Tagen
    /// fällig sind. Anders als der projektweite `deadlineNear` (TasksWidget) nur MEINE.
    private func emitEigeneFaelligkeitsAlerts() {
        guard let eigeneClickUpID else { return }
        let now = Date()
        let sevenDays: TimeInterval = 7 * 24 * 3600
        for item in loader.items {
            guard item.task.assigneeIDs.contains(eigeneClickUpID), let due = item.task.dueDate else { continue }
            let secs = due.timeIntervalSince(now)
            guard secs >= 0 && secs <= sevenDays else { continue }
            let days = Calendar.current.dateComponents([.day], from: now, to: due).day ?? 0
            context.emit(.myClickUpTaskDueSoon(projectID: item.projectNumber, taskName: item.task.name, days: max(0, days)))
        }
    }

    private var filterBar: some View {
        VStack(alignment: .leading, spacing: MykSpace.s3) {
            HStack(spacing: MykSpace.s3) {
                Picker("", selection: $zuweisung) {
                    ForEach(ClickUpZuweisungsFilter.allCases) { Text($0.label).tag($0) }
                }
                .pickerStyle(.segmented).labelsHidden().frame(width: 140)

                Picker("", selection: $projektFilter) {
                    Text("Alle Projekte").tag(String?.none)
                    ForEach(projektRefs, id: \.listID) { ref in
                        Text("\(ref.projectNumber) · \(ref.title)").tag(String?.some(ref.projectNumber))
                    }
                }
                .labelsHidden().frame(maxWidth: 220)

                Picker("", selection: $prioFilter) {
                    ForEach(ClickUpPrioFilter.allCases) { Text($0.label).tag($0) }
                }
                .labelsHidden().frame(width: 130)

                Toggle(isOn: $nurMitFaelligkeit) {
                    Label("Nur mit Fälligkeit", systemImage: "calendar").font(.mykMono(10))
                }
                .toggleStyle(.switch)

                Spacer()
                Text("QUELLE: CLICKUP · \(gefiltert.count)").font(.mykMono(9)).foregroundStyle(MykColor.tasks.color)
            }
        }
        .padding(MykSpace.s4)
        .background(MykColor.card.color)
        .clipShape(RoundedRectangle(cornerRadius: MykRadius.sm))
        .overlay(RoundedRectangle(cornerRadius: MykRadius.sm).stroke(MykColor.line.color, lineWidth: 1))
        .padding(MykSpace.s9)
    }

    private func row(for item: ClickUpAufgabeMitProjekt) -> some View {
        HStack(alignment: .top, spacing: MykSpace.s4) {
            RoundedRectangle(cornerRadius: 4)
                .stroke(item.task.isUrgent ? MykColor.critical.color : MykColor.faint.color, lineWidth: 1.5)
                .background(
                    item.task.isUrgent
                        ? RoundedRectangle(cornerRadius: 4).fill(MykColor.critical.color.opacity(0.12))
                        : nil
                )
                .frame(width: 14, height: 14)
                .padding(.top, 3)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.task.name).font(.mykBody).foregroundStyle(MykColor.ink.color)
                HStack(spacing: MykSpace.s2) {
                    Text(item.task.status).font(.mykMono(9)).foregroundStyle(MykColor.muted.color)
                    if let due = item.task.dueDate {
                        Text("fällig \(Self.stamp.string(from: due))").font(.mykMono(9)).foregroundStyle(MykColor.faint.color)
                    }
                    if let prio = item.task.priority {
                        Text(prio.label.uppercased()).font(.mykMono(9)).foregroundStyle(MykColor.tasks.color)
                    }
                    Text("\(item.projectNumber) · \(item.projectTitle)").font(.mykMono(9)).foregroundStyle(MykColor.tasks.color)
                    AssigneeChipRow(assigneeIDs: item.task.assigneeIDs)
                }
            }
            Spacer()
        }
        .padding(.horizontal, MykSpace.s9).padding(.vertical, MykSpace.s3)
    }

    private func loadingHint() -> some View {
        VStack { Spacer(); ProgressView().controlSize(.small); Spacer() }
            .frame(maxWidth: .infinity, minHeight: 120)
    }

    private func errorLine(_ text: String) -> some View {
        Text(text).font(.mykSmall).foregroundStyle(MykColor.critical.color)
            .padding(.horizontal, MykSpace.s9).padding(.bottom, MykSpace.s3)
    }

    private func emptyHint(_ text: String) -> some View {
        VStack { Spacer(); Text(text).font(.mykSmall).foregroundStyle(MykColor.muted.color).multilineTextAlignment(.center); Spacer() }
            .frame(maxWidth: .infinity).padding(MykSpace.s9)
    }
}
