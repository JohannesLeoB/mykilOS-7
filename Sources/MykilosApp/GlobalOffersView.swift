import SwiftUI
import MykilosKit
import MykilosDesign
import MykilosServices

// MARK: - GlobalOffersView
// Sidebar-Modul "Angebote": alle Projekte mit verknüpftem Drive-Ordner in einer
// Auswahlliste links — rechts die Belege des gewählten Projekts (OffersTabView).
// Keine neue Datenquelle: nutzt dieselbe Drive-Logik wie der Projekt-Tab.
struct GlobalOffersView: View {
    @Environment(AppState.self) private var appState

    @State private var selectedProjectNumber: String?

    private var offerProjects: [Project] {
        appState.registry.projects.filter { $0.links.driveFolderID != nil }
    }

    var body: some View {
        HStack(spacing: 0) {
            sidebar
            Divider().overlay(MykColor.line.color)
            content
        }
        .background(MykColor.paper.color)
        .onAppear {
            if selectedProjectNumber == nil {
                selectedProjectNumber = offerProjects.first?.projectNumber
            }
        }
    }

    // MARK: Linke Projektliste

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Angebote")
                .font(.mykDisplay)
                .foregroundStyle(MykColor.ink.color)
                .padding(.horizontal, MykSpace.s7)
                .padding(.top, MykSpace.s9)
                .padding(.bottom, MykSpace.s5)
            Divider().overlay(MykColor.line.color)
            if offerProjects.isEmpty {
                Text("Keine Projekte mit Drive-Ordner.")
                    .font(.mykSmall)
                    .foregroundStyle(MykColor.muted.color)
                    .padding(MykSpace.s7)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(offerProjects) { project in
                            projectRow(project)
                        }
                    }
                    .padding(.vertical, MykSpace.s4)
                }
            }
        }
        .frame(width: 220)
        .background(MykColor.card.color)
    }

    private func projectRow(_ project: Project) -> some View {
        let isSelected = selectedProjectNumber == project.projectNumber
        return Button {
            selectedProjectNumber = project.projectNumber
        } label: {
            VStack(alignment: .leading, spacing: 2) {
                Text(project.title)
                    .font(.mykSmall)
                    .foregroundStyle(isSelected ? MykColor.ink.color : MykColor.inkSoft.color)
                    .lineLimit(1)
                Text(project.projectNumber)
                    .font(.mykMono(10))
                    .foregroundStyle(MykColor.muted.color)
            }
            .padding(.horizontal, MykSpace.s6)
            .padding(.vertical, MykSpace.s3)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                isSelected ? MykColor.paper.color : Color.clear
            )
            .clipShape(RoundedRectangle(cornerRadius: MykRadius.sm))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, MykSpace.s3)
    }

    // MARK: Rechter Inhaltsbereich

    @ViewBuilder
    private var content: some View {
        if let nr = selectedProjectNumber,
           let project = offerProjects.first(where: { $0.projectNumber == nr }) {
            OffersTabView(
                projectID: project.projectNumber,
                driveFolderID: project.links.driveFolderID,
                driveFolderPath: project.links.driveFolderPath
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            VStack {
                Text("Kein Projekt ausgewählt.")
                    .font(.mykBody)
                    .foregroundStyle(MykColor.muted.color)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
