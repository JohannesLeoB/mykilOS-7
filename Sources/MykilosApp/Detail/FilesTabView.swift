import SwiftUI
import AppKit
import MykilosKit
import MykilosDesign
import MykilosServices
import MykilosWidgets

// MARK: - FilesTabView
// Projekt-Tab "Dateien": alle Dateien im verlinkten Drive-Ordner (kein Filter).
// Read-only, gleiche Drive-Infrastruktur wie DriveWidget und OffersTabView.
struct FilesTabView: View {
    let projectID: String
    let driveFolderID: String?

    @State private var loader = FilesLoader()

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
            await loader.load(folderID: driveFolderID)
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
            Text("Dateien").mykWidgetTitle()
            Spacer()
            if case .content = loader.renderState { refreshButton }
            else if case .error = loader.renderState { retryButton }
            else if case .permissionRequired = loader.renderState { retryButton }
        }
    }

    private var refreshButton: some View {
        Button {
            Task { await loader.load(folderID: driveFolderID) }
        } label: {
            Image(systemName: "arrow.clockwise")
                .font(.mykCaption)
                .foregroundStyle(MykColor.drive.color)
        }
        .buttonStyle(.plain)
        .help("Aktualisieren")
    }

    private var retryButton: some View {
        Button("Erneut versuchen") {
            Task { await loader.load(folderID: driveFolderID) }
        }
        .font(.mykMono(10))
        .foregroundStyle(MykColor.drive.color)
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var fileList: some View {
        ForEach(loader.files) { file in
            FileRow(file: file)
            if file.id != loader.files.last?.id {
                Divider().overlay(MykColor.line.color)
            }
        }
    }
}

// MARK: - FilesLoader

@MainActor
@Observable
private final class FilesLoader {
    private(set) var files: [GoogleDriveFile] = []
    private(set) var renderState: WidgetRenderState = .loading

    private let client: GoogleDriveFetching
    private var loadGeneration = 0

    init(client: GoogleDriveFetching = GoogleDriveClient()) {
        self.client = client
    }

    func load(folderID: String?) async {
        loadGeneration &+= 1
        let generation = loadGeneration
        guard let folderID, folderID.isEmpty == false else {
            files = []; renderState = .empty; return
        }
        renderState = .loading
        do {
            let result = try await client.listFolder(folderID: folderID)
            guard generation == loadGeneration else { return }
            files = result.sorted { ($0.modifiedAt ?? .distantPast) > ($1.modifiedAt ?? .distantPast) }
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

// MARK: - FileRow

private struct FileRow: View {
    let file: GoogleDriveFile

    var body: some View {
        Button {
            if let link = file.webViewLink, let url = URL(string: link) {
                NSWorkspace.shared.open(url)
            }
        } label: {
            HStack(spacing: MykSpace.s4) {
                Image(systemName: file.iconName)
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
                    .font(.mykCaption)
                    .foregroundStyle(MykColor.faint.color)
            }
        }
        .buttonStyle(.plain)
        .padding(.vertical, MykSpace.s3)
    }
}
