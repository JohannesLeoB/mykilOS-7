import Foundation

// MARK: - GoogleOAuthScope
// mykilOS 6 plant keine Schreibzugriffe — daher ausschließlich Readonly-Scopes.
public enum GoogleOAuthScope: String, CaseIterable, Codable, Sendable {
    case driveMetadataReadonly  = "https://www.googleapis.com/auth/drive.metadata.readonly"
    // Für Datei-Vorschau (L16): Vollständiges read-only auf Drive-Inhalt.
    // Erst nach manuellem Re-Consent von Johannes aktivieren (M5).
    case driveReadonly          = "https://www.googleapis.com/auth/drive.readonly"
    case calendarEventsReadonly = "https://www.googleapis.com/auth/calendar.events.readonly"
    // gmail.readonly (statt gmail.metadata): nur read-only, aber zwingend nötig,
    // damit die Gmail-Volltextsuche (q über Betreff UND Mail-Inhalt) funktioniert —
    // unter gmail.metadata lehnt Google die Inhaltssuche ab.
    case gmailReadonly          = "https://www.googleapis.com/auth/gmail.readonly"
    // Schreibender Gmail-Scope (S14): nötig für drafts.create. NUR Entwürfe — Senden
    // bleibt NO-GO (wir rufen die Send-API nie auf). Erfordert Re-Consent (M2).
    case gmailCompose           = "https://www.googleapis.com/auth/gmail.compose"
    case contactsReadonly       = "https://www.googleapis.com/auth/contacts.readonly"
    // Schreibender Kontakt-Scope (S9): nötig für people:createContact. Schließt
    // contacts.readonly ein, ist aber ein eigener Scope → erfordert Re-Consent (M2).
    case contacts               = "https://www.googleapis.com/auth/contacts"
    // Verzeichnis-Scope (S19): nötig für people:searchDirectoryPeople (Workspace-Domain-
    // Profile + admin-geteilte Domain-Kontakte). Erfordert Re-Consent (M2).
    case directoryReadonly      = "https://www.googleapis.com/auth/directory.readonly"
    // Userinfo-Scopes: Name + E-Mail nach OAuth-Login anzeigen (S17).
    // Erfordert einmaliges Re-Consent (prompt=consent ist bereits gesetzt).
    case userinfoEmail          = "https://www.googleapis.com/auth/userinfo.email"
    case userinfoProfile        = "https://www.googleapis.com/auth/userinfo.profile"
    // Schreibender Drive-Scope (feat/assistant-write-tier): nötig für files.create
    // (Datei-Drop → Drive ablegen). Erlaubt NUR Dateien, die die App selbst erstellt hat.
    // NICHT in readOnlyDefaults — erst nach explizitem Re-Consent von Johannes aktivieren.
    case driveFile              = "https://www.googleapis.com/auth/drive.file"

    public static let readOnlyDefaults: [GoogleOAuthScope] = [
        // drive.readonly: nötig für downloadContent (PDF-Vorschau) + thumbnailLink.
        // Erfordert einmaliges Re-Consent von Johannes nach diesem Update.
        .driveReadonly, .driveMetadataReadonly,
        .calendarEventsReadonly, .gmailReadonly, .gmailCompose,
        // contacts (Schreiben, S9) ersetzt contacts.readonly — schließt Lesen ein.
        // Erfordert einmaliges Re-Consent (M2). Lesen funktioniert weiter darüber.
        .contacts, .directoryReadonly,
        .userinfoEmail, .userinfoProfile,
    ]
}

// MARK: - GoogleTokens
// Token-WERTE landen ausschließlich im Keychain (KeychainGoogleTokenStore) —
// dieses Modell ist nur die Transport-Form dorthin, nie geloggt, nie im Repo.
public struct GoogleTokens: Codable, Equatable, Sendable {
    public var accessToken: String
    public var refreshToken: String?
    public var expiresAt: Date

    public init(accessToken: String, refreshToken: String?, expiresAt: Date) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiresAt = expiresAt
    }

    public var isExpired: Bool { Date() >= expiresAt }
}

// MARK: - GoogleOAuthError
public enum GoogleOAuthError: Error, Sendable, Equatable {
    case invalidEndpoint
    case invalidResponse
    case httpError(Int)
    case decodingFailed
    case redirectStateMismatch
    case missingClientID
    case loopbackStartupFailed
    case loopbackCancelled
    case notConnected
    case refreshUnavailable
}

// MARK: - urlEncodedFormBody
// Geteilter Form-Encoder für POST-Requests an den Google-Token-Endpoint —
// genutzt vom Code-Exchange (GoogleOAuthPKCEService) UND vom Token-Refresh
// (GoogleTokenRefreshService), damit die Escaping-Logik nur einmal existiert.
func urlEncodedFormBody(_ values: [String: String]) -> Data {
    values
        .map { key, value in "\(formEscape(key))=\(formEscape(value))" }
        .joined(separator: "&")
        .data(using: .utf8) ?? Data()
}

private func formEscape(_ value: String) -> String {
    var allowed = CharacterSet.alphanumerics
    allowed.insert(charactersIn: "-._~")
    return value.addingPercentEncoding(withAllowedCharacters: allowed) ?? value
}
