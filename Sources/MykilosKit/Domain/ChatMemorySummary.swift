import Foundation

// MARK: - ChatMemorySummary
// Härtung 2026-07-01 (API-Effizienz Stufe 2): destilliertes Gedächtnis pro
// Chat-Scope. Ersetzt keine Rohhistorie — ergänzt sie. ConversationEngine
// schickt an Claude nur noch die letzten paar Rohnachrichten + diese eine
// Zusammenfassung (im System-Prompt, profitiert vom bestehenden Cache-
// Breakpoint) statt endlos wachsende Historie. Wird bei jeder Verdichtung
// ÜBERSCHRIEBEN, nie angehängt — ein überholter Fakt verschwindet beim
// nächsten Verdichtungslauf, statt für immer im Kontext stehen zu bleiben.
public struct ChatMemorySummary: Sendable, Equatable {
    public let scopeKey: String
    public let summaryText: String
    /// UUID-String der jüngsten Nachricht, die in `summaryText` bereits eingeflossen
    /// ist. Stabiler Anker (statt Index), weil das Datums-/Zählfenster der
    /// Rohhistorie sich verschiebt, IDs aber append-only und unveränderlich sind.
    public let coveredThroughMessageID: String
    public let updatedAt: Date

    public init(scopeKey: String, summaryText: String, coveredThroughMessageID: String, updatedAt: Date) {
        self.scopeKey = scopeKey
        self.summaryText = summaryText
        self.coveredThroughMessageID = coveredThroughMessageID
        self.updatedAt = updatedAt
    }
}
