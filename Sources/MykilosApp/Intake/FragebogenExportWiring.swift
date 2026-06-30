import Foundation
import MykilosKit
import MykilosServices

// MARK: - Verdrahtung der Fragebogen-Export-Protokolle
// Ersetzt die V1-Stubs (FragebogenPDFRenderingStub / FragebogenDriveUploadingStub)
// durch echte Implementierungen:
//   - PDF: MykPDFRenderer (echtes A4-PDF im mykilOS-Stil)
//   - Drive: DriveProjectFolderResolver (01 INFOS/07 Fragebogen) + GoogleDriveClient.uploadFile
// Beide rein additiv, kein DELETE/Overwrite. Drive-Upload braucht drive.file-Re-Consent.

// MARK: - PDF-Renderer (echt)

@MainActor
public struct MykFragebogenPDFRenderer: FragebogenPDFRendering {
    public init() {}

    public func renderPDF(modell: FragebogenModel) async throws -> Data {
        // Über den IntakeResultBuilder die gemappten Kunde-/Projekt-Felder + Warenkorb holen.
        let ergebnis = IntakeResultBuilder.build(from: modell)

        let kundeFelder = ergebnis.kundeFelder
            .sorted { $0.key < $1.key }
            .map { (label: $0.key, value: $0.value) }
        let projektFelder = ergebnis.projektFelder
            .sorted { $0.key < $1.key }
            .map { (label: $0.key, value: $0.value) }

        var sections: [(heading: String, fields: [(label: String, value: String)])] = [
            ("Kunde", kundeFelder),
            ("Projekt", projektFelder),
        ]
        if !modell.sonderwuensche.isEmpty {
            sections.append(("Anmerkungen", [("Sonderwünsche", modell.sonderwuensche)]))
        }

        let titel = "Projekt-Fragebogen"
        let untertitel = modell.projektName.isEmpty ? modell.vollstaendigerKundeName : modell.projektName

        return MykPDFRenderer.render(
            title: titel,
            subtitle: untertitel,
            sections: sections,
            table: nil,
            totals: []
        )
    }
}

// MARK: - Drive-Uploader (echt)

public struct MykFragebogenDriveUploader: FragebogenDriveUploading {
    private let client: GoogleDriveClient

    public init(client: GoogleDriveClient = GoogleDriveClient()) {
        self.client = client
    }

    /// - Parameter projektFolderID: ROOT-Ordner-ID des Projekts in der Drive.
    ///   Der Resolver legt darunter `01 INFOS` → `07 Fragebogen` an/auf und lädt dort hoch.
    public func uploadFragebogenPDF(pdfData: Data, projektFolderID: String, dateiname: String) async throws -> String? {
        let resolver = DriveProjectFolderResolver(client: client)
        let zielOrdnerID = try await resolver.resolveFragebogenOrdner(projektDriveOrdnerID: projektFolderID)
        let datei = try await client.uploadFile(
            name: dateiname,
            mimeType: "application/pdf",
            data: pdfData,
            parentFolderID: zielOrdnerID
        )
        return datei.webViewLink
    }
}
