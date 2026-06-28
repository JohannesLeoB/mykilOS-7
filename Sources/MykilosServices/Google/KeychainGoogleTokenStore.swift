import Foundation
import MykilosKit

// MARK: - GoogleTokenStoring
// Implementierungen dürfen Token-WERTE nie loggen, drucken oder anderswo
// serialisieren als hier.
public protocol GoogleTokenStoring: Sendable {
    func store(_ tokens: GoogleTokens) throws
    func load() throws -> GoogleTokens?
    func clear() throws
    func storeClientID(_ clientID: String) throws
    func loadClientID() throws -> String?
    // Manche Google-OAuth-Client-Typen ("Web", teils "Desktop") verlangen beim
    // Token-Tausch zusätzlich zum PKCE-Verifier ein client_secret — optional,
    // da reine "Installed App"-Clients ohne Secret funktionieren.
    func storeClientSecret(_ clientSecret: String) throws
    func loadClientSecret() throws -> String?
    // Gecachte Nutzeridentität nach OAuth-Login (S17).
    func storeUserInfo(_ userInfo: GoogleUserInfo) throws
    func loadUserInfo() throws -> GoogleUserInfo?
}

// MARK: - KeychainGoogleTokenStore
public struct KeychainGoogleTokenStore: GoogleTokenStoring {
    private static let service = "com.mykilos6.google"
    private static let tokensAccount = "tokens"
    private static let clientIDAccount = "clientID"
    private static let clientSecretAccount = "clientSecret"
    private static let userInfoAccount = "userInfo"

    private let keychain = KeychainStore()
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init() {
        // timeIntervalSinceReferenceDate statt .iso8601/.secondsSince1970 — siehe
        // FileBackedRepository: beide runden über die Epoch-Offset-Konvertierung
        // und verlieren Präzision; nur dieses Maß ist bitgenau roundtrip-sicher.
        let e = JSONEncoder()
        e.dateEncodingStrategy = .custom { date, encoder in
            var container = encoder.singleValueContainer()
            try container.encode(date.timeIntervalSinceReferenceDate)
        }
        let d = JSONDecoder()
        d.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            return Date(timeIntervalSinceReferenceDate: try container.decode(Double.self))
        }
        self.encoder = e
        self.decoder = d
    }

    public func store(_ tokens: GoogleTokens) throws {
        let data = try encoder.encode(tokens)
        guard let json = String(data: data, encoding: .utf8) else { throw KeychainStoreError.encodingFailed }
        try keychain.store(json, service: Self.service, account: Self.tokensAccount)
    }

    public func load() throws -> GoogleTokens? {
        guard let json = try keychain.load(service: Self.service, account: Self.tokensAccount) else { return nil }
        return try decoder.decode(GoogleTokens.self, from: Data(json.utf8))
    }

    public func clear() throws {
        try keychain.delete(service: Self.service, account: Self.tokensAccount)
        try keychain.delete(service: Self.service, account: Self.userInfoAccount)
    }

    public func storeClientID(_ clientID: String) throws {
        try keychain.store(clientID, service: Self.service, account: Self.clientIDAccount)
    }

    public func loadClientID() throws -> String? {
        try keychain.load(service: Self.service, account: Self.clientIDAccount)
    }

    public func storeClientSecret(_ clientSecret: String) throws {
        try keychain.store(clientSecret, service: Self.service, account: Self.clientSecretAccount)
    }

    public func loadClientSecret() throws -> String? {
        try keychain.load(service: Self.service, account: Self.clientSecretAccount)
    }

    public func storeUserInfo(_ userInfo: GoogleUserInfo) throws {
        let data = try JSONEncoder().encode(userInfo)
        guard let json = String(data: data, encoding: .utf8) else { throw KeychainStoreError.encodingFailed }
        try keychain.store(json, service: Self.service, account: Self.userInfoAccount)
    }

    public func loadUserInfo() throws -> GoogleUserInfo? {
        guard let json = try keychain.load(service: Self.service, account: Self.userInfoAccount) else { return nil }
        return try JSONDecoder().decode(GoogleUserInfo.self, from: Data(json.utf8))
    }
}
