import Foundation

// MARK: - DroppedFile
// Gekapselt eine vom Nutzer in den Chat gedropte Datei — nur im RAM, nie
// automatisch geschrieben. Bytes werden erst bei ausdrücklicher Bestätigung
// (Drive-Upload oder Mail-Anhang) an die jeweilige API übergeben.
public struct DroppedFile: Sendable, Equatable {
    /// Dateiname inkl. Extension (z. B. „Angebot_2026.pdf").
    public let fileName: String
    /// MIME-Typ (z. B. „application/pdf").
    public let mimeType: String
    /// Rohe Datei-Bytes — NUR im RAM, kein Schreiben ohne Bestätigung.
    public let data: Data

    public init(fileName: String, mimeType: String, data: Data) {
        self.fileName = fileName
        self.mimeType = mimeType
        self.data = data
    }

    /// Lesbare Dateigröße (B / KB / MB).
    public var humanSize: String {
        let bytes = data.count
        if bytes < 1024 { return "\(bytes) B" }
        if bytes < 1_048_576 { return "\(bytes / 1024) KB" }
        return String(format: "%.1f MB", Double(bytes) / 1_048_576)
    }

    /// Systemnamen-Icon (SF Symbol) passend zum MIME-Typ.
    public var iconName: String {
        if mimeType == "application/pdf" { return "doc.richtext" }
        if mimeType.hasPrefix("image/") { return "photo" }
        if mimeType.hasPrefix("text/") { return "doc.text" }
        return "doc"
    }
}

// MARK: - DriveUploadOutcome
// Ergebnis eines bestätigten Drive-Uploads. Analoges Muster zu DraftCreateOutcome.
public enum DriveUploadOutcome: Sendable, Equatable {
    /// Upload erfolgreich — enthält den Web-Link zur Datei (optional, für Erfolgszeile).
    case uploaded(webLink: String?)
    /// Upload fehlgeschlagen — menschenlesbarer Grund.
    case failed(String)
    /// drive.file-Scope fehlt — Re-Consent nötig.
    case permissionRequired
}
