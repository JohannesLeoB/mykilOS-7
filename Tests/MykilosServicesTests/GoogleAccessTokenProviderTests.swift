import Testing
import Foundation
@testable import MykilosServices

// MARK: - FakeTokenRefreshing
// Test-Double — kein echtes Netzwerk im automatisierten Testlauf.
final class FakeTokenRefreshing: GoogleTokenRefreshing, @unchecked Sendable {
    var callCount = 0
    var response: GoogleOAuthTokenExchangeResponse?
    var errorToThrow: Error?

    func refresh(refreshToken: String, clientID: String) async throws -> GoogleOAuthTokenExchangeResponse {
        callCount += 1
        if let errorToThrow { throw errorToThrow }
        guard let response else { fatalError("response oder errorToThrow setzen") }
        return response
    }
}

struct GoogleAccessTokenProviderTests {

    @Test func wirftNotConnectedOhneToken() async {
        let provider = GoogleAccessTokenProvider(
            tokenStore: InMemoryGoogleTokenStore(),
            refreshing: FakeTokenRefreshing()
        )
        do {
            _ = try await provider.validAccessToken()
            Issue.record("sollte werfen")
        } catch {
            #expect(error as? GoogleOAuthError == .notConnected)
        }
    }

    @Test func gibtNichtAbgelaufenesTokenDirektZurueck() async throws {
        let store = InMemoryGoogleTokenStore()
        store.tokens = GoogleTokens(accessToken: "gueltig", refreshToken: "r", expiresAt: Date().addingTimeInterval(3600))
        let refresher = FakeTokenRefreshing()
        let provider = GoogleAccessTokenProvider(tokenStore: store, refreshing: refresher)

        let token = try await provider.validAccessToken()

        #expect(token == "gueltig")
        #expect(refresher.callCount == 0)
    }

    @Test func wirftRefreshUnavailableOhneRefreshToken() async {
        let store = InMemoryGoogleTokenStore()
        store.tokens = GoogleTokens(accessToken: "abgelaufen", refreshToken: nil, expiresAt: Date().addingTimeInterval(-10))
        let provider = GoogleAccessTokenProvider(tokenStore: store, refreshing: FakeTokenRefreshing())

        do {
            _ = try await provider.validAccessToken()
            Issue.record("sollte werfen")
        } catch {
            #expect(error as? GoogleOAuthError == .refreshUnavailable)
        }
    }

    @Test func erneuertAbgelaufenesTokenUndPersistiertEs() async throws {
        let store = InMemoryGoogleTokenStore()
        store.tokens = GoogleTokens(accessToken: "alt", refreshToken: "refresh-1", expiresAt: Date().addingTimeInterval(-10))
        store.clientID = "client-1"
        let refresher = FakeTokenRefreshing()
        refresher.response = GoogleOAuthTokenExchangeResponse(accessToken: "neu", expiresIn: 3600, refreshToken: nil)
        let provider = GoogleAccessTokenProvider(tokenStore: store, refreshing: refresher)

        let token = try await provider.validAccessToken()

        #expect(token == "neu")
        #expect(refresher.callCount == 1)
        #expect(store.tokens?.accessToken == "neu")
        // Kein neues Refresh-Token in der Antwort → das alte bleibt erhalten.
        #expect(store.tokens?.refreshToken == "refresh-1")
    }
}
