import Foundation
import GRDB
import MykilosKit

// MARK: - WidgetInstanceRecord
// Dünner GRDB-Record-Wrapper. Hält MykilosKit sauber (kein GRDB-Import dort).
// Mapping zu/von WidgetInstance ist explizit — kein verstecktes ORM-Mapping.
struct WidgetInstanceRecord: Codable, FetchableRecord, PersistableRecord {
    static var databaseTableName: String { "widgetInstances" }

    var id:        String
    var boardID:   String
    var kind:      String
    var size:      String
    var position:  Int
    var isVisible: Bool
    var isPinned:  Bool

    // MARK: Mapping ← Domain
    init(from instance: WidgetInstance, boardID: String) {
        self.id        = instance.id.uuidString
        self.boardID   = boardID
        self.kind      = instance.kind.rawValue
        self.size      = instance.size.rawValue
        self.position  = instance.position
        self.isVisible = instance.isVisible
        self.isPinned  = instance.isPinned
    }

    // MARK: Mapping → Domain
    var toDomain: WidgetInstance {
        WidgetInstance(
            id:        UUID(uuidString: id) ?? UUID(),
            kind:      WidgetKind(rawValue: kind) ?? .notes,
            size:      WidgetSize(rawValue: size) ?? .medium,
            position:  position,
            isVisible: isVisible,
            isPinned:  isPinned
        )
    }
}

// MARK: - NoteRecord
struct NoteRecord: Codable, FetchableRecord, PersistableRecord {
    static var databaseTableName: String { "notes" }

    var id:        String
    var boardID:   String
    var body:      String
    var updatedAt: Double   // Unix timestamp

    init(id: UUID = UUID(), boardID: String, body: String, updatedAt: Date = Date()) {
        self.id        = id.uuidString
        self.boardID   = boardID
        self.body      = body
        self.updatedAt = updatedAt.timeIntervalSince1970
    }

    var updatedAtDate: Date { Date(timeIntervalSince1970: updatedAt) }
}

// MARK: - AuditRecord
struct AuditRecord: Codable, FetchableRecord, PersistableRecord {
    static var databaseTableName: String { "auditEntries" }

    var id:          String
    var timestamp:   Double
    var actorUserID: String
    var projectID:   String
    var action:      String
    var summary:     String
    // Additiv (CheckIn-Spine, v23): nullable Spalten. GRDB matcht per Spaltenname —
    // die Property-Namen `quelle`/`idempotenzKey` müssen EXAKT den ALTER-TABLE-
    // Spaltennamen der v23-Migration entsprechen, sonst schlägt der Rundtrip stumm fehl.
    var quelle:        String?
    var idempotenzKey: String?

    init(from entry: AuditEntry) {
        self.id          = entry.id.uuidString
        self.timestamp   = entry.timestamp.timeIntervalSince1970
        self.actorUserID = entry.actorUserID
        self.projectID   = entry.projectID
        self.action      = entry.action.rawValue
        self.summary     = entry.summary
        self.quelle        = entry.quelle
        self.idempotenzKey = entry.idempotenzKey
    }

    var toDomain: AuditEntry? {
        guard let id = UUID(uuidString: id),
              let action = AuditEntry.Action(rawValue: action) else { return nil }
        return AuditEntry(
            id: id,
            timestamp: Date(timeIntervalSince1970: timestamp),
            actorUserID: actorUserID,
            projectID: projectID,
            action: action,
            summary: summary,
            quelle: quelle,
            idempotenzKey: idempotenzKey
        )
    }
}
