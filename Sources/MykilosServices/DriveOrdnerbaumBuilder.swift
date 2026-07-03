import Foundation
import MykilosKit

// MARK: - DriveOrdnerbaumBuilder
// Baut den Ordnerbaum eines FolderSchema unter einem beliebigen Parent-Ordner
// (find-or-create, idempotent). Extrahiert aus ProjektProvisioningService (Block D,
// TEST-Sandbox), damit dieselbe Logik auch für die echte Fragebogen-Provisionierung
// (AppState.erzeugeKundeUndProjekt) genutzt werden kann — beide Aufrufer unterscheiden
// sich nur im Parent-Ordner (Sandbox-Unterordner vs. echter PROJEKTE-Root).
public enum DriveOrdnerbaumBuilder {
    public struct Ergebnis: Sendable {
        public let rootOrdnerID: String
        public let unterordnerIDs: [String: String]
    }

    /// `bestehendeUnterordnerIDs` erlaubt Wiederaufnahme (Teilpfad → Ordner-ID bereits
    /// bekannt, z. B. aus einem Ledger) — dann werden nur fehlende Pfade neu aufgelöst.
    /// `bekannteRootOrdnerID` überspringt auch die Root-Auflösung selbst, wenn sie schon
    /// bekannt ist (sonst würde ein Resume trotz vollständigem Unterbau-Cache die Root
    /// noch einmal anfragen — unnötig, auch wenn find-or-create ergebnisstabil bleibt).
    public static func baue(
        drive: any DriveFolderProvisioning,
        parentID: String,
        ordnerName: String,
        schema: FolderSchema,
        bestehendeUnterordnerIDs: [String: String] = [:],
        bekannteRootOrdnerID: String? = nil
    ) async throws -> Ergebnis {
        let rootOrdnerID: String
        if let bekannteRootOrdnerID {
            rootOrdnerID = bekannteRootOrdnerID
        } else {
            rootOrdnerID = try await drive.findOrCreateSubfolder(parentID: parentID, name: ordnerName)
        }

        // Jeden Schema-Pfad komponentenweise find-or-create. `erzeugteIDs` cacht
        // relativen Pfad → Folder-ID, damit gemeinsame Präfixe (01 INFOS/…) nur
        // einmal aufgelöst werden.
        var erzeugteIDs = bestehendeUnterordnerIDs
        for pfad in schema.allePfade() {
            var parent = rootOrdnerID
            var teilpfad = ""
            for komponente in pfad.split(separator: "/").map(String.init) {
                teilpfad = teilpfad.isEmpty ? komponente : teilpfad + "/" + komponente
                if let cached = erzeugteIDs[teilpfad] {
                    parent = cached
                } else {
                    let id = try await drive.findOrCreateSubfolder(parentID: parent, name: komponente)
                    erzeugteIDs[teilpfad] = id
                    parent = id
                }
            }
        }
        return Ergebnis(rootOrdnerID: rootOrdnerID, unterordnerIDs: erzeugteIDs)
    }
}
