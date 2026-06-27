import Testing
import Foundation
@testable import MykilosServices
@testable import MykilosKit

@MainActor
struct ProfileStoreTests {

    @Test func profilUeberlebtNeustart() throws {
        let db = try GRDBDatabase.inMemory()
        let profile = UserProfile(displayName: "Johannes", role: "Design & Projektleitung",
                                  updatedAt: Date(timeIntervalSince1970: 1_800_000_000))

        let storeA = ProfileStore(db: db)
        try storeA.save(profile)

        // „App neu gestartet": neue Instanz, selbe DB
        let storeB = ProfileStore(db: db)
        try storeB.load()
        #expect(storeB.profile == profile)   // displayName/role/updatedAt bitgenau
        #expect(storeB.isEmpty == false)
    }

    @Test func leereDatenbankLiefertNil() throws {
        let db = try GRDBDatabase.inMemory()
        let store = ProfileStore(db: db)
        try store.load()
        #expect(store.profile == nil)
        #expect(store.isEmpty == true)
    }

    @Test func saveSetztSaveStateUndUeberschreibt() throws {
        let db = try GRDBDatabase.inMemory()
        let store = ProfileStore(db: db)
        try store.save(UserProfile(displayName: "A", role: "x", updatedAt: Date(timeIntervalSince1970: 1_700_000_000)))
        if case .saved = store.saveState {} else { Issue.record("SaveState sollte .saved sein: \(store.saveState)") }

        // Upsert: zweites Save überschreibt dieselbe Single-Row.
        try store.save(UserProfile(displayName: "B", role: "y", updatedAt: Date(timeIntervalSince1970: 1_700_000_500)))
        let storeB = ProfileStore(db: db)
        try storeB.load()
        #expect(storeB.profile?.displayName == "B")
    }
}
