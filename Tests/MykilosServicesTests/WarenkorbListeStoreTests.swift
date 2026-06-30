import Testing
import Foundation
@testable import MykilosServices
@testable import MykilosKit

// MARK: - WarenkorbListeStoreTests
// Testet Mapping, Sortierung und Store-Lifecycle ohne Netzwerk.
struct WarenkorbListeStoreTests {

    // MARK: - Mapping: Pflichtfeld Bezeichnung

    @Test func mappingErfordertBezeichnung() {
        let records: [[String: AirtableFieldValue]] = [
            ["_airtableRecordID": .string("r1")],  // kein Bezeichnung-Feld
        ]
        let items = WarenkorbListeStore.mapEintraege(from: records)
        #expect(items.isEmpty)
    }

    @Test func mappingMitLeererBezeichnungWirdUebersprungen() {
        let records: [[String: AirtableFieldValue]] = [
            ["_airtableRecordID": .string("r1"), "Bezeichnung": .string("  ")],
        ]
        let items = WarenkorbListeStore.mapEintraege(from: records)
        #expect(items.isEmpty)
    }

    // MARK: - Volles Mapping

    @Test func mappingVollerWarenkorbRecord() {
        let records: [[String: AirtableFieldValue]] = [
            [
                "_airtableRecordID": .string("recWK001"),
                "Bezeichnung": .string("Küche Müller v2"),
                "Projekt": .string("2026-015"),
                "Status": .string("Aktuell"),
                "Version": .number(2),
                "Erstellt-am": .string("2026-06-30T10:00:00.000Z"),
                "Anzahl Positionen": .number(12),
                "Gesamt EK (€)": .number(4500.50),
                "Gesamt VK (€)": .number(6800.00),
                "Positionen (JSON)": .string("[{\"bezeichnung\":\"Armatur\"}]"),
            ],
        ]
        let items = WarenkorbListeStore.mapEintraege(from: records)
        #expect(items.count == 1)
        let e = items[0]
        #expect(e.id == "recWK001")
        #expect(e.bezeichnung == "Küche Müller v2")
        #expect(e.projekt == "2026-015")
        #expect(e.status == "Aktuell")
        #expect(e.version == 2)
        #expect(e.erstelltAm != nil)
        #expect(e.anzahlPositionen == 12)
        #expect(e.gesamtEK == 4500.50)
        #expect(e.gesamtVK == 6800.00)
        #expect(e.positionenJSON == "[{\"bezeichnung\":\"Armatur\"}]")
        #expect(e.istAktuell)
    }

    @Test func mappingArchiviertStatus() {
        let records: [[String: AirtableFieldValue]] = [
            [
                "_airtableRecordID": .string("r2"),
                "Bezeichnung": .string("Alt"),
                "Status": .string("Archiviert"),
                "Version": .number(1),
            ],
        ]
        let items = WarenkorbListeStore.mapEintraege(from: records)
        #expect(items.count == 1)
        #expect(!items[0].istAktuell)
    }

    @Test func mappingOptionaleFelderNil() {
        let records: [[String: AirtableFieldValue]] = [
            ["_airtableRecordID": .string("r1"), "Bezeichnung": .string("Minimal")],
        ]
        let items = WarenkorbListeStore.mapEintraege(from: records)
        #expect(items.count == 1)
        let e = items[0]
        #expect(e.projekt == nil)
        #expect(e.erstelltAm == nil)
        #expect(e.gesamtEK == nil)
        #expect(e.positionenJSON == nil)
        #expect(e.version == 1)  // Default
    }

    @Test func mappingProjektAlsArray() {
        // Lookup-Felder in Airtable kommen als [String]-Array
        let records: [[String: AirtableFieldValue]] = [
            [
                "_airtableRecordID": .string("r1"),
                "Bezeichnung": .string("Test"),
                "Projekt": .array(["2026-015 Schmidt"]),
            ],
        ]
        let items = WarenkorbListeStore.mapEintraege(from: records)
        #expect(items[0].projekt == "2026-015 Schmidt")
    }

    // MARK: - Positionen-JSON-Dekodierung

    @Test func decodedItemsLiefertPositionen() throws {
        let items: [WarenkorbItem] = [
            WarenkorbItem(
                bezeichnung: "Grohe Eurosmart",
                artikelnummer: "GFW-750",
                menge: 2,
                ekNetto: 89.90,
                quelle: "katalog"
            ),
        ]
        let json = try JSONEncoder().encode(items)
        let jsonStr = String(data: json, encoding: .utf8)!
        let eintrag = WarenkorbEintrag(id: "r1", bezeichnung: "Test", positionenJSON: jsonStr)
        let decoded = eintrag.decodedItems()
        #expect(decoded?.count == 1)
        #expect(decoded?.first?.artikelnummer == "GFW-750")
        #expect(decoded?.first?.menge == 2)
    }

    @Test func decodedItemsNilBeiKeinemJSON() {
        let eintrag = WarenkorbEintrag(id: "r1", bezeichnung: "Test")
        #expect(eintrag.decodedItems() == nil)
    }

    @Test func decodedItemsNilBeiUngueltigemJSON() {
        let eintrag = WarenkorbEintrag(id: "r1", bezeichnung: "Test", positionenJSON: "{ungültig}")
        #expect(eintrag.decodedItems() == nil)
    }

    // MARK: - Store-Lifecycle

    @Test @MainActor func storeLoadtContentState() async {
        let fake = FakeLagerFetcher(records: [
            ["_airtableRecordID": .string("r1"), "Bezeichnung": .string("WK 1"), "Version": .number(1)],
            ["_airtableRecordID": .string("r2"), "Bezeichnung": .string("WK 2"), "Version": .number(2)],
        ])
        let store = WarenkorbListeStore(client: fake)
        #expect(store.state == .idle)
        await store.load()
        if case .content(let items) = store.state {
            #expect(items.count == 2)
        } else {
            Issue.record("Erwarteter .content-State, bekam \(store.state)")
        }
    }

    @Test @MainActor func storeNotConnected() async {
        let fake = FakeLagerFetcher(error: AirtableError.notConnected)
        let store = WarenkorbListeStore(client: fake)
        await store.load()
        #expect(store.state == .notConnected)
    }

    @Test @MainActor func storeHTTPFehler() async {
        let fake = FakeLagerFetcher(error: AirtableError.httpError(403))
        let store = WarenkorbListeStore(client: fake)
        await store.load()
        if case .error = store.state { } else {
            Issue.record("Erwarteter .error-State, bekam \(store.state)")
        }
    }

    @Test @MainActor func storeLeerBeiKeineRecords() async {
        let fake = FakeLagerFetcher(records: [])
        let store = WarenkorbListeStore(client: fake)
        await store.load()
        #expect(store.state == .empty)
    }
}

// MARK: - AirtableFieldValue.anyStringValue Tests

struct AirtableFieldValueAnyStringTests {

    @Test func anyStringValueFuerString() {
        let v = AirtableFieldValue.string("GFW-750")
        #expect(v.anyStringValue == "GFW-750")
    }

    @Test func anyStringValueFuerGanzeZahl() {
        let v = AirtableFieldValue.number(12345.0)
        #expect(v.anyStringValue == "12345")
    }

    @Test func anyStringValueFuerDezimalzahl() {
        let v = AirtableFieldValue.number(3.14)
        #expect(v.anyStringValue == "3.14")
    }

    @Test func anyStringValueFuerNull() {
        let v = AirtableFieldValue.null
        #expect(v.anyStringValue == nil)
    }

    @Test func anyStringValueFuerArray() {
        let v = AirtableFieldValue.array(["a", "b"])
        #expect(v.anyStringValue == nil)
    }
}

// MARK: - ArtikelKatalogStore: anyStringValue für Artikelnummer

struct ArtikelNumerischeArtikelnummerTests {

    @Test func mappingNumerischeArtikelnummer() {
        // Artikelnummer als Zahl (wie Airtable manchmal Zahlenfelder liefert)
        let records: [[String: AirtableFieldValue]] = [
            [
                "_airtableRecordID": .string("recART001"),
                "Artikelnummer": .number(12345.0),
                "Hersteller": .string("GROHE"),
            ],
        ]
        let items = ArtikelKatalogStore.mapArtikelItems(from: records)
        // BUG WAR: stringValue nil → record übersprungen → .empty
        // FIX: anyStringValue konvertiert 12345.0 → "12345"
        #expect(items.count == 1)
        #expect(items[0].artikelnummer == "12345")
        #expect(items[0].hersteller == "GROHE")
    }

    @Test func mappingNumerischeArtikelnummerMitNachkommastellen() {
        let records: [[String: AirtableFieldValue]] = [
            [
                "_airtableRecordID": .string("r1"),
                "Artikelnummer": .number(750.5),
            ],
        ]
        let items = ArtikelKatalogStore.mapArtikelItems(from: records)
        #expect(items.count == 1)
        #expect(items[0].artikelnummer == "750.5")
    }
}
