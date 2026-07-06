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
    private static let base = "airtable"
    private static let patAccount = "pat"
    private static let baseIDAccount = "baseID"
    private let userID: String?

    // V10 Folge-Block A: per-User-Service `com.mykilos6.airtable.<userID>`.
    public init(keychain: KeychainStore = KeychainStore(), userID: String? = CurrentUserContext.current) {
        self.keychain = keychain
        self.userID = userID
    }

    private var service: String { PerUserKeychainService.perUser(Self.base, userID: userID) }

    public func store(_ credentials: AirtableCredentials) throws {
        try keychain.store(credentials.pat, service: service, account: Self.patAccount)
        try keychain.store(credentials.baseID, service: service, account: Self.baseIDAccount)
    }

    public func load() throws -> AirtableCredentials? {
        guard let pat = try PerUserKeychainMigrator.loadWithMigration(
                keychain: keychain, base: Self.base, userID: userID, account: Self.patAccount),
              let baseID = try PerUserKeychainMigrator.loadWithMigration(
                keychain: keychain, base: Self.base, userID: userID, account: Self.baseIDAccount) else {
            return nil
        }
        return AirtableCredentials(pat: pat, baseID: baseID)
    }

    public func clear() throws {
        try keychain.delete(service: service, account: Self.patAccount)
        try keychain.delete(service: service, account: Self.baseIDAccount)
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
        guard let creds = try credentialsStore.load() else { return nil }
        // Auto-Heal: häufiger Bedienfehler — PAT und Base-ID wurden in der Onboarding-
        // Maske vertauscht eingegeben. Eindeutig erkennbar: das Base-ID-Feld enthält
        // einen PAT/API-Key (pat…/key…) UND das PAT-Feld eine echte Base-ID (app…).
        // Nur dann tauschen (sonst nichts anfassen) und still neu speichern.
        if Self.looksLikeToken(creds.baseID), creds.pat.hasPrefix("app") {
            let healed = AirtableCredentials(pat: creds.baseID, baseID: creds.pat)
            try? credentialsStore.store(healed)   // best-effort; in-memory-Korrektur zählt sofort
            return healed
        }
        return creds
    }

    /// Heuristik: sieht der String wie ein Airtable-PAT/Key aus (nicht wie eine Base-ID)?
    static func looksLikeToken(_ s: String) -> Bool {
        s.hasPrefix("pat") || s.hasPrefix("key")
    }

    public func connect(pat: String, baseID: String) throws {
        let trimmedPAT = pat.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedBase = baseID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedPAT.isEmpty, !trimmedBase.isEmpty else {
            status = .error("PAT oder Base-ID fehlt")
            throw AirtableError.notConnected
        }
        guard trimmedBase.hasPrefix("app"), (15...22).contains(trimmedBase.count) else {
            let msg = "Base-ID muss mit \u{201E}app\u{201C} beginnen (z.\u{202F}B. appuVMh3KDfKw4OoQ) \u{2013} vermutlich wurde der PAT ins Base-ID-Feld eingef\u{FC}gt."
            status = .error(msg)
            throw AirtableError.invalidBaseID(trimmedBase)
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

    // MARK: Admin-Einladung (Onboarding-Plan Ebene 2)

    /// Admin: baut eine .mykinvite-Datei aus den AKTUELL verbundenen Zugangsdaten.
    public func einladungErstellen(passwort: String, gueltigTage: Int? = 7) throws -> Data {
        try MykInviteService.einladungErstellen(
            airtableCredentials: credentialsStore, passwort: passwort, gueltigTage: gueltigTage)
    }

    /// Neuer User: öffnet eine .mykinvite-Datei und übernimmt die Zugangsdaten.
    public func einladungOeffnen(daten: Data, passwort: String) throws {
        try MykInviteService.einladungOeffnen(daten: daten, passwort: passwort, airtableCredentials: credentialsStore)
        status = .connected
    }

    public func setSyncing() { status = .syncing }
    public func setSynced() { status = .connected }
    public func setError(_ message: String) { status = .error(message) }
}
