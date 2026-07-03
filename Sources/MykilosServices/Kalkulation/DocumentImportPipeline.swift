import Foundation
import GRDB

// MARK: - DocumentImportEntry
// Härtung 2026-07-01 (Schritt 1 des PDF-Imports): SHA256-Dedup-Log für vom
// Assistenten importierte Lieferanten-PDFs. Persistiert in der bestehenden
// `document_imports`-Tabelle (Migration v2, war bisher unbenutzt — kein neues
// Schema nötig). No-delete, append-only wie der Rest von LearningStore.
public struct DocumentImportEntry: Codable, Equatable, Sendable {
    /// Airtable-Record-ID bei erfolgreichem Import, sonst eine lokale UUID
    /// (reiner Duplikat-Log-Eintrag — kein Airtable-Schreibvorgang fand statt).
    public let recordID: String
    public let fileName: String
    public let sha256: String
    public let sizeBytes: Int
    public let isDuplicate: Bool
    /// Bei Duplikat: der SHA256-Hash des bereits vorhandenen Imports (hier: derselbe
    /// Hash, da SHA256 der Dedup-Schlüssel selbst ist).
    public let duplicateOf: String?
    public let archivedPath: String?
    public let importedAt: Date
    public let note: String

    public init(
        recordID: String, fileName: String, sha256: String, sizeBytes: Int,
        isDuplicate: Bool, duplicateOf: String? = nil, archivedPath: String? = nil,
        importedAt: Date = Date(), note: String = ""
    ) {
        self.recordID = recordID
        self.fileName = fileName
        self.sha256 = sha256
        self.sizeBytes = sizeBytes
        self.isDuplicate = isDuplicate
        self.duplicateOf = duplicateOf
        self.archivedPath = archivedPath
        self.importedAt = importedAt
        self.note = note
    }
}

// MARK: - DocumentImportRecord (GRDB)
struct DocumentImportRecord: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "document_imports"
    var pk: Int64?
    var recordID: String
    var fileName: String
    var sha256: String
    var sizeBytes: Int
    var isDuplicate: Bool
    var duplicateOf: String?
    var archivedPath: String?
    var importedAt: String
    var note: String

    init(_ e: DocumentImportEntry) {
        pk = nil
        recordID = e.recordID
        fileName = e.fileName
        sha256 = e.sha256
        sizeBytes = e.sizeBytes
        isDuplicate = e.isDuplicate
        duplicateOf = e.duplicateOf
        archivedPath = e.archivedPath
        importedAt = LearningCodec.string(from: e.importedAt)
        note = e.note
    }

    var domain: DocumentImportEntry {
        DocumentImportEntry(
            recordID: recordID, fileName: fileName, sha256: sha256, sizeBytes: sizeBytes,
            isDuplicate: isDuplicate, duplicateOf: duplicateOf, archivedPath: archivedPath,
            importedAt: LearningCodec.date(from: importedAt), note: note
        )
    }
}

extension LearningDatabase {
    func insert(_ e: DocumentImportEntry, _ db: Database) throws {
        try DocumentImportRecord(e).insert(db)
    }

    func documentImports(_ db: Database) throws -> [DocumentImportEntry] {
        try DocumentImportRecord.order(sql: "pk").fetchAll(db).map(\.domain)
    }

    func documentImports() throws -> [DocumentImportEntry] { try read { try documentImports($0) } }

    // Nur nicht-Duplikat-Einträge zählen als "schon importiert" — ein Duplikat-
    // Log-Eintrag selbst darf keine Kettenreaktion auslösen.
    func documentImportExists(sha256: String) throws -> Bool {
        try read { db in
            (try Int.fetchOne(
                db,
                sql: "SELECT EXISTS(SELECT 1 FROM document_imports WHERE sha256 = ? AND isDuplicate = 0)",
                arguments: [sha256]
            ) ?? 0) == 1
        }
    }
}
