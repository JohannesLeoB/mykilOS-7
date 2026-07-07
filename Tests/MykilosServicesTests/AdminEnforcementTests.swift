import Testing
import Foundation
@testable import MykilosServices
@testable import MykilosKit

// MARK: - AdminEnforcementTests (Admin-Ebene S3+S4)
//
// AdminAuthorityTests.swift beweist die reine Berechtigungslogik (istAdmin/assertAdmin).
// Diese Suite beweist, dass die Gates tatsächlich an den echten Aufrufpfaden SITZEN:
// ein Nicht-Admin wirft `.nurAdmin` UND die DB bleibt unverändert (kein Teilschreiben vor
// dem Wurf). Die Positiv-Gegenprobe „Nicht-Admin legt Projekt DURCH an" lebt bereits in
// ProvisioningServiceTests.erfolgErzeugtBaumRecordUndEinenAuditEintrag (actorUserID "test",
// kein Admin, Ledger wird trotzdem geschrieben) — Provisioning ist bewusst NICHT admin-gated
// (Johannes 2026-07-07: Projekte anlegen ist Nutzer-Alltag, keine Admin-Funktion).
//
// AppState.einladungErstellen (das dritte Gate aus dem Bauplan) wird hier NICHT end-to-end
// getestet: AppState baut beim Konstruieren echte Keychain-backed AuthServices auf — ein
// Test dafür würde entweder echtes Keychain berühren (verboten) oder eine aufwendige Fake-
// AppState-Fabrik erfordern, die nirgends sonst im Projekt existiert. Das Gate dort ist
// stattdessen durch Code-Lesen verifiziert: `assertAdmin` steht als allererste Zeile in
// `einladungErstellen`, vor jedem der vier Keychain-Reads (AppState.swift).
@MainActor
struct AdminEnforcementTests {

    private func admin() -> ResidentIdentity {
        ResidentIdentity(googleEmail: "johannes@mykilos.com", userID: "u-admin")
    }

    private func gast() -> ResidentIdentity {
        ResidentIdentity(googleEmail: "gast@example.com", userID: "u-gast")
    }

    private func eigenesSchema(version: Int = 9) -> FolderSchema {
        FolderSchema(version: version, rootTemplate: "<JJJJ_NNN_Kunde>", children: [], rootDateien: [])
    }

    // MARK: setzeSchema

    @Test func nichtAdminKannSchemaNichtSetzenDbBleibtUnveraendert() throws {
        let db = try GRDBDatabase.inMemory()
        let store = NomenklaturStore(db: db)
        try store.load()

        #expect(throws: BerechtigungError.nurAdmin(funktion: "Ordnerschema ändern")) {
            try store.setzeSchema(eigenesSchema(), ausgeloestVon: gast(), tokenPresent: true)
        }
        #expect(store.customFolderSchema == nil)
        #expect(store.aktivesSchema() == FolderSchema.v1)
    }

    @Test func adminOhneTokenKannSchemaNichtSetzen() throws {
        // Token-Kopplung auch am Store-Gate: Admin-Mail allein reicht nicht.
        let db = try GRDBDatabase.inMemory()
        let store = NomenklaturStore(db: db)
        try store.load()

        #expect(throws: BerechtigungError.self) {
            try store.setzeSchema(eigenesSchema(), ausgeloestVon: admin(), tokenPresent: false)
        }
        #expect(store.customFolderSchema == nil)
    }

    @Test func nilIdentitaetKannSchemaNichtSetzen() throws {
        let db = try GRDBDatabase.inMemory()
        let store = NomenklaturStore(db: db)
        try store.load()

        #expect(throws: BerechtigungError.self) {
            try store.setzeSchema(eigenesSchema(), ausgeloestVon: nil, tokenPresent: true)
        }
    }

    @Test func adminKannSchemaSetzen() throws {
        let db = try GRDBDatabase.inMemory()
        let store = NomenklaturStore(db: db)
        try store.load()

        try store.setzeSchema(eigenesSchema(), ausgeloestVon: admin(), tokenPresent: true)
        #expect(store.customFolderSchema == eigenesSchema())
    }

    // MARK: setzeSchemaAufStandard

    @Test func nichtAdminKannSchemaNichtAufStandardZuruecksetzen() throws {
        let db = try GRDBDatabase.inMemory()
        let store = NomenklaturStore(db: db)
        try store.load()
        try store.setzeSchema(eigenesSchema(), ausgeloestVon: admin(), tokenPresent: true)

        #expect(throws: BerechtigungError.nurAdmin(funktion: "Ordnerschema zurücksetzen")) {
            try store.setzeSchemaAufStandard(ausgeloestVon: gast(), tokenPresent: true)
        }
        // Das Admin-Schema von eben ist noch da — kein Teilschreiben vor dem Wurf.
        #expect(store.customFolderSchema == eigenesSchema())
    }

    @Test func adminKannSchemaAufStandardZuruecksetzen() throws {
        let db = try GRDBDatabase.inMemory()
        let store = NomenklaturStore(db: db)
        try store.load()
        try store.setzeSchema(eigenesSchema(), ausgeloestVon: admin(), tokenPresent: true)

        try store.setzeSchemaAufStandard(ausgeloestVon: admin(), tokenPresent: true)
        #expect(store.customFolderSchema == nil)
        #expect(store.aktivesSchema() == FolderSchema.v1)
    }

    // MARK: setzeAuthorityMode (neu, S4 — von Geburt an gegatet)

    @Test func nichtAdminKannAuthorityModeNichtSetzen() throws {
        let db = try GRDBDatabase.inMemory()
        let store = NomenklaturStore(db: db)
        try store.load()

        #expect(throws: BerechtigungError.nurAdmin(funktion: "Nummern-Autoritätsmodus ändern")) {
            try store.setzeAuthorityMode(.airtable, ausgeloestVon: gast(), tokenPresent: true)
        }
        #expect(store.authorityMode == .local)
    }

    @Test func adminAuthorityModeUeberlebtNeustart() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("myk6-authmode-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: dir) }
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let url = dir.appendingPathComponent("db.sqlite")

        let dbA = try GRDBDatabase(url: url)
        let storeA = NomenklaturStore(db: dbA)
        try storeA.load()
        try storeA.setzeAuthorityMode(.airtable, ausgeloestVon: admin(), tokenPresent: true)
        #expect(storeA.authorityMode == .airtable)

        let dbB = try GRDBDatabase(url: url)
        let storeB = NomenklaturStore(db: dbB)
        try storeB.load()   // neue Instanz, echter Neustart
        #expect(storeB.authorityMode == .airtable)
    }

    // MARK: Assistent-Whitelist-Cross-Check (Bauplan-Härtung: KI erreicht keinen Admin-Store)

    @Test func assistentWhitelistErreichtKeinenAdminStore() {
        let registry = AssistantToolRegistry.standard()
        // Keines dieser Wörter darf in einem registrierten Tool-Namen vorkommen — sonst hätte
        // der Assistent einen Draht zu Schema/Einladung/Prod-Freischaltung/Kalibrierung.
        let verdaechtigeBestandteile = ["schema", "invite", "einladung", "prod", "promote", "authority_mode"]
        for name in registry.toolNames {
            for stichwort in verdaechtigeBestandteile {
                #expect(name.contains(stichwort) == false, "Tool '\(name)' klingt nach einem Admin-Store-Zugriff")
            }
        }
    }
}
