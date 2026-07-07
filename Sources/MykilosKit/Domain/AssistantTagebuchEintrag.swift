import Foundation

// MARK: - AssistantTagebuchEintrag (S10_WIRBELSAEULE.md §9, Parallel-Track, 2026-07-07)
// Backlog: statt Code selbst zu editieren (verworfen, "zu dünnes Eis"), schreibt der
// Assistent bei FRIKTIONSPUNKTEN (kann etwas nicht lesen, Daten widersprechen sich,
// fehlende Info) einen kurzen strukturierten Eintrag in ein append-only Tagebuch —
// gleiche Risikoklasse wie `AuditEntry` (nur Log-Schreiben, kein Datei-/Code-Zugriff,
// kein neuer Sicherheitsgrenzfall). Wert: echte, aus dem Alltag gesammelte
// Reibungspunkte statt erratener Ideen — lesbarer Input für künftige Sessions/Backlog.
public struct AssistantTagebuchEintrag: Codable, Identifiable, Sendable, Equatable {
    /// Art des Friktionspunkts — konkret aus dem Backlog-Beispiel abgeleitet.
    public enum Art: String, Codable, Sendable, CaseIterable {
        /// "PDF liegt nur im Mail-Anhang, kann ich nicht lesen" (Backlog-Beispiel).
        case kannNichtLesen
        /// Zwei Datenquellen widersprechen sich (z. B. Airtable vs. ClickUp-Status).
        case widerspruch
        /// Eine für die Aufgabe nötige Information fehlt schlicht.
        case fehlendeInfo
        /// Alles andere, das nicht in die drei obigen Kategorien passt.
        case sonstiges
    }

    public let id: UUID
    public let timestamp: Date
    /// Optional — ein Friktionspunkt kann projektübergreifend auftreten.
    public let projectID: String?
    public let art: Art
    public let text: String

    public init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        projectID: String? = nil,
        art: Art,
        text: String
    ) {
        self.id = id
        self.timestamp = timestamp
        self.projectID = projectID
        self.art = art
        self.text = text
    }
}
