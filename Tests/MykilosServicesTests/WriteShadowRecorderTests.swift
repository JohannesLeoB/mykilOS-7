import Testing
import Foundation
@testable import MykilosServices
@testable import MykilosKit

// Block A: beweist, dass JEDER gespiegelte Write eine vollständige, unverlierbare
// lokale Kopie bekommt — Cold-Start-Pflicht für neue Persistenz.
@MainActor
struct WriteShadowRecorderTests {

    @Test func writeShadowUeberlebtNeustartMitVollstaendigemPayload() throws {
        let db = try GRDBDatabase.inMemory()
        let recorderA = WriteShadowRecorder(db: db)
        let entry = try recorderA.recordAirtableWrite(
            action: .create, actorUserID: "johannes",
            baseID: "appdxTeT6bhSBmwx5", table: "Projekte", recordID: "recP1",
            fields: ["Projektname": .string("Küche Schmidt"), "Budget": .number(42000)],
            mode: .test, result: .ok
        )

        let recorderB = WriteShadowRecorder(db: db)
        let loaded = try recorderB.load()

        #expect(loaded.count == 1)
        let read = try #require(loaded.first)
        #expect(read.id == entry.id)
        #expect(read.targetSystem == .airtable)
        #expect(read.targetBase == "appdxTeT6bhSBmwx5")
        #expect(read.targetTable == "Projekte")
        #expect(read.payloadJSON.contains("Küche Schmidt"))
        #expect(read.payloadJSON.contains("42000"))
        #expect(read.mode == .test)
        #expect(read.result == .ok)
    }

    @Test func fehlenderBackupBasePflanztSichtbareWarnungInsDataFlowLog() throws {
        let db = try GRDBDatabase.inMemory()
        let dataFlow = DataFlowLogger(db: db)   // airtable: nil → kein echter Netzwerkversuch
        try dataFlow.load()
        // backupBaseID bewusst nil — das ist der heutige Echtzustand.
        let recorder = WriteShadowRecorder(db: db, backupBaseID: nil, dataFlow: dataFlow)

        _ = try recorder.recordAirtableWrite(
            action: .create, actorUserID: "johannes", baseID: "appdxTeT6bhSBmwx5",
            table: "Kunden", recordID: "recK1", fields: ["Nachname": .string("Schmidt")],
            mode: .test, result: .ok
        )

        #expect(dataFlow.entries.contains { $0.integrationID == "WRITE_SHADOW_BACKUP_FEHLT" })
    }

    @Test func primaerSchreibvorgangBleibtUnberuehrtAuchOhneBackupBase() throws {
        // Der Write-Shadow darf NIE den eigentlichen Write blockieren — hier geprüft,
        // indem recordAirtableWrite trotz fehlender Backup-Base erfolgreich zurückkehrt.
        let db = try GRDBDatabase.inMemory()
        let recorder = WriteShadowRecorder(db: db, backupBaseID: nil)
        let entry = try recorder.recordAirtableWrite(
            action: .update, actorUserID: "johannes", baseID: "appdxTeT6bhSBmwx5",
            table: "Projekte", recordID: "recP1", fields: [:], mode: .test, result: .ok
        )
        #expect(entry.result == .ok)
    }
}

// Block A: TEST/PROD-Schalter — Default .test, .prod hart gesperrt.
@MainActor
struct ProvisioningModeStoreTests {

    @Test func defaultIstTestUndUeberlebtNeustart() throws {
        let db = try GRDBDatabase.inMemory()
        let storeA = ProvisioningModeStore(db: db)
        try storeA.load()
        #expect(storeA.mode == .test)
        try storeA.setMode(.test)

        let storeB = ProvisioningModeStore(db: db)
        try storeB.load()
        #expect(storeB.mode == .test)
    }

    @Test func prodIstGesperrt() throws {
        let db = try GRDBDatabase.inMemory()
        let store = ProvisioningModeStore(db: db)
        try store.load()
        #expect(throws: ProvisioningModeError.prodLocked) {
            try store.setMode(.prod)
        }
        #expect(store.mode == .test)
    }
}

// TestMarker: Doppel-Strategie (Präfix UND Quelle-Feld) — beide müssen stimmen.
struct TestMarkerTests {
    @Test func erkenntNurRecordsMitBeidenMarkern() {
        #expect(TestMarker.isTestRecord(name: "TEST_Schmidt", quelle: "TEST") == true)
        #expect(TestMarker.isTestRecord(name: "TEST_Schmidt", quelle: nil) == false)
        #expect(TestMarker.isTestRecord(name: "Schmidt", quelle: "TEST") == false)
        #expect(TestMarker.isTestRecord(name: "Schmidt", quelle: nil) == false)
    }
}
