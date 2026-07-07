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
    // Gecachte Identität aus dem letzten erfolgreichen Login (S17).
    // nil = nie verbunden oder nach disconnect(). Non-fatal: fehlende
    // userinfo blockiert weder Login noch App-Start.
    public private(set) var currentUser: GoogleUserInfo?

    private let tokenStore: GoogleTokenStoring
    private let redirectServer: GoogleOAuthLoopbackRedirectServer
    private let scopes: [GoogleOAuthScope]
    private let userInfoClient: GoogleUserInfoFetching

    // MULTI-USER (2026-07-06): Hook fuer einen LIVE (nicht App-Start) erfolgreichen
    // Login. Bewusst eine settable var statt Init-Parameter, damit AppState sie erst
    // am ENDE seines eigenen init setzen kann (self muss dort schon vollstaendig
    // initialisiert sein, um sicher [weak self] zu capturen). Default nil -> Tests/
    // Call-Sites ohne AppState bleiben unveraendert.
    public var onLoginComplete: (@MainActor () async -> Void)?

    public init(
        tokenStore: GoogleTokenStoring = KeychainGoogleTokenStore(),
        redirectServer: GoogleOAuthLoopbackRedirectServer = .shared,
        scopes: [GoogleOAuthScope] = GoogleOAuthScope.readOnlyDefaults,
        userInfoClient: GoogleUserInfoFetching = GoogleUserInfoClient()
    ) {
        self.tokenStore = tokenStore
        self.redirectServer = redirectServer
        self.scopes = scopes
        self.userInfoClient = userInfoClient
        self.status = (try? tokenStore.load()) != nil ? .connected : .disconnected
        self.currentUser = try? tokenStore.loadUserInfo()
    }

    public func storedClientID() throws -> String? {
        try tokenStore.loadClientID()
    }

    public func storedClientSecret() throws -> String? {
        try tokenStore.loadClientSecret()
    }

    /// Legt NUR die OAuth-Client-Config ab (ID + optional Secret), OHNE den Login zu starten —
    /// für den Einladungs-Import (Schlüsselbund): der neue User bekommt die geteilte Client-
    /// Config, muss danach nur noch seinen persönlichen Google-Login machen (kein User-Token
    /// wandert je mit). Leere ID = No-Op (nichts zu setzen).
    public func storeClientConfig(clientID: String, clientSecret: String?) throws {
        let trimmedID = clientID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedID.isEmpty == false else { return }
        try tokenStore.storeClientID(trimmedID)
        if let clientSecret {
            let trimmedSecret = clientSecret.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmedSecret.isEmpty == false { try tokenStore.storeClientSecret(trimmedSecret) }
        }
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
            // Userinfo nicht-fatal: ein Profil-Hiccup darf den bereits
            // abgeschlossenen Token-Tausch nie zurückrollen.
            do {
                let info = try await userInfoClient.fetchUserInfo(accessToken: response.accessToken)
                try tokenStore.storeUserInfo(info)
                currentUser = info
            } catch {}
            status = .connected
            // MULTI-USER: nur nach einem ECHTEN Live-Login (dieser Punkt hier,
            // nicht App-Start-Hydration) -- schliesst die Login-Ausfloesung
            // (Sign-out-Marker aufheben, ggf. Neustart bei Bewohner-Wechsel).
            await onLoginComplete?()
        } catch {
            redirectServer.stop()
            status = .error(String(describing: error))
            throw error
        }
    }

    public func disconnect() throws {
        try tokenStore.clear()
        currentUser = nil
        status = .disconnected
    }

    /// Lädt GoogleUserInfo nach, wenn verbunden aber kein Cache vorhanden (B2-Fix).
    /// Non-fatal: Fehler werden still geschluckt — fehlendes UserInfo blockiert nie die App.
    public func refreshUserInfoIfNeeded() async {
        guard status == .connected, currentUser == nil else { return }
        do {
            let token = try await GoogleAccessTokenProvider(tokenStore: tokenStore).validAccessToken()
            let info = try await userInfoClient.fetchUserInfo(accessToken: token)
            try tokenStore.storeUserInfo(info)
            currentUser = info
        } catch {}
    }
}
