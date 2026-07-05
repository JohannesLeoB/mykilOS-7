import Foundation

// MARK: - PlanCategory (Zeichnungs-/Planstand-Katalog)
//
// Die sechs Schema-Unterordner eines Projektordners, aus denen der
// Zeichnungs-/Planstand-Katalog und der Material-Tab gespeist werden.
// Ordnernamen werden tolerant erkannt (Diakritik-/Groß-Kleinschreibung-
// unabhängig, Substring) — echte Ordner heißen z.B. "01 INFOS/01 Pläne",
// "08 Werkszeichnung", "Vorplanung | Screenshots".
public enum PlanCategory: String, CaseIterable, Sendable, Identifiable, Hashable {
    case plaene, werkszeichnung, renderings, vorplanung, layouts, praesentation

    public var id: String { rawValue }

    public var label: String {
        switch self {
        case .plaene:         "Pläne"
        case .werkszeichnung: "Werkszeichnung"
        case .renderings:     "Renderings"
        case .vorplanung:     "Vorplanung & Screenshots"
        case .layouts:        "Layouts"
        case .praesentation:  "Präsentation"
        }
    }

    public var iconName: String {
        switch self {
        case .plaene:         "map"
        case .werkszeichnung: "pencil.and.ruler"
        case .renderings:     "photo.on.rectangle"
        case .vorplanung:     "camera.viewfinder"
        case .layouts:        "square.grid.2x2"
        case .praesentation:  "rectangle.on.rectangle.angled"
        }
    }

    /// Präsentationsmaterial gehört in den Material-Tab, aber NICHT in den
    /// globalen Zeichnungs-Katalog (der bleibt Zeichnungs-/Plan-rein).
    public var inGlobalKatalog: Bool { self != .praesentation }

    /// Erkennungs-Schlüsselwörter, bereits diakritik-gefaltet + kleingeschrieben
    /// ("pläne" → "plane"). Zusätzlich die ASCII-Transliteration ("Plaene",
    /// "Praesentation"), die die Faltung NICHT auf die Umlaut-Form reduziert.
    /// Vergleich läuft über `PlanCollector.foldedName`.
    var keywords: [String] {
        switch self {
        case .plaene:         ["plane", "plaene"]
        case .werkszeichnung: ["werkszeichnung", "werkzeichnung"]
        case .renderings:     ["rendering"]
        case .vorplanung:     ["vorplanung", "screenshot"]
        case .layouts:        ["layout"]
        case .praesentation:  ["prasentation", "praesentation", "presentation"]
        }
    }

    /// Prüf-Reihenfolge beim Kategorisieren: spezifischste Signale zuerst,
    /// "plane" zuletzt (generischstes Substring-Signal — "Layoutpläne" soll
    /// z.B. zuerst als Layout erkannt werden). Ein Ordner bekommt maximal
    /// EINE Kategorie (erster Treffer gewinnt).
    static let matchOrder: [PlanCategory] = [
        .werkszeichnung, .vorplanung, .renderings, .layouts, .praesentation, .plaene
    ]
}

// MARK: - PlanCollector
//
// Testbare Sammel-Logik für den Zeichnungs-/Planstand-Katalog — baugleich zum
// bewährten `OffersCollector` (BFS-Ordnersuche, tolerantes Matching, Whitelist),
// nur mit sechs Kategorien statt zwei Richtungen. Read-only; der rekursive
// Datei-Walk wird von `OffersCollector.collect` wiederverwendet (eine Quelle
// der Wahrheit, kein zweiter Walk-Algorithmus).
public enum PlanCollector {

    public static let maxDepthDefault = OffersCollector.maxDepthDefault

    /// Gebündeltes Ergebnis: Dateien je gefundener Kategorie (sortiert nach
    /// Änderungsdatum, neueste zuerst) + welche Schema-Ordner existierten.
    public struct Result: Sendable {
        public let filesByCategory: [PlanCategory: [GoogleDriveFile]]
        public let foundCategories: Set<PlanCategory>
        public init(filesByCategory: [PlanCategory: [GoogleDriveFile]],
                    foundCategories: Set<PlanCategory>) {
            self.filesByCategory = filesByCategory
            self.foundCategories = foundCategories
        }

        public var totalFileCount: Int { filesByCategory.values.reduce(0) { $0 + $1.count } }
        public var isEmpty: Bool { totalFileCount == 0 }
    }

    private static let folderMime = "application/vnd.google-apps.folder"

    /// Diakritik- und Groß/Klein-unabhängige Faltung ("PLÄNE" → "plane"),
    /// damit "Pläne"/"Plaene"/"PLÄNE" alle dasselbe Schlüsselwort treffen.
    static func foldedName(_ name: String) -> String {
        name.folding(options: [.diacriticInsensitive, .caseInsensitive],
                     locale: Locale(identifier: "de_DE"))
    }

    /// Ordnet einen Ordnernamen maximal EINER Kategorie zu (Prüf-Reihenfolge
    /// `PlanCategory.matchOrder`, erster Treffer gewinnt). `nil` = kein Schema-Ordner.
    static func category(forFolderName name: String) -> PlanCategory? {
        let folded = foldedName(name)
        for candidate in PlanCategory.matchOrder
        where candidate.keywords.contains(where: { folded.contains($0) }) {
            return candidate
        }
        return nil
    }

    // MARK: Akzeptierte Plan-Dateitypen
    // Pläne/Zeichnungen/Renderings sind PDF (primär) oder Bild — bewusst ENGER
    // als die Angebote-Whitelist (keine Mail-Formate: eine .eml in einem
    // Plan-Ordner ist Korrespondenz, kein Planstand).
    nonisolated public static let acceptedPlanExtensions: Set<String> = [
        "pdf",
        "jpg", "jpeg", "png", "heic", "heif", "tiff", "tif", "webp"
    ]

    /// True, wenn die Datei ein plausibler Plan-/Zeichnungs-Dateityp ist.
    /// Endung zuerst (Drive-MIME ist oft generisch); ohne Endung entscheidet
    /// die MIME (PDF bzw. `image/`-Präfix).
    nonisolated public static func isAcceptedPlanFileType(_ file: GoogleDriveFile) -> Bool {
        if file.isFolder { return false }
        let ext = (file.name as NSString).pathExtension.lowercased()
        if ext.isEmpty {
            return file.mimeType == "application/pdf" || file.mimeType.hasPrefix("image/")
        }
        return acceptedPlanExtensions.contains(ext)
    }

    /// Findet die Schema-Ordner im Projektbaum — wie `OffersCollector.findOfferFolders`
    /// nicht nur in den direkten Kindern, sondern bis `maxDepth` Ebenen tief (BFS,
    /// "01 Pläne" liegt live unter "01 INFOS/"). Pro Kategorie gewinnt der flachste
    /// Fund (BFS-Reihenfolge); in bereits kategorisierte Ordner wird nicht weiter
    /// abgestiegen. Bricht ab, sobald alle Kategorien gefunden sind.
    public static func findPlanFolders(
        rootFolderID: String, client: GoogleDriveFetching, maxDepth: Int = maxDepthDefault
    ) async throws -> [PlanCategory: GoogleDriveFile] {
        var found: [PlanCategory: GoogleDriveFile] = [:]
        var frontier: [(id: String, depth: Int)] = [(rootFolderID, 0)]

        while frontier.isEmpty == false {
            let (id, depth) = frontier.removeFirst()
            let children = try await client.listFolder(folderID: id)
            var categorizedIDs: Set<String> = []
            for child in children where child.mimeType == folderMime {
                if let category = category(forFolderName: child.name) {
                    categorizedIDs.insert(child.id)
                    if found[category] == nil { found[category] = child }
                }
            }
            if found.count == PlanCategory.allCases.count { break }
            if depth < maxDepth {
                for child in children where child.mimeType == folderMime
                    && categorizedIDs.contains(child.id) == false {
                    frontier.append((child.id, depth + 1))
                }
            }
        }
        return found
    }

    /// Lädt alle Schema-Ordner eines Projektordners und liefert die (gefilterten,
    /// sortierten) Dateien je Kategorie. Fehlende Ordner = leere Kategorie, nie Fehler.
    public static func load(
        rootFolderID: String,
        client: GoogleDriveFetching,
        maxDepth: Int = maxDepthDefault
    ) async throws -> Result {
        let folders = try await findPlanFolders(
            rootFolderID: rootFolderID, client: client, maxDepth: maxDepth)

        var filesByCategory: [PlanCategory: [GoogleDriveFile]] = [:]
        try await withThrowingTaskGroup(of: (PlanCategory, [GoogleDriveFile]).self) { group in
            for (category, folder) in folders {
                group.addTask {
                    let collected = try await OffersCollector.collect(
                        in: folder, client: client, depth: 0, maxDepth: maxDepth)
                    let files = collected.map(\.file)
                        .filter { isAcceptedPlanFileType($0) }
                        .sorted { ($0.modifiedAt ?? .distantPast) > ($1.modifiedAt ?? .distantPast) }
                    return (category, files)
                }
            }
            for try await (category, files) in group {
                filesByCategory[category] = files
            }
        }

        return Result(filesByCategory: filesByCategory,
                      foundCategories: Set(folders.keys))
    }
}
