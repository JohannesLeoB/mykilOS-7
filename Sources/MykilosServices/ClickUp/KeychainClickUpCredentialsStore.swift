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
    private static let service = "com.mykilos6.clickup"
    private static let tokenAccount = "apiToken"

    public init(keychain: KeychainStore = KeychainStore()) {
        self.keychain = keychain
    }

    public func store(_ credentials: ClickUpCredentials) throws {
        try keychain.store(credentials.apiToken, service: Self.service, account: Self.tokenAccount)
    }

    public func load() throws -> ClickUpCredentials? {
        guard let token = try keychain.load(service: Self.service, account: Self.tokenAccount) else {
            return nil
        }
        return ClickUpCredentials(apiToken: token)
    }

    public func clear() throws {
        try keychain.delete(service: Self.service, account: Self.tokenAccount)
    }
}
