import Foundation
import Security

struct ClaudeCredentials: Equatable {
    let apiKey: String
}

enum ClaudeCredentialsError: Error, LocalizedError {
    case notConnected
    case keychainFailure(OSStatus)

    var errorDescription: String? {
        switch self {
        case .notConnected: return "Kein Anthropic-API-Key hinterlegt — erst in den Einstellungen verbinden."
        case .keychainFailure(let status): return "Schlüsselbund-Fehler (\(status))."
        }
    }
}

protocol ClaudeCredentialsStoring {
    func load() throws -> ClaudeCredentials
    func save(_ credentials: ClaudeCredentials) throws
    func clear() throws
}

/// Eigener, gerätelokaler Schlüsselbund-Eintrag — getrennt vom Airtable-Token
/// und vom Mothership. Ein Feld: der Anthropic-API-Key.
struct KeychainClaudeCredentialsStore: ClaudeCredentialsStoring {
    private let service = "com.johannes.myMini.claude"
    private let account = "apiKey"

    func load() throws -> ClaudeCredentials {
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
              let apiKey = String(data: data, encoding: .utf8), !apiKey.isEmpty else {
            throw ClaudeCredentialsError.notConnected
        }
        return ClaudeCredentials(apiKey: apiKey)
    }

    func save(_ credentials: ClaudeCredentials) throws {
        try? clear()
        let data = Data(credentials.apiKey.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
        ]
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw ClaudeCredentialsError.keychainFailure(status)
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
            throw ClaudeCredentialsError.keychainFailure(status)
        }
    }
}
