import Foundation

// MARK: - GoogleUserInfo
// Zwischengespeicherte Google-Identität nach erfolgreichem OAuth-Login.
// Heimat in MykilosKit/Domain (analog zu GoogleConnectionStatus), damit
// MykilosServices UND MykilosApp es sauber referenzieren können.
public struct GoogleUserInfo: Equatable, Sendable, Codable {
    public var email: String
    public var displayName: String

    public init(email: String, displayName: String) {
        self.email = email
        self.displayName = displayName
    }
}
