import Testing
import Foundation
@testable import MykilosServices
@testable import MykilosKit

// MARK: - WarenkorbTests
struct WarenkorbTests {

    // MARK: Prüfsummen-Stabilität

    @Test func pruefsummeIstDeterministisch() {
        let item = WarenkorbItem(bezeichnung: "Spüle", artikelnummer: "SPL-001", menge: 1, quelle: "manuell")
        let wk1 = Warenkorb(items: [item], projektName: "Küche Meyer")
        let wk2 = Warenkorb(items: [item], projektName: "Küche Meyer")
        #expect(wk1.pruefsumme == wk2.pruefsumme)
    }

    @Test func pruefsummeAendertSichBeiAndererMenge() {
        let item1 = WarenkorbItem(bezeichnung: "Spüle", artikelnummer: "SPL-001", menge: 1, quelle: "manuell")
        let item2 = WarenkorbItem(bezeichnung: "Spüle", artikelnummer: "SPL-001", menge: 2, quelle: "manuell")
        let wk1 = Warenkorb(items: [item1])
        let wk2 = Warenkorb(items: [item2])
        #expect(wk1.pruefsumme != wk2.pruefsumme)
    }

    @Test func pruefsummeAendertSichBeiAndererBezeichnung() {
        let item1 = WarenkorbItem(bezeichnung: "Spüle A", artikelnummer: "SPL-001", menge: 1, quelle: "manuell")
        let item2 = WarenkorbItem(bezeichnung: "Spüle B", artikelnummer: "SPL-001", menge: 1, quelle: "manuell")
        let wk1 = Warenkorb(items: [item1])
        let wk2 = Warenkorb(items: [item2])
        #expect(wk1.pruefsumme != wk2.pruefsumme)
    }

    @Test func pruefsummeAendertSichBeiAnderesProjekt() {
        let item = WarenkorbItem(bezeichnung: "Spüle", artikelnummer: "SPL-001", menge: 1, quelle: "manuell")
        let wk1 = Warenkorb(items: [item], projektName: "Küche Meyer")
        let wk2 = Warenkorb(items: [item], projektName: "Küche Schmidt")
        #expect(wk1.pruefsumme != wk2.pruefsumme)
    }

    @Test func pruefsummeIstUnabhaengigVonItemReihenfolge() {
        let a = WarenkorbItem(bezeichnung: "Alpha", artikelnummer: "A-001", menge: 1, quelle: "katalog")
        let b = WarenkorbItem(bezeichnung: "Beta",  artikelnummer: "B-002", menge: 2, quelle: "katalog")
        let wk1 = Warenkorb(items: [a, b])
        let wk2 = Warenkorb(items: [b, a])
        #expect(wk1.pruefsumme == wk2.pruefsumme)
    }

    @Test func pruefsummeIstSHA256Hex64Zeichen() {
        let item = WarenkorbItem(bezeichnung: "Test", artikelnummer: "T-001", menge: 1, quelle: "test")
        let wk = Warenkorb(items: [item])
        #expect(wk.pruefsumme.count == 64)
        #expect(wk.pruefsumme.allSatisfy { "0123456789abcdef".contains($0) })
    }

    // MARK: Berechnete Summen

    @Test func gesamtEKNettoRechnetMengeKorrekt() {
        let items = [
            WarenkorbItem(bezeichnung: "A", artikelnummer: "A-1", menge: 2, ekNetto: 100.0, quelle: "test"),
            WarenkorbItem(bezeichnung: "B", artikelnummer: "B-1", menge: 3, ekNetto: 50.0,  quelle: "test"),
        ]
        let wk = Warenkorb(items: items)
        #expect(wk.gesamtEKNetto == 350.0)  // 2×100 + 3×50
    }

    @Test func gesamtVKNettoRechnetMengeKorrekt() {
        let items = [
            WarenkorbItem(bezeichnung: "A", artikelnummer: "A-1", menge: 1, vkNetto: 200.0, quelle: "test"),
            WarenkorbItem(bezeichnung: "B", artikelnummer: "B-1", menge: 2, vkNetto: 75.0,  quelle: "test"),
        ]
        let wk = Warenkorb(items: items)
        #expect(wk.gesamtVKNetto == 350.0)  // 1×200 + 2×75
    }

    @Test func summenIgnorierenNilPreise() {
        let items = [
            WarenkorbItem(bezeichnung: "A", artikelnummer: "A-1", menge: 2, ekNetto: nil, quelle: "test"),
        ]
        let wk = Warenkorb(items: items)
        #expect(wk.gesamtEKNetto == 0.0)
    }
}

// MARK: - CartStoreTests
struct CartStoreTests {

    // MARK: JSON-Serialisierung

    @Test func serializeItemsErzeugtGueltigenJSON() throws {
        let items = [
            WarenkorbItem(
                artikelRecordID: "recABC",
                bezeichnung: "Spüle Blanco",
                artikelnummer: "BLA-001",
                menge: 1,
                ekNetto: 199.0,
                vkNetto: 299.0,
                quelle: "katalog"
            )
        ]
        let json = try CartStore.serializeItems(items)
        #expect(!json.isEmpty)
        #expect(json.contains("BLA-001"))
        #expect(json.contains("Spüle Blanco"))
    }

    @Test func deserializeItemsRoundtrip() throws {
        let items = [
            WarenkorbItem(bezeichnung: "Armatur", artikelnummer: "ARM-002", menge: 2, ekNetto: 80.0, vkNetto: 120.0, quelle: "manuell"),
            WarenkorbItem(bezeichnung: "Spüle",   artikelnummer: "SPL-001", menge: 1, ekNetto: 200.0, quelle: "katalog"),
        ]
        let json = try CartStore.serializeItems(items)
        let decoded = try CartStore.deserializeItems(from: json)
        #expect(decoded.count == 2)
        #expect(decoded[0].bezeichnung == items[0].bezeichnung)
        #expect(decoded[1].artikelnummer == items[1].artikelnummer)
        #expect(decoded[0].ekNetto == items[0].ekNetto)
    }

    @Test func deserializeWirftBeiUngueltigemJSON() {
        #expect(throws: (any Error).self) {
            _ = try CartStore.deserializeItems(from: "{ not valid json }")
        }
    }

    // MARK: Versionierung (Fake-Client)

    @Test func versionierungArchiviertAltenRecordUndErstelltNeuenMitVersionPlusEins() async throws {
        let fake = FakeAirtableRW()

        // Simuliere einen bestehenden Warenkorb (Status: Aktuell, gleiche Prüfsumme)
        let item = WarenkorbItem(bezeichnung: "Herd", artikelnummer: "HRD-001", menge: 1, ekNetto: 500.0, vkNetto: 750.0, quelle: "test")
        let wk = Warenkorb(items: [item], projektName: "Küche Test")
        let pruefsumme = wk.pruefsumme

        fake.existingRecords = [[
            "_airtableRecordID": .string("recALT"),
            CartStore.feldPruefsumme: .string(pruefsumme),
            CartStore.feldStatus: .string(CartStore.statusAktuell),
            CartStore.feldVersion: .number(1.0),
        ]]

        let store = CartStore(fetcher: fake, creator: fake, updater: fake)
        let outcome = try await store.sendWarenkorbToAirtable(wk)

        // Alter Record muss auf Archiviert gesetzt worden sein
        #expect(fake.updatedRecords["recALT"]?[CartStore.feldStatus]?.stringValue == CartStore.statusArchiviert)

        // Neuer Record muss Version 2 haben
        guard case .success(_, let version) = outcome else {
            Issue.record("Erwartet .success, bekommen: \(outcome)")
            return
        }
        #expect(version == 2)
    }

    @Test func ohneVorhandeneRecordsStartetMitVersion1() async throws {
        let fake = FakeAirtableRW()
        fake.existingRecords = []

        let item = WarenkorbItem(bezeichnung: "Spüle", artikelnummer: "SPL-002", menge: 1, quelle: "test")
        let wk = Warenkorb(items: [item], projektName: "Neues Projekt")

        let store = CartStore(fetcher: fake, creator: fake, updater: fake)
        let outcome = try await store.sendWarenkorbToAirtable(wk)

        guard case .success(_, let version) = outcome else {
            Issue.record("Erwartet .success")
            return
        }
        #expect(version == 1)
        #expect(fake.updatedRecords.isEmpty)  // Nichts zu archivieren
    }

    @Test func leererWarenkorbGibtLeerOutcome() async throws {
        let fake = FakeAirtableRW()
        let wk = Warenkorb(items: [])

        let store = CartStore(fetcher: fake, creator: fake, updater: fake)
        let outcome = try await store.sendWarenkorbToAirtable(wk)

        #expect(outcome == .leer)
        #expect(fake.createdRecords.isEmpty)  // Keine Airtable-Anfrage
    }

    @Test func nurAktuellRecordsMitGleicherPruefsummeWerdenArchiviert() async throws {
        let fake = FakeAirtableRW()
        let item = WarenkorbItem(bezeichnung: "Test", artikelnummer: "T-001", menge: 1, quelle: "test")
        let wk = Warenkorb(items: [item], projektName: "P1")
        let pruefsumme = wk.pruefsumme

        // Ein Aktuell + Ein bereits Archiviert + Ein anderer Warenkorb
        fake.existingRecords = [
            [
                "_airtableRecordID": .string("recAKTUELL"),
                CartStore.feldPruefsumme: .string(pruefsumme),
                CartStore.feldStatus: .string(CartStore.statusAktuell),
                CartStore.feldVersion: .number(2.0),
            ],
            [
                "_airtableRecordID": .string("recALTARCHIV"),
                CartStore.feldPruefsumme: .string(pruefsumme),
                CartStore.feldStatus: .string(CartStore.statusArchiviert),
                CartStore.feldVersion: .number(1.0),
            ],
            [
                "_airtableRecordID": .string("recANDERER"),
                CartStore.feldPruefsumme: .string("anderepruefsumme"),
                CartStore.feldStatus: .string(CartStore.statusAktuell),
                CartStore.feldVersion: .number(1.0),
            ],
        ]

        let store = CartStore(fetcher: fake, creator: fake, updater: fake)
        _ = try await store.sendWarenkorbToAirtable(wk)

        // Nur recAKTUELL muss archiviert werden
        #expect(fake.updatedRecords["recAKTUELL"] != nil)
        #expect(fake.updatedRecords["recALTARCHIV"] == nil)  // Schon archiviert → nicht nochmal anfassen
        #expect(fake.updatedRecords["recANDERER"] == nil)    // Andere Prüfsumme

        // Neue Version muss max(2)+1 = 3 sein
        guard case .success(_, let version) = fake.successVersion else { return }
        #expect(version == 3)
    }

    @Test func positioenenJSONIstImCreatedRecord() async throws {
        let fake = FakeAirtableRW()
        let item = WarenkorbItem(bezeichnung: "Armatur", artikelnummer: "ARM-X", menge: 3, ekNetto: 60.0, vkNetto: 90.0, quelle: "test")
        let wk = Warenkorb(items: [item])

        let store = CartStore(fetcher: fake, creator: fake, updater: fake)
        _ = try await store.sendWarenkorbToAirtable(wk)

        let createdFields = fake.createdRecords.first(where: {
            $0.table == CartStore.warenkorbTable
        })?.fields
        let json = createdFields?[CartStore.feldPositionenJSON]?.stringValue ?? ""
        #expect(json.contains("ARM-X"))
        #expect(json.contains("Armatur"))
    }
}

// MARK: - FakeAirtableRW
// Fake-Implementierung für alle drei Protokolle — kein Netzwerk, kein Keychain.
final class FakeAirtableRW: AirtableFetching, AirtableRecordCreating, AirtableRecordUpdating, @unchecked Sendable {
    var existingRecords: [[String: AirtableFieldValue]] = []
    var updatedRecords: [String: [String: AirtableFieldValue]] = [:]  // recordID → fields
    var createdRecords: [(table: String, fields: [String: AirtableFieldValue])] = []
    var successVersion: CartSendOutcome = .leer

    private var nextRecordID = 1

    func fetchRecords(baseID: String, table: String) async throws -> [[String: AirtableFieldValue]] {
        existingRecords
    }

    func createRecord(baseID: String, table: String, fields: [String: AirtableFieldValue]) async throws -> String {
        let id = "recNEW\(nextRecordID)"
        nextRecordID += 1
        createdRecords.append((table: table, fields: fields))
        if table == CartStore.warenkorbTable, let v = fields[CartStore.feldVersion]?.numberValue {
            successVersion = .success(recordID: id, version: Int(v))
        }
        return id
    }

    func updateRecord(baseID: String, table: String, recordID: String, fields: [String: AirtableFieldValue]) async throws {
        updatedRecords[recordID] = fields
    }
}
