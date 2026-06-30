import Foundation

// MARK: - ArtikelItem
// Ein Eintrag aus der Airtable-Tabelle „Artikel" (tbl3dAbQtbF51wb4a, ~13.419 Records).
// Foundation-only — kein SwiftUI, kein GRDB, kein Airtable-Typ.
// Felder (Feld-IDs — READ-ONLY):
//   Artikelnummer               fld2pimT2447Sagl1
//   Hersteller                  fldizMl5VBOXzF4f4
//   Kategorie                   fldJFz5O7mw1ByU9W
//   Artikelbeschreibung         fldRlWTXhPGQukZNM
//   Netto-Einkaufspreis (€)     fldBemUVIGpZ77wIi
//   Netto-Verkaufspreis MYKILOS fldUjIDfTheQZpFSW
//   Produktbild                 fldmqAJFWQhl0jGRv
public struct ArtikelItem: Codable, Sendable, Equatable, Identifiable {
    /// Airtable-Record-ID (stabiler Primärschlüssel).
    public let id: String
    /// Artikelnummer (Lieferantencode, Bestellnummer).
    public let artikelnummer: String
    /// Hersteller / Marke.
    public let hersteller: String?
    /// Produktkategorie.
    public let kategorie: String?
    /// Artikelbeschreibung (Freitext).
    public let artikelbeschreibung: String?
    /// Netto-Einkaufspreis in €.
    public let ekNetto: Double?
    /// Netto-Verkaufspreis MYKILOS in €.
    public let vkNetto: Double?
    /// URL des Produktbilds (erste Anlage aus dem Airtable-Attachments-Feld).
    public let produktbildURL: String?

    public init(
        id: String,
        artikelnummer: String,
        hersteller: String? = nil,
        kategorie: String? = nil,
        artikelbeschreibung: String? = nil,
        ekNetto: Double? = nil,
        vkNetto: Double? = nil,
        produktbildURL: String? = nil
    ) {
        self.id = id
        self.artikelnummer = artikelnummer
        self.hersteller = hersteller
        self.kategorie = kategorie
        self.artikelbeschreibung = artikelbeschreibung
        self.ekNetto = ekNetto
        self.vkNetto = vkNetto
        self.produktbildURL = produktbildURL
    }

    // MARK: - Suchrelevante Felder

    /// Normalisierte Artikelnummer (Großbuchstaben, nur Buchstaben + Ziffern).
    public var normalisierteArtikelnummer: String {
        LagerItem.normalisiereArtikelnummer(artikelnummer)
    }

    /// Alle suchbaren Tokens (Bezeichnung, Hersteller, Artikelnummer, Kategorie).
    /// Für clientseitiges Filtern nach Eingabe im Suchfeld.
    public var suchTokens: [String] {
        var tokens: [String] = []
        tokens.append(contentsOf: Self.tokenize(artikelnummer))
        if let h = hersteller  { tokens.append(contentsOf: Self.tokenize(h)) }
        if let b = artikelbeschreibung { tokens.append(contentsOf: Self.tokenize(b)) }
        if let k = kategorie   { tokens.append(contentsOf: Self.tokenize(k)) }
        return tokens
    }

    /// Tokenisierung für Overlap-Berechnung und Suche.
    /// Reine Funktion — testbar ohne Instanz.
    public static func tokenize(_ text: String) -> [String] {
        text.lowercased()
            .components(separatedBy: .whitespacesAndNewlines)
            .flatMap { $0.components(separatedBy: CharacterSet.punctuationCharacters) }
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { $0.count >= 2 }
    }
}

// MARK: - ArtikelSuchergebnis
// Wrapper mit Relevanz-Score für die Ergebnisliste.
public struct ArtikelSuchergebnis: Sendable, Equatable, Identifiable {
    public let artikel: ArtikelItem
    public let score: Int  // Anzahl treffender Tokens

    public var id: String { artikel.id }

    public init(artikel: ArtikelItem, score: Int) {
        self.artikel = artikel
        self.score = score
    }
}
