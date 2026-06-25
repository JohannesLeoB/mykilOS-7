import Foundation

// MARK: - Customer
// Quelle der Wahrheit: Airtable. mykilOS hält eine lokale Kopie + Referenz.
public struct Customer: Codable, Identifiable, Equatable, Sendable {
    public let id: UUID
    public var customerNumber: String        // Business-Schlüssel (Airtable)
    public var name: String
    public var airtableRecordID: String?     // Referenz auf den Airtable-Datensatz
    public var updatedAt: Date

    public init(id: UUID = UUID(), customerNumber: String, name: String,
                airtableRecordID: String? = nil, updatedAt: Date = Date()) {
        self.id = id
        self.customerNumber = customerNumber
        self.name = name
        self.airtableRecordID = airtableRecordID
        self.updatedAt = updatedAt
    }
}
