import SwiftUI
import AppKit
import MykilosKit
import MykilosDesign
import MykilosServices

// MARK: - DriveWidget
// Dateien & Zeichnungen, lesend aus dem im Projekt verlinkten Drive-Ordner
// (Project.links.driveFolderID). Nie Schreiben. Klick auf eine Datei öffnet die
// In-App-Dokumentenvorschau (read-only downloadContent, Sammlungs-Ansicht-
// Standard); Ordner/Google-Native-Formate öffnen im Browser.
public struct DriveWidget: View {
    public let projectID: String
    public let driveFolderID: String?

    public init(projectID: String, driveFolderID: String?) {
        self.projectID = projectID
        self.driveFolderID = driveFolderID
    }

    @State private var loader = DriveFolderLoader()

    public var body: some View {
        WidgetContainer(
            kind: .drive,
            sourceLabel: sourceLabel,
            renderState: loader.renderState,
            projectID: projectID
        ) {
            VStack(alignment: .leading, spacing: MykSpace.s5) {
                widgetHeader
                fileList
            }
        }
        .task(id: driveFolderID) {
            await loader.load(folderID: driveFolderID)
        }
    }

    private var sourceLabel: String {
        switch loader.renderState {
        case .content: "DRIVE  ·  \(loader.files.count) DATEIEN"
        default:       "DRIVE"
        }
    }

    private var widgetHeader: some View {
        HStack {
            SourceChip(kind: .drive)
            Text("Zeichnungen & Pläne").mykWidgetTitle()
            Spacer()
            if case .error = loader.renderState {
                retryButton
            } else if case .permissionRequired = loader.renderState {
                retryButton
            }
        }
    }

    private var retryButton: some View {
        Button("Erneut versuchen") {
            Task { await loader.load(folderID: driveFolderID) }
        }
        .font(.mykMono(9.5))
        .buttonStyle(.plain)
        .foregroundStyle(MykColor.drive.color)
    }

    private var fileList: some View {
        VStack(spacing: 0) {
            ForEach(loader.files) { file in
                DriveFileRow(file: file)
                if file.id != loader.files.last?.id {
                    Divider().overlay(MykColor.line.color.opacity(0.6))
                }
            }
        }
    }
}

// MARK: - DriveFolderLoader
// Pro Widget-Instanz, kein geteilter Zustand nötig — Drive-Daten sind reine
// Lesefetches, kein Speichern-Vertrag wie bei NoteStore/WidgetBoardStore.
@MainActor
@Observable
private final class DriveFolderLoader {
    private(set) var files: [GoogleDriveFile] = []
    private(set) var renderState: WidgetRenderState = .loading

    private let client: GoogleDriveFetching
    // Generation-Token: nur das jüngste load() darf committen. Schützt gegen
    // ein langsames altes Ergebnis (Projektwechsel) UND gegen den Retry-Button,
    // dessen Task nie gecancelt wird. (Task.isCancelled reichte nicht.)
    private var loadGeneration = 0

    init(client: GoogleDriveFetching = GoogleDriveClient()) {
        self.client = client
    }

    func load(folderID: String?) async {
        loadGeneration &+= 1
        let generation = loadGeneration
        guard let folderID, folderID.isEmpty == false else {
            files = []
            renderState = .empty
            return
        }
        renderState = .loading
        do {
            let result = try await client.listFolder(folderID: folderID)
            guard generation == loadGeneration else { return }
            files = result
            renderState = result.isEmpty ? .empty : .content
        } catch GoogleDriveError.notConnected {
            guard generation == loadGeneration else { return }
            files = []
            renderState = .permissionRequired
        } catch {
            guard generation == loadGeneration else { return }
            files = []
            renderState = .error(String(describing: error))
        }
    }
}

// MARK: - DriveFileRow
// Klick auf eine Datei öffnet die In-App-Dokumentenvorschau (Sammlungs-Ansicht-
// Standard: Vorschau überall) — read-only via Drive downloadContent; Ordner und
// Google-Native-Formate gehen weiterhin in den Browser. Kontextmenü behält den
// Browser-Weg als Sekundär-Option.
private struct DriveFileRow: View {
    let file: GoogleDriveFile

    @State private var showViewer = false

    private var canPreview: Bool {
        file.isFolder == false && file.mimeType.hasPrefix("application/vnd.google-apps") == false
    }

    // Read-only Remote-Fallback: Datei-Bytes aus Drive (kein Schreiben) — gleiche
    // Mechanik wie Dateien-Tab/Angebote.
    private func remoteContent() -> (@Sendable () async -> Data?)? {
        guard canPreview else { return nil }
        let fileID = file.id
        return { try? await GoogleDriveClient().downloadContent(fileID: fileID) }
    }

    private func openInBrowser() {
        if let link = file.webViewLink, let url = URL(string: link) {
            NSWorkspace.shared.open(url)
        }
    }

    var body: some View {
        Button {
            if canPreview { showViewer = true } else { openInBrowser() }
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
            }
        }
        .buttonStyle(.plain)
        .padding(.vertical, MykSpace.s3)
        .contextMenu {
            if canPreview { Button("Vorschau") { showViewer = true } }
            if file.webViewLink != nil { Button("Im Browser öffnen") { openInBrowser() } }
        }
        .sheet(isPresented: $showViewer) {
            DocumentViewerView(file: file, localURL: nil, remoteContent: remoteContent(),
                               onClose: { showViewer = false })
                .frame(minWidth: 820, minHeight: 680)
        }
    }
}
