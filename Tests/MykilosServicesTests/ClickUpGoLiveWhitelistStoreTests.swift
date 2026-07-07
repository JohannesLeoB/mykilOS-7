import Testing
import Foundation
@testable import MykilosServices
@testable import MykilosKit

// MARK: - ClickUpGoLiveWhitelistStoreTests (ClickUp-Vollintegration S10, 2026-07-07)
@MainActor
struct ClickUpGoLiveWhitelistStoreTests {

    private func tempDBURL() -> URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("myk6-golive-\(UUID().uuidString)/db.sqlite")
    }

    private func admin() -> ResidentIdentity {
        ResidentIdentity(googleEmail: "johannes@mykilos.com", userID: "u-admin")
    }

    private func gast() -> ResidentIdentity {
        ResidentIdentity(googleEmail: "gast@example.com", userID: "u-gast")
    }

    // MARK: Store-Gate (Admin-only, gleiche Linie wie NomenklaturStore/einladungErstellen)

    @Test func nichtAdminKannNichtFreischalten() throws {
        let db = try GRDBDatabase.inMemory()
        let audit = AuditStore(db: db)
        let store = ClickUpGoLiveWhitelistStore(db: db, audit: audit)

        #expect(throws: BerechtigungError.nurAdmin(funktion: "ClickUp-Liste Go-Live freischalten")) {
            try store.freischalten(listID: "901218617645", projektNummer: "2026-015", ausgeloestVon: gast(), tokenPresent: true)
        }
        #expect(store.freigegebeneListen.isEmpty)
        #expect(audit.entries.isEmpty)
    }

    @Test func adminKannFreischaltenUndSperren() throws {
        let db = try GRDBDatabase.inMemory()
        let audit = AuditStore(db: db)
        try audit.load()
        let store = ClickUpGoLiveWhitelistStore(db: db, audit: audit)

        try store.freischalten(listID: "901218617645", projektNummer: "2026-015", ausgeloestVon: admin(), tokenPresent: true)
        #expect(store.freigegebeneListen["901218617645"] == "2026-015")
        #expect(store.listIDs.contains("901218617645"))
        #expect(audit.entries.contains { $0.action == .clickUpGoLiveFreigegeben })

        try store.sperren(listID: "901218617645", ausgeloestVon: admin(), tokenPresent: true)
        #expect(store.freigegebeneListen.isEmpty)
        #expect(store.listIDs.isEmpty)
        #expect(audit.entries.contains { $0.action == .clickUpGoLiveGesperrt })
    }

    @Test func nichtAdminKannNichtSperren() throws {
        let db = try GRDBDatabase.inMemory()
        let audit = AuditStore(db: db)
        let store = ClickUpGoLiveWhitelistStore(db: db, audit: audit)
        try store.freischalten(listID: "901218617645", projektNummer: "2026-015", ausgeloestVon: admin(), tokenPresent: true)

        #expect(throws: BerechtigungError.nurAdmin(funktion: "ClickUp-Liste Go-Live sperren")) {
            try store.sperren(listID: "901218617645", ausgeloestVon: gast(), tokenPresent: true)
        }
        // Freigabe bleibt bestehen — kein Teilschreiben vor dem Wurf.
        #expect(store.freigegebeneListen["901218617645"] == "2026-015")
    }

    // MARK: Cold-Start (Pflicht für jedes persistierbare Feature)

    @Test func whitelisteUeberlebtNeustart() throws {
        let url = tempDBURL()
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)

        let dbA = try GRDBDatabase(url: url)
        let auditA = AuditStore(db: dbA)
        let storeA = ClickUpGoLiveWhitelistStore(db: dbA, audit: auditA)
        try storeA.freischalten(listID: "901218617645", projektNummer: "2026-015", ausgeloestVon: admin(), tokenPresent: true)

        let dbB = try GRDBDatabase(url: url)
        let auditB = AuditStore(db: dbB)
        let storeB = ClickUpGoLiveWhitelistStore(db: dbB, audit: auditB)
        try storeB.load()   // neue Instanz, echter Neustart

        #expect(storeB.freigegebeneListen["901218617645"] == "2026-015")
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
    }
}
