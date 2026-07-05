import Foundation

/// Ein bestätigter Fang, lokal auf dem Gerät geparkt — bis der echte
/// Adapter-Base-Schreibpfad (Airtable) freigeschaltet ist, ist das Gerät
/// selbst die Postbox.
struct PostboxItem: Identifiable, Codable, Hashable {
    let id: UUID
    let kind: String // "zeit" | "idee"
    let text: String
    let kontext: String
    let capturedAt: Date
    var syncedAt: Date?

    init(id: UUID = UUID(), kind: String, text: String, kontext: String, capturedAt: Date = Date(), syncedAt: Date? = nil) {
        self.id = id
        self.kind = kind
        self.text = text
        self.kontext = kontext
        self.capturedAt = capturedAt
        self.syncedAt = syncedAt
    }
}
