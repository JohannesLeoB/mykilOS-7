import Testing
import Foundation
@testable import MykilosServices
@testable import MykilosKit

@MainActor
struct ResidentIdentityStoreTests {

    // COLD-START (Pflicht): schreiben → neue Store-Instanz auf DERSELBEN DB → lesen → identisch.
    // WICHTIG: Timestamp auf GANZSEKUNDEN festnageln (Date(timeIntervalSince1970: 1_800_000_000)).
    // Grund: ResidentIdentityRecord spiegelt updatedAt als timeIntervalSince1970 (Double) — dieser
    // Bezugspunkt verliert Sub-Sekunden-Präzision über die Unix-Epoche (Akt-2-Lehre). Nur ein
    // runder Ganzsekunden-Wert ist bitgenau roundtrip-sicher; sonst flakt der ==-Vergleich.
    @Test func residentIdentityUeberlebtNeustart() throws {
        let db = try GRDBDatabase.inMemory()
        let identity = ResidentIdentity(
            googleEmail: "johannes@mykilos.com",
            userID: "UUID-STABIL-001",
            displayName: "Johannes",
            clockodoUserID: "9001",
            clockodoEntwurfsTabelle: "tbl4vZ2UFyeTRD8hd",
            clickUpMemberID: nil,
            airtableRecordID: "recABC",
            updatedAt: Date(timeIntervalSince1970: 1_800_000_000))

        let storeA = ResidentIdentityStore(db: db)
        try storeA.save(identity)

        // „App neu gestartet": neue Instanz, selbe DB.
        let storeB = ResidentIdentityStore(db: db)
        try storeB.loadByEmail("johannes@mykilos.com")
        #expect(storeB.identity == identity)   // bitgenau
    }

    @Test func leereDatenbankLiefertNil() throws {
        let db = try GRDBDatabase.inMemory()
        let store = ResidentIdentityStore(db: db)
        try store.loadByEmail("johannes@mykilos.com")
        #expect(store.identity == nil)
    }

    // Nicht-Leer-Invariante: ein leerer/nur-Whitespace kanonischer Schlüssel darf
    // NIE geschrieben werden (geteilter Anker-Kollaps).
    @Test func leererSchluesselWirdNieGeschrieben() throws {
        let db = try GRDBDatabase.inMemory()
        let store = ResidentIdentityStore(db: db)
        let leer = ResidentIdentity(googleEmail: "   ", userID: "UUID-X")
        #expect(throws: ResidentIdentityError.emptyEmailKey) {
            try store.save(leer)
        }
        if case .failed = store.saveState {} else {
            Issue.record("SaveState sollte .failed sein: \(store.saveState)")
        }
    }

    @Test func saveSetztSaveStateSaved() throws {
        let db = try GRDBDatabase.inMemory()
        let store = ResidentIdentityStore(db: db)
        try store.save(ResidentIdentity(googleEmail: "a@mykilos.com", userID: "u1",
                                        updatedAt: Date(timeIntervalSince1970: 1_700_000_000)))
        if case .saved = store.saveState {} else {
            Issue.record("SaveState sollte .saved sein: \(store.saveState)")
        }
    }

    // MARK: - static userID(forEmail:db:)

    @Test func userIDForEmailTrefferUndKeinTreffer() throws {
        let db = try GRDBDatabase.inMemory()
        let store = ResidentIdentityStore(db: db)
        try store.save(ResidentIdentity(googleEmail: "jill@mykilos.com", userID: "UUID-JILL",
                                        updatedAt: Date(timeIntervalSince1970: 1_800_000_000)))

        #expect(ResidentIdentityStore.userID(forEmail: "jill@mykilos.com", db: db) == "UUID-JILL")
        // Kein Treffer → nil.
        #expect(ResidentIdentityStore.userID(forEmail: "unbekannt@mykilos.com", db: db) == nil)
    }

    // Leere Mail wird NIE zum Schlüssel — weder beim Lookup noch (siehe oben) beim Schreiben.
    @Test func leereMailWirdNieSchluessel() throws {
        let db = try GRDBDatabase.inMemory()
        #expect(ResidentIdentityStore.userID(forEmail: "", db: db) == nil)
        #expect(ResidentIdentityStore.userID(forEmail: "   ", db: db) == nil)
    }
}
