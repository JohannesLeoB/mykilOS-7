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

    // MARK: - ensureUserID (V10 Folge-Block A, Vorab)

    @Test func ensureUserIDErzeugtUUIDBeiLeererDatenbank() throws {
        let db = try GRDBDatabase.inMemory()
        let userID = ProfileStore.ensureUserID(db: db)
        #expect(userID.isEmpty == false)
        #expect(UUID(uuidString: userID) != nil)
    }

    @Test func ensureUserIDIstStabilUeberNeustart() throws {
        let db = try GRDBDatabase.inMemory()
        let first = ProfileStore.ensureUserID(db: db)
        let second = ProfileStore.ensureUserID(db: db)
        #expect(first == second)
    }

    @Test func ensureUserIDBehaeltBestehendesProfilUnangetastet() throws {
        let db = try GRDBDatabase.inMemory()
        let store = ProfileStore(db: db)
        try store.save(UserProfile(displayName: "Johannes", role: "Design",
                                    updatedAt: Date(timeIntervalSince1970: 1_800_000_000)))

        let userID = ProfileStore.ensureUserID(db: db)
        #expect(userID.isEmpty == false)

        // displayName/role bleiben unverändert — ensureUserID darf sie nie überschreiben.
        let reloaded = ProfileStore(db: db)
        try reloaded.load()
        #expect(reloaded.profile?.displayName == "Johannes")
        #expect(reloaded.profile?.role == "Design")
        #expect(reloaded.profile?.userID == userID)
    }

    @Test func ensureUserIDMigriertAlteRowOhneUserIDAdditivUndStabil() throws {
        // Simuliert ein Bestandsprofil VOR v22_user_identity: gespeichert ohne
        // userID (Codable-Gedächtnisverlust-Lehre — additive Spalte, alte
        // Zeile hat NULL). ensureUserID muss sie einmalig nachziehen, ohne
        // andere Felder zu verlieren, und danach stabil bleiben.
        let db = try GRDBDatabase.inMemory()
        let store = ProfileStore(db: db)
        try store.save(UserProfile(displayName: "Alt-Profil", role: "Bestand",
                                    updatedAt: Date(timeIntervalSince1970: 1_600_000_000),
                                    clockodoUserID: "42", googleDomain: "mykilos.de"))
        // Zur Sicherheit: frisch gespeichertes Profil hat hier noch keine userID.
        let beforeReload = ProfileStore(db: db)
        try beforeReload.load()
        #expect(beforeReload.profile?.userID == nil)

        let firstID = ProfileStore.ensureUserID(db: db)
        let secondID = ProfileStore.ensureUserID(db: db)
        #expect(firstID == secondID)

        let reloaded = ProfileStore(db: db)
        try reloaded.load()
        #expect(reloaded.profile?.displayName == "Alt-Profil")
        #expect(reloaded.profile?.clockodoUserID == "42")
        #expect(reloaded.profile?.googleDomain == "mykilos.de")
        #expect(reloaded.profile?.userID == firstID)
    }

    // Regressionsschutz: Onboarding-/Settings-Save MUSS die bestehende userID
    // mitführen (siehe OnboardingWizardView.saveProfileAndAdvance /
    // SettingsView.saveProfile) — ein UserProfile(...)-Konstruktor ohne
    // userID: würde sie sonst stillschweigend auf nil zurücksetzen.
    @Test func speichernOhneExpliziteUserIDLoeschtSieNichtWennBewusstMitgefuehrt() throws {
        let db = try GRDBDatabase.inMemory()
        let userID = ProfileStore.ensureUserID(db: db)

        let store = ProfileStore(db: db)
        try store.load()
        let existingUserID = store.profile?.userID
        #expect(existingUserID == userID)

        // Simuliert den korrekten View-Aufruf: userID explizit aus dem
        // geladenen Profil mitgeführt.
        try store.save(UserProfile(displayName: "Neuer Name", role: "Neue Rolle",
                                    userID: existingUserID))

        let reloaded = ProfileStore(db: db)
        try reloaded.load()
        #expect(reloaded.profile?.userID == userID)
    }
}
