import Foundation
import GRDB
import MykilosKit

// MARK: - ChatMessageRecord
// GRDB-Persistenz einer Chat-Nachricht. Blocks und Status werden als JSON-BLOB
// abgelegt (eine Quelle der Wahrheit — Anhänge stecken in den image/document-
// Blocks, daher KEINE separate Anhang-Spalte). Datum als timeIntervalSince1970
// (Double), konsistent mit `notes`/`auditEntries`. Mapping hält MykilosKit GRDB-frei.
struct ChatMessageRecord: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "chatMessages"

    var id: String
    var threadScopeKey: String
    var role: String
    var blocksJSON: Data
    var statusJSON: Data
    var sequence: Int
    var createdAt: Double

    enum Columns {
        static let threadScopeKey = Column(CodingKeys.threadScopeKey)
        static let sequence = Column(CodingKeys.sequence)
    }
}

extension ChatMessageRecord {
    init(from message: ChatMessage, scopeKey: String, sequence: Int) throws {
        self.id = message.id.uuidString
        self.threadScopeKey = scopeKey
        self.role = message.role.rawValue
        self.blocksJSON = try JSONEncoder().encode(message.blocks)
        self.statusJSON = try JSONEncoder().encode(message.status)
        self.sequence = sequence
        self.createdAt = message.createdAt.timeIntervalSince1970
    }

    func toDomain() throws -> ChatMessage {
        guard let uuid = UUID(uuidString: id) else { throw ChatStoreError.corruptRecord("id") }
        guard let parsedRole = ChatRole(rawValue: role) else { throw ChatStoreError.corruptRecord("role") }
        let blocks = try JSONDecoder().decode([ChatContentBlock].self, from: blocksJSON)
        let status = try JSONDecoder().decode(ChatTurnStatus.self, from: statusJSON)
        return ChatMessage(
            id: uuid,
            role: parsedRole,
            blocks: blocks,
            status: status,
            createdAt: Date(timeIntervalSince1970: createdAt)
        )
    }
}
