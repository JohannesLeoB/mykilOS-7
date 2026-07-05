import Foundation
import Security

struct FireflyCredentials: Equatable {
    let clientID: String
    let clientSecret: String
}

enum FireflyCredentialsError: Error, LocalizedError {
    case notConnected
    case keychainFailure(OSStatus)

    var errorDescription: String? {
        switch self {
        case .notConnected: return "Kein Firefly-Zugang hinterlegt - erst Client ID + Secret in den Einstellungen eintragen."
        case .keychainFailure(let status): return "Schluesselbund-Fehler (\(status))."
        }
    }
}

protocol FireflyCredentialsStoring {
    func load() throws -> FireflyCredentials
    func save(_ credentials: FireflyCredentials) throws
    func clear() throws
}

/// Gerätelokaler Schlüsselbund-Eintrag für den Adobe-Firefly-Services-Zugang.
/// Zwei Felder (Client ID + Secret), gespeichert als ein JSON-Blob unter einem
/// eigenen Service — getrennt von Claude/Google/Airtable. Nie in Code, Chat
/// oder Repo; genau wie alle anderen Secrets.
struct KeychainFireflyCredentialsStore: FireflyCredentialsStoring {
    private let service = "com.johannes.myMini.firefly"
    private let account = "oauth"

    private struct Blob: Codable { let clientID: String; let clientSecret: String }

    func load() throws -> FireflyCredentials {
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
              let blob = try? JSONDecoder().decode(Blob.self, from: data),
              !blob.clientID.isEmpty, !blob.clientSecret.isEmpty else {
            throw FireflyCredentialsError.notConnected
        }
        return FireflyCredentials(clientID: blob.clientID, clientSecret: blob.clientSecret)
    }

    func save(_ credentials: FireflyCredentials) throws {
        try? clear()
        let blob = Blob(clientID: credentials.clientID, clientSecret: credentials.clientSecret)
        let data = try JSONEncoder().encode(blob)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
        ]
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw FireflyCredentialsError.keychainFailure(status)
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
            throw FireflyCredentialsError.keychainFailure(status)
        }
    }
}
