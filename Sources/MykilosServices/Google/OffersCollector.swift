import Foundation

// MARK: - OffersCollector (Mandate C — testbare Angebote-Sammel-/Klassifikationslogik)
//
// Die reine Lese-/Sammel-/Klassifikations-Logik des Angebote-Tabs, aus dem
// `@MainActor @Observable OffersLoader` (MykilosApp) herausgelöst, damit sie hier
// in MykilosServices ECHT getestet werden kann (Forensik F7: vorher lag die Logik
// nur in der App-Schicht und war aus keinem Test-Target erreichbar).
//
// Löst die zwei realen Unterordner ("…eingehende"/"…ausgehende") tolerant auf,
// sammelt deren Inhalte rekursiv (bis maxDepth) MIT dem unmittelbaren Eltern-
// Unterordnernamen (sicherstes Klassifikationssignal) und klassifiziert jeden Beleg.
public enum OffersCollector {

    public static let maxDepthDefault = 3

    /// Eine Datei mit dem Namen ihres unmittelbaren Eltern-Unterordners.
    /// `parentName == nil` → Datei liegt direkt im 04/05-Ordner.
    public struct FileWithParent: Sendable {
        public let file: GoogleDriveFile
        public let parentName: String?
        public init(file: GoogleDriveFile, parentName: String?) {
            self.file = file
            self.parentName = parentName
        }
    }

    /// Gebündeltes Ergebnis für beide Spalten.
    public struct Result: Sendable {
        public let incoming: [ClassifiedOffer]
        public let outgoing: [ClassifiedOffer]
        public let incomingFolderFound: Bool
        public let outgoingFolderFound: Bool
        public init(incoming: [ClassifiedOffer], outgoing: [ClassifiedOffer],
                    incomingFolderFound: Bool, outgoingFolderFound: Bool) {
            self.incoming = incoming
            self.outgoing = outgoing
            self.incomingFolderFound = incomingFolderFound
            self.outgoingFolderFound = outgoingFolderFound
        }
    }

    /// Tolerant: echte Ordner heißen z.B. "04 ausgehende Angebote" /
    /// "05 eingehende Angebote" — Nummerierung und Groß-/Kleinschreibung ignorieren.
    public static func subfolder(in children: [GoogleDriveFile], matching keyword: String) -> GoogleDriveFile? {
        children.first {
            $0.mimeType == "application/vnd.google-apps.folder"
                && $0.name.lowercased().contains(keyword)
        }
    }

    private static let folderMime = "application/vnd.google-apps.folder"

    /// Findet die beiden Angebots-Ordner ("…eingehende"/"…ausgehende") im Projektbaum —
    /// NICHT nur in den direkten Kindern, sondern bis `maxDepth` Ebenen tief (BFS).
    /// Hintergrund (live bestätigt): bei MYKILOS liegen sie KONSTANT in „01 INFOS/",
    /// also eine Ebene unter dem verknüpften Projektordner — die frühere Direkt-Kind-
    /// Suche fand sie deshalb nie. Bricht ab, sobald beide gefunden sind.
    public static func findOfferFolders(
        rootFolderID: String, client: GoogleDriveFetching, maxDepth: Int = maxDepthDefault
    ) async throws -> (incoming: GoogleDriveFile?, outgoing: GoogleDriveFile?) {
        var incoming: GoogleDriveFile?
        var outgoing: GoogleDriveFile?
        var frontier: [(id: String, depth: Int)] = [(rootFolderID, 0)]

        while frontier.isEmpty == false {
            let (id, depth) = frontier.removeFirst()
            let children = try await client.listFolder(folderID: id)
            for child in children where child.mimeType == folderMime {
                let name = child.name.lowercased()
                if incoming == nil, name.contains("eingehende") { incoming = child }
                if outgoing == nil, name.contains("ausgehende") { outgoing = child }
            }
            if incoming != nil, outgoing != nil { break }
            if depth < maxDepth {
                for child in children where child.mimeType == folderMime
                    && child.id != incoming?.id && child.id != outgoing?.id {
                    frontier.append((child.id, depth + 1))
                }
            }
        }
        return (incoming, outgoing)
    }

    /// Rekursiv bis `maxDepth` — sammelt alle Nicht-Ordner-Dateien samt ihrem
    /// unmittelbaren Eltern-Unterordnernamen.
    public static func collect(
        in folder: GoogleDriveFile?,
        client: GoogleDriveFetching,
        depth: Int,
        parentName: String? = nil,
        maxDepth: Int = maxDepthDefault
    ) async throws -> [FileWithParent] {
        guard let folder, depth < maxDepth else { return [] }
        let children = try await client.listFolder(folderID: folder.id)
        var result: [FileWithParent] = []
        var subfolderTasks: [Task<[FileWithParent], Error>] = []
        for child in children {
            if child.mimeType == "application/vnd.google-apps.folder" {
                let t = Task {
                    try await collect(in: child, client: client, depth: depth + 1,
                                      parentName: child.name, maxDepth: maxDepth)
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

    /// Lädt + klassifiziert beide Spalten für einen Projektordner.
    public static func load(
        rootFolderID: String,
        client: GoogleDriveFetching,
        maxDepth: Int = maxDepthDefault
    ) async throws -> Result {
        // Rekursiv suchen statt nur direkte Kinder — die Ordner liegen in „01 INFOS/".
        let (incomingFolder, outgoingFolder) = try await findOfferFolders(
            rootFolderID: rootFolderID, client: client, maxDepth: maxDepth)

        async let incomingFiles = collect(in: incomingFolder, client: client, depth: 0, maxDepth: maxDepth)
        async let outgoingFiles = collect(in: outgoingFolder, client: client, depth: 0, maxDepth: maxDepth)
        let (rawIncoming, rawOutgoing) = try await (incomingFiles, outgoingFiles)

        // Typ-Whitelist (EINE Quelle der Wahrheit, `DriveOfferWatcher`): Angebote sind
        // NIE ZIP/.numbers — nur PDF/Bild/Mail zählen als Beleg. Genau hier gefiltert,
        // damit Projekt-Tab UND „Alle Angebote" denselben sauberen Bestand sehen.
        let cleanIncoming = rawIncoming.filter { DriveOfferWatcher.isAcceptedOfferFileType($0.file) }
        let cleanOutgoing = rawOutgoing.filter { DriveOfferWatcher.isAcceptedOfferFileType($0.file) }

        return Result(
            incoming: cleanIncoming.map {
                OfferDocumentClassifier.classify($0.file, isIncoming: true, folderName: $0.parentName)
            },
            outgoing: cleanOutgoing.map {
                OfferDocumentClassifier.classify($0.file, isIncoming: false, folderName: $0.parentName)
            },
            incomingFolderFound: incomingFolder != nil,
            outgoingFolderFound: outgoingFolder != nil
        )
    }
}
