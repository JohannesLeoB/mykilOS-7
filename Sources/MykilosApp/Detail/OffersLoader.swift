import Foundation
import MykilosKit
import MykilosServices
import MykilosWidgets

// MARK: - OffersLoader
// Pro Tab-Instanz, reiner Lesefetch. Löst die zwei realen Unterordner
// ("...ausgehende Angebote" / "...eingehende Angebote") tolerant auf,
// listet deren Inhalte rekursiv (max. 3 Ebenen) und klassifiziert jeden Beleg
// bereits beim Laden — dabei wird der unmittelbare Eltern-Unterordnername
// mitgeführt (sicherstes Zuordnungssignal). Testbar via injizierbarem Client.
@MainActor
@Observable
final class OffersLoader {
    private(set) var incoming: [ClassifiedOffer] = []
    private(set) var outgoing: [ClassifiedOffer] = []
    private(set) var incomingFolderFound = true
    private(set) var outgoingFolderFound = true
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
            incoming = []; outgoing = []
            renderState = .empty
            return
        }
        renderState = .loading
        do {
            let rootChildren = try await client.listFolder(folderID: rootFolderID)
            guard generation == loadGeneration else { return }

            let incomingFolder = Self.subfolder(in: rootChildren, matching: "eingehende")
            let outgoingFolder = Self.subfolder(in: rootChildren, matching: "ausgehende")
            incomingFolderFound = incomingFolder != nil
            outgoingFolderFound = outgoingFolder != nil

            async let incomingFiles = Self.collect(in: incomingFolder, client: client, depth: 0)
            async let outgoingFiles = Self.collect(in: outgoingFolder, client: client, depth: 0)
            let (rawIncoming, rawOutgoing) = try await (incomingFiles, outgoingFiles)
            guard generation == loadGeneration else { return }

            // Klassifikation mit sicherem Unterordner-Signal (parentName).
            incoming = rawIncoming.map {
                OfferDocumentClassifier.classify($0.file, isIncoming: true, folderName: $0.parentName)
            }
            outgoing = rawOutgoing.map {
                OfferDocumentClassifier.classify($0.file, isIncoming: false, folderName: $0.parentName)
            }
            renderState = (incoming.isEmpty && outgoing.isEmpty) ? .empty : .content
        } catch GoogleDriveError.notConnected {
            guard generation == loadGeneration else { return }
            incoming = []; outgoing = []
            renderState = .permissionRequired
        } catch {
            guard generation == loadGeneration else { return }
            incoming = []; outgoing = []
            renderState = .error(String(describing: error))
        }
    }

    // Tolerant: echte Ordner heißen z.B. "04 ausgehende Angebote" /
    // "05 eingehende Angebote" — Nummerierung und Groß-/Kleinschreibung ignorieren.
    static func subfolder(in children: [GoogleDriveFile], matching keyword: String) -> GoogleDriveFile? {
        children.first {
            $0.mimeType == "application/vnd.google-apps.folder"
                && $0.name.lowercased().contains(keyword)
        }
    }

    // Eine Datei mit dem Namen ihres unmittelbaren Eltern-Unterordners.
    // parentName == nil bedeutet: Datei liegt direkt im 04/05-Ordner (kein Subordner).
    struct FileWithParent: Sendable {
        let file: GoogleDriveFile
        let parentName: String?
    }

    // Rekursiv bis max. 3 Ebenen — sammelt alle Nicht-Ordner-Dateien samt
    // ihrem unmittelbaren Eltern-Unterordnernamen (sicheres Zuordnungssignal).
    static func collect(
        in folder: GoogleDriveFile?,
        client: GoogleDriveFetching,
        depth: Int,
        parentName: String? = nil
    ) async throws -> [FileWithParent] {
        guard let folder, depth < 3 else { return [] }
        let children = try await client.listFolder(folderID: folder.id)
        var result: [FileWithParent] = []
        var subfolderTasks: [Task<[FileWithParent], Error>] = []
        for child in children {
            if child.mimeType == "application/vnd.google-apps.folder" {
                // Kinder dieses Unterordners bekommen seinen Namen als parentName.
                let t = Task {
                    try await collect(in: child, client: client, depth: depth + 1, parentName: child.name)
                }
                subfolderTasks.append(t)
            } else {
                result.append(FileWithParent(file: child, parentName: parentName))
            }
        }
        for task in subfolderTasks {
            result.append(contentsOf: try await task.value)
        }
        return result
    }
}
