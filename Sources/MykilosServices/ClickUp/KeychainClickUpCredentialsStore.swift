import Foundation

// MARK: - ClickUpCredentials
// ClickUp authentifiziert über einen einzelnen Personal-API-Token
// (Authorization-Header). Kein OAuth, kein Refresh — daher nur ein Feld.
public struct ClickUpCredentials: Equatable, Sendable {
    public var apiToken: String

    public init(apiToken: String) {
        self.apiToken = apiToken
    }
}

// MARK: - ClickUpCredentialsStoring
public protocol ClickUpCredentialsStoring: Sendable {
    func store(_ credentials: ClickUpCredentials) throws
    func load() throws -> ClickUpCredentials?
    func clear() throws
}

// MARK: - KeychainClickUpCredentialsStore
// Nutzt den bestehenden generischen KeychainStore (siehe Google/KeychainStore.swift),
// kein neuer Keychain-Code nötig. Secret bleibt ausschließlich im Keychain.
public struct KeychainClickUpCredentialsStore: ClickUpCredentialsStoring {
    private let keychain: KeychainStore
    private static let base = "clickup"
    private static let tokenAccount = "apiToken"
    private let userID: String?

    // V10 Folge-Block A: per-User-Service `com.mykilos6.clickup.<userID>`.
    public init(keychain: KeychainStore = KeychainStore(), userID: String? = CurrentUserContext.current) {
        self.keychain = keychain
        self.userID = userID
    }

    private var service: String { PerUserKeychainService.perUser(Self.base, userID: userID) }

    public func store(_ credentials: ClickUpCredentials) throws {
        try keychain.store(credentials.apiToken, service: service, account: Self.tokenAccount)
    }

    public func load() throws -> ClickUpCredentials? {
        guard let token = try PerUserKeychainMigrator.loadWithMigration(
                keychain: keychain, base: Self.base, userID: userID, account: Self.tokenAccount) else {
            return nil
        }
        return ClickUpCredentials(apiToken: token)
    }

    public func clear() throws {
        try keychain.delete(service: service, account: Self.tokenAccount)
    }
}
