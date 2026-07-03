import SwiftUI
import AppKit
import MykilosKit
import MykilosDesign
import MykilosServices
import MykilosWidgets

// MARK: - AllPlansLoader
// Dünner @Observable-Wrapper um die testbare `AllPlansCollector`-Logik (Services).
// Hält nur UI-Belange: Render-State, Generations-Guard, Lade-Fortschritt.
// Baugleich zu AllOffersLoader.
@MainActor
@Observable
final class AllPlansLoader {
    private(set) var plans: [AllPlansCollector.AggregatedPlan] = []
    private(set) var renderState: WidgetRenderState = .loading
    private(set) var projectsScanned = 0
    private(set) var projectsTotal = 0
    private(set) var projectsFailed = 0

    private let client: GoogleDriveFetching
    private var generation = 0

    init(client: GoogleDriveFetching = GoogleDriveClient()) {
        self.client = client
    }

    func load(projects: [AllPlansCollector.ProjectRef]) async {
        generation &+= 1
        let gen = generation
        projectsScanned = 0
        projectsTotal = projects.count
        projectsFailed = 0
        guard projects.isEmpty == false else {
            plans = []; renderState = .empty
            return
        }
        renderState = .loading
        do {
            let outcome = try await AllPlansCollector.collectAll(
                projects: projects, client: client,
                onProgress: { [weak self] done, total in
                    Task { @MainActor [weak self] in
                        guard let self, gen == self.generation else { return }
                        self.projectsScanned = done
                        self.projectsTotal = total
                    }
                })
            guard gen == generation else { return }
            plans = outcome.plans
            projectsFailed = outcome.projectsFailed
            projectsScanned = outcome.projectsScanned
            renderState = plans.isEmpty ? .empty : .content
        } catch GoogleDriveError.notConnected {
            guard gen == generation else { return }
            plans = []; renderState = .permissionRequired
        } catch {
            guard gen == generation else { return }
            plans = []; renderState = .error(String(describing: error))
        }
    }
}

// MARK: - AllPlansSort UI-Beschriftung (Logik testbar in MykilosServices.AllPlansSorter)
extension AllPlansSort {
    var label: String {
        switch self {
        case .datum:     "Datum"
        case .projekt:   "Projekt"
        case .kategorie: "Kategorie"
        case .name:      "Name"
        }
    }
    var icon: String {
        switch self {
        case .datum:     "calendar"
        case .projekt:   "folder"
        case .kategorie: "tag"
        case .name:      "textformat"
        }
    }
}

// MARK: - AllPlansView ("Zeichnungen & Pläne", global)
// Aggregiert die Schema-Ordner-Dateien (Pläne/Werkszeichnungen/Renderings/
// Vorplanung/Layouts) ALLER Projekte mit Drive-Ordner in EINE Liste mit
// Kategorie-Sektionen — bewusst KEINE fünf Spalten (unlesbar schmal); die
// Kategorie-Dimension übernehmen Sektionen + Filter. Read-only; Klick
// öffnet die Datei im Browser.
struct AllPlansView: View {
    let projects: [AllPlansCollector.ProjectRef]

    @Environment(AppState.self) private var appState
    @State private var loader = AllPlansLoader()
    @State private var searchText = ""
    @State private var reloadToken = 0
    /// Kategorie-Filter. `nil` = alle Kategorien.
    @State private var categoryFilter: PlanCategory?
    /// Datei-Typ-Filter über alle Ordner hinweg. `nil` = alle Typen.
    @State private var typeFilter: PlanTypeFilter?
    @AppStorage("plaene.alle.sort") private var sortRaw = AllPlansSort.datum.rawValue

    private var sort: AllPlansSort { AllPlansSort(rawValue: sortRaw) ?? .datum }

    /// Kategorien, die im globalen Katalog auftauchen (ohne Präsentation).
    private var globalCategories: [PlanCategory] {
        PlanCategory.allCases.filter(\.inGlobalKatalog)
    }

    // Kategorie → Typ → Volltext → Sortierung. Spalten teilen danach nach Kategorie.
    private var visible: [AllPlansCollector.AggregatedPlan] {
        let byCategory = AllPlansSorter.filtered(loader.plans, category: categoryFilter)
        let byType = byCategory.filter { typeFilter?.matches($0.file) ?? true }
        let byQuery = AllPlansSorter.filtered(byType, query: searchText)
        return AllPlansSorter.sorted(byQuery, by: sort)
    }

    private func visiblePlans(in category: PlanCategory) -> [AllPlansCollector.AggregatedPlan] {
        visible.filter { $0.category == category }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: MykSpace.s5) {
            header
            if case .content = loader.renderState { toolbar }
            content
            Spacer(minLength: 0)
            sourceLine
        }
        .padding(.horizontal, MykSpace.s9)
        .padding(.top, MykSpace.s7)
        .padding(.bottom, MykSpace.s7)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .task(id: reloadToken) {
            await loader.load(projects: projects)
            switch loader.renderState {
            case .content, .empty:
                appState.dataFlow.log(integrationID: "DRIVE_ALL_PLANS", actorUserID: appState.actorUserID,
                                       action: .success, recordsRead: loader.plans.count,
                                       summary: "Zeichnungen & Pläne geladen (\(loader.plans.count) über \(projects.count) Projekte)")
            case .error(let msg):
                appState.dataFlow.log(integrationID: "DRIVE_ALL_PLANS", actorUserID: appState.actorUserID,
                                       action: .error, errorMessage: msg, summary: "Zeichnungen & Pläne: Laden fehlgeschlagen")
            case .loading, .permissionRequired, .offline:
                break
            }
        }
    }

    // MARK: Kopf

    private var header: some View {
        HStack(spacing: MykSpace.s4) {
            SourceChip(kind: .drive)
            Text("Alle Zeichnungen & Pläne").mykWidgetTitle()
            Spacer()
            Button {
                reloadToken &+= 1
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.mykCaption)
                    .foregroundStyle(MykColor.drive.color)
            }
            .buttonStyle(.plain)
            .help("Alle Projektordner neu durchsuchen")
            .accessibilityLabel("Alle Projektordner neu durchsuchen")
        }
    }

    private var toolbar: some View {
        HStack(spacing: MykSpace.s4) {
            categoryMenu
            typeMenu
            sortMenu
            HStack(spacing: MykSpace.s3) {
                Image(systemName: "magnifyingglass")
                    .font(.mykCaption)
                    .foregroundStyle(MykColor.muted.color)
                TextField("Datei oder Projekt suchen…", text: $searchText)
                    .font(.mykSmall)
                    .textFieldStyle(.plain)
                    .frame(minWidth: 200)
            }
            .padding(.horizontal, MykSpace.s4)
            .padding(.vertical, MykSpace.s3)
            .background(RoundedRectangle(cornerRadius: MykRadius.sm)
                .fill(MykColor.card.color)
                .overlay(RoundedRectangle(cornerRadius: MykRadius.sm).stroke(MykColor.line.color, lineWidth: 1)))
            Spacer()
            Text("\(visible.count) Dateien")
                .font(.mykMono(10))
                .foregroundStyle(MykColor.muted.color)
        }
    }

    private var categoryMenu: some View {
        Menu {
            Button { categoryFilter = nil } label: {
                Label("Alle Kategorien", systemImage: categoryFilter == nil ? "checkmark" : "square.stack.3d.up")
            }
            Divider()
            ForEach(globalCategories) { category in
                Button { categoryFilter = category } label: {
                    Label(category.label, systemImage: categoryFilter == category ? "checkmark" : category.iconName)
                }
            }
        } label: {
            Label(categoryFilter?.label ?? "Alle Kategorien", systemImage: "line.3.horizontal.decrease.circle")
                .font(.mykSmall).foregroundStyle(categoryFilter == nil ? MykColor.muted.color : MykColor.drive.color)
                .padding(.horizontal, MykSpace.s4).padding(.vertical, MykSpace.s3)
                .background(RoundedRectangle(cornerRadius: MykRadius.sm).fill(MykColor.card.color)
                    .overlay(RoundedRectangle(cornerRadius: MykRadius.sm).stroke(MykColor.line.color, lineWidth: 1)))
        }
        .menuStyle(.borderlessButton).fixedSize()
        .help("Nach Plan-Kategorie filtern")
    }

    private var typeMenu: some View {
        Menu {
            Button { typeFilter = nil } label: {
                Label("Alle Typen", systemImage: typeFilter == nil ? "checkmark" : "doc.on.doc")
            }
            Divider()
            ForEach(PlanTypeFilter.allCases, id: \.self) { type in
                Button { typeFilter = type } label: {
                    Label(type.label, systemImage: typeFilter == type ? "checkmark" : type.icon)
                }
            }
        } label: {
            Label(typeFilter?.label ?? "Alle Typen", systemImage: "doc.badge.ellipsis")
                .font(.mykSmall).foregroundStyle(typeFilter == nil ? MykColor.muted.color : MykColor.drive.color)
                .padding(.horizontal, MykSpace.s4).padding(.vertical, MykSpace.s3)
                .background(RoundedRectangle(cornerRadius: MykRadius.sm).fill(MykColor.card.color)
                    .overlay(RoundedRectangle(cornerRadius: MykRadius.sm).stroke(MykColor.line.color, lineWidth: 1)))
        }
        .menuStyle(.borderlessButton).fixedSize()
        .help("Nach Datei-Typ filtern (über alle Ordner)")
    }

    private var sortMenu: some View {
        Menu {
            ForEach(AllPlansSort.allCases, id: \.self) { option in
                Button { sortRaw = option.rawValue } label: {
                    Label(option.label, systemImage: sort == option ? "checkmark" : option.icon)
                }
            }
        } label: {
            Label("Sortieren: \(sort.label)", systemImage: "arrow.up.arrow.down")
                .font(.mykSmall).foregroundStyle(MykColor.muted.color)
                .padding(.horizontal, MykSpace.s4).padding(.vertical, MykSpace.s3)
                .background(RoundedRectangle(cornerRadius: MykRadius.sm).fill(MykColor.card.color)
                    .overlay(RoundedRectangle(cornerRadius: MykRadius.sm).stroke(MykColor.line.color, lineWidth: 1)))
        }
        .menuStyle(.borderlessButton).fixedSize()
    }

    // MARK: Inhalt / Zustände

    @ViewBuilder
    private var content: some View {
        switch loader.renderState {
        case .loading:
            loadingState
        case .content:
            categoryColumns
        case .empty:
            hint(icon: "tray", text: "Keine Pläne/Zeichnungen in den Schema-Ordnern gefunden.")
        case .permissionRequired:
            hint(icon: "lock.circle",
                 text: "Google Drive nicht verbunden. In den Einstellungen verbinden, dann erneut versuchen.",
                 retry: true)
        case .offline:
            hint(icon: "wifi.slash", text: "Offline — keine Verbindung zu Google Drive.", retry: true)
        case .error(let msg):
            hint(icon: "exclamationmark.triangle", text: "Fehler: \(msg)", retry: true, critical: true)
        }
    }

    private var loadingState: some View {
        VStack(spacing: MykSpace.s4) {
            ProgressView()
            Text(loader.projectsTotal > 0
                 ? "Durchsuche alle Projektordner … \(loader.projectsScanned)/\(loader.projectsTotal)"
                 : "Durchsuche alle Projektordner …")
                .font(.mykSmall)
                .foregroundStyle(MykColor.muted.color)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // Spalten je Parent-Ordner-Kategorie (Johannes, 2026-07-03) — nur nicht-leere
    // Kategorien bekommen eine Spalte; bei mehr Spalten als Fensterbreite scrollt
    // die Leiste horizontal. Jede Spalte scrollt vertikal eigenständig
    // (gleiche Idee wie die zwei Richtungs-Spalten der Angebote).
    private var categoryColumns: some View {
        ScrollView(.horizontal) {
            HStack(alignment: .top, spacing: MykSpace.s7) {
                ForEach(globalCategories) { category in
                    let plans = visiblePlans(in: category)
                    if plans.isEmpty == false {
                        VStack(alignment: .leading, spacing: MykSpace.s2) {
                            HStack(spacing: MykSpace.s3) {
                                Image(systemName: category.iconName)
                                    .font(.mykMono(10))
                                    .foregroundStyle(MykColor.drive.color)
                                Text(category.label.uppercased())
                                    .font(.mykMono(9.5))
                                    .foregroundStyle(MykColor.muted.color)
                                Text("\(plans.count)")
                                    .font(.mykMono(9.5))
                                    .foregroundStyle(MykColor.faint.color)
                            }
                            Divider().overlay(MykColor.line.color.opacity(0.6))
                            ScrollView {
                                VStack(spacing: 0) {
                                    ForEach(plans) { plan in
                                        AllPlanRow(plan: plan)
                                        if plan.id != plans.last?.id {
                                            Divider().overlay(MykColor.line.color.opacity(0.6))
                                        }
                                    }
                                }
                            }
                        }
                        .frame(width: 330, alignment: .topLeading)
                    }
                }
            }
            .frame(maxHeight: .infinity, alignment: .topLeading)
        }
    }

    private func hint(icon: String, text: String, retry: Bool = false, critical: Bool = false) -> some View {
        VStack(spacing: MykSpace.s4) {
            Image(systemName: icon)
                .font(.mykHeadline)
                .foregroundStyle(critical ? MykColor.critical.color : MykColor.faint.color)
            Text(text)
                .font(.mykSmall)
                .foregroundStyle(MykColor.muted.color)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 360)
            if retry {
                Button("Erneut versuchen") { reloadToken &+= 1 }
                    .font(.mykMono(9.5))
                    .buttonStyle(.plain)
                    .foregroundStyle(MykColor.drive.color)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var sourceLine: some View {
        HStack(spacing: MykSpace.s3) {
            Circle().fill(MykColor.drive.color).frame(width: 5, height: 5)
            Text(sourceText)
                .font(.mykMono(9))
                .foregroundStyle(MykColor.muted.color)
        }
    }

    private var sourceText: String {
        switch loader.renderState {
        case .content:
            var s = "GOOGLE DRIVE · \(loader.plans.count) DATEIEN · \(loader.projectsScanned) PROJEKTE"
            if loader.projectsFailed > 0 { s += " · \(loader.projectsFailed) ÜBERSPRUNGEN" }
            return s
        default:
            return "GOOGLE DRIVE"
        }
    }
}

// MARK: - AllPlanRow
// Eine Zeile der globalen Liste: preview-fähige Datei (geteilte `PlanFileRow`) +
// echte Projektzuordnung (Titel · Nummer) als Kontextzeile. PlanTypeFilter ist
// jetzt geteilt (MykilosServices), damit Material-Tab denselben Typ-Filter nutzt.
private struct AllPlanRow: View {
    let plan: AllPlansCollector.AggregatedPlan

    var body: some View {
        PlanFileRow(
            file: plan.file,
            contextLine: "\(plan.projectTitle) · \(plan.projectNumber)",
            projectFolderID: plan.projectFolderID
        )
    }
}
