import Foundation

// MARK: - DraftAttachment (Session B)
/// Datei-Anhang für einen Mail-Entwurf. Wird base64-kodiert in die MIME-Nachricht
/// eingebettet (buildMIMEMultipart). Kein Schreiben in Keychain/Drive — nur RAM.
public struct DraftAttachment: Codable, Sendable, Equatable {
    public var filename: String
    public var mimeType: String
    public var data: Data

    public init(filename: String, mimeType: String, data: Data) {
        self.filename = filename
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
}

// MARK: - EmailDraft (S14)
// Ein vom Assistenten vorgeschlagener Mail-Entwurf. Wird NIE automatisch geschrieben
// und NIE versendet — erst eine ausdrückliche Bestätigung legt ihn als Gmail-Entwurf
// an (erscheint dann auch in Apple Mail, da das Mac-Postfach das Gmail-Konto spiegelt).
// Versenden bleibt ein hartes NO-GO; dies ist reine Entwurfs-Ablage.
public struct EmailDraft: Codable, Sendable, Equatable {
    public var to: String?
    public var subject: String
    public var body: String
    public var attachments: [DraftAttachment]

    public init(to: String? = nil, subject: String, body: String, attachments: [DraftAttachment] = []) {
        self.to = to
        self.subject = subject
        self.body = body
        self.attachments = attachments
    }

    /// Kurze Kopfzeile für die Karte/Logs (nie der ganze Body).
    public var headline: String {
        let empfaenger = (to?.isEmpty == false) ? to! : "(kein Empfänger)"
        return "\(subject) · an \(empfaenger)"
    }
}

// MARK: - DraftCreateOutcome (S14)
// Ergebnis einer bestätigten Entwurfs-Anlage. created = menschenlesbarer Hinweis
// (z. B. „Entwurf in Gmail abgelegt"); failed = Fehlermeldung.
public enum DraftCreateOutcome: Sendable, Equatable {
    case created(String)
    case failed(String)
}
