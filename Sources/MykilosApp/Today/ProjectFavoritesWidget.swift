import SwiftUI
import AppKit
import MykilosKit
import MykilosDesign
import MykilosWidgets

// MARK: - ProjectFavoritesWidget
// Angeheftete Projekte als Mini-Karten. Schnellzugriff auf das Wichtigste.
// Full-width (3 Spalten). Echte Projekte kommen aus RegistryStore.
struct ProjectFavoritesWidget: View {
    @Environment(AppState.self) private var appState

    // Bis zu 3 Zeilen à 3 Karten — mehr würde das Home-Board sprengen.
    private static let maxCards = 9

    // Favorisierte aktive Projekte (L25). Reihenfolge folgt der Registry.
    private var favoriteProjects: [Project] {
        appState.registry.activeProjects().filter { appState.favorites.isFavorite($0.projectNumber) }
    }

    private var shownProjects: [Project] { Array(favoriteProjects.prefix(Self.maxCards)) }

    // Zähler MUSS zeigen, was sichtbar ist (Polish 2026-07-04: vorher „7", aber nur
    // 6 Karten gerendert). Bei Überlauf ehrlich „N VON GESAMT".
    private var sourceLabel: String {
        let total = favoriteProjects.count
        return shownProjects.count < total
            ? "PINNED  ·  \(shownProjects.count) VON \(total) FAVORITEN"
            : "PINNED  ·  \(total) FAVORITEN"
    }

    var body: some View {
        WidgetContainer(
            kind: .projectFaves,
            sourceLabel: sourceLabel,
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
            ForEach(shownProjects) { project in
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
    // Echtes Hero-Bild je Projekt — konsistent zur Galerie-Karte (ProjectCard).
    @State private var heroImage: NSImage?
    @State private var focalPoint = CGPoint(x: 0.5, y: 0.5)

    var body: some View {
        Button(action: onTap) {
            cardContent
        }
        .buttonStyle(.plain)
        .task(id: project.projectNumber) {
            heroImage = ProjectHeroImageStore.image(for: project.projectNumber)
            focalPoint = ProjectHeroImageStore.focalPoint(for: project.projectNumber)
        }
    }

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Hero-Mini: eigenes Bild (Fokus-Fill) sonst Archetyp-Gradient.
            heroArea
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

    private var heroArea: some View {
        GeometryReader { geo in
            if let heroImage {
                focalImage(heroImage, in: geo.size)
            } else {
                LinearGradient(
                    colors: project.kind.heroGradient,   // L26: geteilter, token-basierter Verlauf
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
    }

    // Fokus-zentrierter Fill-Zuschnitt — identische Logik wie ProjectCard/ProjectHeroView.
    private func focalImage(_ image: NSImage, in frame: CGSize) -> some View {
        let iw = max(image.size.width, 1)
        let ih = max(image.size.height, 1)
        let scale = max(frame.width / iw, frame.height / ih)
        let sw = iw * scale
        let sh = ih * scale
        let offsetX = min(0, max(frame.width - sw, frame.width / 2 - focalPoint.x * sw))
        let offsetY = min(0, max(frame.height - sh, frame.height / 2 - focalPoint.y * sh))
        return Color.clear
            .overlay(alignment: .topLeading) {
                Image(nsImage: image)
                    .resizable()
                    .frame(width: sw, height: sh)
                    .offset(x: offsetX, y: offsetY)
            }
            .frame(width: frame.width, height: frame.height)
            .clipped()
    }
}
