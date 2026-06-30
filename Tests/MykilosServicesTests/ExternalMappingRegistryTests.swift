import Testing
import Foundation
@testable import MykilosServices
@testable import MykilosKit

// Block A: beweist die SoR-Trennung. Routing (Mastermind) und Geschäft (Artikel)
// landen NIE im selben Cache; der Resolver joint NUR über die Projektnummer.
struct ExternalMappingRegistryTests {

    private func tempDir() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("myk6-extmap-\(UUID().uuidString)", isDirectory: true)
    }

    @Test func businessSyncSchreibtNurInBusinessCacheNiemalsInRouting() async throws {
        let dir = tempDir(); defer { try? FileManager.default.removeItem(at: dir) }
        let routingCache = try CachedProjectRegistry(directory: dir)
        let businessCache = try CachedBusinessRegistry(directory: dir)
        try routingCache.replaceProjects([
            Project(projectNumber: "2026-015", title: "Küche Schmidt", kind: .kitchen, customerNumber: "K-1")
        ])

        let fake = FakeAirtableFetcher(tables: [
            "Kunden": [
                ["_airtableRecordID": .string("recK1"), "Nachname": .string("Schmidt"), "Firma": .string("")],
            ],
            "Projekte": [
                ["_airtableRecordID": .string("recP1"), "Projektname": .string("Küche Schmidt"),
                 "Projektstatus": .string("Angebot"), "Budget": .number(42000),
                 "Kunde": .array(["recK1"])],
            ],
        ])
        let registry = ExternalMappingRegistry(routing: routingCache, business: businessCache)
        try await registry.syncBusiness(client: fake, baseID: "appXYZ")

        // Routing-Cache unberührt — eine Wahrheit pro Datum, kein Cross-Write.
        #expect(try routingCache.allProjects().count == 1)
        #expect(try routingCache.allProjects().first?.projectNumber == "2026-015")
        // Business-Cache hat den neuen Geschäfts-Record.
        #expect(try businessCache.allProjects().count == 1)
        #expect(try businessCache.allProjects().first?.projektname == "Küche Schmidt")
    }

    @Test func resolveOhneProjektnummerFeldErgibtBusinessOnlyUnbound() async throws {
        let dir = tempDir(); defer { try? FileManager.default.removeItem(at: dir) }
        let routingCache = try CachedProjectRegistry(directory: dir)
        let businessCache = try CachedBusinessRegistry(directory: dir)
        try routingCache.replaceProjects([
            Project(projectNumber: "2026-015", title: "Küche Schmidt", kind: .kitchen, customerNumber: "K-1")
        ])
        // Heutiger Echtzustand: Artikel-`Projekte` hat KEIN Projektnummer-Feld.
        try businessCache.replaceProjects([
            BusinessProject(airtableRecordID: "recP1", projektname: "Küche Schmidt", projectNumber: nil)
        ])

        let registry = ExternalMappingRegistry(routing: routingCache, business: businessCache)
        let resolved = try registry.resolve(projectNumber: "2026-015")

        #expect(resolved.bindingState == .routingOnly)
        #expect(resolved.routing?.projectNumber == "2026-015")
        #expect(resolved.business == nil)
        #expect(try registry.unboundBusinessProjects().count == 1)
    }

    @Test func resolveMitProjektnummerVerbindetBeideSeiten() throws {
        let dir = tempDir(); defer { try? FileManager.default.removeItem(at: dir) }
        let routingCache = try CachedProjectRegistry(directory: dir)
        let businessCache = try CachedBusinessRegistry(directory: dir)
        try routingCache.replaceProjects([
            Project(projectNumber: "2026-015", title: "Küche Schmidt", kind: .kitchen, customerNumber: "K-1")
        ])
        try businessCache.replaceCustomers([
            BusinessCustomer(airtableRecordID: "recK1", nachname: "Schmidt")
        ])
        try businessCache.replaceProjects([
            BusinessProject(airtableRecordID: "recP1", projektname: "Küche Schmidt",
                             budget: 42000, kundeRecordIDs: ["recK1"], projectNumber: "2026-015")
        ])

        let registry = ExternalMappingRegistry(routing: routingCache, business: businessCache)
        let resolved = try registry.resolve(projectNumber: "2026-015")

        #expect(resolved.bindingState == .linked)
        #expect(resolved.business?.budget == 42000)
        #expect(resolved.customer?.nachname == "Schmidt")
        #expect(try registry.unboundBusinessProjects().isEmpty)
    }

    @Test func mapBusinessProjectsIstTolerantBeiFehlendemFeld() {
        // Fallstrick aus ROLLING_PLAN §3b: ein fehlendes Feld darf den Record
        // nicht lautlos verwerfen — nur Projektname ist Pflicht.
        let records: [[String: AirtableFieldValue]] = [
            ["_airtableRecordID": .string("rec1"), "Projektname": .string("Nur Name")],
            ["_airtableRecordID": .string("rec2")],  // kein Projektname → korrekt verworfen
        ]
        let projects = AirtableClient.mapBusinessProjects(from: records)
        #expect(projects.count == 1)
        #expect(projects.first?.projektname == "Nur Name")
        #expect(projects.first?.projectNumber == nil)
    }
}

// MARK: - FakeAirtableFetcher
private struct FakeAirtableFetcher: AirtableFetching {
    let tables: [String: [[String: AirtableFieldValue]]]
    func fetchRecords(baseID: String, table: String) async throws -> [[String: AirtableFieldValue]] {
        tables[table] ?? []
    }
}
