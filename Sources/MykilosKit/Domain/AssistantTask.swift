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
    /// Feature 2026-07-07 (Johannes-Feedback, Aufgaben-Spalten): löst bei `dueDate` eine
    /// echte lokale Mitteilung aus (TaskAlarmScheduler), sofern global nicht abgeschaltet
    /// (Einstellungen → Mitteilungen). Ohne `dueDate` bleibt der Alarm wirkungslos.
    public var alarmAktiv: Bool
    public let createdAt: Date
    public var updatedAt: Date

    public init(id: String = UUID().uuidString, title: String, done: Bool = false,
                dueDate: Date? = nil, projectID: String? = nil, alarmAktiv: Bool = false,
                createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.title = title
        self.done = done
        self.dueDate = dueDate
        self.projectID = projectID
        self.alarmAktiv = alarmAktiv
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // Additiv (2026-07-07): alte persistierte/JSON-Payloads ohne "alarmAktiv" decodieren
    // als false statt mit keyNotFound zu brechen.
    private enum CodingKeys: String, CodingKey {
        case id, title, done, dueDate, projectID, alarmAktiv, createdAt, updatedAt
    }
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        done = try container.decode(Bool.self, forKey: .done)
        dueDate = try container.decodeIfPresent(Date.self, forKey: .dueDate)
        projectID = try container.decodeIfPresent(String.self, forKey: .projectID)
        alarmAktiv = try container.decodeIfPresent(Bool.self, forKey: .alarmAktiv) ?? false
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }

    /// Kurzer Bezug für die Anzeige im Chat (erste 6 Zeichen der ID).
    public var ref: String { String(id.prefix(6)) }
}
