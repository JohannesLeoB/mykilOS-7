import SwiftUI
import MykilosKit
import MykilosDesign
import MykilosServices

// UI-Beschriftung der Sortier-Modi (Logik liegt testbar in MykilosServices.ProjectSorter).
extension ProjectSort {
    var label: String {
        switch self {
        case .nummer:    "Nummer"
        case .name:      "Name"
        case .datum:     "Datum"
        case .kategorie: "Kategorie"
        case .eigene:    "Eigene"
        }
    }
    var icon: String {
        switch self {
        case .nummer:    "number"
        case .name:      "textformat"
        case .datum:     "calendar"
        case .kategorie: "tag"
        case .eigene:    "hand.draw"
        }
    }
}

// MARK: - ProjectGalleryView
// Lazy grid — trägt 400 Projekte, weil nie alle 400 gleichzeitig gerendert werden.
// Suche, Filter, leere/Lade-Zustände — alle schön, nie nackt.
struct ProjectGalleryView: View {
    @Environment(AppState.self) private var appState
    @State private var searchText = ""
    @State private var selectedProject: Project? = nil
    @AppStorage("projekte.sort") private var sortRaw = ProjectSort.nummer.rawValue
    @AppStorage("projekte.kategorie") private var kategorieFilter = ""   // "" = alle
    @AppStorage("projekte.customOrder") private var customOrderRaw = ""  // projectNumbers, komma-getrennt
    // Gespeicherte Galerie-Ansichten (S5): benannte Filter-/Sortier-Kombinationen.
    @AppStorage("projekte.savedViews") private var savedViewsRaw = ""
    @State private var showSaveDialog = false
    @State private var newViewName = ""
    // S6: Ansichtsmodus Galerie (Raster) ⇄ Pipeline (Kanban über Lebenszyklus-Stufen).
    @AppStorage("projekte.viewMode") private var viewModeRaw = "grid"
    private var sort: ProjectSort { ProjectSort(rawValue: sortRaw) ?? .nummer }

    private var savedViews: [SavedGalleryView] {
        (try? JSONDecoder().decode([SavedGalleryView].self, from: Data(savedViewsRaw.utf8))) ?? []
    }
    private func persistViews(_ views: [SavedGalleryView]) {
        savedViewsRaw = (try? String(data: JSONEncoder().encode(views), encoding: .utf8) ?? "") ?? ""
    }
    private func applyView(_ v: SavedGalleryView) {
        kategorieFilter = v.kategorie
        sortRaw = v.sortRaw
        searchText = v.search
    }
    private func saveCurrentView(named name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        var views = savedViews.filter { $0.name.caseInsensitiveCompare(trimmed) != .orderedSame }
        views.append(SavedGalleryView(id: trimmed.lowercased(), name: trimmed,
                                      kategorie: kategorieFilter, sortRaw: sortRaw, search: searchText))
        persistViews(views)
    }
    private func deleteView(_ v: SavedGalleryView) {
        persistViews(savedViews.filter { $0.id != v.id })
    }

    private var registry: RegistryStore { appState.registry }

    private let columns = [
        GridItem(.adaptive(minimum: 260, maximum: 340), spacing: MykSpace.s5)
    ]

    var body: some View {
        // .topLeading statt Default-Center: ein overbreiter Inhalt (z.B. Grid mit
        // vielen Widget-Daten) würde sonst mit negativem x-Offset zentriert und
        // schöbe einen unsichtbaren Hit-Test-Bereich über die Sidebar.
        // frame(maxWidth/Height .infinity) auf ProjectDetailView stellt sicher,
        // dass der ZStack die Detail-Ansicht exakt auf seine eigene Breite zwingt.
        ZStack(alignment: .topLeading) {
            if let project = selectedProject {
                // Bewusst KEINE .move-Transition: der Transform-Offset trieb in
                // einem inhalts-dimensionierten Fenster die Fensterbreite hoch
                // (Backtrace lief durch updateTransform → invalidateTransform →
                // Endlosschleife der Update-Constraints-Pässe → Crash). Ein reiner
                // Opacity-Übergang hat keinen Transform und ist crash-sicher.
                ProjectDetailView(project: project) {
                    withAnimation(.easeInOut(duration: 0.22)) {
                        selectedProject = nil
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .transition(.opacity)
            } else {
                galleryContent
                    .transition(.opacity)
            }
        }
        // maxWidth/maxHeight .infinity: die ZStack-Kinder (Gallery-Grid vs.
        // ProjectDetailView) haben unterschiedliche ideale Breiten. Ohne diese
        // Angabe propagiert SwiftUI die enger bevorzugte Größe nach oben in die
        // NSHostingView — die ruft daraufhin setContentSize: auf dem NSWindow
        // auf und verschiebt dessen Ursprung. Das ist der eigentliche Drift-
        // Auslöser, nicht nur ein Positionierungsproblem.
        .background(MykColor.paper.color)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // Clipping als zusätzliche Sperre: verhindert, dass transiente Größen
        // während der Opacity-Transition als Fenster-Constraint sichtbar werden.
        .clipped()
        .animation(.easeInOut(duration: 0.22), value: selectedProject?.id)
        .task { await registry.load() }
        // Navigations-Brücke (siehe AppState.pendingProjectSelection): andere
        // Module fordern hier "öffne dieses Projekt" an, ohne unseren lokalen
        // selectedProject-State zu kennen. Wir öffnen es und räumen sofort auf,
        // damit ein erneutes Tippen auf "Projekte" in der Sidebar es nicht
        // wieder aufreißt.
        .onChange(of: appState.pendingProjectSelection) { _, requested in
            guard let requested else { return }
            withAnimation(.easeInOut(duration: 0.22)) { selectedProject = requested }
            appState.pendingProjectSelection = nil
        }
        .guardWindowPosition(on: selectedProject?.id)
    }

    // MARK: Galerie-Inhalt
    private var galleryContent: some View {
        VStack(spacing: 0) {
            commandBar
            Divider().overlay(MykColor.line.color)
            if registry.isLoading && registry.projects.isEmpty {
                // Spinner NUR wenn noch nichts da ist. Liegt ein Cache vor, zeigen
                // wir ihn sofort weiter (ein laufender Refresh blockiert nicht).
                loadingView
            } else if filtered.isEmpty {
                emptyView
            } else if viewModeRaw == "pipeline" {
                ProjectPipelineView(
                    projects: filtered,
                    stageFor: { appState.projectLifecycle.stage(for: $0.projectNumber) ?? .akquise },
                    customerFor: { registry.customer(for: $0) },
                    budgetFor: { $0.links.budget },
                    onMove: { project, stage in
                        try? appState.projectLifecycle.setStage(stage, for: project.projectNumber)
                    },
                    onOpen: { project in
                        withAnimation(.easeInOut(duration: 0.22)) { selectedProject = project }
                    }
                )
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: MykSpace.s5) {
                        ForEach(filtered) { project in
                            ProjectCard(
                                project: project,
                                customer: registry.customer(for: project)
                            ) {
                                withAnimation(.easeInOut(duration: 0.22)) {
                                    selectedProject = project
                                }
                            }
                            // Frei sortieren per Drag&Drop (aktiviert „Eigene"-Sortierung).
                            .draggable(project.projectNumber) {
                                Text(project.title).font(.mykSmall).padding(MykSpace.s3)
                                    .background(MykColor.card.color)
                            }
                            .dropDestination(for: String.self) { items, _ in
                                guard let dragged = items.first else { return false }
                                withAnimation(.easeInOut(duration: 0.18)) {
                                    reorder(dragged: dragged, before: project.projectNumber)
                                }
                                return true
                            }
                        }
                    }
                    // Karten richten sich horizontal am Page-Rand (s9) aus — gleiche
                    // Inhalt-zu-Rand-Kante wie die Command-Bar darüber und alle anderen
                    // Seiten. Vertikal s8 für Luft unter dem Divider (wie TodayView-Body).
                    .padding(.horizontal, MykSpace.s9)
                    .padding(.vertical, MykSpace.s8)
                }
            }
        }
    }

    // MARK: Command-Bar
    // Fix 2026-07-03 (Live-Fund Johannes): bei wenig Breite (schmaleres Fenster/
    // Sidebar offen) wickelte SwiftUI Titel + Umschalter-Labels buchstabenweise
    // um, statt sie zu kürzen. .fixedSize() verweigert das Umbrechen — der
    // Suchfeld-Bereich (hat bereits minWidth) gibt bei Platznot zuerst nach.
    private var commandBar: some View {
        HStack(spacing: MykSpace.s5) {
            Text("Projekte")
                .font(.mykDisplay)
                .foregroundStyle(MykColor.ink.color)
                .fixedSize(horizontal: true, vertical: false)
            Spacer()
            modusToggle
            viewsMenu
            sortMenu
            kategorieMenu
            HStack(spacing: MykSpace.s3) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(MykColor.muted.color)
                TextField("Suchen…", text: $searchText)
                    .font(.mykSmall)
                    .textFieldStyle(.plain)
                    .frame(minWidth: 180)
            }
            .padding(.horizontal, MykSpace.s5)
            .padding(.vertical, MykSpace.s3)
            .background(
                RoundedRectangle(cornerRadius: MykRadius.md)
                    .fill(MykColor.card.color)
                    .overlay(
                        RoundedRectangle(cornerRadius: MykRadius.md)
                            .stroke(MykColor.line.color, lineWidth: 1)
                    )
            )
            .frame(maxWidth: 260)
        }
        .padding(.horizontal, MykSpace.s9)
        .padding(.vertical, MykSpace.s5)
    }

    // Galerie (Raster) ⇄ Pipeline (Kanban) umschalten.
    private var modusToggle: some View {
        HStack(spacing: 0) {
            modusButton(mode: "grid", icon: "square.grid.2x2", label: "Galerie")
            modusButton(mode: "pipeline", icon: "rectangle.split.3x1", label: "Pipeline")
        }
        .background(RoundedRectangle(cornerRadius: MykRadius.md).fill(MykColor.card.color)
            .overlay(RoundedRectangle(cornerRadius: MykRadius.md).stroke(MykColor.line.color, lineWidth: 1)))
    }

    private func modusButton(mode: String, icon: String, label: String) -> some View {
        let active = viewModeRaw == mode
        return Button { viewModeRaw = mode } label: {
            Label(label, systemImage: icon)
                .font(.mykSmall)
                .foregroundStyle(active ? MykColor.paper.color : MykColor.muted.color)
                .fixedSize(horizontal: true, vertical: false)
                .padding(.horizontal, MykSpace.s4).padding(.vertical, MykSpace.s3)
                .background(RoundedRectangle(cornerRadius: MykRadius.md).fill(active ? MykColor.ink.color : Color.clear))
        }
        .buttonStyle(.plain)
        .help(label)
    }

    private var viewsMenu: some View {
        Menu {
            if savedViews.isEmpty {
                Text("Noch keine gespeicherten Ansichten")
            } else {
                ForEach(savedViews) { v in
                    Button { applyView(v) } label: { Label(v.name, systemImage: "rectangle.stack") }
                }
                Divider()
                Menu("Ansicht löschen") {
                    ForEach(savedViews) { v in
                        Button(role: .destructive) { deleteView(v) } label: { Text(v.name) }
                    }
                }
                Divider()
            }
            Button { newViewName = ""; showSaveDialog = true } label: {
                Label("Aktuellen Filter sichern …", systemImage: "plus")
            }
        } label: {
            Label("Ansichten", systemImage: "rectangle.stack")
                .font(.mykSmall).foregroundStyle(MykColor.muted.color)
                .padding(.horizontal, MykSpace.s4).padding(.vertical, MykSpace.s3)
                .background(RoundedRectangle(cornerRadius: MykRadius.md).fill(MykColor.card.color)
                    .overlay(RoundedRectangle(cornerRadius: MykRadius.md).stroke(MykColor.line.color, lineWidth: 1)))
        }
        .menuStyle(.borderlessButton).fixedSize()
        .alert("Ansicht sichern", isPresented: $showSaveDialog) {
            TextField("Name (z. B. Aktive Küchen)", text: $newViewName)
            Button("Sichern") { saveCurrentView(named: newViewName) }
            Button("Abbrechen", role: .cancel) { }
        } message: {
            Text("Speichert die aktuelle Kombination aus Kategorie, Sortierung und Suche.")
        }
    }

    private var sortMenu: some View {
        Menu {
            ForEach(ProjectSort.allCases, id: \.self) { option in
                Button { sortRaw = option.rawValue } label: {
                    Label(option.label, systemImage: sort == option ? "checkmark" : option.icon)
                }
            }
        } label: {
            Label("Sortieren: \(sort.label)", systemImage: "arrow.up.arrow.down")
                .font(.mykSmall).foregroundStyle(MykColor.muted.color)
                .padding(.horizontal, MykSpace.s4).padding(.vertical, MykSpace.s3)
                .background(RoundedRectangle(cornerRadius: MykRadius.md).fill(MykColor.card.color)
                    .overlay(RoundedRectangle(cornerRadius: MykRadius.md).stroke(MykColor.line.color, lineWidth: 1)))
        }
        .menuStyle(.borderlessButton).fixedSize()
    }

    private var kategorieMenu: some View {
        Menu {
            Button { kategorieFilter = "" } label: {
                Label("Alle Kategorien", systemImage: kategorieFilter.isEmpty ? "checkmark" : "tag")
            }
            ForEach(verfuegbareKategorien, id: \.self) { kind in
                Button { kategorieFilter = kind.rawValue } label: {
                    Label(kind.displayLabel, systemImage: kategorieFilter == kind.rawValue ? "checkmark" : "tag")
                }
            }
        } label: {
            let title = kategorieFilter.isEmpty ? "Kategorie" : (ProjectKind(rawValue: kategorieFilter)?.displayLabel ?? "Kategorie")
            Label(title, systemImage: "line.3.horizontal.decrease.circle")
                .font(.mykSmall)
                .foregroundStyle(kategorieFilter.isEmpty ? MykColor.muted.color : MykColor.brand.color)
                .padding(.horizontal, MykSpace.s4).padding(.vertical, MykSpace.s3)
                .background(RoundedRectangle(cornerRadius: MykRadius.md).fill(MykColor.card.color)
                    .overlay(RoundedRectangle(cornerRadius: MykRadius.md).stroke(MykColor.line.color, lineWidth: 1)))
        }
        .menuStyle(.borderlessButton).fixedSize()
    }

    // MARK: Zustände
    private var loadingView: some View {
        VStack(spacing: MykSpace.s5) {
            Spacer()
            ProgressView()
                .progressViewStyle(.circular)
                .tint(MykColor.muted.color)
            Text("Lade Projekte…")
                .font(.mykBody)
                .foregroundStyle(MykColor.muted.color)
            Spacer()
        }
    }

    private var emptyView: some View {
        VStack(spacing: MykSpace.s5) {
            Spacer()
            ZStack {
                RoundedRectangle(cornerRadius: MykRadius.lg)
                    .fill(MykColor.paper2.color)
                    .frame(width: 96, height: 96)
                    .overlay(GridTexture().opacity(0.25).clipShape(RoundedRectangle(cornerRadius: MykRadius.lg)))
                Image(systemName: searchText.isEmpty ? "square.grid.2x2" : "magnifyingglass")
                    .font(.mykDisplay)
                    .foregroundStyle(MykColor.brand.color.opacity(0.7))
            }
            Text(searchText.isEmpty ? "Noch keine Projekte hier." : "Keine Treffer für „\(searchText)“.")
                .font(.mykTitle)
                .foregroundStyle(MykColor.inkSoft.color)
            Text(searchText.isEmpty
                 ? "Projekte kommen aus dem Drive-Ordner PROJEKTE und der Airtable-Registry."
                 : (kategorieFilter.isEmpty ? "Andere Schreibweise probieren?" : "Vielleicht liegt es am Kategorie-Filter?"))
                .font(.mykSmall)
                .foregroundStyle(MykColor.muted.color)
            if searchText.isEmpty == false || kategorieFilter.isEmpty == false {
                Button {
                    searchText = ""
                    kategorieFilter = ""
                } label: {
                    Text("Filter zurücksetzen")
                        .font(.mykMono(10)).tracking(0.5)
                        .foregroundStyle(MykColor.paper.color)
                        .padding(.horizontal, MykSpace.s5).padding(.vertical, MykSpace.s3)
                        .background(Capsule().fill(MykColor.ink.color))
                }
                .buttonStyle(.plain)
                .padding(.top, MykSpace.s2)
            }
            Spacer()
        }
    }

    // MARK: Filter + Sortierung
    private var filtered: [Project] {
        var base = registry.activeProjects()
        // 1. Kategorie-Filter
        if kategorieFilter.isEmpty == false, let kind = ProjectKind(rawValue: kategorieFilter) {
            base = base.filter { $0.kind == kind }
        }
        // 2. Suche
        if searchText.isEmpty == false {
            let q = searchText.lowercased()
            base = base.filter {
                $0.title.lowercased().contains(q)
                || $0.projectNumber.lowercased().contains(q)
                || $0.customerNumber.lowercased().contains(q)
            }
        }
        // 3. Sortierung (Logik testbar in MykilosServices.ProjectSorter)
        return ProjectSorter.sorted(base, by: sort, customOrder: ProjectSorter.parseOrder(customOrderRaw))
    }

    /// Welche Kategorien kommen in den aktiven Projekten vor (für das Filter-Menü).
    private var verfuegbareKategorien: [ProjectKind] {
        let present = Set(registry.activeProjects().map(\.kind))
        return ProjectKind.allCases.filter { present.contains($0) }
    }

    // Drag&Drop: verschiebt `dragged` vor `target` und speichert die neue Eigene-Reihenfolge.
    private func reorder(dragged: String, before target: String) {
        guard dragged != target else { return }
        var order = filtered.map(\.projectNumber)          // aktuelle sichtbare Folge als Basis
        guard let from = order.firstIndex(of: dragged) else { return }
        order.remove(at: from)
        let insert = order.firstIndex(of: target) ?? order.count
        order.insert(dragged, at: insert)
        customOrderRaw = order.joined(separator: ",")
        sortRaw = ProjectSort.eigene.rawValue              // Drag aktiviert die Eigene-Sortierung
    }
}

// MARK: - SavedGalleryView
// Eine benannte, gespeicherte Galerie-Ansicht (Filter-/Sortier-Kombination).
// Rein lokal (@AppStorage-JSON), keine externen Daten.
struct SavedGalleryView: Codable, Identifiable, Equatable {
    var id: String        // stabil = kleingeschriebener Name
    var name: String
    var kategorie: String // "" = alle Kategorien
    var sortRaw: String
    var search: String
}
