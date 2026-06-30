import Testing
import Foundation
@testable import MykilosServices
@testable import MykilosKit

// MARK: - LagerlisteStoreTests
// Testet Mapping und Store-Logik ohne Netzwerk (FakeLagerFetcher).
struct LagerlisteStoreTests {

    // MARK: - Mapping: Pflichtfeld Bezeichnung

    @Test func mappingErfordertBezeichnung() {
        // Record ohne Bezeichnung wird übersprungen
        let records: [[String: AirtableFieldValue]] = [
            ["_airtableRecordID": .string("rec1")],  // kein Bezeichnung-Feld
        ]
        let items = LagerlisteStore.mapLagerItems(from: records)
        #expect(items.isEmpty)
    }

    @Test func mappingMitLeererBezeichnungWirdUebersprungen() {
        let records: [[String: AirtableFieldValue]] = [
            [
                "_airtableRecordID": .string("rec1"),
                "fldVBhI0ozPXh7XkE": .string("   "),  // Leerzeichen-only
            ],
        ]
        let items = LagerlisteStore.mapLagerItems(from: records)
        #expect(items.isEmpty)
    }

    // MARK: - Mapping: Vollständiger Record

    @Test func mappingVollerRecordAlleFelder() {
        let records: [[String: AirtableFieldValue]] = [
            [
                "_airtableRecordID": .string("recABC"),
                "fldVBhI0ozPXh7XkE": .string("Unterputz-Spülbecken"),
                "fldaqtdkWSgwiDZvL": .string("Sanitär"),
                "fldeOCaWqzojGUtd2": .string("Franke"),
                "fldKIAfFwuvRuDlnY": .string("FRANKE-UPX-500"),
                "fldcSK7xsT896exNf": .number(3),
                "fldpqoXnOpKkluQC8": .number(245.50),
                "fld7OcmQ7ImmU47iT": .number(389.00),
                "fldA8VVAdN9JrXxSh": .string("Sanitär Lieferer GmbH"),
                "fldaR6YTb0601O3SX": .string("Eingebaut 2025"),
            ],
        ]
        let items = LagerlisteStore.mapLagerItems(from: records)
        #expect(items.count == 1)
        let item = items[0]
        #expect(item.id == "recABC")
        #expect(item.bezeichnung == "Unterputz-Spülbecken")
        #expect(item.kategorie == "Sanitär")
        #expect(item.hersteller == "Franke")
        #expect(item.artikelnummer == "FRANKE-UPX-500")
        #expect(item.bestand == 3)
        #expect(item.ekNetto == 245.50)
        #expect(item.vkNetto == 389.00)
        #expect(item.quelle == "Sanitär Lieferer GmbH")
        #expect(item.notiz == "Eingebaut 2025")
    }

    @Test func mappingMitNilOptionalenFeldern() {
        let records: [[String: AirtableFieldValue]] = [
            [
                "_airtableRecordID": .string("recXYZ"),
                "fldVBhI0ozPXh7XkE": .string("Spot LED"),
                // alle anderen Felder fehlen
            ],
        ]
        let items = LagerlisteStore.mapLagerItems(from: records)
        #expect(items.count == 1)
        let item = items[0]
        #expect(item.bezeichnung == "Spot LED")
        #expect(item.kategorie == nil)
        #expect(item.hersteller == nil)
        #expect(item.artikelnummer == nil)
        #expect(item.bestand == nil)
        #expect(item.ekNetto == nil)
        #expect(item.vkNetto == nil)
    }

    @Test func mappingFallbackIDAufBezeichnung() {
        // Kein _airtableRecordID → Bezeichnung als Fallback-ID
        let records: [[String: AirtableFieldValue]] = [
            ["fldVBhI0ozPXh7XkE": .string("Einbauleuchte")],
        ]
        let items = LagerlisteStore.mapLagerItems(from: records)
        #expect(items.count == 1)
        #expect(items[0].id == "Einbauleuchte")
    }

    @Test func mappingMehrereRecords() {
        let records: [[String: AirtableFieldValue]] = [
            ["_airtableRecordID": .string("r1"), "fldVBhI0ozPXh7XkE": .string("Spüle A")],
            ["_airtableRecordID": .string("r2"), "fldVBhI0ozPXh7XkE": .string("Spüle B")],
            ["_airtableRecordID": .string("r3")],  // ohne Bezeichnung → übersprungen
            ["_airtableRecordID": .string("r4"), "fldVBhI0ozPXh7XkE": .string("Armatur C")],
        ]
        let items = LagerlisteStore.mapLagerItems(from: records)
        #expect(items.count == 3)
        #expect(items.map(\.id) == ["r1", "r2", "r4"])
    }

    // MARK: - Store-LoadState via FakeFetcher

    @Test @MainActor func storeLoadtContentState() async {
        let fake = FakeLagerFetcher(records: [
            ["_airtableRecordID": .string("r1"), "fldVBhI0ozPXh7XkE": .string("Wandleuchte")],
        ])
        let store = LagerlisteStore(client: fake)
        #expect(store.state == .idle)
        await store.load()
        if case .content(let items) = store.state {
            #expect(items.count == 1)
            #expect(items[0].bezeichnung == "Wandleuchte")
        } else {
            Issue.record("Erwarteter .content-State, bekam \(store.state)")
        }
        #expect(store.items.count == 1)
    }

    @Test @MainActor func storeLoadtEmptyStateBeiKeinenRecords() async {
        let fake = FakeLagerFetcher(records: [])
        let store = LagerlisteStore(client: fake)
        await store.load()
        #expect(store.state == .empty)
        #expect(store.items.isEmpty)
    }

    @Test @MainActor func storeSetztNotConnectedBeiAirtableError() async {
        let fake = FakeLagerFetcher(error: AirtableError.notConnected)
        let store = LagerlisteStore(client: fake)
        await store.load()
        #expect(store.state == .notConnected)
    }

    @Test @MainActor func storeSetztErrorStateBeHTTPFehler() async {
        let fake = FakeLagerFetcher(error: AirtableError.httpError(403))
        let store = LagerlisteStore(client: fake)
        await store.load()
        if case .error(let msg) = store.state {
            #expect(msg.contains("403"))
        } else {
            Issue.record("Erwarteter .error-State")
        }
    }

    @Test @MainActor func storeReloadErzwingtNeuladung() async {
        let fake = FakeLagerFetcher(records: [
            ["_airtableRecordID": .string("r1"), "fldVBhI0ozPXh7XkE": .string("Tischleuchte")],
        ])
        let store = LagerlisteStore(client: fake)
        await store.load()
        // Reload erzwingt erneuten Fetch
        fake.records = [
            ["_airtableRecordID": .string("r1"), "fldVBhI0ozPXh7XkE": .string("Tischleuchte")],
            ["_airtableRecordID": .string("r2"), "fldVBhI0ozPXh7XkE": .string("Stehleuchte")],
        ]
        await store.reload()
        #expect(store.items.count == 2)
    }
}

// MARK: - FakeLagerFetcher
// Wiederverwendbarer Fake für Lagerliste- und ArtikelKatalog-Tests.
final class FakeLagerFetcher: AirtableFetching, @unchecked Sendable {
    var records: [[String: AirtableFieldValue]]
    var error: Error?

    init(records: [[String: AirtableFieldValue]] = [], error: Error? = nil) {
        self.records = records
        self.error = error
    }

    func fetchRecords(baseID: String, table: String) async throws -> [[String: AirtableFieldValue]] {
        if let error { throw error }
        return records
    }
}
