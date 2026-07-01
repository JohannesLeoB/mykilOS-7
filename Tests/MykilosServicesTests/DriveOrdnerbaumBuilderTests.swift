import Testing
import Foundation
@testable import MykilosServices
@testable import MykilosKit

// DriveOrdnerbaumBuilder wurde aus ProjektProvisioningService extrahiert, damit die echte
// Fragebogen-Provisionierung (AppState.erzeugeKundeUndProjekt) dieselbe Baum-Logik nutzt.
// Diese Tests beweisen die Logik unabhängig von beiden Aufrufern — alles mit einem Fake,
// KEIN echter Drive-Write im Testlauf.
struct DriveOrdnerbaumBuilderTests {

    @Test func bautWurzelUndKompletenUnterbaum() async throws {
        let drive = FakeDrive()
        let ergebnis = try await DriveOrdnerbaumBuilder.baue(
            drive: drive, parentID: "root", ordnerName: "2026_031_Schmidt_HEI8", schema: .v1)

        #expect(ergebnis.rootOrdnerID.isEmpty == false)
        // Alle Schema-Pfade müssen als Unterordner-IDs vorhanden sein.
        for pfad in FolderSchema.v1.allePfade() {
            #expect(ergebnis.unterordnerIDs[pfad] != nil, "Fehlender Pfad: \(pfad)")
        }
    }

    @Test func istIdempotentZweiterAufrufErzeugtNichtsNeues() async throws {
        let drive = FakeDrive()
        let erster = try await DriveOrdnerbaumBuilder.baue(
            drive: drive, parentID: "root", ordnerName: "2026_031_Schmidt_HEI8", schema: .v1)
        let aufrufeNachErstem = drive.aufrufe

        let zweiter = try await DriveOrdnerbaumBuilder.baue(
            drive: drive, parentID: "root", ordnerName: "2026_031_Schmidt_HEI8", schema: .v1,
            bestehendeUnterordnerIDs: erster.unterordnerIDs, bekannteRootOrdnerID: erster.rootOrdnerID)

        #expect(drive.aufrufe == aufrufeNachErstem)   // find-or-create-Cache + Ledger-Wiederaufnahme → kein neuer Aufruf
        #expect(zweiter.rootOrdnerID == erster.rootOrdnerID)
        #expect(zweiter.unterordnerIDs == erster.unterordnerIDs)
    }

    @Test func ohneBekannteRootOrdnerIDLoestRootJedesMalNeuAuf() async throws {
        // Die echte Fragebogen-Provisionierung (AppState) ruft baue(...) einmalig pro
        // Submission auf, ohne bekannteRootOrdnerID — hier ist find-or-create korrekt
        // ERGEBNISSTABIL (gleiche ID), aber ruft findOrCreateSubfolder für die Root
        // erneut auf, wenn baue(...) zweimal mit demselben Parent+Name aufgerufen wird.
        let drive = FakeDrive()
        let erster = try await DriveOrdnerbaumBuilder.baue(
            drive: drive, parentID: "root", ordnerName: "2026_031_Schmidt_HEI8", schema: .v1)
        let aufrufeNachErstem = drive.aufrufe

        let zweiter = try await DriveOrdnerbaumBuilder.baue(
            drive: drive, parentID: "root", ordnerName: "2026_031_Schmidt_HEI8", schema: .v1,
            bestehendeUnterordnerIDs: erster.unterordnerIDs)

        #expect(drive.aufrufe == aufrufeNachErstem + 1)   // nur die Root wird erneut aufgelöst
        #expect(zweiter.rootOrdnerID == erster.rootOrdnerID)   // aber ergebnisstabil (gleiche ID)
    }

    @Test func wirftWennDriveFehlschlaegt() async throws {
        let drive = FakeDrive(); drive.wirft = true
        await #expect(throws: (any Error).self) {
            _ = try await DriveOrdnerbaumBuilder.baue(
                drive: drive, parentID: "root", ordnerName: "2026_031_Schmidt_HEI8", schema: .v1)
        }
    }
}

private final class FakeDrive: DriveFolderProvisioning, @unchecked Sendable {
    var wirft = false
    private(set) var aufrufe = 0
    private var ids: [String: String] = [:]
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
