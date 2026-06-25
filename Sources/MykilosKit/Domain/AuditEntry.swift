import Foundation

// MARK: - AuditEntry
// Jede externe Aktion hinterlässt einen Audit-Eintrag.
// Akt 1: Modell da, Tabelle kommt mit GRDB in Akt 2.
public struct AuditEntry: Codable, Identifiable, Sendable {
    public enum Action: String, Codable, Sendable {
        case offerImported, draftCreated, draftSent, projectLinked, noteUpdated
    }
    public let id: UUID
    public let timestamp: Date
    public let actorUserID: String
    public let projectID: String
    public let action: Action
    public let summary: String

    public init(id: UUID = UUID(), timestamp: Date = Date(), actorUserID: String,
                projectID: String, action: Action, summary: String) {
        self.id = id; self.timestamp = timestamp; self.actorUserID = actorUserID
        self.projectID = projectID; self.action = action; self.summary = summary
    }
}
