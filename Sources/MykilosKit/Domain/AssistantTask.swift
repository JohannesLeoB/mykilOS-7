import Foundation

// MARK: - AssistantTask (S6)
// Eine vom Assistenten verwaltete, lokal persistente Aufgabe — kleines Memo oder
// Erinnerung, die Johannes sich selbst intern setzt. Persistiert via
// AssistantTasksStore in der GRDB-Tabelle `assistantTasks`.
// Bewusst NUR lokale, nutzer-eigene Daten — kein externer Schreibzugriff.
// `ref` ist ein kurzer, menschenlesbarer Bezug (z. B. "a1b2c3"), den der Assistent
// im Chat nennen kann, um eine Aufgabe gezielt abzuhaken/zu löschen.
public struct AssistantTask: Codable, Identifiable, Equatable, Sendable {
    public let id: String
    public var title: String
    public var done: Bool
    public var dueDate: Date?       // optionale Erinnerung
    /// Projektnummer (z. B. „2026-015"), zu der die Aufgabe gehört — nil = projektübergreifend/global.
    public var projectID: String?
    public let createdAt: Date
    public var updatedAt: Date

    public init(id: String = UUID().uuidString, title: String, done: Bool = false,
                dueDate: Date? = nil, projectID: String? = nil,
                createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.title = title
        self.done = done
        self.dueDate = dueDate
        self.projectID = projectID
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    /// Kurzer Bezug für die Anzeige im Chat (erste 6 Zeichen der ID).
    public var ref: String { String(id.prefix(6)) }
}
