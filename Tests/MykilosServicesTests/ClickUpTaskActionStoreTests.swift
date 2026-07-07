import Testing
import Foundation
@testable import MykilosServices
@testable import MykilosKit

// MARK: - ClickUpTaskActionStoreTests (ClickUp-Vollintegration S4, 2026-07-07)
// Beweist: das Gate sitzt tatsächlich VOR dem echten Schreiben — bei fremder Space wird
// `client.setStatus` NIE aufgerufen (Zähler bleibt 0) und es entsteht KEIN Audit-Eintrag.
@MainActor
struct ClickUpTaskActionStoreTests {

    private final class FakeWriter: ClickUpTaskWriting, ClickUpSpaceResolving, @unchecked Sendable {
        var spaceIDToReturn: String?
        private(set) var setStatusAufrufe = 0
        private(set) var createTaskAufrufe = 0
        private(set) var letzterContent: String?
        var wirftBeimSchreiben: Error?

        func createTask(listID: String, name: String, content: String?) async throws -> String {
            createTaskAufrufe += 1
            letzterContent = content
            if let wirftBeimSchreiben { throw wirftBeimSchreiben }
            return "neu"
        }

        func setStatus(taskID: String, status: String) async throws {
            setStatusAufrufe += 1
            if let wirftBeimSchreiben { throw wirftBeimSchreiben }
        }

        func spaceID(forListID listID: String) async throws -> String? { spaceIDToReturn }
    }

    private func admin() -> ResidentIdentity {
        ResidentIdentity(googleEmail: "johannes@mykilos.com", userID: "u-admin")
    }

    @Test func statusWechselInTestspaceListeSchreibtUndProtokolliert() async throws {
        let fake = FakeWriter()
        fake.spaceIDToReturn = ClickUpWriteGate.testspaceID
        let db = try GRDBDatabase.inMemory()
        let audit = AuditStore(db: db)
        let store = ClickUpTaskActionStore(client: fake, audit: audit)

        try await store.setStatus(
            taskID: "t1", listID: "901218940344", status: "complete",
            projectID: "2026-999", actorUserID: "johannes@mykilos.com")

        #expect(fake.setStatusAufrufe == 1)
        #expect(audit.entries.count == 1)
        #expect(audit.entries.first?.action == .clickUpStatusChanged)
        #expect(audit.entries.first?.actorUserID == "johannes@mykilos.com")
        #expect(audit.entries.first?.projectID == "2026-999")
    }

    @Test func statusWechselInFremderListeWirftUndSchreibtNie() async throws {
        let fake = FakeWriter()
        fake.spaceIDToReturn = "90127216979"   // PROJEKTE — echte Produktivliste, keine Testspace
        let db = try GRDBDatabase.inMemory()
        let audit = AuditStore(db: db)
        let store = ClickUpTaskActionStore(client: fake, audit: audit)

        await #expect(throws: ClickUpWriteGateError.nichtErlaubt(listID: "901218617645")) {
            try await store.setStatus(
                taskID: "t1", listID: "901218617645", status: "complete",
                projectID: "2026-015", actorUserID: "johannes@mykilos.com")
        }

        #expect(fake.setStatusAufrufe == 0)
        #expect(audit.entries.isEmpty)
    }

    @Test func unbekannteSpaceWirdEbenfallsAbgelehnt() async throws {
        let fake = FakeWriter()
        fake.spaceIDToReturn = nil
        let db = try GRDBDatabase.inMemory()
        let audit = AuditStore(db: db)
        let store = ClickUpTaskActionStore(client: fake, audit: audit)

        await #expect(throws: ClickUpWriteGateError.self) {
            try await store.setStatus(
                taskID: "t1", listID: "unbekannt", status: "complete",
                projectID: "2026-015", actorUserID: "johannes@mykilos.com")
        }
        #expect(fake.setStatusAufrufe == 0)
        #expect(audit.entries.isEmpty)
    }

    // MARK: Go-Live-Whitelist (S10) — die einzige Brücke zu echten Produktivlisten

    @Test func goLiveFreigeschalteteListeErlaubtSchreibenTrotzFremderSpace() async throws {
        let fake = FakeWriter()
        fake.spaceIDToReturn = "90127216979"   // echte PROJEKTE-Space, keine Testspace
        let db = try GRDBDatabase.inMemory()
        let audit = AuditStore(db: db)
        let whitelist = ClickUpGoLiveWhitelistStore(db: db, audit: audit)
        try whitelist.freischalten(listID: "901218617645", projektNummer: "2026-015", ausgeloestVon: admin(), tokenPresent: true)
        let store = ClickUpTaskActionStore(client: fake, audit: audit, goLiveWhitelist: whitelist)

        try await store.setStatus(
            taskID: "t1", listID: "901218617645", status: "complete",
            projectID: "2026-015", actorUserID: "johannes@mykilos.com")

        #expect(fake.setStatusAufrufe == 1)
        #expect(audit.entries.contains { $0.action == .clickUpStatusChanged })
    }

    @Test func nichtFreigeschalteteListeBleibtGesperrtTrotzWhitelistAnschluss() async throws {
        let fake = FakeWriter()
        fake.spaceIDToReturn = "90127216979"
        let db = try GRDBDatabase.inMemory()
        let audit = AuditStore(db: db)
        let whitelist = ClickUpGoLiveWhitelistStore(db: db, audit: audit)
        try whitelist.freischalten(listID: "ANDERE-LISTE", projektNummer: "2026-016", ausgeloestVon: admin(), tokenPresent: true)
        let store = ClickUpTaskActionStore(client: fake, audit: audit, goLiveWhitelist: whitelist)

        await #expect(throws: ClickUpWriteGateError.nichtErlaubt(listID: "901218617645")) {
            try await store.setStatus(
                taskID: "t1", listID: "901218617645", status: "complete",
                projectID: "2026-015", actorUserID: "johannes@mykilos.com")
        }
        #expect(fake.setStatusAufrufe == 0)
    }

    // MARK: createTask (S4) — gleiches Gate wie setStatus

    @Test func createTaskInTestspaceSchreibtGhostMarkerUndProtokolliert() async throws {
        let fake = FakeWriter()
        fake.spaceIDToReturn = ClickUpWriteGate.testspaceID
        let db = try GRDBDatabase.inMemory()
        let audit = AuditStore(db: db)
        let store = ClickUpTaskActionStore(client: fake, audit: audit)

        let neueID = try await store.createTask(
            listID: "901218940344", name: "Testaufgabe", ghostKuerzel: "Jo",
            projectID: "2026-999", actorUserID: "johannes@mykilos.com")

        #expect(neueID == "neu")
        #expect(fake.createTaskAufrufe == 1)
        #expect(fake.letzterContent == "Zugewiesen (simuliert, Ghost-Persona): Jo")
        #expect(audit.entries.contains { $0.action == .clickUpTaskCreated })
    }

    @Test func createTaskInFremderListeWirftUndSchreibtNie() async throws {
        let fake = FakeWriter()
        fake.spaceIDToReturn = "90127216979"
        let db = try GRDBDatabase.inMemory()
        let audit = AuditStore(db: db)
        let store = ClickUpTaskActionStore(client: fake, audit: audit)

        await #expect(throws: ClickUpWriteGateError.self) {
            _ = try await store.createTask(
                listID: "901218617645", name: "Sollte nie geschrieben werden", ghostKuerzel: nil,
                projectID: "2026-015", actorUserID: "johannes@mykilos.com")
        }
        #expect(fake.createTaskAufrufe == 0)
        #expect(audit.entries.isEmpty)
    }
}
