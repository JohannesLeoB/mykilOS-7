import SwiftUI
import MykilosKit
import MykilosDesign
import MykilosServices

// MARK: - GlobalPlansView
// Kataloge-Tab "Zeichnungen & Pläne": alle Projekte mit verknüpftem Drive-Ordner
// in einer Auswahlliste links — rechts entweder die globale Kategorie-Liste
// (AllPlansView) oder die Schema-Ordner des gewählten Projekts (MaterialTabView,
// dieselbe Ansicht wie der Material-Tab der Projekt-Detailseite — eine Quelle
// der Wahrheit). Baugleich zum GlobalOffersView-Muster, read-only, ohne Warenkorb.
struct GlobalPlansView: View {
    @Environment(AppState.self) private var appState

    @State private var selectedProjectNumber: String?
    @State private var showAll = true

    private var planProjects: [Project] {
        appState.registry.projects.filter { $0.links.driveFolderID != nil }
    }

    private var allProjectRefs: [AllPlansCollector.ProjectRef] {
        planProjects.compactMap { project in
            guard let id = project.links.driveFolderID, id.isEmpty == false else { return nil }
            return AllPlansCollector.ProjectRef(
                projectNumber: project.projectNumber, title: project.title, driveFolderID: id)
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            sidebar
            Divider().overlay(MykColor.line.color)
            content
        }
        .background(MykColor.paper.color)
    }

    // MARK: Linke Projektliste

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            // "Zeichnungen" ist zu breit für die 220pt-Sidebar in voller Display-Größe —
            // ohne Skalierung bricht der Titel mitten im Wort um ("Zeichnunge/n").
            Text("Zeichnungen & Pläne")
                .font(.mykDisplay)
                .foregroundStyle(MykColor.ink.color)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
                .padding(.horizontal, MykSpace.s7)
                // Bugfix 2026-07-07 (Johannes-Feedback): oberer Rand auf dieselbe Baseline
                // wie der mykilOS-Button in der Sidebar (SidebarView: s7) -- vorher s9 (48pt),
                // 20pt zu tief gegenüber der Sidebar.
                .padding(.top, MykSpace.s7)
                .padding(.bottom, MykSpace.s5)
            Divider().overlay(MykColor.line.color)
            allPlansButton
            Divider().overlay(MykColor.line.color.opacity(0.5))
            if planProjects.isEmpty {
                Text("Keine Projekte mit Drive-Ordner.")
                    .font(.mykSmall)
                    .foregroundStyle(MykColor.muted.color)
                    .padding(MykSpace.s7)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(planProjects) { project in
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

    private var allPlansButton: some View {
        Button {
            showAll = true
        } label: {
            HStack(spacing: MykSpace.s3) {
                Image(systemName: "square.stack.3d.up")
                    .font(.mykCaption)
                    .foregroundStyle(showAll ? MykColor.drive.color : MykColor.muted.color)
                Text("Alle Zeichnungen")
                    .font(.mykSmall)
                    .foregroundStyle(showAll ? MykColor.ink.color : MykColor.inkSoft.color)
                Spacer()
            }
            .padding(.horizontal, MykSpace.s6)
            .padding(.vertical, MykSpace.s4)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(showAll ? MykColor.paper.color : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: MykRadius.sm))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, MykSpace.s3)
        .padding(.vertical, MykSpace.s3)
    }

    private func projectRow(_ project: Project) -> some View {
        let isSelected = showAll == false && selectedProjectNumber == project.projectNumber
        return Button {
            showAll = false
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
        if showAll {
            AllPlansView(projects: allProjectRefs)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let nr = selectedProjectNumber,
           let project = planProjects.first(where: { $0.projectNumber == nr }) {
            ScrollView {
                MaterialTabView(
                    projectID: project.projectNumber,
                    driveFolderID: project.links.driveFolderID
                )
            }
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
