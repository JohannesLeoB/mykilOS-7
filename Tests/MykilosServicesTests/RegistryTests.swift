import Testing
import Foundation
@testable import MykilosServices
@testable import MykilosKit

// Registry über lokalen Cache: beweist u. a. die Nachtrag→Eltern-Beziehung
// und dass alles den Neustart übersteht.
struct RegistryTests {

    private func tempDir() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("myk6-reg-\(UUID().uuidString)", isDirectory: true)
    }

    @Test func projekteUndKundenUeberlebenNeustart() throws {
        let dir = tempDir(); defer { try? FileManager.default.removeItem(at: dir) }

        let writer = try CachedProjectRegistry(directory: dir)
        try writer.replaceCustomers([Customer(customerNumber: "K-1001", name: "Familie Meyer")])
        try writer.replaceProjects([
            Project(projectNumber: "ME-24", title: "Küche Meyer", kind: .kitchen, customerNumber: "K-1001")
        ])

        // "Neustart": neue Instanz, selber Ort
        let reader = try CachedProjectRegistry(directory: dir)
        #expect(try reader.allCustomers().count == 1)
        #expect(try reader.allProjects().first?.projectNumber == "ME-24")
    }

    @Test func nachtragVerweistAufElternProjekt() throws {
        let dir = tempDir(); defer { try? FileManager.default.removeItem(at: dir) }

        let reg = try CachedProjectRegistry(directory: dir)
        try reg.replaceProjects([
            Project(projectNumber: "ME-24", title: "Küche Meyer", kind: .kitchen, customerNumber: "K-1001"),
            Project(projectNumber: "ME-24-N1", title: "Nachtrag Beleuchtung", kind: .addendum,
                    customerNumber: "K-1001", parentProjectNumber: "ME-24")
        ])

        let nachtraege = try reg.addenda(ofParent: "ME-24")
        #expect(nachtraege.count == 1)
        #expect(nachtraege.first?.isAddendum == true)
    }

    @Test func airtableSyncSchreibtInCache() async throws {
        let dir = tempDir(); defer { try? FileManager.default.removeItem(at: dir) }
        let cache = try CachedProjectRegistry(directory: dir)
        let fake = FakeAirtableFetcher(tables: [
            "Kunden": [
                ["Kundennummer": .string("K-1001"), "Name": .string("Meyer"), "_airtableRecordID": .string("rec1")],
            ],
            "Projekte": [
                ["Projektnummer": .string("ME-24"), "Titel": .string("Küche Meyer"), "Art": .string("kitchen"),
                 "Kundennummer": .string("K-1001"), "_airtableRecordID": .string("recP1")],
            ],
        ])
        let airtable = AirtableRegistry(client: fake)
        try await airtable.sync(baseID: "appXYZ", into: cache)

        let customers = try cache.allCustomers()
        let projects = try cache.allProjects()
        #expect(customers.count == 1)
        #expect(customers[0].name == "Meyer")
        #expect(projects.count == 1)
        #expect(projects[0].projectNumber == "ME-24")
    }
}

// MARK: - FakeAirtableFetcher

private struct FakeAirtableFetcher: AirtableFetching {
    let tables: [String: [[String: AirtableFieldValue]]]

    func fetchRecords(baseID: String, table: String) async throws -> [[String: AirtableFieldValue]] {
        tables[table] ?? []
    }
}
