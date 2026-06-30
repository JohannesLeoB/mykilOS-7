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

    // Wie toDomain(), aber ausfallsicher: ein nicht dekodierbarer Block (z. B. nach
    // einem Schema-Wechsel an einem persistierten Typ) darf NICHT den ganzen Scope
    // mitreißen — sonst verschwindet beim Laden das komplette Chat-Archiv. Die
    // Nachricht bleibt an ihrer Stelle erhalten; ihr Inhalt wird, falls undekodierbar,
    // durch einen sichtbaren Platzhalter ersetzt. Sequenz/Reihenfolge bleiben intakt.
    func toDomainResilient() -> ChatMessage {
        let uuid = UUID(uuidString: id) ?? UUID()
        let parsedRole = ChatRole(rawValue: role) ?? .assistant
        let createdDate = Date(timeIntervalSince1970: createdAt)
        if let blocks = try? JSONDecoder().decode([ChatContentBlock].self, from: blocksJSON),
           let status = try? JSONDecoder().decode(ChatTurnStatus.self, from: statusJSON) {
            return ChatMessage(id: uuid, role: parsedRole, blocks: blocks, status: status, createdAt: createdDate)
        }
        return ChatMessage(
            id: uuid,
            role: parsedRole,
            blocks: [.text("⚠️ Diese Nachricht konnte nicht geladen werden (Format-Änderung).")],
            status: .complete,
            createdAt: createdDate
        )
    }
}
