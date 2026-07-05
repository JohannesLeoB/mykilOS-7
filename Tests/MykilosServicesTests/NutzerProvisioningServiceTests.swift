import Testing
import Foundation
@testable import MykilosServices
@testable import MykilosKit

// Bewohner-Oberfläche: idempotente Nutzer-Anlage (find-or-create) in Airtable
// Clockodo-Nutzer (appuVMh3KDfKw4OoQ/tblPbly2br8mR2kaU). Alles mit Fakes —
// KEIN echtes Netzwerk, KEIN echtes Keychain.
@MainActor
struct NutzerProvisioningServiceTests {

    private func makeService(
        fetch: FakeFetch = FakeFetch(),
        create: FakeCreate = FakeCreate()
    ) -> (NutzerProvisioningService, FakeCreate) {
        let svc = NutzerProvisioningService(
            airtableFetch: fetch, airtableCreate: create,
            // Fakes kennen keine echte Base/Tabelle — die Freigabeliste hier bewusst umgangen.
            isWritable: { _, _ in true })
        return (svc, create)
    }

    @Test func keinMatchLegtGenauEinenRecordAn() async throws {
        let (svc, create) = makeService()
        let id = try await svc.findOrCreate(googleEmail: "johannes@mykilos.com", displayName: "Johannes")

        #expect(create.aufrufe == 1)
        #expect(id == "rec_1")
        #expect(create.letzteFelder?["Name"]?.stringValue == "Johannes")
        #expect(create.letzteFelder?["E-Mail"]?.stringValue == "johannes@mykilos.com")
        #expect(create.letzteFelder?["Aktiv"]?.stringValue == "true")
        #expect(create.letzteBaseID == NutzerProvisioningService.baseID)
        #expect(create.letzteTabelle == NutzerProvisioningService.tabelle)
    }

    @Test func bestehenderMatchLegtNichtsNeuesAn() async throws {
        let fetch = FakeFetch()
        fetch.records = [[
            "_airtableRecordID": .string("rec_existing"),
            "Name": .string("Daniel"),
            "E-Mail": .string("daniel@mykilos.com")
        ]]
        let (svc, create) = makeService(fetch: fetch)

        let id = try await svc.findOrCreate(googleEmail: "daniel@mykilos.com", displayName: "Daniel")

        #expect(id == "rec_existing")
        #expect(create.aufrufe == 0)
    }

    @Test func matchIstCaseInsensitivUndGetrimmt() async throws {
        let fetch = FakeFetch()
        fetch.records = [[
            "_airtableRecordID": .string("rec_existing"),
            "Name": .string("Frauke"),
            "E-Mail": .string("Frauke@mykilos.com")
        ]]
        let (svc, create) = makeService(fetch: fetch)

        let id = try await svc.findOrCreate(googleEmail: "  frauke@MYKILOS.com  ", displayName: "Frauke")

        #expect(id == "rec_existing")
        #expect(create.aufrufe == 0)
    }

    @Test func zweiterAufrufNachCreateIstIdempotent() async throws {
        let fetch = FakeFetch()
        let (svc, create) = makeService(fetch: fetch)

        let id1 = try await svc.findOrCreate(googleEmail: "sebastian@mykilos.com", displayName: "Sebastian")
        #expect(create.aufrufe == 1)

        // Simuliert: der neu angelegte Record ist jetzt in Airtable sichtbar (nächster fetch findet ihn).
        fetch.records = [[
            "_airtableRecordID": .string(id1),
            "Name": .string("Sebastian"),
            "E-Mail": .string("sebastian@mykilos.com")
        ]]

        let id2 = try await svc.findOrCreate(googleEmail: "sebastian@mykilos.com", displayName: "Sebastian")
        #expect(id2 == id1)
        #expect(create.aufrufe == 1)   // KEIN zweiter Create
    }

    @Test func nichtSchreibbareTabelleWirftVorAllemAnderen() async throws {
        let (fetch, create) = (FakeFetch(), FakeCreate())
        let svc = NutzerProvisioningService(
            airtableFetch: fetch, airtableCreate: create,
            isWritable: { _, _ in false })

        await #expect(throws: ProvisioningError.self) {
            _ = try await svc.findOrCreate(googleEmail: "johannes@mykilos.com", displayName: "Johannes")
        }
        #expect(fetch.aufrufe == 0)   // gar nicht erst versucht
        #expect(create.aufrufe == 0)
    }

    @Test func createFehlerWirftUndSetztSaveStateFailed() async throws {
        let create = FakeCreate(); create.wirft = true
        let (svc, _) = makeService(create: create)

        await #expect(throws: (any Error).self) {
            _ = try await svc.findOrCreate(googleEmail: "neu@mykilos.com", displayName: "Neu")
        }
        if case .failed = svc.saveState {
            // erwarteter Zustand
        } else {
            Issue.record("saveState sollte .failed sein, ist aber \(svc.saveState)")
        }
    }
}

// MARK: - Fakes

private final class FakeFetch: AirtableFetching, @unchecked Sendable {
    var records: [[String: AirtableFieldValue]] = []
    private(set) var aufrufe = 0
    func fetchRecords(baseID: String, table: String) async throws -> [[String: AirtableFieldValue]] {
        aufrufe += 1
        return records
    }
}

private final class FakeCreate: AirtableRecordCreating, @unchecked Sendable {
    var wirft = false
    private(set) var aufrufe = 0
    private(set) var letzteFelder: [String: AirtableFieldValue]?
    private(set) var letzteBaseID: String?
    private(set) var letzteTabelle: String?
    func createRecord(baseID: String, table: String, fields: [String: AirtableFieldValue]) async throws -> String {
        if wirft { throw AirtableError.httpError(422) }
        aufrufe += 1
        letzteFelder = fields
        letzteBaseID = baseID
        letzteTabelle = table
        return "rec_\(aufrufe)"
    }
}
