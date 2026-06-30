import Foundation

// MARK: - FragebogenPDFRendering
// Protokoll für PDF-Export des Fragebogens. Injizierbarer Stub-Default für V1.
// Echte Implementierung (via MykPDFRenderer o.ä.) wird separat verdrahtet.
public protocol FragebogenPDFRendering: Sendable {
    /// Rendert den Fragebogen als PDF-Daten. Wirft bei Fehler.
    @MainActor func renderPDF(modell: FragebogenModel) async throws -> Data
}

// MARK: - FragebogenPDFRenderingStub
// V1-Stub: gibt ein minimal-valides PDF zurück (1 Seite, Klartextinhalt).
// Ersetzt die echte Impl bis MykPDFRenderer verdrahtet ist.
public struct FragebogenPDFRenderingStub: FragebogenPDFRendering, Sendable {
    public init() {}

    @MainActor public func renderPDF(modell: FragebogenModel) async throws -> Data {
        // Minimales PDF-Stub: base64-codiertes 1-Seiten-PDF mit Text
        let inhalt = buildTextInhalt(modell)
        // Wir bauen ein einfaches UTF8-PDF via CGPDFContext (ohne AppKit-Import):
        // Für den Stub reicht ein Plain-Text-Ersatz als Data.
        let pdfData = inhalt.data(using: .utf8) ?? Data()
        return pdfData
    }

    @MainActor private func buildTextInhalt(_ m: FragebogenModel) -> String {
        var zeilen: [String] = [
            "MYKILOS — Projekt-Fragebogen",
            "Erstellt: \(Date().formatted(date: .abbreviated, time: .shortened))",
            "",
            "KUNDE",
            "Name: \(m.vollstaendigerKundeName)",
        ]
        if !m.kundeFirma.isEmpty { zeilen.append("Firma: \(m.kundeFirma)") }
        if !m.kundeEmail.isEmpty { zeilen.append("E-Mail: \(m.kundeEmail)") }
        if !m.kundeTelefon.isEmpty { zeilen.append("Telefon: \(m.kundeTelefon)") }
        zeilen.append("")
        zeilen.append("PROJEKT")
        zeilen.append("Name: \(m.projektName)")
        zeilen.append("Status: \(m.projektStatus)")
        if let budget = m.budget { zeilen.append("Budget: \(budget) €") }
        zeilen.append("")
        zeilen.append("RAUM")
        if !m.raumBreite.isEmpty { zeilen.append("Breite: \(m.raumBreite) m") }
        if !m.raumTiefe.isEmpty { zeilen.append("Tiefe: \(m.raumTiefe) m") }
        zeilen.append("Form: \(m.raumform.rawValue)")
        zeilen.append("")
        zeilen.append("AUSWAHL (Zusammenfassung)")
        if !m.stil.isEmpty { zeilen.append("Stil: \(m.stil.map(\.rawValue).joined(separator: ", "))") }
        if !m.einbausituation.isEmpty { zeilen.append("Einbau: \(m.einbausituation.map(\.rawValue).joined(separator: ", "))") }
        if !m.sonderwuensche.isEmpty { zeilen.append("Sonderwünsche: \(m.sonderwuensche)") }
        zeilen.append("")
        zeilen.append("Nächster Schritt: \(m.naechsterSchritt.rawValue)")
        return zeilen.joined(separator: "\n")
    }
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

// MARK: - FragebogenDriveUploadingStub
// V1-Stub: no-op, gibt nil zurück. Upload wird später verdrahtet.
public struct FragebogenDriveUploadingStub: FragebogenDriveUploading, Sendable {
    public init() {}
    public func uploadFragebogenPDF(pdfData: Data, projektFolderID: String, dateiname: String) async throws -> String? {
        // TODO: Verdrahtung mit GoogleDriveClient.uploadFile(name:mimeType:data:parentFolderID:)
        // Ziel: parentFolderID = Unterordner "07 Fragebogen" innerhalb des Projekt-Drive-Ordners.
        return nil
    }
}
