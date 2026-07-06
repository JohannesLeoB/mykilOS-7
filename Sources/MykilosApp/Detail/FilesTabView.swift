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

    // Flache Liste aller sichtbaren Knoten mit Tiefe + Name des unmittelbaren
    // Eltern-Ordners (Herkunft, D3; `nil` auf Wurzelebene). Wird jedes Mal neu
    // berechnet, sobald isExpanded sich ändert (Observable greift automatisch).
    var visibleRows: [VisibleRow] {
        var result: [VisibleRow] = []
        func walk(_ nodes: [DriveTreeNode], depth: Int, parentName: String?) {
            for node in nodes {
                result.append(VisibleRow(node: node, depth: depth, parentName: parentName))
                if node.isExpanded, let children = node.children {
                    walk(children, depth: depth + 1, parentName: node.file.name)
                }
            }
        }
        walk(rootNodes, depth: 0, parentName: nil)
        return result
    }

    // Lädt die Kinder eines Ordners, OHNE ihn im Baum aufzuklappen (`isExpanded`
    // bleibt unberührt). Speist die Galerie-Ansicht, ohne die Liste zu verändern.
    private func loadChildren(_ node: DriveTreeNode) async {
        guard node.file.isFolder, node.children == nil, !node.isLoading else { return }
        node.isLoading = true
        do {
            let items = try await client.listFolder(folderID: node.file.id)
            node.children = items.map { DriveTreeNode(file: $0) }
        } catch {
            node.children = []
        }
        node.isLoading = false
    }

    // „Durch alle Dateien fliegen": lädt rekursiv alle Unterordner (begrenzte Tiefe,
    // damit tiefe Archivbäume die App nicht fluten). Read-only.
    func expandAll(maxDepth: Int = 6) async {
        func walk(_ nodes: [DriveTreeNode], depth: Int) async {
            guard depth < maxDepth else { return }
            for node in nodes where node.file.isFolder {
                await loadChildren(node)
                if let children = node.children { await walk(children, depth: depth + 1) }
            }
        }
        await walk(rootNodes, depth: 0)
    }

    // Alle geladenen Dateien (Ordner ausgeschlossen), flach — mit lokalem URL-Hinweis
    // für das Thumbnail und dem Namen des unmittelbaren Eltern-Ordners (Herkunft, D3).
    // `parentName == nil` für Dateien direkt im Projekt-Wurzelordner. Basis der
    // Galerie-Kacheln.
    var alleDateien: [DateiEintrag] {
        var result: [DateiEintrag] = []
        func walk(_ nodes: [DriveTreeNode], parentName: String?) {
            for node in nodes {
                if node.file.isFolder {
                    if let children = node.children { walk(children, parentName: node.file.name) }
                } else {
                    result.append(DateiEintrag(file: node.file,
                                               localURL: localURL(for: node.file),
                                               parentName: parentName))
                }
            }
        }
        walk(rootNodes, parentName: nil)
        return result
    }
}

// MARK: - Zeilen-Modelle (Herkunft, D3)
// Kleine benannte Träger statt großer Tupel — je ein sichtbarer Baum-Knoten bzw.
// eine flache Galerie-Datei, jeweils mit dem Namen ihres Eltern-Ordners.
struct VisibleRow {
    let node: DriveTreeNode
    let depth: Int
    let parentName: String?
}

struct DateiEintrag {
    let file: GoogleDriveFile
    let localURL: URL?
    let parentName: String?
}

// MARK: - FilesTabView
struct FilesTabView: View {
    let projectID: String
    let driveFolderID: String?
    /// Optionaler expliziter lokaler Pfad-Hinweis (Airtable `driveFolderPath`).
    var driveFolderPath: String? = nil

    @State private var store = DriveTreeStore()
    // Galerie-Flug: „durch alle Dateien fliegen, gekachelt" — pro Nutzer gemerkt.
    @AppStorage("dateien.tab.galerie") private var galerieAn = false
    @AppStorage("dateien.tab.kachel") private var kachelSeiteRaw: Double = 150
    @State private var viewerFile: GoogleDriveFile?

    private var kachelSeite: Binding<CGFloat> {
        Binding(get: { CGFloat(kachelSeiteRaw) }, set: { kachelSeiteRaw = Double($0) })
    }

    var body: some View {
        WidgetContainer(
            kind: .drive,
            sourceLabel: sourceLabel,
            renderState: store.renderState,
            projectID: projectID,
            // Bugfix 2026-07-07: kollidiert mit den eigenständig hover-fähigen Datei-
            // Galerie-Kacheln (siehe WidgetContainer.hoverAnimiert-Kommentar).
            hoverAnimiert: false
        ) {
            VStack(spacing: 0) {
                statusBar
                if case .content = store.renderState {
                    if galerieAn { galerieContent } else { treeContent }
                }
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

    // MARK: Controls bar
    // 2026-07-05 (Johannes, Item D): die Drive-„geprüft"/„Jetzt prüfen"-Chrome hier
    // entfernt (der globale Sync lebt jetzt zentral in Einstellungen → Integrationen →
    // Google, Parent-I/O-Prinzip). Der Dateien-Tab lädt seinen Ordner beim Öffnen
    // ohnehin frisch (.task). Übrig bleiben nur die Ansichts-Controls.
    private var statusBar: some View {
        HStack(spacing: MykSpace.s4) {
            Spacer()
            if galerieAn { KachelGroessenSlider(kachelSeite: kachelSeite) }
            ansichtsUmschalter
        }
        .padding(.horizontal, MykSpace.s9)
        .padding(.vertical, MykSpace.s3)
        .background(MykColor.line.color.opacity(0.18))
    }

    // Liste (Finder-Baum) ⇄ Galerie (Kachel-Flug durch alle Dateien).
    private var ansichtsUmschalter: some View {
        Picker("", selection: $galerieAn) {
            Image(systemName: "list.bullet").tag(false)
            Image(systemName: "square.grid.2x2").tag(true)
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        .frame(width: 78)
        .help("Liste oder Galerie")
    }

    // MARK: Galerie
    // Eine Quelle der Wahrheit für Grid + Viewer-Blättern — gleiche Reihenfolge, gleiche Indizes.
    private var galerieEintraege: [DateiGalerieGrid.Eintrag] {
        store.alleDateien.map {
            DateiGalerieGrid.Eintrag(file: $0.file, subtitle: $0.file.typeLabel,
                                     localURL: $0.localURL, herkunftOrdner: $0.parentName)
        }
    }

    private var galerieViewerItems: [DocumentViewerItem] {
        galerieEintraege.map {
            DocumentViewerItem(file: $0.file, localURL: $0.localURL, remoteContent: galerieRemoteContent(for: $0.file))
        }
    }

    @ViewBuilder private var galerieContent: some View {
        let eintraege = galerieEintraege
        Group {
            if eintraege.isEmpty {
                VStack(spacing: MykSpace.s4) {
                    ProgressView().controlSize(.small)
                    Text("Lade alle Dateien …")
                        .font(.mykMono(10))
                        .foregroundStyle(MykColor.muted.color)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.top, MykSpace.s9)
            } else {
                DateiGalerieGrid(
                    eintraege: eintraege, kachelSeite: kachelSeite,
                    onPreview: { viewerFile = $0.file },
                    onOpen: { store.revealInFinder(for: $0.file) })
                .padding(.horizontal, MykSpace.s6)
            }
        }
        .task(id: galerieAn) { if galerieAn { await store.expandAll() } }
        .sheet(item: $viewerFile) { file in
            let items = galerieViewerItems
            let startIndex = items.firstIndex(where: { $0.id == file.id }) ?? 0
            DocumentViewerView(items: items, initialIndex: startIndex, onClose: { viewerFile = nil })
                .frame(minWidth: 820, minHeight: 680)
        }
    }

    private func galerieRemoteContent(for file: GoogleDriveFile) -> (@Sendable () async -> Data?)? {
        guard file.isFolder == false else { return nil }
        let fileID = file.id
        return { try? await GoogleDriveClient().downloadContent(fileID: fileID) }
    }

    // MARK: Tree
    private var treeContent: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                columnHeader
                Divider().overlay(MykColor.line.color)
                ForEach(store.visibleRows, id: \.node.id) { row in
                    DriveTreeRow(node: row.node, depth: row.depth,
                                 parentName: row.parentName, store: store)
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
    /// Name des unmittelbaren Eltern-Ordners (Herkunft, D3; `nil` auf Wurzelebene).
    let parentName: String?
    let store: DriveTreeStore

    @State private var isHovered = false
    @State private var showViewer = false
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
            // Single-Click auf eine Datei → direkt die volle Dokumentenvorschau
            // (mehrseitiges PDFKit / Bild / QuickLook), kein 300pt-Popover-Zwischenschritt.
            .sheet(isPresented: $showViewer) {
                DocumentViewerView(file: node.file, localURL: resolvedLocalURL,
                                   remoteContent: remoteContent(),
                                   onClose: { showViewer = false })
                    .frame(minWidth: 820, minHeight: 680)
            }
    }

    // Read-only Remote-Fallback: Datei-Bytes aus Drive (jede Nicht-Ordner-Datei), falls
    // nicht lokal materialisiert. Versorgt PDF-Thumbnail UND volle Dokumentenvorschau (S3).
    private func remoteContent() -> (@Sendable () async -> Data?)? {
        guard node.file.isFolder == false else { return nil }
        let fileID = node.file.id
        return { try? await GoogleDriveClient().downloadContent(fileID: fileID) }
    }

    // Herkunfts-Kategorie aus dem Eltern-Ordnernamen (nil = keine bekannte Kategorie).
    private var herkunftKategorie: DriveFolderCategory? {
        DriveFolderCategory.category(forFolderName: parentName)
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

            // Herkunft (D3): dezenter Farbpunkt der Eltern-Ordner-Kategorie —
            // „Farbe ist Sprache". Nur für Dateien mit erkannter Kategorie; sonst
            // nichts (keine Sackgasse). Der Ordnername steht im Baum bereits als
            // Eltern-Zeile, daher hier nur der Punkt, kein Text-Chip.
            if node.file.isFolder == false, let category = herkunftKategorie {
                Circle()
                    .fill(category.markeColor)
                    .frame(width: 6, height: 6)
                    .padding(.trailing, MykSpace.s3)
                    .help("Herkunft: \(parentName ?? "") · \(category.chipLabel)")
            }

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
            // Lokalen Pfad VOR der Vorschau auflösen, damit der Viewer die Datei
            // per PDFKit/QuickLook rendert statt den Browser zu öffnen (Mandate B+D, S25).
            resolvedLocalURL = store.localURL(for: node.file)
            showViewer = true
        }
    }
}
