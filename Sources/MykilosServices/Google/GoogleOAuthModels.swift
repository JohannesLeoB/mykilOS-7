import Foundation

// MARK: - GoogleOAuthScope
// mykilOS 6 plant keine Schreibzugriffe — daher ausschließlich Readonly-Scopes.
public enum GoogleOAuthScope: String, CaseIterable, Codable, Sendable {
    case driveMetadataReadonly  = "https://www.googleapis.com/auth/drive.metadata.readonly"
    case calendarEventsReadonly = "https://www.googleapis.com/auth/calendar.events.readonly"
    // gmail.readonly (statt gmail.metadata): nur read-only, aber zwingend nötig,
    // damit die Gmail-Volltextsuche (q über Betreff UND Mail-Inhalt) funktioniert —
    // unter gmail.metadata lehnt Google die Inhaltssuche ab.
    case gmailReadonly          = "https://www.googleapis.com/auth/gmail.readonly"
    case contactsReadonly       = "https://www.googleapis.com/auth/contacts.readonly"

    public static let readOnlyDefaults: [GoogleOAuthScope] = [
        .driveMetadataReadonly, .calendarEventsReadonly, .gmailReadonly, .contactsReadonly,
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
