import SwiftUI
import MykilosKit
import MykilosDesign
import MykilosWidgets

// MARK: - ProjectFavoritesWidget
// Angeheftete Projekte als Mini-Karten. Schnellzugriff auf das Wichtigste.
// Full-width (3 Spalten). Echte Projekte kommen aus RegistryStore.
struct ProjectFavoritesWidget: View {
    @Environment(AppState.self) private var appState

    // Favorisierte aktive Projekte (L25). Reihenfolge folgt der Registry.
    private var favoriteProjects: [Project] {
        appState.registry.activeProjects().filter { appState.favorites.isFavorite($0.projectNumber) }
    }

    var body: some View {
        WidgetContainer(
            kind: .projectFaves,
            sourceLabel: "PINNED  ·  \(favoriteProjects.count) FAVORITEN",
            renderState: appState.registry.isLoading ? .loading : .content,
            projectID: "home"
        ) {
            VStack(alignment: .leading, spacing: MykSpace.s5) {
                HStack {
                    SourceChip(kind: .projectFaves)
                    Text("Favoriten").mykWidgetTitle()
                    Spacer()
                }
                if favoriteProjects.isEmpty {
                    emptyState
                } else {
                    projectGrid
                }
            }
        }
    }

    private var emptyState: some View {
        Text("Noch keine Favoriten — Stern auf einer Projektkarte tippen.")
            .font(.mykCaption)
            .foregroundStyle(MykColor.muted.color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, MykSpace.s8)
    }

    private var projectGrid: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: MykSpace.s4), count: 3),
            spacing: MykSpace.s4
        ) {
            ForEach(favoriteProjects.prefix(6)) { project in
                MiniProjectCard(project: project, customer: appState.registry.customer(for: project)) {
                    appState.pendingProjectSelection = project
                }
            }
        }
    }
}

// MARK: - MiniProjectCard
private struct MiniProjectCard: View {
    let project: Project
    let customer: Customer?
    let onTap: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: onTap) {
            cardContent
        }
        .buttonStyle(.plain)
    }

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Hero-Mini
            heroGradient
                .frame(height: 72)
                .clipShape(UnevenRoundedRectangle(
                    topLeadingRadius: MykRadius.sm, bottomLeadingRadius: 0,
                    bottomTrailingRadius: 0, topTrailingRadius: MykRadius.sm
                ))
                .overlay(alignment: .bottomLeading) {
                    Text(project.title)
                        .font(.mykCaption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .padding(MykSpace.s3)
                        .background(
                            LinearGradient(colors: [.clear, .black.opacity(0.55)],
                                           startPoint: .top, endPoint: .bottom)
                        )
                }
            // Info
            HStack {
                Text(project.projectNumber)
                    .font(.mykMono(9))
                    .foregroundStyle(MykColor.muted.color)
                Spacer()
                Circle()
                    .fill(project.kind.accentColor)
                    .frame(width: 5, height: 5)
            }
            .padding(.horizontal, MykSpace.s3)
            .padding(.vertical, MykSpace.s3)
        }
        .background(MykColor.paper2.color)
        .clipShape(RoundedRectangle(cornerRadius: MykRadius.sm))
        .overlay(
            RoundedRectangle(cornerRadius: MykRadius.sm)
                .stroke(MykColor.line.color, lineWidth: 1)
        )
        .scaleEffect(isHovered ? 1.03 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isHovered)
        .onHover { isHovered = $0 }
    }

    private var heroGradient: some View {
        LinearGradient(
            colors: project.kind.heroGradient,   // L26: geteilter, token-basierter Verlauf
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
