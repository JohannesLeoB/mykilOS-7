import Foundation

// MARK: - SevdeskCredentials
// Sevdesk authentifiziert über einen einzelnen API-Token im Authorization-
// Header. Kein OAuth, kein Refresh — daher nur ein Feld.
public struct SevdeskCredentials: Equatable, Sendable {
    public var apiToken: String

    public init(apiToken: String) {
        self.apiToken = apiToken
    }
}

// MARK: - SevdeskCredentialsStoring
public protocol SevdeskCredentialsStoring: Sendable {
    func store(_ credentials: SevdeskCredentials) throws
    func load() throws -> SevdeskCredentials?
    func clear() throws
}

// MARK: - KeychainSevdeskCredentialsStore
// Nutzt den bestehenden generischen KeychainStore (siehe Google/KeychainStore.swift),
// kein neuer Keychain-Code nötig. Secret bleibt ausschließlich im Keychain.
public struct KeychainSevdeskCredentialsStore: SevdeskCredentialsStoring {
    private let keychain: KeychainStore
    private static let base = "sevdesk"
    private static let tokenAccount = "apiToken"
    private let userID: String?

    // V10 Folge-Block A: per-User-Service `com.mykilos6.sevdesk.<userID>`.
    public init(keychain: KeychainStore = KeychainStore(), userID: String? = CurrentUserContext.current) {
        self.keychain = keychain
        self.userID = userID
    }

    private var service: String { PerUserKeychainService.perUser(Self.base, userID: userID) }

    public func store(_ credentials: SevdeskCredentials) throws {
        try keychain.store(credentials.apiToken, service: service, account: Self.tokenAccount)
    }

    public func load() throws -> SevdeskCredentials? {
        guard let token = try PerUserKeychainMigrator.loadWithMigration(
                keychain: keychain, base: Self.base, userID: userID, account: Self.tokenAccount) else {
            return nil
        }
        return SevdeskCredentials(apiToken: token)
    }

    public func clear() throws {
        try keychain.delete(service: service, account: Self.tokenAccount)
    }
}
