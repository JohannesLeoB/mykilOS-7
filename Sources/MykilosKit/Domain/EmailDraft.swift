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
    /// Komma-getrennte CC-Adressen (optional, z. B. bei Reply-All gesetzt).
    public var cc: String?
    public var subject: String
    public var body: String
    public var attachments: [DraftAttachment]

    public init(to: String? = nil, cc: String? = nil, subject: String, body: String, attachments: [DraftAttachment] = []) {
        self.to = to
        self.cc = cc
        self.subject = subject
        self.body = body
        self.attachments = attachments
    }

    // Rückwärtskompatibel: `attachments` kam erst mit Session B dazu, `cc` mit feat/mail-folders-reply.
    // Alte persistierte Entwürfe haben diese Keys NICHT — der synthetisierte Decoder würde dann
    // `keyNotFound` werfen und beim Laden eines ganzen Chat-Scopes ALLE Nachrichten mitreißen.
    // Daher `decodeIfPresent ?? nil/[]`.
    private enum CodingKeys: String, CodingKey { case to, cc, subject, body, attachments }
    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.to = try c.decodeIfPresent(String.self, forKey: .to)
        self.cc = try c.decodeIfPresent(String.self, forKey: .cc)
        self.subject = try c.decode(String.self, forKey: .subject)
        self.body = try c.decode(String.self, forKey: .body)
        self.attachments = try c.decodeIfPresent([DraftAttachment].self, forKey: .attachments) ?? []
    }

    /// Kurze Kopfzeile für die Karte/Logs (nie der ganze Body).
    public var headline: String {
        let empfaenger = (to?.isEmpty == false) ? to! : "(kein Empfänger)"
        return "\(subject) · an \(empfaenger)"
    }

    // Bugfix 2026-07-06/07 (docs/IDEEN_UND_BACKLOG.md, "Mail-Signaturen laufen nicht sauber
    // aus dem Assistenten-Versand"): die manuelle Verfassen-Ansicht baute die Signatur selbst
    // in ihren Body ein (eigene "\n\n-- \n"-Konvention), der vom Assistenten bestätigte
    // Entwurfs-Pfad (AppState.createDraft) tat das nie — jeder Assistenten-Entwurf ging ohne
    // Signatur raus. EINE geteilte Konvention statt zwei Kopien, damit beide Pfade fortan
    // identisch funktionieren.

    /// Hängt eine Signatur nach der Standard-Konvention ("\n\n-- \n<Signatur>") an einen Body
    /// an. Leere/nur-Whitespace-Signatur → Body bleibt unverändert.
    public static func signaturAnhaengen(an body: String, signatur: String?) -> String {
        let getrimmt = (signatur ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard getrimmt.isEmpty == false else { return body }
        return body.isEmpty ? "\n\n-- \n\(getrimmt)" : "\(body)\n\n-- \n\(getrimmt)"
    }

    /// Wie `signaturAnhaengen(an:signatur:)`, aber liefert einen neuen `EmailDraft` mit
    /// angepasstem Body (Rest unverändert).
    public func mitAngehaengterSignatur(_ signatur: String?) -> EmailDraft {
        var neu = self
        neu.body = Self.signaturAnhaengen(an: body, signatur: signatur)
        return neu
    }
}

// MARK: - DraftCreateOutcome (S14)
// Ergebnis einer bestätigten Entwurfs-Anlage. created = menschenlesbarer Hinweis
// (z. B. „Entwurf in Gmail abgelegt"); failed = Fehlermeldung.
public enum DraftCreateOutcome: Sendable, Equatable {
    case created(String)
    case failed(String)
}

// MARK: - MailSendOutcome (S3)
// Ergebnis eines BESTÄTIGTEN echten Mail-Versands (gmail.compose deckt messages.send).
// permissionRequired = gmail.compose-Scope noch nicht erteilt (Re-Consent M2 offen).
public enum MailSendOutcome: Sendable, Equatable {
    case sent(String)            // menschenlesbarer Hinweis
    case failed(String)
    case permissionRequired
}
