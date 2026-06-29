import Foundation

// MARK: - DriveFileRef (S22)
// Leichte, anklickbare Referenz auf eine Drive-Datei in einem Assistenten-Ergebnis.
// Trägt genau das, was die In-App-Vorschau braucht (id für downloadContent, mimeType
// für den Viewer-Modus, webViewLink als Browser-Fallback). Read-only.
public struct DriveFileRef: Codable, Sendable, Equatable, Identifiable {
    public let id: String                // Drive-File-ID
    public var name: String
    public var mimeType: String
    public var webViewLink: String?
    public var subtitle: String?         // z. B. „eingehend · 12.06.26" für die Zeile

    public init(id: String, name: String, mimeType: String, webViewLink: String? = nil, subtitle: String? = nil) {
        self.id = id
        self.name = name
        self.mimeType = mimeType
        self.webViewLink = webViewLink
        self.subtitle = subtitle
    }
}
