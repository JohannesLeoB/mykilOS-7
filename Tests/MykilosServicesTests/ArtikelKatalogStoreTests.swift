import Testing
import Foundation
@testable import MykilosServices
@testable import MykilosKit

// MARK: - ArtikelKatalogStoreTests
// Testet Mapping, clientseitiges Filtern und Store-Lifecycle ohne Netzwerk.
struct ArtikelKatalogStoreTests {

    // MARK: - Mapping

    @Test func mappingErfordertArtikelnummer() {
        let records: [[String: AirtableFieldValue]] = [
            ["_airtableRecordID": .string("r1")],  // kein Artikelnummer-Feld
        ]
        let items = ArtikelKatalogStore.mapArtikelItems(from: records)
        #expect(items.isEmpty)
    }

    @Test func mappingMitLeererArtikelnummerWirdUebersprungen() {
        let records: [[String: AirtableFieldValue]] = [
            ["_airtableRecordID": .string("r1"), "fld2pimT2447Sagl1": .string(" ")],
        ]
        let items = ArtikelKatalogStore.mapArtikelItems(from: records)
        #expect(items.isEmpty)
    }

    @Test func mappingVollerArtikelRecord() {
        let records: [[String: AirtableFieldValue]] = [
            [
                "_airtableRecordID": .string("recART001"),
                "fld2pimT2447Sagl1": .string("GFW-750"),
                "fldizMl5VBOXzF4f4": .string("GROHE"),
                "fldJFz5O7mw1ByU9W": .string("Armaturen"),
                "fldRlWTXhPGQukZNM": .string("Grohe Eurosmart Einhebel-Waschtischarmatur"),
                "fldBemUVIGpZ77wIi": .number(89.90),
                "fldUjIDfTheQZpFSW": .number(149.00),
                "fldmqAJFWQhl0jGRv": .string("https://cdn.example.com/img.jpg"),
            ],
        ]
        let items = ArtikelKatalogStore.mapArtikelItems(from: records)
        #expect(items.count == 1)
        let a = items[0]
        #expect(a.id == "recART001")
        #expect(a.artikelnummer == "GFW-750")
        #expect(a.hersteller == "GROHE")
        #expect(a.kategorie == "Armaturen")
        #expect(a.artikelbeschreibung == "Grohe Eurosmart Einhebel-Waschtischarmatur")
        #expect(a.ekNetto == 89.90)
        #expect(a.vkNetto == 149.00)
        #expect(a.produktbildURL == "https://cdn.example.com/img.jpg")
    }

    @Test func mappingOptionaleFelderNil() {
        let records: [[String: AirtableFieldValue]] = [
            ["_airtableRecordID": .string("r1"), "fld2pimT2447Sagl1": .string("XYZ-001")],
        ]
        let items = ArtikelKatalogStore.mapArtikelItems(from: records)
        #expect(items.count == 1)
        let a = items[0]
        #expect(a.hersteller == nil)
        #expect(a.kategorie == nil)
        #expect(a.artikelbeschreibung == nil)
        #expect(a.ekNetto == nil)
        #expect(a.vkNetto == nil)
        #expect(a.produktbildURL == nil)
    }

    @Test func mappingFallbackIDaufArtikelnummer() {
        let records: [[String: AirtableFieldValue]] = [
            ["fld2pimT2447Sagl1": .string("AB-999")],
        ]
        let items = ArtikelKatalogStore.mapArtikelItems(from: records)
        #expect(items[0].id == "AB-999")
    }

    // MARK: - Tokenisierung

    @Test func tokenizeZerlegt() {
        let tokens = ArtikelItem.tokenize("Grohe Eurosmart 750")
        #expect(tokens.contains("grohe"))
        #expect(tokens.contains("eurosmart"))
        #expect(tokens.contains("750"))
    }

    @Test func tokenizeFiltertKurzTokens() {
        // Tokens < 2 Zeichen werden gefiltert
        let tokens = ArtikelItem.tokenize("A B AB Armatur")
        #expect(!tokens.contains("a"))
        #expect(!tokens.contains("b"))
        #expect(tokens.contains("ab"))
        #expect(tokens.contains("armatur"))
    }

    @Test func tokenizeKleinbuchstaben() {
        let tokens = ArtikelItem.tokenize("GROHE Waschtisch")
        #expect(tokens.contains("grohe"))
        #expect(tokens.contains("waschtisch"))
    }

    @Test func tokenizeLeererString() {
        let tokens = ArtikelItem.tokenize("")
        #expect(tokens.isEmpty)
    }

    // MARK: - Clientseitiges Filtern

    @Test func filtereFindetNachArtikelnummer() {
        let artikel = [
            makeArtikel(id: "r1", artikelnummer: "GFW-750", beschreibung: "Eurosmart Armatur"),
            makeArtikel(id: "r2", artikelnummer: "TUX-100", beschreibung: "Tuchsen Ventil"),
        ]
        let ergebnisse = ArtikelKatalogStore.filtere(artikel: artikel, term: "GFW-750")
        #expect(ergebnisse.count == 1)
        #expect(ergebnisse[0].artikel.id == "r1")
    }

    @Test func filtereFindetNachBeschreibung() {
        let artikel = [
            makeArtikel(id: "r1", artikelnummer: "A1", beschreibung: "Eurosmart Einhebelmischer"),
            makeArtikel(id: "r2", artikelnummer: "A2", beschreibung: "Unterputz Ventil"),
        ]
        let ergebnisse = ArtikelKatalogStore.filtere(artikel: artikel, term: "Eurosmart")
        #expect(ergebnisse.count == 1)
        #expect(ergebnisse[0].artikel.id == "r1")
    }

    @Test func filtereScoreHoeherBeiMehrerenTrefferTokens() {
        let artikel = [
            makeArtikel(id: "r1", artikelnummer: "A1", hersteller: "Grohe", beschreibung: "Eurosmart Einhebelmischer"),
            makeArtikel(id: "r2", artikelnummer: "A2", hersteller: "Grohe", beschreibung: "Eurosmart Duscharmatur Thermostat"),
        ]
        // Suche nach "Grohe Eurosmart Thermostat" → r2 hat mehr Token-Matches
        let ergebnisse = ArtikelKatalogStore.filtere(artikel: artikel, term: "Grohe Eurosmart Thermostat")
        #expect(!ergebnisse.isEmpty)
        // r2 sollte höheren Score haben (treffen: grohe, eurosmart, thermostat vs. nur grohe, eurosmart)
        if let first = ergebnisse.first {
            #expect(first.artikel.id == "r2")
        }
    }

    @Test func filtereLeererTermGibtAlleZurueck() {
        let artikel = [
            makeArtikel(id: "r1", artikelnummer: "A1", beschreibung: "Armatur"),
            makeArtikel(id: "r2", artikelnummer: "A2", beschreibung: "Ventil"),
        ]
        let ergebnisse = ArtikelKatalogStore.filtere(artikel: artikel, term: "   ")
        #expect(ergebnisse.count == 2)
    }

    @Test func filtereNachKategorieExakt() {
        let artikel = [
            makeArtikel(id: "r1", artikelnummer: "A1", kategorie: "Armaturen"),
            makeArtikel(id: "r2", artikelnummer: "A2", kategorie: "Beleuchtung"),
            makeArtikel(id: "r3", artikelnummer: "A3", kategorie: "Armaturen"),
        ]
        let gefiltert = ArtikelKatalogStore.filtereNachKategorie(artikel: artikel, kategorie: "Armaturen")
        #expect(gefiltert.count == 2)
        #expect(gefiltert.map(\.id).sorted() == ["r1", "r3"])
    }

    @Test func filtereNachKategorieCaseInsensitive() {
        let artikel = [makeArtikel(id: "r1", artikelnummer: "A1", kategorie: "ARMATUREN")]
        let gefiltert = ArtikelKatalogStore.filtereNachKategorie(artikel: artikel, kategorie: "armaturen")
        #expect(gefiltert.count == 1)
    }

    @Test func filtereNachHerstellerExakt() {
        let artikel = [
            makeArtikel(id: "r1", artikelnummer: "A1", hersteller: "GROHE"),
            makeArtikel(id: "r2", artikelnummer: "A2", hersteller: "Hansgrohe"),
            makeArtikel(id: "r3", artikelnummer: "A3", hersteller: "GROHE"),
        ]
        let gefiltert = ArtikelKatalogStore.filtereNachHersteller(artikel: artikel, hersteller: "GROHE")
        #expect(gefiltert.count == 2)
    }

    // MARK: - Store-Lifecycle

    @Test @MainActor func storeLoadtContentState() async {
        let fake = FakeLagerFetcher(records: [
            ["_airtableRecordID": .string("r1"), "fld2pimT2447Sagl1": .string("ART-001")],
            ["_airtableRecordID": .string("r2"), "fld2pimT2447Sagl1": .string("ART-002")],
        ])
        let store = ArtikelKatalogStore(client: fake)
        #expect(store.state == .idle)
        await store.load()
        if case .content(let items) = store.state {
            #expect(items.count == 2)
        } else {
            Issue.record("Erwarteter .content-State, bekam \(store.state)")
        }
        #expect(store.alleArtikel.count == 2)
        #expect(store.istGeladen)
    }

    @Test @MainActor func storeLaedtNichtZweiMalOhnereload() async {
        var callCount = 0
        let fake = CountingFakeFetcher {
            callCount += 1
            return [["_airtableRecordID": .string("r1"), "fld2pimT2447Sagl1": .string("ART-001")]]
        }
        let store = ArtikelKatalogStore(client: fake)
        await store.load()
        await store.load()  // zweiter Call — soll gecacht sein
        #expect(callCount == 1)
    }

    @Test @MainActor func storeReloadErzwingtNeuladung() async {
        var callCount = 0
        let fake = CountingFakeFetcher {
            callCount += 1
            return [["_airtableRecordID": .string("r1"), "fld2pimT2447Sagl1": .string("ART-001")]]
        }
        let store = ArtikelKatalogStore(client: fake)
        await store.load()
        await store.reload()
        #expect(callCount == 2)
    }

    @Test @MainActor func storeNotConnectedZustand() async {
        let fake = FakeLagerFetcher(error: AirtableError.notConnected)
        let store = ArtikelKatalogStore(client: fake)
        await store.load()
        #expect(store.state == .notConnected)
        #expect(!store.istGeladen)
    }

    @Test @MainActor func storeClientSeitigeSuche() async {
        let fake = FakeLagerFetcher(records: [
            [
                "_airtableRecordID": .string("r1"),
                "fld2pimT2447Sagl1": .string("GFW-750"),
                "fldRlWTXhPGQukZNM": .string("Eurosmart Einhebelmischer"),
            ],
            [
                "_airtableRecordID": .string("r2"),
                "fld2pimT2447Sagl1": .string("HK-200"),
                "fldRlWTXhPGQukZNM": .string("Hansgrohe Ventil"),
            ],
        ])
        let store = ArtikelKatalogStore(client: fake)
        await store.load()
        let ergebnisse = store.suche(term: "Eurosmart")
        #expect(ergebnisse.count == 1)
        #expect(ergebnisse[0].artikel.id == "r1")
    }
}

// MARK: - Helpers

private func makeArtikel(
    id: String,
    artikelnummer: String,
    hersteller: String? = nil,
    kategorie: String? = nil,
    beschreibung: String? = nil
) -> ArtikelItem {
    ArtikelItem(
        id: id,
        artikelnummer: artikelnummer,
        hersteller: hersteller,
        kategorie: kategorie,
        artikelbeschreibung: beschreibung
    )
}

// Zählt Fetch-Aufrufe für Caching-Test
final class CountingFakeFetcher: AirtableFetching, @unchecked Sendable {
    let handler: () throws -> [[String: AirtableFieldValue]]
    init(handler: @escaping () throws -> [[String: AirtableFieldValue]]) {
        self.handler = handler
    }
    func fetchRecords(baseID: String, table: String) async throws -> [[String: AirtableFieldValue]] {
        try handler()
    }
}
