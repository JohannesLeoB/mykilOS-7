import SwiftUI
import AppKit
import MykilosKit
import MykilosDesign
import MykilosServices
import MykilosWidgets

// MARK: - MaterialTabView
// Zeigt den Inhalt des "03 PRÄSENTATION"-Unterordners eines Projekts als
// scrollbare Dateiliste. Read-only; Klick öffnet Datei im Browser.
// Folgt dem gleichen Muster wie OffersTabView (generation-token, WidgetContainer,
// alle WidgetRenderStates abgedeckt). Kein Zwei-Spalten-Layout — Präsentations-
// material wird in einer einzigen sortierten Liste angezeigt.
struct MaterialTabView: View {
    let projectID: String
    let driveFolderID: String?

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
                fileList
            }
        }
        .task(id: driveFolderID) {
            await loader.load(rootFolderID: driveFolderID)
        }
        .padding(.horizontal, MykSpace.s9)
        .padding(.top, MykSpace.s7)
        .padding(.bottom, 64)
    }

    private var sourceLabel: String {
        switch loader.renderState {
        case .content: "GOOGLE DRIVE  ·  \(loader.files.count) DATEIEN"
        default:       "GOOGLE DRIVE"
        }
    }

    private var header: some View {
        HStack {
            SourceChip(kind: .drive)
            Text("Präsentation & Material").mykWidgetTitle()
            Spacer()
            if case .content = loader.renderState { refreshButton }
            else if case .error = loader.renderState { retryButton }
            else if case .permissionRequired = loader.renderState { retryButton }
        }
    }

    private var refreshButton: some View {
        Button {
            Task { await loader.load(rootFolderID: driveFolderID) }
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
            Task { await loader.load(rootFolderID: driveFolderID) }
        }
        .font(.mykMono(9.5))
        .buttonStyle(.plain)
        .foregroundStyle(MykColor.drive.color)
    }

    private var fileList: some View {
        VStack(spacing: 0) {
            if loader.files.isEmpty {
                Text("Keine Dateien im Präsentationsordner")
                    .font(.mykSmall)
                    .foregroundStyle(MykColor.muted.color)
            } else {
                ForEach(loader.files) { file in
                    MaterialRow(file: file)
                    if file.id != loader.files.last?.id {
                        Divider().overlay(MykColor.line.color.opacity(0.6))
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
    private(set) var files: [GoogleDriveFile] = []
    private(set) var renderState: WidgetRenderState = .loading

    private let client: GoogleDriveFetching
    private var loadGeneration = 0

    init(client: GoogleDriveFetching = GoogleDriveClient()) {
        self.client = client
    }

    func load(rootFolderID: String?) async {
        loadGeneration &+= 1
        let generation = loadGeneration
        guard let rootFolderID, rootFolderID.isEmpty == false else {
            files = []; renderState = .empty; return
        }
        renderState = .loading
        do {
            let rootChildren = try await client.listFolder(folderID: rootFolderID)
            guard generation == loadGeneration else { return }

            // Tolerant: echte Ordner heißen z.B. "03 PRÄSENTATION" — Nummerierung
            // und Großschreibung werden ignoriert, nur das Schlüsselwort muss passen.
            let folder = rootChildren.first {
                $0.mimeType == "application/vnd.google-apps.folder"
                    && ($0.name.lowercased().contains("präsentation")
                        || $0.name.lowercased().contains("prasentation")
                        || $0.name.lowercased().contains("presentation"))
            }

            guard let folder else {
                guard generation == loadGeneration else { return }
                files = []; renderState = .empty; return
            }

            let children = try await client.listFolder(folderID: folder.id)
            guard generation == loadGeneration else { return }

            files = children
                .filter { $0.mimeType != "application/vnd.google-apps.folder" }
                .sorted { ($0.modifiedAt ?? .distantPast) > ($1.modifiedAt ?? .distantPast) }

            renderState = files.isEmpty ? .empty : .content
        } catch GoogleDriveError.notConnected {
            guard generation == loadGeneration else { return }
            files = []; renderState = .permissionRequired
        } catch {
            guard generation == loadGeneration else { return }
            files = []; renderState = .error(String(describing: error))
        }
    }
}
