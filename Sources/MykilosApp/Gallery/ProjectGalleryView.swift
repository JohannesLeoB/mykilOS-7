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
    private var sort: ProjectSort { ProjectSort(rawValue: sortRaw) ?? .nummer }

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
                    .padding(MykSpace.s8)
                }
            }
        }
    }

    // MARK: Command-Bar
    private var commandBar: some View {
        HStack(spacing: MykSpace.s5) {
            Text("Projekte")
                .font(.mykDisplay)
                .foregroundStyle(MykColor.ink.color)
            Spacer()
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
                RoundedRectangle(cornerRadius: 11)
                    .fill(MykColor.card.color)
                    .overlay(
                        RoundedRectangle(cornerRadius: 11)
                            .stroke(MykColor.line.color, lineWidth: 1)
                    )
            )
            .frame(maxWidth: 260)
        }
        .padding(.horizontal, MykSpace.s9)
        .padding(.vertical, MykSpace.s5)
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
                .background(RoundedRectangle(cornerRadius: 11).fill(MykColor.card.color)
                    .overlay(RoundedRectangle(cornerRadius: 11).stroke(MykColor.line.color, lineWidth: 1)))
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
                .background(RoundedRectangle(cornerRadius: 11).fill(MykColor.card.color)
                    .overlay(RoundedRectangle(cornerRadius: 11).stroke(MykColor.line.color, lineWidth: 1)))
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
            Image(systemName: "square.grid.2x2")
                .font(.mykDisplay)
                .foregroundStyle(MykColor.faint.color)
            Text(searchText.isEmpty ? "Noch keine Projekte." : "Keine Treffer für „\(searchText)“.")
                .font(.mykBody)
                .foregroundStyle(MykColor.muted.color)
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
