import Testing
import Foundation
@testable import MykilosServices
@testable import MykilosKit

// MARK: - ChatMemoryStore Cold-Start-Test (Stufe 2, Härtung 2026-07-01)
// Beweist: die destillierte Zusammenfassung überlebt einen Neustart (schreiben →
// neue Instanz → lesen → identisch) — Pflicht-Test für jedes persistierbare Feld.
@MainActor
struct ChatMemoryStoreTests {
    @Test func summaryUeberlebtNeustart() throws {
        let db = try GRDBDatabase.inMemory()
        let scope = ChatScope.project("2026-042")
        let summary = ChatMemorySummary(
            scopeKey: scope.rawKey,
            summaryText: "Kunde will Eichenfronten, Liefertermin KW34, Budget 24.000€.",
            coveredThroughMessageID: "11111111-1111-1111-1111-111111111111",
            updatedAt: Date(timeIntervalSince1970: 1_800_000_000)
        )

        let storeA = ChatMemoryStore(db: db)
        try storeA.save(summary)

        // „App neu gestartet": neue Instanz, selbe DB.
        let storeB = ChatMemoryStore(db: db)
        let loaded = try storeB.summary(for: scope)
        #expect(loaded == summary)
    }

    @Test func fehlendeZusammenfassungIstNil() throws {
        let db = try GRDBDatabase.inMemory()
        let store = ChatMemoryStore(db: db)
        #expect(try store.summary(for: .home) == nil)
    }
}
