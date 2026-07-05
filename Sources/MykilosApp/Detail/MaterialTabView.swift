import SwiftUI
import AppKit
import MykilosKit
import MykilosDesign
import MykilosServices
import MykilosWidgets

// MARK: - MaterialTabView
// Zeigt die Schema-Ordner eines Projekts (Pläne, Werkszeichnung, Renderings,
// Vorplanung, Layouts, Präsentation) als gruppierte, scrollbare Dateiliste —
// verallgemeinert aus der früheren Nur-Präsentation-Ansicht (der "03
// PRÄSENTATION"-Bestand bleibt als eigene Sektion erhalten). Read-only;
// Klick öffnet Datei im Browser. Sammel-Logik: `PlanCollector` (dieselbe
// Quelle der Wahrheit wie der globale "Zeichnungen & Pläne"-Katalog).
// Muster wie OffersTabView: generation-token, WidgetContainer, alle Renderstates.
struct MaterialTabView: View {
    let projectID: String
    let driveFolderID: String?

    @Environment(AppState.self) private var appState
    @State private var loader = MaterialLoader()
    @State private var searchText = ""
    /// Kategorie-Filter. `nil` = alle (vorhandenen) Kategorien.
    @State private var categoryFilter: PlanCategory?
    /// Datei-Typ-Filter (PDF/Bilder). `nil` = alle Typen.
    @State private var typeFilter: PlanTypeFilter?
    @AppStorage("material.tab.sort") private var sortRaw = MaterialSort.datum.rawValue
    // Galerie-Flug Akt 1: Liste ⇄ Galerie + Finder-Kachelgröße (pro Ansicht gemerkt).
    @AppStorage("material.tab.galerie") private var galerieAn = false
    @AppStorage("material.tab.kachel") private var kachelSeiteRaw: Double = 150
    @State private var viewerFile: GoogleDriveFile?

    private var sort: MaterialSort { MaterialSort(rawValue: sortRaw) ?? .datum }
    private var kachelSeite: Binding<CGFloat> {
        Binding(get: { CGFloat(kachelSeiteRaw) }, set: { kachelSeiteRaw = Double($0) })
    }

    // Alle sichtbaren Dateien flach als Galerie-Einträge (mit Kategorie als Untertitel).
    private var galerieEintraege: [DateiGalerieGrid.Eintrag] {
        categoriesToShow.flatMap { cat in
            visibleFiles(in: cat).map { file in
                DateiGalerieGrid.Eintrag(
                    file: file, subtitle: cat.label,
                    localURL: LocalDriveRootResolver.shared.localURL(
                        forFileID: file.id, fileName: file.name,
                        inProjectFolderID: driveFolderID ?? "", explicitProjectPath: nil))
            }
        }
    }

    /// Vorhandene Kategorien nach Kategorie-Filter eingeschränkt.
    private var categoriesToShow: [PlanCategory] {
        let base = loader.nonEmptyCategories
        if let categoryFilter { return base.filter { $0 == categoryFilter } }
        return base
    }

    /// Sichtbare Dateien einer Kategorie: Typ → Volltext → Sortierung.
    private func visibleFiles(in category: PlanCategory) -> [GoogleDriveFile] {
        let byType = MaterialSorter.filtered(loader.files(for: category), type: typeFilter)
        let byQuery = MaterialSorter.filtered(byType, query: searchText)
        return MaterialSorter.sorted(byQuery, by: sort)
    }

    private var visibleTotal: Int {
        categoriesToShow.reduce(0) { $0 + visibleFiles(in: $1).count }
    }

    var body: some View {
        WidgetContainer(
            kind: .drive,
            sourceLabel: sourceLabel,
            renderState: loader.renderState,
            projectID: projectID
        ) {
            VStack(alignment: .leading, spacing: MykSpace.s5) {
                header
                toolbar
                if galerieAn {
                    DateiGalerieGrid(
                        eintraege: galerieEintraege, kachelSeite: kachelSeite,
                        onPreview: { viewerFile = $0.file },
                        onOpen: { oeffne($0.file) })
                } else {
                    categoryColumns
                }
            }
        }
        .task(id: driveFolderID) {
            await loader.load(rootFolderID: driveFolderID)
            logDataFlow()
        }
        .padding(.horizontal, MykSpace.s9)
        .padding(.top, MykSpace.s7)
        .padding(.bottom, 64)
        .sheet(item: $viewerFile) { file in
            let items = galerieEintraege.map { eintrag in
                DocumentViewerItem(
                    file: eintrag.file, localURL: eintrag.localURL,
                    remoteContent: { try? await GoogleDriveClient().downloadContent(fileID: eintrag.file.id) })
            }
            let startIndex = items.firstIndex(where: { $0.id == file.id }) ?? 0
            DocumentViewerView(items: items, initialIndex: startIndex, onClose: { viewerFile = nil })
                .frame(minWidth: 820, minHeight: 680)
        }
    }

    private func oeffne(_ file: GoogleDriveFile) {
        let local = LocalDriveRootResolver.shared.localURL(
            forFileID: file.id, fileName: file.name,
            inProjectFolderID: driveFolderID ?? "", explicitProjectPath: nil)
        LocalDriveRootResolver.shared.openFile(
            localURL: local, fallbackURL: file.webViewLink.flatMap { URL(string: $0) })
    }

    private var sourceLabel: String {
        switch loader.renderState {
        case .content:
            "GOOGLE DRIVE  ·  \(loader.totalFileCount) DATEIEN  ·  \(loader.nonEmptyCategories.count) ORDNER"
        default:
            "GOOGLE DRIVE"
        }
    }

    private var header: some View {
        HStack {
            SourceChip(kind: .drive)
            Text("Material & Pläne").mykWidgetTitle()
            Spacer()
            if case .content = loader.renderState { refreshButton }
            else if case .error = loader.renderState { retryButton }
            else if case .permissionRequired = loader.renderState { retryButton }
        }
    }

    private var refreshButton: some View {
        Button {
            Task {
                await loader.load(rootFolderID: driveFolderID)
                logDataFlow()
            }
        } label: {
            Image(systemName: "arrow.clockwise")
                .font(.mykCaption)
                .foregroundStyle(MykColor.drive.color)
        }
        .buttonStyle(.plain)
        .help("Aktualisieren")
        .accessibilityLabel("Aktualisieren")
    }

    private var retryButton: some View {
        Button("Erneut versuchen") {
            Task {
                await loader.load(rootFolderID: driveFolderID)
                logDataFlow()
            }
        }
        .font(.mykMono(9.5))
        .buttonStyle(.plain)
        .foregroundStyle(MykColor.drive.color)
    }

    // MARK: - Toolbar (Sammlungs-Ansicht-Standard: Kategorie/Typ/Sort/Suche)
    // Nur bei geladenem Inhalt sichtbar — leere/Fehler-Zustände braucht kein Filter.

    @ViewBuilder
    private var toolbar: some View {
        if case .content = loader.renderState {
            HStack(spacing: MykSpace.s4) {
                categoryMenu
                typeMenu
                sortMenu
                searchField
                Spacer()
                if galerieAn { KachelGroessenSlider(kachelSeite: kachelSeite) }
                ansichtsToggle
                Text("\(visibleTotal) Dateien")
                    .font(.mykMono(10))
                    .foregroundStyle(MykColor.muted.color)
            }
        }
    }

    // Liste ⇄ Galerie (Finder-Stil-Segment).
    private var ansichtsToggle: some View {
        HStack(spacing: 0) {
            toggleTaste(aktiv: galerieAn == false, icon: "list.bullet") { galerieAn = false }
            toggleTaste(aktiv: galerieAn, icon: "square.grid.2x2") { galerieAn = true }
        }
        .background(RoundedRectangle(cornerRadius: MykRadius.sm).fill(MykColor.card.color)
            .overlay(RoundedRectangle(cornerRadius: MykRadius.sm).stroke(MykColor.line.color, lineWidth: 1)))
    }

    private func toggleTaste(aktiv: Bool, icon: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.mykCaption)
                .foregroundStyle(aktiv ? MykColor.paper.color : MykColor.muted.color)
                .padding(.horizontal, MykSpace.s3).padding(.vertical, MykSpace.s2)
                .background(aktiv ? MykColor.ink.color : Color.clear)
        }
        .buttonStyle(.plain)
    }

    private var searchField: some View {
        HStack(spacing: MykSpace.s3) {
            Image(systemName: "magnifyingglass")
                .font(.mykCaption)
                .foregroundStyle(MykColor.muted.color)
            TextField("Datei suchen…", text: $searchText)
                .font(.mykSmall)
                .textFieldStyle(.plain)
                .frame(minWidth: 160)
        }
        .padding(.horizontal, MykSpace.s4)
        .padding(.vertical, MykSpace.s3)
        .background(RoundedRectangle(cornerRadius: MykRadius.sm)
            .fill(MykColor.card.color)
            .overlay(RoundedRectangle(cornerRadius: MykRadius.sm).stroke(MykColor.line.color, lineWidth: 1)))
    }

    private var categoryMenu: some View {
        Menu {
            Button { categoryFilter = nil } label: {
                Label("Alle Kategorien", systemImage: categoryFilter == nil ? "checkmark" : "square.stack.3d.up")
            }
            Divider()
            ForEach(loader.nonEmptyCategories) { category in
                Button { categoryFilter = category } label: {
                    Label(category.label, systemImage: categoryFilter == category ? "checkmark" : category.iconName)
                }
            }
        } label: {
            toolbarLabel(categoryFilter?.label ?? "Alle Kategorien",
                         systemImage: "line.3.horizontal.decrease.circle",
                         active: categoryFilter != nil)
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
            toolbarLabel(typeFilter?.label ?? "Alle Typen",
                         systemImage: "doc.badge.ellipsis",
                         active: typeFilter != nil)
        }
        .menuStyle(.borderlessButton).fixedSize()
        .help("Nach Datei-Typ filtern")
    }

    private var sortMenu: some View {
        Menu {
            ForEach(MaterialSort.allCases, id: \.self) { option in
                Button { sortRaw = option.rawValue } label: {
                    Label(option.label, systemImage: sort == option ? "checkmark" : option.icon)
                }
            }
        } label: {
            toolbarLabel("Sortieren: \(sort.label)", systemImage: "arrow.up.arrow.down", active: false)
        }
        .menuStyle(.borderlessButton).fixedSize()
    }

    private func toolbarLabel(_ text: String, systemImage: String, active: Bool) -> some View {
        Label(text, systemImage: systemImage)
            .font(.mykSmall)
            .foregroundStyle(active ? MykColor.drive.color : MykColor.muted.color)
            .padding(.horizontal, MykSpace.s4).padding(.vertical, MykSpace.s3)
            .background(RoundedRectangle(cornerRadius: MykRadius.sm).fill(MykColor.card.color)
                .overlay(RoundedRectangle(cornerRadius: MykRadius.sm).stroke(MykColor.line.color, lineWidth: 1)))
    }

    // MARK: - Spalten je Kategorie (wie globaler Katalog: horizontal scrollend,
    // jede Spalte eigenständig vertikal). Leere Kategorien nach Filter fallen weg.

    private var categoryColumns: some View {
        ScrollView(.horizontal) {
            HStack(alignment: .top, spacing: MykSpace.s7) {
                ForEach(categoriesToShow) { category in
                    let files = visibleFiles(in: category)
                    if files.isEmpty == false {
                        VStack(alignment: .leading, spacing: MykSpace.s2) {
                            HStack(spacing: MykSpace.s3) {
                                Image(systemName: category.iconName)
                                    .font(.mykMono(10))
                                    .foregroundStyle(MykColor.drive.color)
                                Text(category.label.uppercased())
                                    .font(.mykMono(9.5))
                                    .foregroundStyle(MykColor.muted.color)
                                Text("\(files.count)")
                                    .font(.mykMono(9.5))
                                    .foregroundStyle(MykColor.faint.color)
                            }
                            Divider().overlay(MykColor.line.color.opacity(0.6))
                            ScrollView {
                                VStack(spacing: 0) {
                                    ForEach(files) { file in
                                        PlanFileRow(file: file, projectFolderID: driveFolderID)
                                        if file.id != files.last?.id {
                                            Divider().overlay(MykColor.line.color.opacity(0.6))
                                        }
                                    }
                                }
                            }
                        }
                        .frame(width: 330, alignment: .topLeading)
                    }
                }
                if categoriesToShow.allSatisfy({ visibleFiles(in: $0).isEmpty }) {
                    Text("Keine Datei passt zu Filter/Suche.")
                        .font(.mykSmall)
                        .foregroundStyle(MykColor.muted.color)
                        .padding(.top, MykSpace.s4)
                }
            }
            .frame(maxHeight: .infinity, alignment: .topLeading)
        }
    }

    // Härtung: DRIVE_MATERIAL_TAB stand im Datenstrom-Manifest, hatte aber nie
    // einen echten dataFlow.log-Aufruf — in der Schaltzentrale unsichtbar.
    private func logDataFlow() {
        switch loader.renderState {
        case .content, .empty:
            appState.dataFlow.log(integrationID: "DRIVE_MATERIAL_TAB", actorUserID: appState.actorUserID,
                                   action: .success, recordsRead: loader.totalFileCount,
                                   summary: "Material & Pläne geladen (\(loader.totalFileCount) Dateien, \(loader.nonEmptyCategories.count) Ordner)")
        case .error(let msg):
            appState.dataFlow.log(integrationID: "DRIVE_MATERIAL_TAB", actorUserID: appState.actorUserID,
                                   action: .error, errorMessage: msg, summary: "Material & Pläne: Laden fehlgeschlagen")
        case .loading, .permissionRequired, .offline:
            break
        }
    }
}

// MARK: - MaterialLoader
@MainActor
@Observable
private final class MaterialLoader {
    private(set) var filesByCategory: [PlanCategory: [GoogleDriveFile]] = [:]
    private(set) var renderState: WidgetRenderState = .loading

    private let client: GoogleDriveFetching
    private var loadGeneration = 0

    init(client: GoogleDriveFetching = GoogleDriveClient()) {
        self.client = client
    }

    var totalFileCount: Int { filesByCategory.values.reduce(0) { $0 + $1.count } }

    /// Nicht-leere Kategorien in Enum-Deklarationsreihenfolge (stabile Sektionen).
    var nonEmptyCategories: [PlanCategory] {
        PlanCategory.allCases.filter { (filesByCategory[$0]?.isEmpty == false) }
    }

    func files(for category: PlanCategory) -> [GoogleDriveFile] {
        filesByCategory[category] ?? []
    }

    func load(rootFolderID: String?) async {
        loadGeneration &+= 1
        let generation = loadGeneration
        guard let rootFolderID, rootFolderID.isEmpty == false else {
            filesByCategory = [:]; renderState = .empty; return
        }
        renderState = .loading
        do {
            let result = try await PlanCollector.load(rootFolderID: rootFolderID, client: client)
            guard generation == loadGeneration else { return }
            filesByCategory = result.filesByCategory
            renderState = result.isEmpty ? .empty : .content
        } catch GoogleDriveError.notConnected {
            guard generation == loadGeneration else { return }
            filesByCategory = [:]; renderState = .permissionRequired
        } catch {
            guard generation == loadGeneration else { return }
            filesByCategory = [:]; renderState = .error(String(describing: error))
        }
    }
}
