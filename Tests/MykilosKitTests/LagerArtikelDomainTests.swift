import Testing
import Foundation
@testable import MykilosKit

// MARK: - LagerItemTests
struct LagerItemTests {

    @Test func lagerItemNormalisierteArtikelnummer() {
        let item = LagerItem(id: "r1", bezeichnung: "Armatur", artikelnummer: "FRANKE-UPX 500")
        #expect(item.normalisierteArtikelnummer == "FRANKEUPX500")
    }

    @Test func lagerItemNormalisierteArtikelnummerNilFallback() {
        let item = LagerItem(id: "r1", bezeichnung: "Armatur")  // kein artikelnummer
        #expect(item.normalisierteArtikelnummer.isEmpty)
    }

    @Test func lagerItemIstCodable() throws {
        let original = LagerItem(
            id: "recXYZ",
            bezeichnung: "Spüle",
            kategorie: "Sanitär",
            hersteller: "Franke",
            artikelnummer: "SPL-001",
            bestand: 2,
            ekNetto: 120.00,
            vkNetto: 199.00,
            quelle: "Lieferant A",
            notiz: "Vorrat"
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(LagerItem.self, from: data)
        #expect(decoded == original)
    }

    @Test func lagerItemEquatable() {
        let a = LagerItem(id: "r1", bezeichnung: "Spüle", bestand: 3)
        let b = LagerItem(id: "r1", bezeichnung: "Spüle", bestand: 3)
        let c = LagerItem(id: "r2", bezeichnung: "Armatur")
        #expect(a == b)
        #expect(a != c)
    }

    @Test func normalisiereArtikelnummerStatisch() {
        #expect(LagerItem.normalisiereArtikelnummer("abc-123") == "ABC123")
        #expect(LagerItem.normalisiereArtikelnummer("  ") == "")
        #expect(LagerItem.normalisiereArtikelnummer("GFW 750") == "GFW750")
    }
}

// MARK: - ArtikelItemTests
struct ArtikelItemTests {

    @Test func artikelItemNormalisierteArtikelnummer() {
        let a = ArtikelItem(id: "r1", artikelnummer: "GROHE-GFW 750")
        #expect(a.normalisierteArtikelnummer == "GROHEGFW750")
    }

    @Test func artikelItemSuchTokens() {
        let a = ArtikelItem(
            id: "r1",
            artikelnummer: "GFW-750",
            hersteller: "GROHE",
            artikelbeschreibung: "Eurosmart Einhebelmischer"
        )
        let tokens = a.suchTokens
        #expect(tokens.contains("gfw"))
        #expect(tokens.contains("750"))
        #expect(tokens.contains("grohe"))
        #expect(tokens.contains("eurosmart"))
        #expect(tokens.contains("einhebelmischer"))
    }

    @Test func artikelItemSuchTokensOhneOptionaleFelder() {
        let a = ArtikelItem(id: "r1", artikelnummer: "AB-001")
        let tokens = a.suchTokens
        // Nur Artikelnummer-Tokens
        #expect(tokens.contains("ab"))
        #expect(tokens.contains("001"))
    }

    @Test func artikelItemIstCodable() throws {
        let original = ArtikelItem(
            id: "recABC",
            artikelnummer: "GFW-750",
            hersteller: "GROHE",
            kategorie: "Armaturen",
            artikelbeschreibung: "Eurosmart",
            ekNetto: 89.90,
            vkNetto: 149.00,
            produktbildURL: "https://example.com/img.jpg"
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ArtikelItem.self, from: data)
        #expect(decoded == original)
    }

    @Test func artikelItemEquatable() {
        let a = ArtikelItem(id: "r1", artikelnummer: "GFW-750", hersteller: "GROHE")
        let b = ArtikelItem(id: "r1", artikelnummer: "GFW-750", hersteller: "GROHE")
        let c = ArtikelItem(id: "r2", artikelnummer: "TUX-100")
        #expect(a == b)
        #expect(a != c)
    }

    @Test func artikelSuchergebnisEquatable() {
        let a1 = ArtikelItem(id: "r1", artikelnummer: "X")
        let a2 = ArtikelItem(id: "r1", artikelnummer: "X")
        let s1 = ArtikelSuchergebnis(artikel: a1, score: 3)
        let s2 = ArtikelSuchergebnis(artikel: a2, score: 3)
        #expect(s1 == s2)
    }
}
