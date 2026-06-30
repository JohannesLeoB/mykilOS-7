import Testing
import Foundation
@testable import MykilosServices
@testable import MykilosKit

// MARK: - DataFlowLogger Cold-Start + NO-GO-Tests
// Beweist: (1) Handshake-Einträge überleben den Neustart (GRDB).
//          (2) Der Airtable-Schreibpfad ist hart auf die zwei Schaltzentrum-Tabellen
//              der Mastermind-Base begrenzt — alles andere wirft.
@MainActor
struct DataFlowLoggerTests {

    // MARK: Cold-Start: Handshake überlebt Neustart
    @Test func handshakeUeberlebtNeustart() throws {
        let db = try GRDBDatabase.inMemory()
        let entry = DataFlowEntry(
            id: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
            timestamp: Date(timeIntervalSince1970: 1_806_086_400),
            integrationID: "AIRTABLE_KUNDEN_PROJEKTE",
            actorUserID: "johannes",
            action: .success,
            recordsRead: 61,
            recordsWritten: 0,
            httpStatus: 200,
            errorMessage: nil,
            durationMs: 1245,
            summary: "31 Projekte + 30 Kunden"
        )

        let loggerA = DataFlowLogger(db: db)   // airtable: nil → nur lokal
        try loggerA.load()
        try loggerA.append(entry)

        let loggerB = DataFlowLogger(db: db)
        try loggerB.load()

        #expect(loggerB.entries.count == 1)
        let read = try #require(loggerB.entries.first)
        #expect(read.id == entry.id)
        #expect(read.timestamp == entry.timestamp)
        #expect(read.integrationID == entry.integrationID)
        #expect(read.action == .success)
        #expect(read.recordsRead == 61)
        #expect(read.httpStatus == 200)
        #expect(read.durationMs == 1245)
        #expect(read.summary == entry.summary)
    }

    // MARK: NO-GO: Schreiben nur in die zwei Schaltzentrum-Tabellen
    @Test func createRecordBlocktFremdeTabellen() async {
        let client = AirtableClient(credentialsStore: StubCreds())
        // Verbotene Tabellen in der Mastermind-Base → muss werfen, kein Netzwerk.
        for table in ["Kunden", "Projekte", "Kalkulationen", "Eingehende-Angebote"] {
            await #expect(throws: AirtableError.self) {
                _ = try await client.createRecord(baseID: AirtableClient.writableBaseID, table: table, fields: [:])
            }
        }
    }

    // MARK: NO-GO: Schreiben nur in die Mastermind-Base
    @Test func createRecordBlocktFremdeBase() async {
        let client = AirtableClient(credentialsStore: StubCreds())
        await #expect(throws: AirtableError.self) {
            _ = try await client.createRecord(baseID: "appFREMDxxxxxxxxx", table: "Datenstrom-Log", fields: [:])
        }
    }

    // MARK: Whitelist-Konstanten korrekt
    @Test func whitelistKonstanten() {
        #expect(AirtableClient.writableBaseID == "appuVMh3KDfKw4OoQ")
        // S19: "Kontakte" wurde als schreibbare Tabelle hinzugefügt (Kontakt anlegen/aktualisieren)
        #expect(AirtableClient.writableTables.contains("Datenstrom-Handbuch"))
        #expect(AirtableClient.writableTables.contains("Datenstrom-Log"))
        #expect(AirtableClient.writableTables.contains("Kontakte"))
    }
}

// Stub-Store, der nie geladen wird (die Whitelist wirft vor jedem Keychain-Zugriff).
private struct StubCreds: AirtableCredentialsStoring {
    func load() throws -> AirtableCredentials? { AirtableCredentials(pat: "x", baseID: "appuVMh3KDfKw4OoQ") }
    func store(_ credentials: AirtableCredentials) throws {}
    func clear() throws {}
}
