import Foundation
import AppKit
import Observation
import MykilosKit

// MARK: - GoogleAuthService
// Orchestriert den PKCE-Flow: Loopback starten, Browser öffnen, auf Redirect
// warten, Code gegen Token tauschen, Token im Keychain ablegen. Schreibt nie
// direkt — jeder Fehler wird geworfen, der Status zeigt ihn sichtbar an.
@MainActor
@Observable
public final class GoogleAuthService {
    public private(set) var status: GoogleConnectionStatus

    private let tokenStore: GoogleTokenStoring
    private let redirectServer: GoogleOAuthLoopbackRedirectServer
    private let scopes: [GoogleOAuthScope]

    public init(
        tokenStore: GoogleTokenStoring = KeychainGoogleTokenStore(),
        redirectServer: GoogleOAuthLoopbackRedirectServer = .shared,
        scopes: [GoogleOAuthScope] = GoogleOAuthScope.readOnlyDefaults
    ) {
        self.tokenStore = tokenStore
        self.redirectServer = redirectServer
        self.scopes = scopes
        self.status = (try? tokenStore.load()) != nil ? .connected : .disconnected
    }

    public func storedClientID() throws -> String? {
        try tokenStore.loadClientID()
    }

    public func storedClientSecret() throws -> String? {
        try tokenStore.loadClientSecret()
    }

    public func startAuthorization(clientID: String, clientSecret: String = "") async throws {
        let trimmedClientID = clientID.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedClientSecret = clientSecret.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedClientID.isEmpty == false else {
            status = .error("Client-ID fehlt")
            throw GoogleOAuthError.missingClientID
        }

        status = .connecting
        do {
            try tokenStore.storeClientID(trimmedClientID)
            if trimmedClientSecret.isEmpty == false {
                try tokenStore.storeClientSecret(trimmedClientSecret)
            }

            let redirectURI = try await redirectServer.start()
            let pkceService = GoogleOAuthPKCEService(
                clientID: trimmedClientID,
                clientSecret: trimmedClientSecret.isEmpty ? nil : trimmedClientSecret,
                redirectURI: redirectURI
            )
            guard let request = pkceService.buildAuthorizationRequest(scopes: scopes) else {
                throw GoogleOAuthError.invalidEndpoint
            }

            NSWorkspace.shared.open(request.url)

            let callbackURL = try await redirectServer.awaitRedirect()
            redirectServer.stop()

            guard let redirect = pkceService.parseRedirect(callbackURL, expectedState: request.state) else {
                throw GoogleOAuthError.redirectStateMismatch
            }

            let response = try await pkceService.exchangeCodeForToken(
                code: redirect.code,
                codeVerifier: request.pkce.verifier
            )
            let tokens = GoogleTokens(
                accessToken: response.accessToken,
                refreshToken: response.refreshToken,
                expiresAt: Date().addingTimeInterval(TimeInterval(response.expiresIn ?? 3600))
            )
            try tokenStore.store(tokens)
            status = .connected
        } catch {
            redirectServer.stop()
            status = .error(String(describing: error))
            throw error
        }
    }

    public func disconnect() throws {
        try tokenStore.clear()
        status = .disconnected
    }
}
