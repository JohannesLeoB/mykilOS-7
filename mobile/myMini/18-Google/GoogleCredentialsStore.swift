import Foundation
import Security

/// Client-ID UND Tokens zusammen als ein JSON-Blob — anders als die reinen
/// String-Tokens bei Airtable/Claude, weil Google mehrere Felder braucht.
/// Mirrort das Mothership-Prinzip: nichts hardcodiert, alles über UI
/// eingegeben/verwaltet, nur im Schlüsselbund.
struct GoogleCredentials: Codable, Equatable {
    let clientID: String
    var accessToken: String?
    var refreshToken: String?
    var ablaufDatum: Date?
}

enum GoogleCredentialsError: Error, LocalizedError {
    case notConnected
    case keychainFailure(OSStatus)

    var errorDescription: String? {
        switch self {
        case .notConnected: return "Kein Google-Konto verbunden — erst in den Einstellungen anmelden."
        case .keychainFailure(let status): return "Schlüsselbund-Fehler (\(status))."
        }
    }
}

protocol GoogleCredentialsStoring {
    func load() throws -> GoogleCredentials
    func save(_ credentials: GoogleCredentials) throws
    func clear() throws
}

struct KeychainGoogleCredentialsStore: GoogleCredentialsStoring {
    private let service = "com.johannes.myMini.google"
    private let account = "credentials"

    func load() throws -> GoogleCredentials {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess, let data = item as? Data,
              let credentials = try? JSONDecoder().decode(GoogleCredentials.self, from: data) else {
            throw GoogleCredentialsError.notConnected
        }
        return credentials
    }

    func save(_ credentials: GoogleCredentials) throws {
        try? clear()
        guard let data = try? JSONEncoder().encode(credentials) else {
            throw GoogleCredentialsError.keychainFailure(errSecParam)
        }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
        ]
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw GoogleCredentialsError.keychainFailure(status)
        }
    }

    func clear() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw GoogleCredentialsError.keychainFailure(status)
        }
    }
}

/// Liefert immer einen gültigen Access-Token — erneuert automatisch über
/// den Refresh-Token, wenn der aktuelle bald abläuft (60s Puffer).
struct GoogleAccessTokenProvider {
    private let credentialsStore: GoogleCredentialsStoring

    init(credentialsStore: GoogleCredentialsStoring = KeychainGoogleCredentialsStore()) {
        self.credentialsStore = credentialsStore
    }

    @MainActor
    func validAccessToken() async throws -> String {
        var credentials = try credentialsStore.load()
        if let ablauf = credentials.ablaufDatum, let access = credentials.accessToken,
           ablauf.timeIntervalSinceNow > 60 {
            return access
        }
        guard let refreshToken = credentials.refreshToken else {
            throw GoogleCredentialsError.notConnected
        }
        let service = GoogleOAuthPKCEService(clientID: credentials.clientID)
        let neueTokens = try await service.erneuere(refreshToken: refreshToken)
        credentials.accessToken = neueTokens.accessToken
        credentials.ablaufDatum = neueTokens.ablaufDatum
        try credentialsStore.save(credentials)
        return neueTokens.accessToken
    }
}
