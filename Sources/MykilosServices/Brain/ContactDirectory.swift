import Foundation
import MykilosKit

// MARK: - ContactDirectory (S13)
// Foundation-only Snapshot der Airtable-Tabelle „Kontakte" für den Assistenten.
// Wie KundenBrain ein read-only lokaler Sync-Cache (kein Live-Call pro Frage),
// damit „Adresse Familie Cirnavuk?" sofort und offline beantwortbar ist.
public struct ContactDirectory: Sendable {
    public let contacts: [StudioContact]

    public init(contacts: [StudioContact]) {
        self.contacts = contacts
    }

    /// Freitextsuche über Name/Organisation/Projekt. Exakte Namenstreffer zuerst,
    /// dann Präfix, dann Teilstring; begrenzt auf `limit`.
    public func search(_ query: String, limit: Int = 8) -> [StudioContact] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard q.isEmpty == false else { return [] }
        let hits = contacts.filter { $0.matches(q) }
        let ranked = hits.sorted { lhs, rhs in
            rank(lhs, q) < rank(rhs, q)
        }
        return Array(ranked.prefix(limit))
    }

    // 0 = exakter Name, 1 = Name-Präfix, 2 = sonst — stabil sortierbar.
    private func rank(_ c: StudioContact, _ q: String) -> Int {
        let name = c.name.lowercased()
        if name == q { return 0 }
        if name.hasPrefix(q) { return 1 }
        return 2
    }
}
