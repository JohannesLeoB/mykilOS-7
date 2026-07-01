import Testing
import Foundation
@testable import MykilosServices
@testable import MykilosKit

// Block D / S4: die Mehrsystem-Projekt-Geburt. Beweist die Brief-Pflichten:
// Idempotenz, Teilfehler-Festigkeit + Wiederaufnahme, jeder Schritt wirft, Audit vollständig.
// Alles mit Fakes — KEIN echter Drive/Airtable-Write im Test.
@MainActor
struct ProvisioningServiceTests {

    private func makePlan(nr: Int = 30) -> ProvisioningPlan {
        ProvisioningPlan(
            projektnummer: Projektnummer(jahr: 2026, laufendeNummer: nr),
            kdnr: "K-1001", kundeName: "Schmidt",
            ordnerName: "2026_0\(nr)_Schmidt_HEI8",
            airtableFelder: ["Projektname": "Küche Schmidt"],
            schema: .v1)
    }

    private func makeService(drive: FakeDrive, fetch: FakeFetch = FakeFetch()) throws -> (ProjektProvisioningService, ProvisioningLedger, AuditStore, FakeCreate) {
        let db = try GRDBDatabase.inMemory()
        let ledger = ProvisioningLedger(db: db)
        let audit = AuditStore(db: db)
        let create = FakeCreate()
        let shadow = WriteShadowRecorder(db: db)
        let svc = ProjektProvisioningService(
            drive: drive, airtableCreate: create, airtableFetch: fetch,
            ledger: ledger, audit: audit, writeShadow: shadow,
            isWritable: { _, _ in true })   // Fakes kennen keine echte Base/Tabelle — Whitelist hier bewusst umgangen.
        return (svc, ledger, audit, create)
    }

    @Test func gateSperrtProd() async throws {
        let (svc, _, _, _) = try makeService(drive: FakeDrive())
        await #expect(throws: ProvisioningError.self) {
            _ = try await svc.provision(plan: makePlan(), mode: .prod, driveParentID: "root", airtableBaseID: "appX", airtableTabelle: "TEST_Projekte", actorUserID: "test")
        }
    }

    @Test func erfolgErzeugtBaumRecordUndEinenAuditEintrag() async throws {
        let drive = FakeDrive()
        let (svc, ledger, audit, create) = try makeService(drive: drive)
        try audit.load()
        let r = try await svc.provision(plan: makePlan(), mode: .test, driveParentID: "root", airtableBaseID: "appX", airtableTabelle: "TEST_Projekte", actorUserID: "test")

        #expect(r.status == .vollstaendig)
        #expect(r.driveProjektOrdnerID != nil)
        #expect(r.airtableRecordID != nil)
        #expect(create.aufrufe == 1)                       // genau ein Airtable-Record
        // Unterbaum: alle Schema-Pfade als Ordner (find-or-create).
        #expect(r.driveUnterordnerIDs.keys.contains("01 INFOS/07 Fragebogen"))
        // TEST-Marker im Record.
        #expect(create.letzteFelder?["Projektname"]?.stringValue?.hasPrefix("TEST_") == true)
        #expect(create.letzteFelder?["Quelle"]?.stringValue == "TEST")
        // Genau EIN Audit-Eintrag für die ganze Geburt.
        #expect(audit.entries.filter { $0.action == .projectLinked }.count == 1)
        // Ledger hält den vollständigen Stand.
        #expect(try ledger.eintrag(fuer: r.idempotenzSchluessel)?.status == .vollstaendig)
    }

    @Test func zweiterLaufErzeugtNichtsNeues() async throws {
        let drive = FakeDrive()
        // Fetch liefert beim zweiten Lauf den bestehenden Record → Idempotenz.
        let fetch = FakeFetch()
        let (svc, _, _, create) = try makeService(drive: drive, fetch: fetch)
        let r1 = try await svc.provision(plan: makePlan(), mode: .test, driveParentID: "root", airtableBaseID: "appX", airtableTabelle: "TEST_Projekte", actorUserID: "test")
        fetch.records = [["_airtableRecordID": .string(r1.airtableRecordID ?? "rec1"),
                          "Projektnummer": .string("2026-030"), "Quelle": .string("TEST")]]
        let driveAufrufeNach1 = drive.aufrufe
        let createNach1 = create.aufrufe

        let r2 = try await svc.provision(plan: makePlan(), mode: .test, driveParentID: "root", airtableBaseID: "appX", airtableTabelle: "TEST_Projekte", actorUserID: "test")
        #expect(r2.status == .vollstaendig)
        #expect(create.aufrufe == createNach1)             // KEIN neuer Airtable-Record
        #expect(drive.aufrufe == driveAufrufeNach1)        // Drive-Schritt war erledigt → übersprungen
        #expect(r2.airtableRecordID == r1.airtableRecordID)
    }

    @Test func teilfehlerHinterlaesstDefiniertenZustandUndNimmtWiederAuf() async throws {
        // Airtable wirft beim ersten Lauf → Drive ist erledigt, Status .fehler.
        let drive = FakeDrive()
        let create = FakeCreate(); create.wirft = true
        let db = try GRDBDatabase.inMemory()
        let ledger = ProvisioningLedger(db: db)
        let audit = AuditStore(db: db)
        let svc = ProjektProvisioningService(
            drive: drive, airtableCreate: create, airtableFetch: FakeFetch(),
            ledger: ledger, audit: audit, writeShadow: WriteShadowRecorder(db: db),
            isWritable: { _, _ in true })

        await #expect(throws: ProvisioningError.self) {
            _ = try await svc.provision(plan: makePlan(), mode: .test, driveParentID: "root", airtableBaseID: "appX", airtableTabelle: "TEST_Projekte", actorUserID: "test")
        }
        let nach = try #require(try ledger.eintrag(fuer: makePlan().idempotenzSchluessel))
        #expect(nach.status == .fehler)
        #expect(nach.hat(.driveOrdnerbaum) == true)        // Schritt 1 sauber erledigt
        #expect(nach.hat(.airtableRecord) == false)
        let driveAufrufe = drive.aufrufe

        // Wiederaufnahme: Airtable funktioniert jetzt → nur Schritt 2 läuft, Drive NICHT nochmal.
        create.wirft = false
        let r = try await svc.provision(plan: makePlan(), mode: .test, driveParentID: "root", airtableBaseID: "appX", airtableTabelle: "TEST_Projekte", actorUserID: "test")
        #expect(r.status == .vollstaendig)
        #expect(drive.aufrufe == driveAufrufe)             // Drive war erledigt → keine neuen Aufrufe
        #expect(r.airtableRecordID != nil)
    }

    @Test func driveFehlerWirftSchrittFehlgeschlagen() async throws {
        let drive = FakeDrive(); drive.wirft = true
        let (svc, ledger, _, _) = try makeService(drive: drive)
        await #expect(throws: ProvisioningError.self) {
            _ = try await svc.provision(plan: makePlan(), mode: .test, driveParentID: "root", airtableBaseID: "appX", airtableTabelle: "TEST_Projekte", actorUserID: "test")
        }
        #expect(try ledger.eintrag(fuer: makePlan().idempotenzSchluessel)?.status == .fehler)
    }
}

// MARK: - Fakes

private final class FakeDrive: DriveFolderProvisioning, @unchecked Sendable {
    var wirft = false
    private(set) var aufrufe = 0
    private var ids: [String: String] = [:]   // (parent/name) → stabile ID (idempotent)
    func findOrCreateSubfolder(parentID: String, name: String) async throws -> String {
        if wirft { throw NSError(domain: "drive", code: 1) }
        aufrufe += 1
        let key = parentID + "/" + name
        if let existing = ids[key] { return existing }
        let id = "fld_\(ids.count)"
        ids[key] = id
        return id
    }
}

private final class FakeCreate: AirtableRecordCreating, @unchecked Sendable {
    var wirft = false
    private(set) var aufrufe = 0
    private(set) var letzteFelder: [String: AirtableFieldValue]?
    func createRecord(baseID: String, table: String, fields: [String: AirtableFieldValue]) async throws -> String {
        if wirft { throw AirtableError.httpError(422) }
        aufrufe += 1
        letzteFelder = fields
        return "rec_\(aufrufe)"
    }
}

private final class FakeFetch: AirtableFetching, @unchecked Sendable {
    var records: [[String: AirtableFieldValue]] = []
    func fetchRecords(baseID: String, table: String) async throws -> [[String: AirtableFieldValue]] { records }
}
