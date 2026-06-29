import Foundation

// MARK: - StudioContact (S13)
// Ein Kontakt aus der Airtable-Tabelle „Kontakte" (Kunden, Lieferanten, Handwerker,
// Team). Anders als Google-Kontakte (M2-blockiert) liegt das hier im Mastermind-Sync
// und beantwortet Fragen wie „Adresse Familie Cirnavuk?" sofort, lokal, read-only.
public struct StudioContact: Codable, Identifiable, Equatable, Sendable {
    public let id: String                 // Airtable-Record-ID oder Name-Fallback
    public var name: String
    public var organisation: String?
    public var email: String?
    public var telefon: String?
    public var adresse: String?
    public var projekt: String?
    public var kategorie: String?

    public init(id: String, name: String, organisation: String? = nil, email: String? = nil,
                telefon: String? = nil, adresse: String? = nil, projekt: String? = nil,
                kategorie: String? = nil) {
        self.id = id
        self.name = name
        self.organisation = organisation
        self.email = email
        self.telefon = telefon
        self.adresse = adresse
        self.projekt = projekt
        self.kategorie = kategorie
    }

    /// Freitext-Treffer auf Name/Organisation/Projekt (case-insensitive).
    public func matches(_ query: String) -> Bool {
        let q = query.lowercased()
        return name.lowercased().contains(q)
            || (organisation?.lowercased().contains(q) ?? false)
            || (projekt?.lowercased().contains(q) ?? false)
    }
}
