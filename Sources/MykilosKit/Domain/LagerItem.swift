import Foundation

// MARK: - LagerItem
// Ein Eintrag aus der Airtable-Tabelle „Lagerliste" (tblh8j1Rykv12T2Dx).
// Foundation-only — kein SwiftUI, kein GRDB, kein Airtable-Typ.
// Felder (Feld-IDs — READ-ONLY, kein Schreiben):
//   Bezeichnung    fldVBhI0ozPXh7XkE
//   Kategorie      fldaqtdkWSgwiDZvL
//   Hersteller     fldeOCaWqzojGUtd2
//   Artikelnummer  fldKIAfFwuvRuDlnY
//   Bestand        fldcSK7xsT896exNf
//   EK netto (€)   fldpqoXnOpKkluQC8
//   VK netto (€)   fld7OcmQ7ImmU47iT
//   Quelle         fldA8VVAdN9JrXxSh
//   Notiz          fldaR6YTb0601O3SX
public struct LagerItem: Codable, Sendable, Equatable, Identifiable {
    /// Airtable-Record-ID (stabiler Primärschlüssel).
    public let id: String
    /// Bezeichnung / Produktname.
    public let bezeichnung: String
    /// Produktkategorie (z. B. "Armaturen", "Beleuchtung").
    public let kategorie: String?
    /// Hersteller / Marke.
    public let hersteller: String?
    /// Artikelnummer (Lieferantencode, Bestellnummer) — normalisiert für Matching.
    public let artikelnummer: String?
    /// Aktueller Lagerbestand (Stück).
    public let bestand: Int?
    /// Einkaufspreis netto in €.
    public let ekNetto: Double?
    /// Verkaufspreis netto in € (MYKILOS-VK).
    public let vkNetto: Double?
    /// Quelle / Lieferant.
    public let quelle: String?
    /// Freitext-Notiz.
    public let notiz: String?

    public init(
        id: String,
        bezeichnung: String,
        kategorie: String? = nil,
        hersteller: String? = nil,
        artikelnummer: String? = nil,
        bestand: Int? = nil,
        ekNetto: Double? = nil,
        vkNetto: Double? = nil,
        quelle: String? = nil,
        notiz: String? = nil
    ) {
        self.id = id
        self.bezeichnung = bezeichnung
        self.kategorie = kategorie
        self.hersteller = hersteller
        self.artikelnummer = artikelnummer
        self.bestand = bestand
        self.ekNetto = ekNetto
        self.vkNetto = vkNetto
        self.quelle = quelle
        self.notiz = notiz
    }

    // MARK: - Normalisierte Artikelnummer

    /// Normalisierte Artikelnummer für Matching: Großbuchstaben, Leerzeichen + Bindestriche entfernt.
    /// Gleiche Normalisierung wie `AufLagerMatcher` verwendet.
    public var normalisierteArtikelnummer: String {
        Self.normalisiereArtikelnummer(artikelnummer ?? "")
    }

    /// Statische Normalisierung — reine Funktion für Tests und `AufLagerMatcher`.
    public static func normalisiereArtikelnummer(_ nr: String) -> String {
        nr.uppercased()
            .filter { $0.isLetter || $0.isNumber }
    }
}
