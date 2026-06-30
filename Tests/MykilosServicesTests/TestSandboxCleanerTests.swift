import Testing
import Foundation
@testable import MykilosServices

// Block A: TestSandboxCleaner darf NIE Produktivdaten treffen. Diese Suite beweist
// die drei Sicherungen: Whitelist, Doppel-Marker, Re-Fetch-Verifikation — plus Idempotenz.
struct TestSandboxCleanerTests {

    @Test func findetNurDoppeltMarkierteRecords() async throws {
        let fetcher = FakeFetcher(tables: [
            "Projekte": [
                ["_airtableRecordID": .string("rec1"), "Projektname": .string("TEST_Dummyküche"), "Quelle": .string("TEST")],
                ["_airtableRecordID": .string("rec2"), "Projektname": .string("Echte Küche Schmidt"), "Quelle": .string("Intake")],
                ["_airtableRecordID": .string("rec3"), "Projektname": .string("TEST_OhneQuelle")],  // nur ein Marker
            ],
        ])
        let cleaner = TestSandboxCleaner(fetcher: fetcher, deleter: FakeDeleter())
        let found = try await cleaner.findTestArtifacts(baseID: "appXYZ", table: "Projekte", nameField: "Projektname")

        #expect(found.count == 1)
        #expect(found.first?.recordID == "rec1")
    }

    @Test func cleanupBlocktOhneWhitelistEintrag() async throws {
        let fetcher = FakeFetcher(tables: [
            "Projekte": [["_airtableRecordID": .string("rec1"), "Projektname": .string("TEST_X"), "Quelle": .string("TEST")]],
        ])
        let deleter = FakeDeleter()
        // Leere deletableMap (== Produktiv-Default) → nichts darf gelöscht werden.
        let cleaner = TestSandboxCleaner(fetcher: fetcher, deleter: deleter, deletableMap: [:])
        let candidates = try await cleaner.findTestArtifacts(baseID: "appXYZ", table: "Projekte", nameField: "Projektname")
        let report = try await cleaner.cleanup(candidates, nameField: "Projektname")

        #expect(report.deleted.isEmpty)
        #expect(report.skipped.count == 1)
        #expect(deleter.deletedIDs.isEmpty)
    }

    @Test func cleanupLoeschtNurWennWhitelistUndMarkerStimmen() async throws {
        let fetcher = FakeFetcher(tables: [
            "Projekte": [["_airtableRecordID": .string("rec1"), "Projektname": .string("TEST_X"), "Quelle": .string("TEST")]],
        ])
        let deleter = FakeDeleter()
        let cleaner = TestSandboxCleaner(
            fetcher: fetcher, deleter: deleter,
            deletableMap: ["appXYZ": ["Projekte"]]
        )
        let candidates = try await cleaner.findTestArtifacts(baseID: "appXYZ", table: "Projekte", nameField: "Projektname")
        let report = try await cleaner.cleanup(candidates, nameField: "Projektname")

        #expect(report.deleted.count == 1)
        #expect(deleter.deletedIDs == ["rec1"])
    }

    @Test func produktivFixtureBleibtBeiCleanupUnberuehrt() async throws {
        let fetcher = FakeFetcher(tables: [
            "Projekte": [
                ["_airtableRecordID": .string("rec1"), "Projektname": .string("TEST_X"), "Quelle": .string("TEST")],
                ["_airtableRecordID": .string("rec2"), "Projektname": .string("Küche Meyer"), "Quelle": .string("Intake")],
            ],
        ])
        let deleter = FakeDeleter()
        let cleaner = TestSandboxCleaner(fetcher: fetcher, deleter: deleter, deletableMap: ["appXYZ": ["Projekte"]])
        let candidates = try await cleaner.findTestArtifacts(baseID: "appXYZ", table: "Projekte", nameField: "Projektname")
        _ = try await cleaner.cleanup(candidates, nameField: "Projektname")

        #expect(deleter.deletedIDs == ["rec1"])
        #expect(deleter.deletedIDs.contains("rec2") == false)
    }

    @Test func reFetchVerhindertLoeschenWennMarkerZwischenzeitlichWeg() async throws {
        // Re-Fetch liefert einen Record OHNE TEST-Marker mehr — z. B. weil er
        // zwischen Find und Cleanup produktiv umbenannt wurde.
        let fetcher = MutatingFakeFetcher()
        let deleter = FakeDeleter()
        let cleaner = TestSandboxCleaner(fetcher: fetcher, deleter: deleter, deletableMap: ["appXYZ": ["Projekte"]])
        let candidates = try await cleaner.findTestArtifacts(baseID: "appXYZ", table: "Projekte", nameField: "Projektname")
        #expect(candidates.count == 1)

        fetcher.simulateProduktivUmbenennung()
        let report = try await cleaner.cleanup(candidates, nameField: "Projektname")

        #expect(report.deleted.isEmpty)
        #expect(deleter.deletedIDs.isEmpty)
        #expect(report.skipped.first?.reason.contains("Re-Fetch") == true)
    }

    @Test func cleanupIstIdempotent() async throws {
        let fetcher = FakeFetcher(tables: [
            "Projekte": [["_airtableRecordID": .string("rec1"), "Projektname": .string("TEST_X"), "Quelle": .string("TEST")]],
        ])
        let deleter = FakeDeleter()
        let cleaner = TestSandboxCleaner(fetcher: fetcher, deleter: deleter, deletableMap: ["appXYZ": ["Projekte"]])
        let candidates = try await cleaner.findTestArtifacts(baseID: "appXYZ", table: "Projekte", nameField: "Projektname")
        let first = try await cleaner.cleanup(candidates, nameField: "Projektname")
        deleter.removeFromTable(table: fetcher, recordID: "rec1")

        let second = try await cleaner.cleanup(candidates, nameField: "Projektname")

        #expect(first.deleted.count == 1)
        #expect(second.deleted.isEmpty)
        #expect(second.skipped.first?.reason == "Record nicht mehr vorhanden")
    }
}

// MARK: - Fakes

private final class FakeFetcher: AirtableFetching, @unchecked Sendable {
    var tables: [String: [[String: AirtableFieldValue]]]
    init(tables: [String: [[String: AirtableFieldValue]]]) { self.tables = tables }
    func fetchRecords(baseID: String, table: String) async throws -> [[String: AirtableFieldValue]] {
        tables[table] ?? []
    }
}

private final class FakeDeleter: AirtableRecordDeleting, @unchecked Sendable {
    private(set) var deletedIDs: [String] = []
    func deleteRecord(baseID: String, table: String, recordID: String) async throws {
        deletedIDs.append(recordID)
    }
    /// Test-Helfer: simuliert, dass ein Record nach dem Löschen nicht mehr im
    /// (gemeinsam genutzten) Fake-Fetcher-Bestand auftaucht.
    func removeFromTable(table: FakeFetcher, recordID: String) {
        for key in table.tables.keys {
            table.tables[key]?.removeAll { $0["_airtableRecordID"]?.stringValue == recordID }
        }
    }
}

private final class MutatingFakeFetcher: AirtableFetching, @unchecked Sendable {
    private var records: [[String: AirtableFieldValue]] = [
        ["_airtableRecordID": .string("rec1"), "Projektname": .string("TEST_X"), "Quelle": .string("TEST")],
    ]
    func fetchRecords(baseID: String, table: String) async throws -> [[String: AirtableFieldValue]] { records }
    func simulateProduktivUmbenennung() {
        records = [["_airtableRecordID": .string("rec1"), "Projektname": .string("Küche Schmidt (umbenannt)"), "Quelle": .string("Intake")]]
    }
}
