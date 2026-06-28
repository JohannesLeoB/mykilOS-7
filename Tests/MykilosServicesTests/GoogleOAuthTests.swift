import Testing
import Foundation
import CryptoKit
@testable import MykilosServices
import MykilosKit

// MARK: - InMemoryGoogleTokenStore
// Test-Double — kein echtes Keychain im automatisierten Testlauf (würde an
// OS-Prompts/Sandbox scheitern). Muster wie GRDBDatabase.inMemory().
final class InMemoryGoogleTokenStore: GoogleTokenStoring, @unchecked Sendable {
    var tokens: GoogleTokens?
    var clientID: String?
    var clientSecret: String?
    var userInfo: GoogleUserInfo?

    func store(_ tokens: GoogleTokens) throws { self.tokens = tokens }
    func load() throws -> GoogleTokens? { tokens }
    func clear() throws { tokens = nil; userInfo = nil }
    func storeClientID(_ clientID: String) throws { self.clientID = clientID }
    func loadClientID() throws -> String? { clientID }
    func storeClientSecret(_ clientSecret: String) throws { self.clientSecret = clientSecret }
    func loadClientSecret() throws -> String? { clientSecret }
    func storeUserInfo(_ info: GoogleUserInfo) throws { self.userInfo = info }
    func loadUserInfo() throws -> GoogleUserInfo? { userInfo }
}

// MARK: - ThrowingTokenProvider
// Test-Double für den Fall „Token-Refresh schlägt fehl" (z. B. widerrufenes
// Refresh-Token). Beweist, dass die Live-Clients jeden Provider-Fehler auf
// ihren eigenen .notConnected-Zustand mappen statt ihn durchzureichen.
struct ThrowingTokenProvider: GoogleAccessTokenProviding {
    let error: Error
    func validAccessToken() async throws -> String { throw error }
}

struct GoogleOAuthTests {

    @Test func pkceChallengeHatKorrektesFormat() {
        let pkce = GooglePKCEChallenge.generate()
        #expect(pkce.method == "S256")
        #expect(pkce.verifier.isEmpty == false)
        #expect(pkce.verifier.contains("+") == false)
        #expect(pkce.verifier.contains("/") == false)
        #expect(pkce.verifier.contains("=") == false)

        let digest = SHA256.hash(data: Data(pkce.verifier.utf8))
        let expectedChallenge = Data(digest).base64URLEncoded()
        #expect(pkce.challenge == expectedChallenge)
    }

    @Test func zweiChallengesSindNieGleich() {
        let a = GooglePKCEChallenge.generate()
        let b = GooglePKCEChallenge.generate()
        #expect(a.verifier != b.verifier)
    }

    @Test func authorizationURLEnthaeltPKCEUndState() throws {
        let service = GoogleOAuthPKCEService(clientID: "test-client", redirectURI: "http://127.0.0.1:54321")
        let request = try requireRequest(service.buildAuthorizationRequest(scopes: GoogleOAuthScope.readOnlyDefaults))

        let components = URLComponents(url: request.url, resolvingAgainstBaseURL: false)
        let items = Dictionary(uniqueKeysWithValues: (components?.queryItems ?? []).map { ($0.name, $0.value ?? "") })

        #expect(items["client_id"] == "test-client")
        #expect(items["redirect_uri"] == "http://127.0.0.1:54321")
        #expect(items["response_type"] == "code")
        #expect(items["code_challenge_method"] == "S256")
        #expect(items["code_challenge"] == request.pkce.challenge)
        #expect(items["access_type"] == "offline")
        #expect(items["prompt"] == "consent")
        #expect(items["state"] == request.state)
    }

    @Test func redirectParserPrueftState() {
        let service = GoogleOAuthPKCEService(clientID: "c", redirectURI: "http://127.0.0.1:1")

        let goodURL = URL(string: "http://127.0.0.1:1/?code=abc123&state=xyz")!
        #expect(service.parseRedirect(goodURL, expectedState: "xyz")?.code == "abc123")

        let badStateURL = URL(string: "http://127.0.0.1:1/?code=abc123&state=falsch")!
        #expect(service.parseRedirect(badStateURL, expectedState: "xyz") == nil)

        let missingCodeURL = URL(string: "http://127.0.0.1:1/?state=xyz")!
        #expect(service.parseRedirect(missingCodeURL, expectedState: "xyz") == nil)
    }

    @MainActor
    @Test func statusIstVerbundenWennTokenBereitsImStoreLiegt() {
        let store = InMemoryGoogleTokenStore()
        store.tokens = GoogleTokens(accessToken: "a", refreshToken: nil, expiresAt: Date())
        let service = GoogleAuthService(tokenStore: store, redirectServer: GoogleOAuthLoopbackRedirectServer())
        #expect(service.status == .connected)
    }

    @MainActor
    @Test func disconnectSetztStatusUndKeychainZurueck() throws {
        let store = InMemoryGoogleTokenStore()
        store.tokens = GoogleTokens(accessToken: "a", refreshToken: "r", expiresAt: Date())
        let service = GoogleAuthService(tokenStore: store, redirectServer: GoogleOAuthLoopbackRedirectServer())

        try service.disconnect()

        #expect(service.status == .disconnected)
        #expect(store.tokens == nil)
    }

    @MainActor
    @Test func startAuthorizationWirftBeiLeererClientID() async {
        let store = InMemoryGoogleTokenStore()
        let service = GoogleAuthService(tokenStore: store, redirectServer: GoogleOAuthLoopbackRedirectServer())

        do {
            try await service.startAuthorization(clientID: "   ")
            Issue.record("sollte werfen")
        } catch {
            #expect(error as? GoogleOAuthError == .missingClientID)
        }
        #expect(service.status == .error("Client-ID fehlt"))
    }

    private func requireRequest(_ request: GoogleOAuthAuthorizationRequest?) throws -> GoogleOAuthAuthorizationRequest {
        guard let request else {
            Issue.record("buildAuthorizationRequest sollte eine Request erzeugen")
            throw GoogleOAuthError.invalidEndpoint
        }
        return request
    }
}
