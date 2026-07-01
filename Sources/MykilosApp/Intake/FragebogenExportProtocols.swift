import Foundation

// MARK: - FragebogenPDFRendering
// Protokoll für PDF-Export des Fragebogens. Injizierbarer Stub-Default für V1.
// Echte Implementierung (via MykPDFRenderer o.ä.) wird separat verdrahtet.
public protocol FragebogenPDFRendering: Sendable {
    /// Rendert den Fragebogen als PDF-Daten. Wirft bei Fehler.
    @MainActor func renderPDF(modell: FragebogenModel) async throws -> Data
}

// MARK: - FragebogenDriveUploading
// Protokoll für Drive-Upload des Fragebogens-PDF.
// Stub ist no-op; echte Impl via GoogleDriveClient wird separat verdrahtet.
// Ziel-Ordner (laut §B.1): 01 INFOS/07 Fragebogen im Projekt-Drive-Ordner.
public protocol FragebogenDriveUploading: Sendable {
    /// Lädt das PDF in den Drive-Ordner hoch.
    /// - Parameters:
    ///   - pdfData: Daten des gerenderten PDFs
    ///   - projektFolderID: Drive-Folder-ID des Projekts (01 INFOS/07 Fragebogen)
    ///   - dateiname: Dateiname (z. B. "Fragebogen_2026_MUSTERMANN.pdf")
    /// - Returns: webViewLink des Drive-Dokuments, oder nil beim Stub
    func uploadFragebogenPDF(pdfData: Data, projektFolderID: String, dateiname: String) async throws -> String?
}
