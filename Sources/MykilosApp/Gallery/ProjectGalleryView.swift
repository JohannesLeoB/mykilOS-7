import SwiftUI
import MykilosKit
import MykilosDesign

// MARK: - ProjectGalleryView
// Lazy grid — trägt 400 Projekte, weil nie alle 400 gleichzeitig gerendert werden.
// Suche, Filter, leere/Lade-Zustände — alle schön, nie nackt.
struct ProjectGalleryView: View {
    @Environment(AppState.self) private var appState
    @State private var searchText = ""
    @State private var selectedProject: Project? = nil

    private var registry: RegistryStore { appState.registry }

    private let columns = [
        GridItem(.adaptive(minimum: 260, maximum: 340), spacing: MykSpace.s5)
    ]

    var body: some View {
        ZStack {
            MykColor.paper.color.ignoresSafeArea()
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
                .transition(.opacity)
            } else {
                galleryContent
                    .transition(.opacity)
            }
        }
        // Clipping verhindert zusätzlich, dass eine transiente Größe/Position
        // während des Übergangs die gemessenen Fensterbounds aufbläht.
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

    // MARK: Filter
    private var filtered: [Project] {
        let base = registry.activeProjects()
        guard !searchText.isEmpty else { return base }
        let q = searchText.lowercased()
        return base.filter {
            $0.title.lowercased().contains(q)
            || $0.projectNumber.lowercased().contains(q)
            || $0.customerNumber.lowercased().contains(q)
        }
    }
}
