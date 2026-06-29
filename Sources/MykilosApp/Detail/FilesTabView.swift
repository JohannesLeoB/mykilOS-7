import SwiftUI
import AppKit
import MykilosKit
import MykilosDesign
import MykilosServices
import MykilosWidgets

// MARK: - DriveTreeNode
// Repräsentiert einen Knoten im lazy Ordnerrendering. `children == nil` bedeutet
// "noch nicht geladen"; `children == []` bedeutet "geladen und leer".
@MainActor
@Observable
final class DriveTreeNode: Identifiable {
    nonisolated let id: String   // nonisolated: Identifiable erfordert zugänglich ohne Actor-Hop
    let file: GoogleDriveFile
    var children: [DriveTreeNode]?
    var isExpanded = false
    var isLoading = false

    init(file: GoogleDriveFile) {
        self.id = file.id
        self.file = file
    }
}

// MARK: - DriveTreeStore
@MainActor
@Observable
final class DriveTreeStore {
    private(set) var rootNodes: [DriveTreeNode] = []
    private(set) var folderName: String?
    private(set) var renderState: WidgetRenderState = .loading
    private(set) var lastChecked: Date?
    /// Lokal aufgelöster Projektordner (Drive File Stream), falls materialisiert.
    /// Treibt das „lokal"-Badge und die Finder-Aktionen (Mandate B).
    private(set) var localRootURL: URL?

    private let client: GoogleDriveFetching
    private var loadGeneration = 0
    private var folderID: String?
    private var explicitPath: String?

    init(client: GoogleDriveFetching = GoogleDriveClient()) {
        self.client = client
    }

    func load(folderID: String?, explicitPath: String? = nil) async {
        loadGeneration &+= 1
        let generation = loadGeneration
        self.folderID = folderID
        self.explicitPath = explicitPath
        guard let folderID, !folderID.isEmpty else {
            rootNodes = []; localRootURL = nil; renderState = .empty; return
        }
        if renderState != .content { renderState = .loading }
        // Lokalen Projektordner auflösen (Finder-Routing). Rein lesend, kein Fehlerfall.
        localRootURL = LocalDriveRootResolver.shared.localURL(forDriveFolderID: folderID,
                                                              explicitPath: explicitPath)
        do {
            async let nameTask  = client.getFileName(folderID: folderID)
            async let itemsTask = client.listFolder(folderID: folderID)
            let (name, items) = try await (nameTask, itemsTask)
            guard generation == loadGeneration else { return }
            folderName = name
            rootNodes = items.map { DriveTreeNode(file: $0) }
            lastChecked = Date()
            renderState = rootNodes.isEmpty ? .empty : .content
        } catch GoogleDriveError.notConnected {
            guard generation == loadGeneration else { return }
            rootNodes = []; renderState = .permissionRequired
        } catch {
            guard generation == loadGeneration else { return }
            rootNodes = []; renderState = .error(String(describing: error))
        }
    }

    /// Lokaler URL einer Datei/eines Unterordners im Projektbaum (xattr- bzw.
    /// Namens-Auflösung). `nil`, wenn nicht lokal materialisiert.
    func localURL(for file: GoogleDriveFile) -> URL? {
        guard let folderID, folderID.isEmpty == false else { return nil }
        return LocalDriveRootResolver.shared.localURL(
            forFileID: file.id, fileName: file.name,
            inProjectFolderID: folderID, explicitProjectPath: explicitPath
        )
    }

    /// Zeigt die Datei/den Ordner im Finder; fällt auf den Browser (webViewLink) zurück.
    func revealInFinder(for file: GoogleDriveFile) {
        if let local = localURL(for: file) {
            LocalDriveRootResolver.shared.revealInFinder(localURL: local)
        } else if let link = file.webViewLink, let url = URL(string: link) {
            NSWorkspace.shared.open(url)
        }
    }

    func expand(_ node: DriveTreeNode) async {
        guard node.file.isFolder, node.children == nil, !node.isLoading else { return }
        node.isLoading = true
        do {
            let items = try await client.listFolder(folderID: node.file.id)
            node.children = items.map { DriveTreeNode(file: $0) }
        } catch {
            node.children = []
        }
        node.isLoading = false
        node.isExpanded = true
    }

    func collapse(_ node: DriveTreeNode) {
        node.isExpanded = false
    }

    // Flache Liste aller sichtbaren Knoten mit Tiefe — wird jedes Mal neu
    // berechnet, sobald isExpanded sich ändert (Observable greift automatisch).
    var visibleRows: [(node: DriveTreeNode, depth: Int)] {
        var result: [(DriveTreeNode, Int)] = []
        func walk(_ nodes: [DriveTreeNode], depth: Int) {
            for node in nodes {
                result.append((node, depth))
                if node.isExpanded, let children = node.children {
                    walk(children, depth: depth + 1)
                }
            }
        }
        walk(rootNodes, depth: 0)
        return result
    }
}

// MARK: - FilesTabView
struct FilesTabView: View {
    let projectID: String
    let driveFolderID: String?
    /// Optionaler expliziter lokaler Pfad-Hinweis (Airtable `driveFolderPath`).
    var driveFolderPath: String? = nil

    @State private var store = DriveTreeStore()

    var body: some View {
        WidgetContainer(
            kind: .drive,
            sourceLabel: sourceLabel,
            renderState: store.renderState,
            projectID: projectID
        ) {
            VStack(spacing: 0) {
                statusBar
                if case .content = store.renderState { treeContent }
            }
        }
        .task(id: driveFolderID) {
            await store.load(folderID: driveFolderID, explicitPath: driveFolderPath)
        }
        .padding(.bottom, 64)
    }

    private var sourceLabel: String {
        let lokal = store.localRootURL != nil ? " · LOKAL" : ""
        switch store.renderState {
        case .content: return "GOOGLE DRIVE · \(store.rootNodes.count) EINTRÄGE\(lokal)"
        default:       return "GOOGLE DRIVE"
        }
    }

    // MARK: Status bar
    private var statusBar: some View {
        HStack(spacing: MykSpace.s4) {
            Circle()
                .fill(MykColor.muted.color.opacity(0.45))
                .frame(width: 7, height: 7)
            if let lastChecked = store.lastChecked {
                Text("Zuletzt geprüft: \(lastChecked.formatted(.dateTime.hour().minute()))")
                    .font(.mykMono(10))
                    .foregroundStyle(MykColor.muted.color)
            } else {
                Text("Drive-Ordner noch nicht geprüft")
                    .font(.mykMono(10))
                    .foregroundStyle(MykColor.muted.color)
            }
            Spacer()
            Button("Jetzt prüfen") {
                Task { await store.load(folderID: driveFolderID) }
            }
            .font(.mykMono(10))
            .foregroundStyle(MykColor.drive.color)
            .buttonStyle(.plain)
        }
        .padding(.horizontal, MykSpace.s9)
        .padding(.vertical, MykSpace.s3)
        .background(MykColor.line.color.opacity(0.18))
    }

    // MARK: Tree
    private var treeContent: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                columnHeader
                Divider().overlay(MykColor.line.color)
                ForEach(store.visibleRows, id: \.node.id) { row in
                    DriveTreeRow(node: row.node, depth: row.depth, store: store)
                    Divider().overlay(MykColor.line.color.opacity(0.4))
                }
            }
        }
    }

    private var columnHeader: some View {
        HStack(spacing: 0) {
            Color.clear.frame(width: MykSpace.s9)
            Text("Name")
                .frame(maxWidth: .infinity, alignment: .leading)
            Color.clear.frame(width: 20) // cloud icon column
            Text("Geändert")
                .frame(width: 130, alignment: .leading)
            Text("Größe")
                .frame(width: 70, alignment: .trailing)
                .padding(.horizontal, MykSpace.s3)
            Text("Art")
                .frame(width: 110, alignment: .leading)
                .padding(.trailing, MykSpace.s9)
        }
        .font(.mykMono(9.5))
        .foregroundStyle(MykColor.muted.color)
        .frame(height: 26)
        .background(MykColor.line.color.opacity(0.12))
    }
}

// MARK: - DriveTreeRow
private struct DriveTreeRow: View {
    let node: DriveTreeNode
    let depth: Int
    let store: DriveTreeStore

    @State private var isHovered = false
    @State private var showPreview = false
    @State private var resolvedLocalURL: URL?

    var body: some View {
        Button { handleTap() } label: { rowContent }
            .buttonStyle(.plain)
            .onHover { isHovered = $0 }
            .contextMenu {
                Button("Im Finder zeigen") { store.revealInFinder(for: node.file) }
                if node.file.isFolder == false, let link = node.file.webViewLink, let url = URL(string: link) {
                    Button("Im Browser öffnen") { NSWorkspace.shared.open(url) }
                }
            }
            .popover(isPresented: $showPreview, arrowEdge: .trailing) {
                FilePreviewView(file: node.file, localURL: resolvedLocalURL, remotePDFData: remotePDFData())
                    .frame(width: 300)
                    .padding(MykSpace.s2)
            }
    }

    // Read-only Remote-Fallback: PDF-Bytes aus Drive, falls nicht lokal materialisiert.
    private func remotePDFData() -> (@Sendable () async -> Data?)? {
        guard node.file.mimeType == "application/pdf" else { return nil }
        let fileID = node.file.id
        return { try? await GoogleDriveClient().downloadContent(fileID: fileID) }
    }

    private var rowContent: some View {
        HStack(spacing: 0) {
            // Einrückung
            Color.clear.frame(width: CGFloat(depth) * 18 + MykSpace.s9)

            // Disclosure-Dreieck oder Spacer
            disclosureView
                .frame(width: 16)
                .padding(.trailing, MykSpace.s2)

            // Icon
            Image(systemName: node.file.iconName)
                .font(.mykSmall)
                .foregroundStyle(node.file.isFolder ? MykColor.folderIcon.color : MykColor.drive.color)
                .frame(width: 18)
                .padding(.trailing, MykSpace.s3)

            // Dateiname
            Text(node.file.name)
                .font(.mykSmall)
                .foregroundStyle(MykColor.ink.color)
                .lineLimit(1)
                .truncationMode(.middle)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Cloud-Sync-Icon
            Image(systemName: "arrow.down.circle")
                .font(.mykMono(10))
                .foregroundStyle(MykColor.faint.color)
                .frame(width: 20)

            // Geänderungsdatum
            Text(dateLabel)
                .font(.mykMono(10))
                .foregroundStyle(MykColor.muted.color)
                .frame(width: 130, alignment: .leading)

            // Größe
            Text(node.file.fileSizeLabel)
                .font(.mykMono(10))
                .foregroundStyle(MykColor.muted.color)
                .frame(width: 70, alignment: .trailing)
                .padding(.horizontal, MykSpace.s3)

            // Typ
            Text(node.file.typeLabel)
                .font(.mykMono(10))
                .foregroundStyle(MykColor.muted.color)
                .frame(width: 110, alignment: .leading)
                .padding(.trailing, MykSpace.s9)
        }
        .frame(height: 30)
        .contentShape(Rectangle())
        .background(isHovered ? MykColor.line.color.opacity(0.35) : Color.clear)
    }

    @ViewBuilder
    private var disclosureView: some View {
        if node.file.isFolder {
            if node.isLoading {
                ProgressView()
                    .controlSize(.mini)
                    .scaleEffect(0.7)
            } else {
                Image(systemName: node.isExpanded ? "chevron.down" : "chevron.right")
                    .font(.mykMono(9))
                    .foregroundStyle(MykColor.muted.color)
            }
        } else {
            Color.clear
        }
    }

    private var dateLabel: String {
        guard let date = node.file.modifiedAt else { return "—" }
        let cal = Calendar.current
        if cal.isDateInToday(date) {
            let h = cal.component(.hour, from: date)
            let m = cal.component(.minute, from: date)
            return String(format: "Heute, %02d:%02d", h, m)
        }
        let day   = Calendar.current.component(.day,   from: date)
        let month = Calendar.current.component(.month, from: date)
        let year  = Calendar.current.component(.year,  from: date) % 100
        let hour  = Calendar.current.component(.hour,  from: date)
        let min   = Calendar.current.component(.minute, from: date)
        return String(format: "%02d.%02d.%02d, %02d:%02d", day, month, year, hour, min)
    }

    private func handleTap() {
        if node.file.isFolder {
            if node.isExpanded {
                store.collapse(node)
            } else {
                Task { await store.expand(node) }
            }
        } else {
            // Lokalen Pfad VOR der Vorschau auflösen, damit FilePreviewView die Datei
            // per PDFKit/Vorschau rendert statt den Browser zu öffnen (Mandate B+D).
            resolvedLocalURL = store.localURL(for: node.file)
            showPreview.toggle()
        }
    }
}
