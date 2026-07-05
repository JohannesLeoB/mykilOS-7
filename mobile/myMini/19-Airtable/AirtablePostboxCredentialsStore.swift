import Foundation
import Security

struct AirtablePostboxCredentials: Equatable {
    let pat: String
}

enum AirtablePostboxCredentialsError: Error, LocalizedError {
    case notConnected
    case keychainFailure(OSStatus)

    var errorDescription: String? {
        switch self {
        case .notConnected: return "Kein Airtable-Token hinterlegt — erst in den Einstellungen verbinden."
        case .keychainFailure(let status): return "Schlüsselbund-Fehler (\(status))."
        }
    }
}

protocol AirtablePostboxCredentialsStoring {
    func load() throws -> AirtablePostboxCredentials
    func save(_ credentials: AirtablePostboxCredentials) throws
    func clear() throws
}

/// Eigener, gerätelokaler Schlüsselbund-Eintrag — komplett getrennt vom Mothership
/// (anderes Gerät, andere Bundle-ID, andere Sandbox). Ein Feld: der Airtable-PAT.
/// Landet nie in Code, Datei, Repo oder Log (absolute Regel).
struct KeychainAirtablePostboxCredentialsStore: AirtablePostboxCredentialsStoring {
    private let service = "com.johannes.myMini.airtable-postbox"
    private let account = "pat"

    func load() throws -> AirtablePostboxCredentials {
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
              let pat = String(data: data, encoding: .utf8), !pat.isEmpty else {
            throw AirtablePostboxCredentialsError.notConnected
        }
        return AirtablePostboxCredentials(pat: pat)
    }

    func save(_ credentials: AirtablePostboxCredentials) throws {
        try? clear()
        let data = Data(credentials.pat.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
        ]
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw AirtablePostboxCredentialsError.keychainFailure(status)
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
            throw AirtablePostboxCredentialsError.keychainFailure(status)
        }
    }
}
