import Foundation

// MARK: - DriveProjectFolderResolver
// Löst (oder legt an) den Zielordner für Projekt-Fragebögen in Drive auf.
// Pfad: <projektOrdner> / 01 INFOS / 07 Fragebogen
//
// Architektur-Kontext (docs/handoffs/HANDOFF_PROJEKT_INTAKE.md §B.1):
//  - Jedes Projekt hat in Drive einen Hauptordner (ID = `projektDriveOrdnerID`).
//  - Unterordner `01 INFOS` enthält projektbezogene Infodokumente.
//  - Unterordner `07 Fragebogen` (direkt in `01 INFOS`) ist das Upload-Ziel
//    für Fragebogen-PDFs, die der Intake-Strang erzeugt.
//  - `findOrCreateSubfolder` ist idempotent: existiert der Ordner bereits,
//    wird er wiederverwendet; andernfalls per files.create angelegt.
//    Erfordert drive.file-Scope — Re-Consent (Trennen→Verbinden) durch Johannes.

public struct DriveProjectFolderResolver: Sendable {
    private let client: any GoogleDriveFetching

    public init(client: any GoogleDriveFetching = GoogleDriveClient()) {
        self.client = client
    }

    /// Löst den Fragebogen-Ordner für ein Projekt auf (legt ihn ggf. an).
    ///
    /// Traversiert: `projektDriveOrdnerID` → `01 INFOS` → `07 Fragebogen`
    /// und gibt die Drive-ID des `07 Fragebogen`-Ordners zurück.
    ///
    /// - Parameter projektDriveOrdnerID: Die Drive-Ordner-ID des Projekts
    ///   (z. B. aus `ProjectLinks.driveFolderID`).
    /// - Returns: Drive-ID des `07 Fragebogen`-Unterordners.
    /// - Throws: `GoogleDriveError.notConnected` wenn kein gültiges Token vorhanden;
    ///   `GoogleDriveError.httpError` bei Drive-API-Fehlern.
    public func resolveFragebogenOrdner(projektDriveOrdnerID: String) async throws -> String {
        let infosID = try await client.findOrCreateSubfolder(
            parentID: projektDriveOrdnerID,
            name: "01 INFOS"
        )
        let fragebogenID = try await client.findOrCreateSubfolder(
            parentID: infosID,
            name: "07 Fragebogen"
        )
        return fragebogenID
    }
}
