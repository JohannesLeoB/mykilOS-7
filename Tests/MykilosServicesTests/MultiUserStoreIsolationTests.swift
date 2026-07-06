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

// MARK: - Multi-User TimerStore-Isolation (Clockodo-Zeiten sind datensensitiv)
// TimerStore ist @MainActor → eigene @MainActor-Suite. Beweist: gebuchte Zeiten
// UND der laufende Timer sind pro Bewohner getrennt; ein Bewohner überschreibt/
// löscht die Zeiten eines anderen NIE (die deleteAll→gefilterten Deletes).
@MainActor
struct MultiUserTimerIsolationTests {
    private func fixedClock() -> @MainActor () -> Date { { Date(timeIntervalSince1970: 1_800_000_000) } }

    @Test func gebuchteZeitenSindProBewohnerIsoliert() throws {
        let db = try GRDBDatabase.inMemory()
        var t = Date(timeIntervalSince1970: 1_800_000_000)
        let clock: @MainActor () -> Date = { t }

        let storeA = TimerStore(db: db, userID: "user-a", now: clock)
        try storeA.load()
        try storeA.start(projektNummer: "2026-015", projektTitel: "Vinahl", kostenstelle: "Beratung")
        t = t.addingTimeInterval(3600)
        try storeA.requestStop()
        try storeA.confirmBooking()
        #expect(storeA.bookedSegments.count == 1)

        // B sieht KEINE Zeiten von A.
        let storeB = TimerStore(db: db, userID: "user-b", now: clock)
        try storeB.load()
        #expect(storeB.bookedSegments.isEmpty)

        // A findet seine gebuchte Zeit nach „Neustart" wieder.
        let storeA2 = TimerStore(db: db, userID: "user-a", now: clock)
        try storeA2.load()
        #expect(storeA2.bookedSegments.count == 1)
    }

    @Test func laufenderTimerIstProBewohnerGetrennt() throws {
        let db = try GRDBDatabase.inMemory()
        let clock: @MainActor () -> Date = { Date(timeIntervalSince1970: 1_800_000_000) }

        let storeA = TimerStore(db: db, userID: "user-a", now: clock)
        try storeA.load()
        try storeA.start(projektNummer: "2026-015", projektTitel: "Vinahl", kostenstelle: "Beratung")
        #expect(storeA.active?.projektNummer == "2026-015")

        // B sieht A's laufenden Timer nicht und startet seinen eigenen.
        let storeB = TimerStore(db: db, userID: "user-b", now: clock)
        try storeB.load()
        #expect(storeB.active == nil)
        try storeB.start(projektNummer: "2026-099", projektTitel: "Kollege", kostenstelle: "CAD")

        // A's Timer wurde NICHT überschrieben (eigene Zeile).
        let storeA2 = TimerStore(db: db, userID: "user-a", now: clock)
        try storeA2.load()
        #expect(storeA2.active?.projektNummer == "2026-015")
    }

    @Test func backfillOrdnetAltenSingletonTimerDemErstBewohnerZu() throws {
        let db = try GRDBDatabase.inMemory()
        // Alt-Zustand vor v27: activeTimer-Zeile mit fester id "singleton".
        try db.write { conn in
            try conn.execute(sql: """
                INSERT INTO activeTimer (id, projektNummer, projektTitel, kostenstelle, runSince, pausedAccumulatedSeconds, isPaused, segmentStartedAt)
                VALUES ('singleton', '2026-015', 'Vinahl', 'Beratung', 0, 0, 0, 0)
                """)
        }
        try MultiUserBackfill.assignNullRowsToPrimary(db: db, primaryUserID: "primary")

        let clock: @MainActor () -> Date = { Date(timeIntervalSince1970: 0) }
        let primary = TimerStore(db: db, userID: "primary", now: clock)
        try primary.load()
        #expect(primary.active?.projektNummer == "2026-015")   // Primary erbt den Alt-Timer

        let other = TimerStore(db: db, userID: "other", now: clock)
        try other.load()
        #expect(other.active == nil)                            // Zweit-Bewohner nicht
    }
}
