import Foundation

// MARK: - ClockodoCredentials
public struct ClockodoCredentials: Equatable, Sendable {
    public var email: String
    public var apiKey: String

    public init(email: String, apiKey: String) {
        self.email = email
        self.apiKey = apiKey
    }
}

// MARK: - ClockodoCredentialsStoring
public protocol ClockodoCredentialsStoring: Sendable {
    func store(_ credentials: ClockodoCredentials) throws
    func load() throws -> ClockodoCredentials?
    func clear() throws
}

// MARK: - KeychainClockodoCredentialsStore
// Clockodo authentifiziert über simple API-Key + E-Mail-Header, kein OAuth —
// nutzt den bestehenden generischen KeychainStore direkt (siehe
// Google/KeychainStore.swift), kein neuer Keychain-Code nötig.
public struct KeychainClockodoCredentialsStore: ClockodoCredentialsStoring {
    private let keychain: KeychainStore
    private static let base = "clockodo"
    private static let emailAccount = "email"
    private static let apiKeyAccount = "apiKey"
    private let userID: String?

    // V10 Folge-Block A: per-User-Service `com.mykilos6.clockodo.<userID>`.
    // userID = UserProfile.userID (stabile lokale UUID) — nil/leer fällt auf
    // "local" zurück (siehe PerUserKeychainService).
    public init(keychain: KeychainStore = KeychainStore(), userID: String? = CurrentUserContext.current) {
        self.keychain = keychain
        self.userID = userID
    }

    private var service: String { PerUserKeychainService.perUser(Self.base, userID: userID) }

    public func store(_ credentials: ClockodoCredentials) throws {
        try keychain.store(credentials.email, service: service, account: Self.emailAccount)
        try keychain.store(credentials.apiKey, service: service, account: Self.apiKeyAccount)
    }

    public func load() throws -> ClockodoCredentials? {
        // Sanfte Migration: erst per-User-Service, sonst Legacy-Teamservice
        // nachziehen (Rückwärtskompatibilität, alter Eintrag bleibt bestehen).
        guard let email = try PerUserKeychainMigrator.loadWithMigration(
                keychain: keychain, base: Self.base, userID: userID, account: Self.emailAccount),
              let apiKey = try PerUserKeychainMigrator.loadWithMigration(
                keychain: keychain, base: Self.base, userID: userID, account: Self.apiKeyAccount) else {
            return nil
        }
        return ClockodoCredentials(email: email, apiKey: apiKey)
    }

    public func clear() throws {
        try keychain.delete(service: service, account: Self.emailAccount)
        try keychain.delete(service: service, account: Self.apiKeyAccount)
    }
}
