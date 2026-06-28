import Testing
import Foundation
@testable import MykilosServices

struct AirtableAuthServiceTests {

    @Test @MainActor func startetDisconnectedOhneCredentials() {
        let store = InMemoryAirtableCredentialsStore()
        let service = AirtableAuthService(credentialsStore: store)
        #expect(service.status == .disconnected)
    }

    @Test @MainActor func startetConnectedMitGespeichertenCredentials() {
        let store = InMemoryAirtableCredentialsStore(
            credentials: AirtableCredentials(pat: "pat123", baseID: "appXYZ")
        )
        let service = AirtableAuthService(credentialsStore: store)
        #expect(service.status == .connected)
    }

    @Test @MainActor func connectSpeichertUndSetztConnected() throws {
        let store = InMemoryAirtableCredentialsStore()
        let service = AirtableAuthService(credentialsStore: store)
        try service.connect(pat: "pat123", baseID: "appuVMh3KDfKw4OoQ")
        #expect(service.status == .connected)
        let creds = try store.load()
        #expect(creds?.pat == "pat123")
        #expect(creds?.baseID == "appuVMh3KDfKw4OoQ")
    }

    @Test @MainActor func connectMitLeerenFeldernWirft() {
        let store = InMemoryAirtableCredentialsStore()
        let service = AirtableAuthService(credentialsStore: store)
        #expect(throws: AirtableError.notConnected) {
            try service.connect(pat: "", baseID: "")
        }
        #expect(service.status == .error("PAT oder Base-ID fehlt"))
    }

    @Test @MainActor func disconnectLoeschtUndSetztDisconnected() throws {
        let store = InMemoryAirtableCredentialsStore(
            credentials: AirtableCredentials(pat: "pat", baseID: "app")
        )
        let service = AirtableAuthService(credentialsStore: store)
        try service.disconnect()
        #expect(service.status == .disconnected)
        #expect(try store.load() == nil)
    }

    @Test @MainActor func connectTrimtWhitespace() throws {
        let store = InMemoryAirtableCredentialsStore()
        let service = AirtableAuthService(credentialsStore: store)
        try service.connect(pat: "  pat123  ", baseID: "  appuVMh3KDfKw4OoQ  ")
        let creds = try store.load()
        #expect(creds?.pat == "pat123")
        #expect(creds?.baseID == "appuVMh3KDfKw4OoQ")
    }

    @Test @MainActor func syncingUndSyncedStatus() {
        let store = InMemoryAirtableCredentialsStore()
        let service = AirtableAuthService(credentialsStore: store)
        service.setSyncing()
        #expect(service.status == .syncing)
        service.setSynced()
        #expect(service.status == .connected)
    }

    // MARK: - baseID-Validierung (S17)

    @Test @MainActor func connectAkzeptiertGueltigeBaseID() throws {
        let store = InMemoryAirtableCredentialsStore()
        let service = AirtableAuthService(credentialsStore: store)
        try service.connect(pat: "patTest123", baseID: "appuVMh3KDfKw4OoQ")
        #expect(service.status == .connected)
    }

    @Test @MainActor func connectLehnPATFoermigeBaseIDAb() {
        let store = InMemoryAirtableCredentialsStore()
        let service = AirtableAuthService(credentialsStore: store)
        // PAT-förmige Base-ID (beginnt nicht mit "app")
        #expect(throws: AirtableError.invalidBaseID("patXYZ123abc")) {
            try service.connect(pat: "patTest123", baseID: "patXYZ123abc")
        }
        if case .error = service.status { } else {
            Issue.record("Status sollte .error sein, war: \(service.status)")
        }
    }

    @Test @MainActor func connectLehnKurzeBaseIDAb() {
        let store = InMemoryAirtableCredentialsStore()
        let service = AirtableAuthService(credentialsStore: store)
        #expect(throws: AirtableError.invalidBaseID("app")) {
            try service.connect(pat: "patTest123", baseID: "app")
        }
    }

    @Test @MainActor func connectValidatiertGegenGetrimmtenWert() throws {
        let store = InMemoryAirtableCredentialsStore()
        let service = AirtableAuthService(credentialsStore: store)
        // Whitespace darf die Validierung nicht umgehen
        try service.connect(pat: "patTest123", baseID: "  appuVMh3KDfKw4OoQ  ")
        #expect(service.status == .connected)
        let creds = try store.load()
        #expect(creds?.baseID == "appuVMh3KDfKw4OoQ")
    }
}
