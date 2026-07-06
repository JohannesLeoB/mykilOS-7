import Testing
import Foundation
import MykilosKit
@testable import MykilosServices

// MARK: - Multi-User Store-Isolation
// Beweist für die privaten, per-Bewohner-isolierten Stores: ein zweiter Bewohner
// auf demselben Gerät/DB sieht NIE die Daten des ersten, und die Alt-Zeilen (vor
// der Isolation, userID NULL) landen ausschließlich beim Erst-Bewohner (Backfill).
// Explizite userIDs — kein CurrentUserContext.set (kein Cross-Test-Leck über den
// prozess-globalen Kontext). ChatStore-Isolation liegt in ChatStoreTests.
struct MultiUserStoreIsolationTests {

    // MARK: Notizen (AssistantNotesStore)

    @Test func notizenSindProBewohnerIsoliert() async throws {
        let db = try GRDBDatabase.inMemory()
        let storeA = AssistantNotesStore(db: db, userID: "user-a")
        _ = try await storeA.create("A's private Notiz")

        let storeB = AssistantNotesStore(db: db, userID: "user-b")
        #expect(try await storeB.all().isEmpty)          // B sieht nichts von A

        let storeA2 = AssistantNotesStore(db: db, userID: "user-a")
        #expect(try await storeA2.all().count == 1)       // A findet seine Notiz nach „Neustart"
    }

    @Test func backfillNotizenLandenBeimErstBewohner() async throws {
        let db = try GRDBDatabase.inMemory()
        let legacy = AssistantNotesStore(db: db, userID: nil)   // Alt-Zustand: userID NULL
        _ = try await legacy.create("Bestehende Notiz vor Multi-User")

        try MultiUserBackfill.assignNullRowsToPrimary(db: db, primaryUserID: "primary")

        let primary = AssistantNotesStore(db: db, userID: "primary")
        #expect(try await primary.all().count == 1)        // Primary erbt die Alt-Notiz
        let other = AssistantNotesStore(db: db, userID: "other")
        #expect(try await other.all().isEmpty)             // ein Zweit-Bewohner NICHT
    }

    // MARK: Aufgaben (AssistantTasksStore)

    @Test func aufgabenSindProBewohnerIsoliert() async throws {
        let db = try GRDBDatabase.inMemory()
        let storeA = AssistantTasksStore(db: db, userID: "user-a")
        _ = try await storeA.create("A's private Aufgabe")

        let storeB = AssistantTasksStore(db: db, userID: "user-b")
        #expect(try await storeB.all().isEmpty)

        let storeA2 = AssistantTasksStore(db: db, userID: "user-a")
        #expect(try await storeA2.all().count == 1)
    }

    @Test func backfillAufgabenLandenBeimErstBewohner() async throws {
        let db = try GRDBDatabase.inMemory()
        let legacy = AssistantTasksStore(db: db, userID: nil)
        _ = try await legacy.create("Bestehende Aufgabe vor Multi-User")

        try MultiUserBackfill.assignNullRowsToPrimary(db: db, primaryUserID: "primary")

        let primary = AssistantTasksStore(db: db, userID: "primary")
        #expect(try await primary.all().count == 1)
        let other = AssistantTasksStore(db: db, userID: "other")
        #expect(try await other.all().isEmpty)
    }
}
