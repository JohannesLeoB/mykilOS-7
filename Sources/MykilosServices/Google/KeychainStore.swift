import Foundation
import Security

// MARK: - KeychainStoreError
public enum KeychainStoreError: Error, Sendable {
    case encodingFailed
    case writeFailed(OSStatus)
    case readFailed(OSStatus)
    case deleteFailed(OSStatus)
}

// MARK: - KeychainStore
// Generischer Keychain-Wrapper, der Geheimnisse als (service, account) → String
// speichert. Portiert aus mykilOS 5.5 (Services/SecureCredentialStore.swift),
// generalisiert, damit Google-Tokens UND später ein Airtable-PAT denselben
// Code nutzen können — siehe [[mykilos-keychain-prompt-rebuild]].
public struct KeychainStore: Sendable {
    public init() {}

    @discardableResult
    public func store(_ value: String, service: String, account: String) throws -> Bool {
        guard let data = value.data(using: .utf8) else { throw KeychainStoreError.encodingFailed }

        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
        ]

        // Ad-hoc-signierte Dev-Builds bekommen bei jedem `swift build` einen
        // neuen Code-Hash; die Standard-ACL bindet den Eintrag an genau diesen
        // Hash, daher würde macOS bei jedem Rebuild erneut den Vertrauens-
        // Dialog zeigen. "Allow all applications" entkoppelt den Eintrag vom
        // Code-Hash und verhindert den wiederholten Prompt.
        let allowAllAccess = Self.makeAllowAllApplicationsAccess()

        var addAttributes: [CFString: Any] = [kSecValueData: data]
        if let allowAllAccess {
            addAttributes[kSecAttrAccess] = allowAllAccess
        } else {
            addAttributes[kSecAttrAccessible] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        }
        let addQuery = query.merging(addAttributes) { _, new in new }

        let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
        if addStatus == errSecSuccess { return true }

        guard addStatus == errSecDuplicateItem else {
            throw KeychainStoreError.writeFailed(addStatus)
        }

        // WURZEL-FIX (2026-07-05, Johannes' 6×-Prompt-Hölle): Beim UPDATE die ACL
        // NICHT erneut setzen. Der Dialog „möchte die Zugriffsrechte … ÄNDERN" ist
        // exakt die ACL-Modify-Autorisierung — die feuert auf jeder neu signierten
        // Build, wenn wir kSecAttrAccess mitschreiben (pro Secret ein Prompt → 6×).
        // Die ACL wurde beim Anlegen einmalig auf „alle Apps, kein Prompt" gesetzt und
        // bleibt bestehen; Updates schreiben NUR den Wert (kein ACL-Modify → kein Prompt).
        let updateAttributes: [CFString: Any] = [kSecValueData: data]
        let updateStatus = SecItemUpdate(query as CFDictionary, updateAttributes as CFDictionary)
        guard updateStatus == errSecSuccess else {
            throw KeychainStoreError.writeFailed(updateStatus)
        }
        return false
    }

    public func load(service: String, account: String) throws -> String? {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne,
            kSecUseAuthenticationUI: kSecUseAuthenticationUISkip,
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess else { throw KeychainStoreError.readFailed(status) }
        guard let data = item as? Data, let value = String(data: data, encoding: .utf8) else {
            throw KeychainStoreError.encodingFailed
        }
        return value
    }

    public func delete(service: String, account: String) throws {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
        ]
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainStoreError.deleteFailed(status)
        }
    }

    /// Programmatisches Äquivalent zu "Allow all applications to access this
    /// item" in Keychain Access. macOS-only (Legacy-SecAccess-API); gibt nil
    /// zurück, falls die Erzeugung fehlschlägt — Aufrufer fällt dann auf das
    /// einfache Accessible-Attribut zurück.
    private static func makeAllowAllApplicationsAccess() -> SecAccess? {
        var access: SecAccess?
        let status = SecAccessCreate("mykilOS6 credentials" as CFString, nil, &access)
        guard status == errSecSuccess, let access else { return nil }
        if let aclList = SecAccessCopyMatchingACLList(access, kSecACLAuthorizationDecrypt) as? [SecACL] {
            for acl in aclList {
                // Eine nil-Application-Liste heißt "jede Anwendung"; ein leerer
                // Prompt-Selector heißt "kein Bestätigungsdialog".
                SecACLSetContents(acl, nil, "" as CFString, SecKeychainPromptSelector())
            }
        }
        return access
    }
}
