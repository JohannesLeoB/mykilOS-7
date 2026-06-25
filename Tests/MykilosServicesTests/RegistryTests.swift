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

    @Test func airtableSyncIstNochNichtScharf() throws {
        // Ehrlichkeit: der Stub täuscht keinen Erfolg vor, er wirft.
        let dir = tempDir(); defer { try? FileManager.default.removeItem(at: dir) }
        let cache = try CachedProjectRegistry(directory: dir)
        let airtable = AirtableRegistry(baseID: "appXXXX")
        #expect(throws: AirtableRegistry.State.self) {
            try airtable.sync(into: cache)
        }
    }
}
