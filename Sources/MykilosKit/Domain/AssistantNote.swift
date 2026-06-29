import Foundation

// MARK: - AssistantNote (S4)
// Eine vom Assistenten verwaltete, lokal persistente Notiz/Erinnerung.
// Persistiert via AssistantNotesStore in der GRDB-Tabelle `assistantNotes`.
// `ref` ist ein kurzer, menschenlesbarer Bezug (z. B. "a1b2c3"), den der Assistent
// im Chat nennen kann, um eine Notiz gezielt zu bearbeiten/löschen.
public struct AssistantNote: Codable, Identifiable, Equatable, Sendable {
    public let id: String
    public var body: String
    /// Projektnummer (z. B. „2026-015"), zu der die Notiz gehört — nil = projektübergreifend/global.
    public var projectID: String?
    /// Optionaler Farb-Schlüssel für die Zettel-Wand (z. B. „tasks"/„people"/„personal"/„cash").
    /// nil = automatische Farbe aus der Notiz-ID (Rückwärtskompatibilität).
    public var color: String?
    public let createdAt: Date
    public var updatedAt: Date

    public init(id: String = UUID().uuidString, body: String, projectID: String? = nil,
                color: String? = nil, createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.body = body
        self.projectID = projectID
        self.color = color
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    /// Kurzer Bezug für die Anzeige im Chat (erste 6 Zeichen der ID).
    public var ref: String { String(id.prefix(6)) }
}
