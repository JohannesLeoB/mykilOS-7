import Foundation
import GRDB
import MykilosKit

// MARK: - ChatMemorySummaryRecord
// GRDB-Persistenz für ChatMemorySummary. Upsert-only (save() überschreibt die
// Zeile je scopeKey) — es gibt bewusst keine Historie/Versionierung.
struct ChatMemorySummaryRecord: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "chatMemorySummaries"

    var scopeKey: String
    var summaryText: String
    var coveredThroughMessageID: String
    var updatedAt: Double

    enum Columns {
        static let scopeKey = Column(CodingKeys.scopeKey)
    }
}

extension ChatMemorySummaryRecord {
    init(from summary: ChatMemorySummary) {
        self.scopeKey = summary.scopeKey
        self.summaryText = summary.summaryText
        self.coveredThroughMessageID = summary.coveredThroughMessageID
        self.updatedAt = summary.updatedAt.timeIntervalSince1970
    }

    func toDomain() -> ChatMemorySummary {
        ChatMemorySummary(
            scopeKey: scopeKey,
            summaryText: summaryText,
            coveredThroughMessageID: coveredThroughMessageID,
            updatedAt: Date(timeIntervalSince1970: updatedAt)
        )
    }
}

// MARK: - ChatMemoryStore
// @MainActor, GRDB-backed. Ein Row je Scope, IMMER überschrieben (nie
// angehängt) — das destillierte Gedächtnis soll den aktuellen Stand spiegeln,
// nicht Vergangenheit anhäufen. Gleiches Muster wie ChatStore (load-if-needed,
// throws, SaveState sichtbar), aber ohne @Observable — wird nicht direkt in
// der UI gebunden, nur von ConversationEngine gelesen/geschrieben.
@MainActor
public final class ChatMemoryStore {
    public private(set) var saveState: SaveState = .idle

    private let db: GRDBDatabase
    private var cache: [String: ChatMemorySummary] = [:]
    private var loadedScopes: Set<String> = []

    public init(db: GRDBDatabase) {
        self.db = db
    }

    /// Liest die aktuelle Zusammenfassung eines Scopes (nil = noch nie verdichtet).
    public func summary(for scope: ChatScope) throws -> ChatMemorySummary? {
        let key = scope.rawKey
        if loadedScopes.contains(key) == false {
            let record = try db.read { dbConn in
                try ChatMemorySummaryRecord.fetchOne(dbConn, key: key)
            }
            cache[key] = record?.toDomain()
            loadedScopes.insert(key)
        }
        return cache[key]
    }

    /// Überschreibt die Zusammenfassung eines Scopes (upsert — kein Verlauf).
    public func save(_ summary: ChatMemorySummary) throws {
        saveState = .saving
        do {
            let record = ChatMemorySummaryRecord(from: summary)
            try db.write { dbConn in
                try record.save(dbConn)
            }
            cache[summary.scopeKey] = summary
            loadedScopes.insert(summary.scopeKey)
            saveState = .saved(Date())
        } catch {
            saveState = .failed(error.localizedDescription)
            throw error
        }
    }
}
