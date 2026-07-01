import Foundation

// MARK: - Customer
// Quelle der Wahrheit: Airtable. mykilOS hält eine lokale Kopie + Referenz.
public struct Customer: Codable, Identifiable, Equatable, Sendable {
    public let id: UUID
    public var customerNumber: String        // Business-Schlüssel (Airtable)
    public var name: String
    public var airtableRecordID: String?     // Referenz auf den Airtable-Datensatz
    /// Clockodo `customers_id` (Block E). OPTIONAL und ohne Kodier-Bruch: fehlt der
    /// Schlüssel in älteren, bereits persistierten Kopien, dekodiert Swift ihn
    /// automatisch zu nil (Optional → decodeIfPresent). nil = dieser Kunde ist in
    /// Clockodo (noch) nicht gemappt → der Buchungspfad überspringt ihn sicher.
    public var clockodoCustomerID: Int?
    public var updatedAt: Date

    public init(id: UUID = UUID(), customerNumber: String, name: String,
                airtableRecordID: String? = nil, clockodoCustomerID: Int? = nil,
                updatedAt: Date = Date()) {
        self.id = id
        self.customerNumber = customerNumber
        self.name = name
        self.airtableRecordID = airtableRecordID
        self.clockodoCustomerID = clockodoCustomerID
        self.updatedAt = updatedAt
    }
}
