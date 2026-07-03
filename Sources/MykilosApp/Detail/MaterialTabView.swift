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

    var body: some View {
        WidgetContainer(
            kind: .drive,
            sourceLabel: sourceLabel,
            renderState: loader.renderState,
            projectID: projectID
        ) {
            VStack(alignment: .leading, spacing: MykSpace.s5) {
                header
                categorySections
            }
        }
        .task(id: driveFolderID) {
            await loader.load(rootFolderID: driveFolderID)
            logDataFlow()
        }
        .padding(.horizontal, MykSpace.s9)
        .padding(.top, MykSpace.s7)
        .padding(.bottom, 64)
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

    // Eine Sektion pro nicht-leerer Kategorie, in Enum-Deklarationsreihenfolge.
    private var categorySections: some View {
        VStack(alignment: .leading, spacing: MykSpace.s6) {
            ForEach(loader.nonEmptyCategories) { category in
                VStack(alignment: .leading, spacing: MykSpace.s2) {
                    HStack(spacing: MykSpace.s3) {
                        Image(systemName: category.iconName)
                            .font(.mykMono(10))
                            .foregroundStyle(MykColor.drive.color)
                        Text(category.label.uppercased())
                            .font(.mykMono(9.5))
                            .foregroundStyle(MykColor.muted.color)
                        Text("\(loader.files(for: category).count)")
                            .font(.mykMono(9.5))
                            .foregroundStyle(MykColor.faint.color)
                    }
                    VStack(spacing: 0) {
                        let files = loader.files(for: category)
                        ForEach(files) { file in
                            MaterialRow(file: file)
                            if file.id != files.last?.id {
                                Divider().overlay(MykColor.line.color.opacity(0.6))
                            }
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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

// MARK: - MaterialRow
private struct MaterialRow: View {
    let file: GoogleDriveFile

    private var icon: String {
        switch file.name.split(separator: ".").last?.lowercased() {
        case "pdf":                    "doc.text"
        case "pptx", "ppt", "key":    "rectangle.on.rectangle.angled"
        case "png", "jpg", "jpeg", "heic": "photo"
        case "mp4", "mov":             "play.rectangle"
        default:                       "doc"
        }
    }

    var body: some View {
        Button {
            if let link = file.webViewLink, let url = URL(string: link) {
                NSWorkspace.shared.open(url)
            }
        } label: {
            HStack(spacing: MykSpace.s4) {
                Image(systemName: icon)
                    .font(.mykCaption)
                    .foregroundStyle(MykColor.drive.color)
                    .frame(width: 20)
                VStack(alignment: .leading, spacing: 2) {
                    Text(file.name)
                        .font(.mykSmall)
                        .foregroundStyle(MykColor.ink.color)
                        .lineLimit(1)
                    if let modifiedAt = file.modifiedAt {
                        Text(modifiedAt.formatted(.relative(presentation: .named)))
                            .font(.mykMono(9.5))
                            .foregroundStyle(MykColor.muted.color)
                    }
                }
                Spacer()
                Image(systemName: "arrow.up.right.square")
                    .font(.mykMono(10))
                    .foregroundStyle(MykColor.faint.color)
            }
        }
        .buttonStyle(.plain)
        .padding(.vertical, MykSpace.s3)
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
