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
        try service.connect(pat: "pat123", baseID: "appXYZ")
        #expect(service.status == .connected)
        let creds = try store.load()
        #expect(creds?.pat == "pat123")
        #expect(creds?.baseID == "appXYZ")
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
        try service.connect(pat: "  pat123  ", baseID: "  appXYZ  ")
        let creds = try store.load()
        #expect(creds?.pat == "pat123")
        #expect(creds?.baseID == "appXYZ")
    }

    @Test @MainActor func syncingUndSyncedStatus() {
        let store = InMemoryAirtableCredentialsStore()
        let service = AirtableAuthService(credentialsStore: store)
        service.setSyncing()
        #expect(service.status == .syncing)
        service.setSynced()
        #expect(service.status == .connected)
    }
}
