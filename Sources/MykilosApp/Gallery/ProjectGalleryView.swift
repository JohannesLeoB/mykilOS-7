import SwiftUI
import MykilosKit
import MykilosDesign

// MARK: - ProjectGalleryView
// Lazy grid — trägt 400 Projekte, weil nie alle 400 gleichzeitig gerendert werden.
// Suche, Filter, leere/Lade-Zustände — alle schön, nie nackt.
struct ProjectGalleryView: View {
    @Environment(RegistryStore.self) private var registry
    @State private var searchText = ""
    @State private var selectedProject: Project? = nil

    private let columns = [
        GridItem(.adaptive(minimum: 260, maximum: 340), spacing: MykSpace.s5)
    ]

    var body: some View {
        ZStack {
            MykColor.paper.color.ignoresSafeArea()
            if let project = selectedProject {
                ProjectDetailView(project: project) {
                    withAnimation(.easeInOut(duration: 0.22)) {
                        selectedProject = nil
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal:   .move(edge: .trailing).combined(with: .opacity)
                ))
            } else {
                galleryContent
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.22), value: selectedProject?.id)
        .task { await registry.load() }
    }

    // MARK: Galerie-Inhalt
    private var galleryContent: some View {
        VStack(spacing: 0) {
            commandBar
            Divider().overlay(MykColor.line.color)
            if registry.isLoading {
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
            Text(searchText.isEmpty ? "Noch keine Projekte." : "Keine Treffer für „\(searchText)".")
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
