import Foundation
import Observation
import MykilosKit

// MARK: - AirtableCredentials
public struct AirtableCredentials: Equatable, Sendable {
    public var pat: String
    public var baseID: String

    public init(pat: String, baseID: String) {
        self.pat = pat
        self.baseID = baseID
    }
}

// MARK: - AirtableConnectionStatus
public enum AirtableConnectionStatus: Equatable, Sendable {
    case disconnected
    case connected
    case syncing
    case error(String)
}

// MARK: - AirtableCredentialsStoring
public protocol AirtableCredentialsStoring: Sendable {
    func store(_ credentials: AirtableCredentials) throws
    func load() throws -> AirtableCredentials?
    func clear() throws
}

// MARK: - KeychainAirtableCredentialsStore
public struct KeychainAirtableCredentialsStore: AirtableCredentialsStoring {
    private let keychain: KeychainStore
    private static let service = "com.mykilos6.airtable"
    private static let patAccount = "pat"
    private static let baseIDAccount = "baseID"

    public init(keychain: KeychainStore = KeychainStore()) {
        self.keychain = keychain
    }

    public func store(_ credentials: AirtableCredentials) throws {
        try keychain.store(credentials.pat, service: Self.service, account: Self.patAccount)
        try keychain.store(credentials.baseID, service: Self.service, account: Self.baseIDAccount)
    }

    public func load() throws -> AirtableCredentials? {
        guard let pat = try keychain.load(service: Self.service, account: Self.patAccount),
              let baseID = try keychain.load(service: Self.service, account: Self.baseIDAccount) else {
            return nil
        }
        return AirtableCredentials(pat: pat, baseID: baseID)
    }

    public func clear() throws {
        try keychain.delete(service: Self.service, account: Self.patAccount)
        try keychain.delete(service: Self.service, account: Self.baseIDAccount)
    }
}

// MARK: - AirtableAuthService
@MainActor
@Observable
public final class AirtableAuthService {
    public private(set) var status: AirtableConnectionStatus

    private let credentialsStore: AirtableCredentialsStoring

    public init(credentialsStore: AirtableCredentialsStoring = KeychainAirtableCredentialsStore()) {
        self.credentialsStore = credentialsStore
        self.status = (try? credentialsStore.load()) != nil ? .connected : .disconnected
    }

    public func storedCredentials() throws -> AirtableCredentials? {
        try credentialsStore.load()
    }

    public func connect(pat: String, baseID: String) throws {
        let trimmedPAT = pat.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedBase = baseID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedPAT.isEmpty, !trimmedBase.isEmpty else {
            status = .error("PAT oder Base-ID fehlt")
            throw AirtableError.notConnected
        }
        do {
            try credentialsStore.store(AirtableCredentials(pat: trimmedPAT, baseID: trimmedBase))
            status = .connected
        } catch {
            status = .error(String(describing: error))
            throw error
        }
    }

    public func disconnect() throws {
        try credentialsStore.clear()
        status = .disconnected
    }

    public func setSyncing() { status = .syncing }
    public func setSynced() { status = .connected }
    public func setError(_ message: String) { status = .error(message) }
}
