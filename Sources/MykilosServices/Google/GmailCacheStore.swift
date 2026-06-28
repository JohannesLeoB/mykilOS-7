import Foundation

// MARK: - GmailCacheEntry

public struct GmailCacheEntry: Sendable {
    public let messages: [GoogleGmailMessage]
    public let fetchedAt: Date

    public func isValid(ttl: TimeInterval = 300) -> Bool {
        Date().timeIntervalSince(fetchedAt) < ttl
    }
}

// MARK: - GmailCacheStore
// Thread-sicherer In-Memory-Cache für Gmail-Suchergebnisse.
// Vermeidet wiederholte API-Calls für dieselbe Suchanfrage innerhalb des TTL-Fensters.
// Actor-Isolation: alle Methoden sind von beliebigen async-Kontexten aufrufbar.
public actor GmailCacheStore {
    private var entries: [String: GmailCacheEntry] = [:]
    public let ttl: TimeInterval

    public init(ttl: TimeInterval = 300) {
        self.ttl = ttl
    }

    /// Liefert gecachte Nachrichten wenn vorhanden und noch nicht abgelaufen.
    public func cached(for query: String) -> [GoogleGmailMessage]? {
        guard let entry = entries[query], entry.isValid(ttl: ttl) else { return nil }
        return entry.messages
    }

    /// Speichert Suchergebnisse im Cache.
    public func store(_ messages: [GoogleGmailMessage], for query: String) {
        entries[query] = GmailCacheEntry(messages: messages, fetchedAt: Date())
    }

    /// Löscht einen einzelnen Eintrag oder den gesamten Cache.
    public func invalidate(query: String? = nil) {
        if let query {
            entries.removeValue(forKey: query)
        } else {
            entries.removeAll()
        }
    }

    /// Anzahl gültiger (nicht abgelaufener) Cache-Einträge.
    public var validEntryCount: Int {
        entries.values.filter { $0.isValid(ttl: ttl) }.count
    }
}
