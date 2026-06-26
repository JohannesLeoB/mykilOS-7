import Foundation
import Observation
import MykilosKit

// MARK: - SevdeskAuthService
// Kein OAuth/Redirect — der API-Token wird synchron gespeichert, daher kein
// `.connecting`-Zwischenzustand. Schreibt nie direkt ins Keychain ohne den
// Fehlerweg über `status` sichtbar zu machen.
@MainActor
@Observable
public final class SevdeskAuthService {
    public private(set) var status: SevdeskConnectionStatus

    private let credentialsStore: SevdeskCredentialsStoring

    public init(credentialsStore: SevdeskCredentialsStoring = KeychainSevdeskCredentialsStore()) {
        self.credentialsStore = credentialsStore
        self.status = (try? credentialsStore.load()) != nil ? .connected : .disconnected
    }

    public func storedCredentials() throws -> SevdeskCredentials? {
        try credentialsStore.load()
    }

    public func connect(apiToken: String) throws {
        let trimmed = apiToken.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else {
            status = .error("API-Token fehlt")
            throw SevdeskError.notConnected
        }
        do {
            try credentialsStore.store(SevdeskCredentials(apiToken: trimmed))
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
}
